# Build the two KKCC two-mode networks as igraph objects with node attributes.
#   data/kkcc_two_mode.rds       fine: 56 notions x 135 definitions
#   data/kkcc_two_mode_main.rds  main: 16 categories x 135 definitions
# Each rds is list(biadjacency = <matrix>, graph = <igraph>).
# Inputs are files only: the fine biadjacency (the matrix stored in the previous
# rds), data/kkcc-concept-categories.csv, data/kkcc-definition-years.csv and
# data/kkcc-definition-biblio.csv. Verbatim definition texts are not embedded.
# Run from the project root in a fresh session, after build-concept-categories.R.

library(igraph)

fine_A <- readRDS("data/kkcc_two_mode.rds")$biadjacency
stopifnot(is.matrix(fine_A), all(fine_A %in% c(0, 1)))

concepts <- read.csv("data/kkcc-concept-categories.csv", stringsAsFactors = FALSE)
years    <- read.csv("data/kkcc-definition-years.csv", stringsAsFactors = FALSE)
biblio   <- read.csv("data/kkcc-definition-biblio.csv", stringsAsFactors = FALSE)
stopifnot(
  setequal(concepts$concept, rownames(fine_A)),
  setequal(years$code, colnames(fine_A)),
  setequal(biblio$code, colnames(fine_A)),
  !anyDuplicated(years$code), !anyDuplicated(biblio$code)
)

group_type <- c(A = "descriptive", B = "historical", C = "normative", D = "psychological",
                E = "structural", F = "genetic", G = "incomplete")

defs <- data.frame(code = colnames(fine_A), stringsAsFactors = FALSE)
defs <- merge(defs, years, by = "code", all.x = TRUE, sort = FALSE)
defs <- merge(defs, biblio[, c("code", "entry_id", "match_status", "author_canonical",
                               "bib_year", "bib_ref")], by = "code", all.x = TRUE, sort = FALSE)
defs <- defs[match(colnames(fine_A), defs$code), ]
stopifnot(identical(defs$code, colnames(fine_A)))

def_attr <- data.frame(
  name             = defs$code,
  node_type        = "definition",
  def_group        = substr(defs$group, 1, 1),
  def_subgroup     = defs$group,
  def_type         = unname(group_type[substr(defs$group, 1, 1)]),
  author           = defs$author,
  author_canonical = defs$author_canonical,
  year             = defs$year,
  year_orig        = defs$year_orig,
  year_suffix      = defs$year_suffix,
  decade           = defs$decade,
  bib_entry        = defs$entry_id,
  bib_year         = defs$bib_year,
  bib_ref          = defs$bib_ref,
  match_status     = defs$match_status,
  stringsAsFactors = FALSE
)

# Collapse to main categories: a main category takes the union (OR) of its own
# ties and its auxiliary notions' ties.
mains <- concepts$concept[concepts$is_main]
main_A <- t(sapply(mains, function(m) {
  rows <- concepts$concept[concepts$parent_category == m]
  as.numeric(colSums(fine_A[rows, , drop = FALSE]) > 0)
}))
dimnames(main_A) <- list(mains, colnames(fine_A))
stopifnot(all(main_A %in% c(0, 1)))

old_main <- read.csv("data/kkcc_biadjacency_main.csv", row.names = 1, check.names = FALSE)
stopifnot(identical(dim(old_main), dim(main_A)),
          all(rownames(old_main) == rownames(main_A)),
          all(as.matrix(old_main) == main_A))

make_graph <- function(A, concept_attr, source_files, built) {
  g <- graph_from_biadjacency_matrix(A, directed = FALSE, multiple = FALSE)
  stopifnot(identical(V(g)$name[!V(g)$type], rownames(A)),
            identical(V(g)$name[V(g)$type], colnames(A)))
  ci <- match(V(g)$name, concept_attr$name)
  di <- match(V(g)$name, def_attr$name)
  is_def <- V(g)$type
  for (a in setdiff(names(def_attr), "name")) {
    val <- rep(NA, vcount(g))
    val[is_def] <- def_attr[[a]][di[is_def]]
    vertex_attr(g, a) <- val
  }
  for (a in setdiff(names(concept_attr), "name")) {
    val <- rep(NA, vcount(g))
    val[!is_def] <- concept_attr[[a]][ci[!is_def]]
    vertex_attr(g, a) <- val
  }
  graph_attr(g, "name") <- source_files$name
  graph_attr(g, "built") <- built
  graph_attr(g, "source_files") <- paste(source_files$files, collapse = "; ")
  graph_attr(g, "igraph_version") <- as.character(packageVersion("igraph"))
  g
}

built <- format(Sys.Date())
src <- "data/kkcc-concept-categories.csv; data/kkcc-definition-years.csv; data/kkcc-definition-biblio.csv"

fine_concepts <- data.frame(
  name = concepts$concept,
  node_type = "concept",
  is_main = concepts$is_main,
  parent_category = concepts$parent_category,
  list_item = concepts$list_item,
  printed_uses = concepts$printed_uses,
  n_uses = rowSums(fine_A)[match(concepts$concept, rownames(fine_A))],
  stringsAsFactors = FALSE
)
g_fine <- make_graph(fine_A, fine_concepts, list(name = "kkcc_two_mode", files = src), built)

main_concepts <- data.frame(
  name = mains,
  node_type = "concept",
  is_main = TRUE,
  parent_category = mains,
  list_item = concepts$list_item[match(mains, concepts$concept)],
  printed_uses = concepts$printed_uses[match(mains, concepts$concept)],
  n_uses = rowSums(main_A)[mains],
  stringsAsFactors = FALSE
)
g_main <- make_graph(main_A, main_concepts, list(name = "kkcc_two_mode_main",
                     files = paste0(src, "; data/kkcc_two_mode.rds"), built = built), built)

saveRDS(list(biadjacency = fine_A, graph = g_fine), "data/kkcc_two_mode.rds")
saveRDS(list(biadjacency = main_A, graph = g_main), "data/kkcc_two_mode_main.rds")
write.csv(main_A, "data/kkcc_biadjacency_main.csv")
cat("fine:", vcount(g_fine), "vertices,", ecount(g_fine), "edges\n")
cat("main:", vcount(g_main), "vertices,", ecount(g_main), "edges\n")
