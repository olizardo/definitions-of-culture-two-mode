# Build the K&K Index B two-mode networks as igraph objects, from K&K's own
# index (not from Boroch's Table 2):
#   data/kk-index-b-subelement-network.rds  sub-elements x K&K codes
#   data/kk-index-b-heading-network.rds     headings x K&K codes
# Each rds is list(biadjacency = <matrix>, graph = <igraph>), as in the Boroch
# networks. Inputs are files only. Run from the project root in a fresh session,
# after build-index-b.R and build-index-b-crosswalk.R.

library(igraph)

edges <- read.csv("data/kk-index-b-edges.csv", stringsAsFactors = FALSE)
defs  <- read.csv("data/kk-index-b-definitions.csv", stringsAsFactors = FALSE)
cw    <- read.csv("data/kk-boroch-crosswalk.csv", stringsAsFactors = FALSE)
links <- read.csv("data/kkcc-appendix-only-links.csv", stringsAsFactors = FALSE)

universe <- sort(unique(defs$kk_code), method = "radix")
stopifnot(
  !anyDuplicated(defs$kk_code),
  !anyNA(edges$kk_code), all(edges$kk_code %in% universe),
  all(nzchar(edges$sub_element)), all(nzchar(edges$heading))
)

join_sorted <- function(x) paste(sort(unique(x)), collapse = "; ")

# Boroch correspondence: Table 2 crosswalk plus linked appendix-only codes.
# A K&K code can carry two Boroch codes; the values are joined. Verbatim copies
# excluded in the crosswalk (A10a, C1-5a, F4-6) carry no code here.
t2 <- data.frame(kk_code = cw$kk_code, boroch_code = cw$boroch_code,
                 boroch_source = "table2", stringsAsFactors = FALSE)
t2 <- t2[!is.na(t2$kk_code) & nzchar(t2$kk_code), ]
ap <- data.frame(kk_code = links$kk_row, boroch_code = links$code,
                 boroch_source = "appendix-only", stringsAsFactors = FALSE)
ap <- ap[grepl("^linked", links$verdict) & ap$kk_code %in% universe, ]
bz <- rbind(t2, ap)
boroch_map <- data.frame(
  kk_code = sort(unique(bz$kk_code), method = "radix"),
  stringsAsFactors = FALSE
)
boroch_map$boroch_code <- vapply(boroch_map$kk_code,
  function(k) join_sorted(bz$boroch_code[bz$kk_code == k]), "")
boroch_map$boroch_source <- vapply(boroch_map$kk_code,
  function(k) join_sorted(bz$boroch_source[bz$kk_code == k]), "")

code_attr <- data.frame(
  name = defs$kk_code,
  node_type = "kk_code",
  kk_group = defs$group,
  kk_subgroup = defs$subgroup,
  in_index_a = defs$in_index_a,
  in_index_b = defs$in_index_b,
  n_index_b_elements = defs$n_index_b_elements,
  index_a_authors = defs$index_a_authors,
  boroch_code = boroch_map$boroch_code[match(defs$kk_code, boroch_map$kk_code)],
  boroch_source = boroch_map$boroch_source[match(defs$kk_code, boroch_map$kk_code)],
  stringsAsFactors = FALSE
)

# Biadjacency matrix from (element, code) pairs: 1 if the pair occurs at least once.
biadj <- function(pairs, element_col) {
  rl <- sort(unique(pairs[[element_col]]), method = "radix")
  m <- matrix(0L, nrow = length(rl), ncol = length(universe),
              dimnames = list(rl, universe))
  m[cbind(match(pairs[[element_col]], rl), match(pairs$kk_code, universe))] <- 1L
  m
}

# Edge table: one row per unique (element, code) tie, with the number of source
# rows behind it and the parse flags those rows carry.
edge_table <- function(element_col) {
  key <- paste(edges[[element_col]], edges$kk_code, sep = "\t")
  ukey <- unique(key)
  data.frame(
    element = edges[[element_col]][match(ukey, key)],
    code = edges$kk_code[match(ukey, key)],
    n_source_rows = as.integer(table(factor(key, levels = ukey))),
    parse_flags = vapply(ukey, function(k) join_sorted(edges$parse_flag[key == k]), ""),
    stringsAsFactors = FALSE
  )
}

