# Concept network by unique works, K&K Index B, all nodes. No LCC or 2-core is
# taken here; analyses select their subgraph with scripts/core-index-b.R.
#
# Codes are categories and can hold several works, and one work can sit under
# several codes (see PROVENANCE). Here a work is keyed by its author set and year
# string, built from the Index A entries under each code. Two sub-elements are
# tied by the number of distinct works that cite both. Input: the same 2-core as
# scripts/analysis-ca-index-b.R.

library(igraph)

set.seed(8427)

# Sub-elements x codes, all codes (codes with no sub-element are zero columns).
Ac <- readRDS("data/kk-index-b-verified-network.rds")$biadjacency

defs <- read.csv("data/kk-index-b-definitions.csv", stringsAsFactors = FALSE)
ia <- setNames(defs$index_a_authors, defs$kk_code)

# Authors named in one Index A entry: the main name plus any co-author in
# "(with X, year)" or "(all in collaboration with X, year)"
entry.names <- function(e) {
  main <- trimws(sub("\\s*\\(.*$", "", e))
  co <- if (grepl("\\(.*with ", e)) trimws(sub(".*with ([^,]+),.*", "\\1", e)) else character()
  unique(c(main, co))
}

# A co-author written as a prefix of a full name in the same year group ("Gillin"
# for "Gillin John P", "Davis" for "Davis Allison") takes the full name. Only a
# unique match is used, so "Davis" stays put when two full names share it.
# Reviewed exceptions (data/kk-index-b-name-decisions.csv) override the rule: a
# name with a decision takes that work name and is not prefix-merged.
decisions <- read.csv("data/kk-index-b-name-decisions.csv", stringsAsFactors = FALSE)
canon.names <- function(nm, year) {
  dec <- decisions[decisions$year == year, ]
  for (i in seq_len(nrow(dec))) nm[nm == dec$index_name[i]] <- dec$work_name[i]
  decided <- dec$work_name
  for (x in setdiff(nm, decided)) {
    full <- setdiff(nm[startsWith(nm, paste0(x, " "))], decided)
    if (length(full) == 1) nm[nm == x] <- full
  }
  unique(nm)
}

# Works of one code: entries grouped by year; names are unioned within a year
code.works <- function(s) {
  if (is.na(s) || !nzchar(s)) return(character())
  ents <- trimws(strsplit(s, ";")[[1]])
  # Per-entry year, "" when absent. regmatches() would drop unmatched entries and
  # misalign the years with the entries that follow them.
  has.yr <- grepl("[0-9]{3,4}[a-z]?", ents)
  yr <- ifelse(has.yr, sub("^.*?([0-9]{3,4}[a-z]?).*$", "\\1", ents, perl = TRUE), "")
  ok <- nzchar(yr)
  if (!all(ok)) warning("entry without a year: ", paste(ents[!ok], collapse = " | "))
  ents <- ents[ok]; yr <- yr[ok]
  keys <- vapply(unique(yr), function(y) {
    nm <- canon.names(unique(unlist(lapply(ents[yr == y], entry.names))), y)
    paste(paste(sort(nm), collapse = " & "), y)
  }, character(1))
  unname(keys)
}

codes <- colnames(Ac)
code.w <- setNames(lapply(codes, function(k) code.works(ia[[k]])), codes)
works <- sort(unique(unlist(code.w)))
cat("codes:", length(codes), "| codes with no work:", sum(lengths(code.w) == 0),
    "| works:", length(works), "\n")

# code x work incidence, then concept x work via the 2-core
A.cw <- matrix(0, nrow = length(codes), ncol = length(works),
               dimnames = list(codes, works))
for (k in codes) A.cw[k, code.w[[k]]] <- 1
M <- (Ac %*% A.cw > 0) * 1
storage.mode(M) <- "numeric"

# Sub-element vertex attributes, copied from the verified (definitions) network
ver <- readRDS("data/kk-index-b-verified-network.rds")$graph
ver.sub <- V(ver)[!V(ver)$type]
sub.attrs <- Filter(function(a) any(!is.na(vertex_attr(ver, a, ver.sub))),
                    setdiff(vertex_attr_names(ver), "name"))
cat("concepts:", nrow(M), "| works with >=1 concept:", sum(colSums(M) > 0), "\n")

# works table: one row per work, with the codes that hold it
work.tab <- data.frame(
  work = works,
  n_codes = colSums(A.cw),
  codes = vapply(works, function(w) paste(names(which(A.cw[, w] == 1)), collapse = "; "),
                 character(1)),
  n_concepts = colSums(M),
  stringsAsFactors = FALSE)
work.tab <- work.tab[order(-work.tab$n_codes, work.tab$work), ]
write.csv(work.tab, "data/kk-index-b-works.csv", row.names = FALSE)

