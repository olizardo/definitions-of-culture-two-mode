# Validate the rebuilt K&K Index B two-mode networks (run after
# build-index-b-networks.R). Checks both igraph objects against the CSV
# inputs they were built from: the edge list, the definition registry, and
# the Boroch crosswalk.

library(igraph)

subel <- readRDS("data/kk-index-b-subelement-network.rds")
headn <- readRDS("data/kk-index-b-heading-network.rds")
edges <- read.csv("data/kk-index-b-edges.csv", stringsAsFactors = FALSE)
defs  <- read.csv("data/kk-index-b-definitions.csv", stringsAsFactors = FALSE)
xwalk <- read.csv("data/kk-boroch-crosswalk.csv", stringsAsFactors = FALSE)

fail <- function(msg) stop("CHECK FAILED: ", msg, call. = FALSE)
ok <- function(msg) cat("ok:", msg, "\n")

# Expected (heading, element, code) pairs from the edge list. The builder
# deduplicates on kk_code + heading + sub_element, so these are unique.
pairs <- unique(edges[, c("kk_code", "heading", "sub_element")])
if (anyDuplicated(pairs)) fail("duplicate edge rows")

for (nm in c("subel", "headn")) {
  obj <- get(nm)
  g <- obj$graph; A <- obj$biadjacency
  if (!inherits(g, "igraph")) fail(paste(nm, "graph is not igraph"))
  if (!is_bipartite(g)) fail(paste(nm, "not bipartite"))
  if (!all(A %in% c(0, 1))) fail(paste(nm, "matrix is not binary"))
  # Rows are the K&K element vertices (type FALSE), columns the codes.
  if (!identical(V(g)$name[!V(g)$type], rownames(A))) fail(paste(nm, "element order"))
  if (!identical(V(g)$name[V(g)$type], colnames(A))) fail(paste(nm, "code order"))
  if (ecount(g) != sum(A)) fail(paste(nm, "edge count != ties"))
  # node_type labels the element vertices; code vertices carry NA there.
  expected_el <- if (nm == "subel") "sub_element" else "heading"
  if (!all(V(g)$node_type[!V(g)$type] == expected_el) ||
      !all(is.na(V(g)$node_type[V(g)$type])))
    fail(paste(nm, "node_type does not match the bipartite type"))
  # Round-trip: the matrix rebuilt from the graph must equal the stored one.
  rt <- as.matrix(as_biadjacency_matrix(g))
  rt <- rt[rownames(A), colnames(A)]
  if (!identical((rt != 0), (A != 0))) fail(paste(nm, "graph/matrix round-trip"))
  ok(sprintf("%s: %d vertices, %d edges, bipartite, %d components, adjacency matches matrix",
             nm, vcount(g), ecount(g), components(g)$no))
}

# The sub-element matrix must contain exactly the distinct (element, code)
# pairs. It collapses edge rows that share an element and code under
# different headings (e.g. "systems" is shared by two blocks), so the count
# is smaller than the edge list.
el <- as_edgelist(subel$graph, names = TRUE)
ucode <- unique(pairs[, c("sub_element", "kk_code")])
if (nrow(el) != nrow(ucode))
  fail("sub-element tie count != distinct (element, code) pairs")
key_graph <- paste(el[, 1], el[, 2], sep = "\r")
key_csv   <- paste(ucode$sub_element, ucode$kk_code, sep = "\r")
if (!setequal(key_graph, key_csv)) fail("sub-element (element, code) pairs differ from the edge list")

# The heading matrix must contain exactly the (heading, code) pairs.
hl <- as_edgelist(headn$graph, names = TRUE)
hcsv <- unique(edges[, c("kk_code", "heading")])
if (nrow(hl) != nrow(hcsv)) fail("heading edge count != unique (heading, code) pairs")
key_gh <- paste(hl[, 1], hl[, 2], sep = "\r")
key_ch <- paste(hcsv$heading, hcsv$kk_code, sep = "\r")
if (!setequal(key_gh, key_ch)) fail("heading (heading, code) pairs differ from the edge list")

# Each sub-element belongs to the headings its edges claim. The 'headings'
# attribute is a "; "-joined string (the builder sorts and joins).
hv <- V(subel$graph)[V(subel$graph)$type == FALSE]
for (i in seq_len(nrow(pairs))) {
  h <- strsplit(hv$headings[match(pairs$sub_element[i], hv$name)], "; ", fixed = TRUE)[[1]]
  if (!pairs$heading[i] %in% h)
    fail(sprintf("element '%s' does not list heading '%s'",
                 pairs$sub_element[i], pairs$heading[i]))
}
ok(sprintf("every (heading, sub_element) pair agrees with the element 'headings' attribute (%d elements)",
           length(hv)))

# Code-vertex attributes against the definition registry.
cv <- V(subel$graph)[V(subel$graph)$type == TRUE]
m <- match(cv$name, defs$kk_code)
if (anyNA(m)) fail("code vertex missing from the definition registry")
if (!identical(as.logical(cv$in_index_a), as.logical(defs$in_index_a[m])))
  fail("in_index_a attribute")
if (!identical(as.logical(cv$in_index_b), as.logical(defs$in_index_b[m])))
  fail("in_index_b attribute")
if (!identical(as.integer(cv$n_index_b_elements),
               as.integer(defs$n_index_b_elements[m])))
  fail("n_index_b_elements attribute")
if (!identical(cv$index_a_authors, defs$index_a_authors[m]))
  fail("index_a_authors attribute")
if (!identical(cv$kk_group, defs$group[m])) fail("kk_group attribute")
if (!identical(cv$kk_subgroup, defs$subgroup[m])) fail("kk_subgroup attribute")
# n_index_b_elements counts the code's edge ROWS (heading x sub_element pairs),
# which is larger than its sub-element degree when a sub-element sits under
# two headings (the matrix collapses those). Codes with no Index B edges get 0.
n_rows <- table(edges$kk_code)[cv$name]
n_rows[is.na(n_rows)] <- 0L
if (!all(as.integer(cv$n_index_b_elements) == as.integer(n_rows)))
  fail("n_index_b_elements != edge-row count")
ok(sprintf("code attributes match the definition registry for all %d codes", length(cv)))

# Boroch code on the code vertices: each crosswalk kk_code must appear in the
# vertex's boroch_code string (F-IV-5 legitimately carries two codes). The
# attribute is a "; "-joined string.
xw <- xwalk[!is.na(xwalk$kk_code) & xwalk$kk_code != "", ]
bc <- setNames(strsplit(as.character(cv$boroch_code), "; ", fixed = TRUE),
               cv$name)
bad <- vapply(seq_len(nrow(xw)), function(i) {
  v <- bc[[xw$kk_code[i]]]
  if (is.null(v)) return(TRUE)
  !xw$boroch_code[i] %in% v
}, logical(1))
if (any(bad)) fail(sprintf("crosswalk code(s) missing from the graph: %s",
                           paste(xw$kk_code[bad], collapse = ", ")))
ok(sprintf("all %d crosswalk matches are present on the code vertices", nrow(xw)))

cat(sprintf("done: sub-element %d x %d (%d ties), heading %d x %d (%d ties), %d edges\n",
            nrow(subel$biadjacency), ncol(subel$biadjacency), sum(subel$biadjacency),
            nrow(headn$biadjacency), ncol(headn$biadjacency), sum(headn$biadjacency),
            nrow(edges)))