make_network <- function(m, element_attr, etab, name) {
  g <- graph_from_biadjacency_matrix(m, directed = FALSE, multiple = FALSE)
  stopifnot(identical(V(g)$name[!V(g)$type], rownames(m)),
            identical(V(g)$name[V(g)$type], colnames(m)))
  is_code <- V(g)$type
  ci <- match(V(g)$name, code_attr$name)
  ei <- match(V(g)$name, element_attr$name)
  for (a in setdiff(names(code_attr), "name")) {
    val <- rep(NA, vcount(g)); val[is_code] <- code_attr[[a]][ci[is_code]]
    vertex_attr(g, a) <- val
  }
  for (a in setdiff(names(element_attr), "name")) {
    val <- rep(NA, vcount(g)); val[!is_code] <- element_attr[[a]][ei[!is_code]]
    vertex_attr(g, a) <- val
  }
  el <- as_edgelist(g, names = TRUE)   # (element, code): element vertices come first
  stopifnot(all(m[cbind(el[, 1], el[, 2])] == 1))
  ek <- match(paste(el[, 1], el[, 2], sep = "\t"), paste(etab$element, etab$code, sep = "\t"))
  stopifnot(!anyNA(ek))
  edge_attr(g, "n_source_rows") <- etab$n_source_rows[ek]
  edge_attr(g, "parse_flags") <- etab$parse_flags[ek]
  graph_attr(g, "name") <- name
  graph_attr(g, "built") <- format(Sys.Date())
  graph_attr(g, "igraph_version") <- as.character(packageVersion("igraph"))
  graph_attr(g, "source_files") <- paste(c("data/kk-index-b-edges.csv",
    "data/kk-index-b-definitions.csv", "data/kk-boroch-crosswalk.csv",
    "data/kkcc-appendix-only-links.csv"), collapse = "; ")
  graph_attr(g, "caveat") <- paste(
    "Heading attribution is unreliable in several blocks (PROVENANCE, Index B open items).",
    "Codes and sub-elements are as printed in K&K's index; Index B has not been fully verified.")
  g
}

# Sub-element level. A sub-element can sit under two headings (39 cases); the
# vertex lists them, and the row is keyed by sub-element.
sub_m <- biadj(edges, "sub_element")
sub_names <- rownames(sub_m)
sub_attr <- data.frame(
  name = sub_names,
  node_type = "sub_element",
  headings = vapply(sub_names, function(s) join_sorted(edges$heading[edges$sub_element == s]), ""),
  n_headings = vapply(sub_names, function(s) length(unique(edges$heading[edges$sub_element == s])), 1L),
  n_codes = as.integer(rowSums(sub_m)),
  has_junk_name = vapply(sub_names, function(s) any(edges$parse_flag[edges$sub_element == s] == "junk_name"), NA),
  has_manual_fix = vapply(sub_names, function(s) any(edges$parse_flag[edges$sub_element == s] == "manual_fix"), NA),
  has_ocr_correction = vapply(sub_names, function(s) any(edges$parse_flag[edges$sub_element == s] == "ocr_corrected"), NA),
  stringsAsFactors = FALSE
)
g_sub <- make_network(sub_m, sub_attr, edge_table("sub_element"), "kk_index_b_subelement")

# Heading level: one row per heading.
head_m <- biadj(data.frame(heading = edges$heading, kk_code = edges$kk_code,
                           stringsAsFactors = FALSE), "heading")
head_names <- rownames(head_m)
head_attr <- data.frame(
  name = head_names,
  node_type = "heading",
  n_subelements = vapply(head_names, function(h) length(unique(edges$sub_element[edges$heading == h])), 1L),
  n_codes = as.integer(rowSums(head_m)),
  stringsAsFactors = FALSE
)
g_head <- make_network(head_m, head_attr, edge_table("heading"), "kk_index_b_heading")

saveRDS(list(biadjacency = sub_m, graph = g_sub), "data/kk-index-b-subelement-network.rds")
saveRDS(list(biadjacency = head_m, graph = g_head), "data/kk-index-b-heading-network.rds")
cat("subelement:", nrow(sub_m), "x", ncol(sub_m), "ties", sum(sub_m), "\n")
cat("heading:", nrow(head_m), "x", ncol(head_m), "ties", sum(head_m), "\n")