# Heading x work: a work is under a heading if one of its codes is under that heading
hd <- readRDS("data/kk-index-b-heading-network.rds")$biadjacency
hd <- hd[, rownames(A.cw), drop = FALSE]
stopifnot(all(colnames(hd) == rownames(A.cw)))
H.w <- (hd %*% A.cw > 0) * 1
cat("heading x work:", nrow(H.w), "headings x", ncol(H.w), "works, works with >=1 heading:",
    sum(colSums(H.w) > 0), "\n")

# Work x work graph: used only to attach work attributes; projections are not saved
source("scripts/label-authors-index-b.R")
Q.all <- crossprod(M); diag(Q.all) <- 0
G.work <- graph_from_adjacency_matrix(Q.all, mode = "undirected", weighted = TRUE, diag = FALSE)
w.idx <- match(V(G.work)$name, work.tab$work)
stopifnot(!anyNA(w.idx))
# Year is the last token of the work key, kept as printed (letter suffix included)
w.year <- sub(".*\\s", "", V(G.work)$name)
stopifnot(all(grepl("^[0-9]{3,4}[a-z]?$", w.year)))
V(G.work)$n_codes <- work.tab$n_codes[w.idx]
V(G.work)$codes <- work.tab$codes[w.idx]
V(G.work)$n_concepts <- work.tab$n_concepts[w.idx]
V(G.work)$year <- w.year
V(G.work)$decade <- as.integer(floor(as.integer(sub("[a-z]$", "", w.year)) / 10) * 10)
V(G.work)$label <- vapply(V(G.work)$name, label.authors, character(1))

# Sub-element x work two-mode graph. type is FALSE for sub-elements, TRUE for works
# (set by the bipartite construction), so it is not copied from the verified network.
G.two <- graph_from_biadjacency_matrix(M, directed = FALSE, multiple = FALSE)
stopifnot(identical(V(G.two)$name[!V(G.two)$type], rownames(M)),
          identical(V(G.two)$name[V(G.two)$type], colnames(M)),
          !anyDuplicated(V(G.two)$name))
s.pos <- which(!V(G.two)$type)
w.pos <- which(V(G.two)$type)
s.match <- match(V(G.two)$name[s.pos], ver.sub$name)
stopifnot(!anyNA(s.match))
for (a in setdiff(sub.attrs, "type")) {
  val <- rep(NA, vcount(G.two))
  val[s.pos] <- vertex_attr(ver, a, ver.sub)[s.match]
  vertex_attr(G.two, a) <- val
}
w.match <- match(V(G.two)$name[w.pos], V(G.work)$name)
stopifnot(!anyNA(w.match))
for (a in c("n_codes", "codes", "n_concepts", "year", "decade", "label")) {
  val <- if (a %in% vertex_attr_names(G.two)) vertex_attr(G.two, a) else rep(NA, vcount(G.two))
  val[w.pos] <- vertex_attr(G.work, a)[w.match]
  vertex_attr(G.two, a) <- val
}
vertex_attr(G.two, "node_type") <- ifelse(V(G.two)$type, "work", "sub_element")

# Heading x work two-mode graph; heading vertices take the heading attributes from the heading network
hg <- readRDS("data/kk-index-b-heading-network.rds")$graph
G.hw <- graph_from_biadjacency_matrix(H.w, directed = FALSE, multiple = FALSE)
stopifnot(identical(V(G.hw)$name[!V(G.hw)$type], rownames(H.w)),
          identical(V(G.hw)$name[V(G.hw)$type], colnames(H.w)),
          !anyDuplicated(V(G.hw)$name))
h.pos <- which(!V(G.hw)$type)
hw.pos <- which(V(G.hw)$type)
h.match <- match(V(G.hw)$name[h.pos], V(hg)$name)
stopifnot(!anyNA(h.match))
for (a in c("n_subelements", "n_codes")) {
  val <- if (a %in% vertex_attr_names(G.hw)) vertex_attr(G.hw, a) else rep(NA, vcount(G.hw))
  val[h.pos] <- vertex_attr(hg, a)[h.match]
  vertex_attr(G.hw, a) <- val
}
hw.match <- match(V(G.hw)$name[hw.pos], V(G.work)$name)
stopifnot(!anyNA(hw.match))
for (a in c("n_codes", "codes", "n_concepts", "year", "decade", "label")) {
  val <- if (a %in% vertex_attr_names(G.hw)) vertex_attr(G.hw, a) else rep(NA, vcount(G.hw))
  val[hw.pos] <- vertex_attr(G.work, a)[hw.match]
  vertex_attr(G.hw, a) <- val
}
vertex_attr(G.hw, "node_type") <- ifelse(V(G.hw)$type, "work", "heading")

saveRDS(list(works = work.tab, two_mode_graph = G.two, two_mode_heading_graph = G.hw),
        "data/kk-index-b-work-concept-network-full.rds")
cat("works table and network written\n")
