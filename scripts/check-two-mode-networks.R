# Validate the rebuilt two-mode networks (run after build-two-mode-networks.R).
# Reads the pre-rebuild backup (OLD_RDS env var, default: the scratch copy) to check
# that definition type/group are unchanged.

library(igraph)

fine <- readRDS("data/kkcc_two_mode.rds")
main <- readRDS("data/kkcc_two_mode_main.rds")
years  <- read.csv("data/kkcc-definition-years.csv", stringsAsFactors = FALSE)
biblio <- read.csv("data/kkcc-definition-biblio.csv", stringsAsFactors = FALSE)
concepts <- read.csv("data/kkcc-concept-categories.csv", stringsAsFactors = FALSE)

fail <- function(msg) stop("CHECK FAILED: ", msg, call. = FALSE)
ok <- function(msg) cat("ok:", msg, "\n")

for (nm in c("fine", "main")) {
  obj <- get(nm)
  g <- obj$graph; A <- obj$biadjacency
  if (!inherits(g, "igraph")) fail(paste(nm, "graph is not igraph"))
  if (!is_bipartite(g)) fail(paste(nm, "not bipartite"))
  if (!identical(V(g)$name[!V(g)$type], rownames(A))) fail(paste(nm, "concept order"))
  if (!identical(V(g)$name[V(g)$type], colnames(A))) fail(paste(nm, "definition order"))
  if (ecount(g) != sum(A)) fail(paste(nm, "edge count != ties"))
  el <- as_edgelist(g, names = TRUE)
  if (!all(A[cbind(el[, 1], el[, 2])] == 1)) fail(paste(nm, "edges not in matrix"))
  if (sum(degree(g)[V(g)$type] == 0) > 0) fail(paste(nm, "isolated definitions"))
  # The fine network is disconnected by design (6 small components split off;
  # see PROVENANCE). The main network must be connected.
  if (nm == "main" && !is_connected(g)) fail("main not connected")
  if (nm == "fine" && components(g)$no != 7) fail("fine component count changed")
  ok(sprintf("%s: %d vertices, %d edges, bipartite, %d component(s), adjacency matches matrix",
             nm, vcount(g), ecount(g), components(g)$no))

  d <- V(g)[V(g)$type]; cn <- V(g)[!V(g)$type]
  m <- match(d$name, years$code)
  b <- match(d$name, biblio$code)
  if (!identical(d$author, years$author[m])) fail(paste(nm, "author"))
  if (!identical(as.integer(d$year), as.integer(years$year[m]))) fail(paste(nm, "year"))
  if (!identical(as.integer(d$decade), as.integer(years$decade[m]))) fail(paste(nm, "decade"))
  if (!identical(d$year_suffix, years$year_suffix[m])) fail(paste(nm, "year_suffix"))
  if (!identical(d$bib_entry, biblio$entry_id[b])) fail(paste(nm, "bib_entry"))
  if (!identical(d$bib_ref, biblio$bib_ref[b])) fail(paste(nm, "bib_ref"))
  if (!identical(d$match_status, biblio$match_status[b])) fail(paste(nm, "match_status"))
  if (!identical(d$def_subgroup, years$group[m])) fail(paste(nm, "subgroup"))
  if (!all(d$def_group == substr(d$def_subgroup, 1, 1))) fail(paste(nm, "group letter"))
  ok(sprintf("%s: definition attributes match the CSVs for all %d definitions", nm, length(d)))

  if (any(cn$node_type != "concept")) fail(paste(nm, "concept node_type"))
  if (!all(cn$parent_category %in% concepts$parent_category)) fail(paste(nm, "parent category"))
  ok(sprintf("%s: %d concepts with parent categories", nm, length(cn)))
}

# Reference copy: OLD_RDS if set, otherwise the last committed version from git.
old_path <- Sys.getenv("OLD_RDS", unset = "")
old <- if (nzchar(old_path)) {
  readRDS(old_path)
} else {
  con <- pipe("git show HEAD:data/kkcc_two_mode.rds", "rb")
  obj <- readRDS(gzcon(con))
  close(con)
  obj
}
if (!is.null(old$def_attrs)) {
  dv <- V(fine$graph)[V(fine$graph)$type]
  o <- old$def_attrs[match(dv$name, old$def_attrs$code), ]
  if (!identical(dv$def_group, o$group)) fail("def_group differs from pre-rebuild def_attrs")
  if (!identical(dv$def_type, o$type)) fail("def_type differs from pre-rebuild def_attrs")
  ok("def_group and def_type match the pre-rebuild def_attrs")
}
if (!identical(fine$biadjacency, old$biadjacency)) fail("fine biadjacency changed")
ok("fine biadjacency identical to pre-rebuild matrix")
