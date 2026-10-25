# Concept network by unique works, K&K Index B LCC 2-core.
#
# Codes are categories and can hold several works, and one work can sit under
# several codes (see PROVENANCE). Here a work is keyed by its author set and year
# string, built from the Index A entries under each code. Two sub-elements are
# tied by the number of distinct works that cite both. Input: the same 2-core as
# scripts/analysis-ca-index-b.R.

library(igraph)

set.seed(8427)

g <- readRDS("data/kk-index-b-verified-network.rds")$graph
comp <- components(g)
gl <- induced_subgraph(g, comp$membership == which.max(comp$csize))
el <- as_edgelist(gl, names = TRUE)
Al <- matrix(0, nrow = length(unique(el[, 1])), ncol = length(unique(el[, 2])),
             dimnames = list(sort(unique(el[, 1])), sort(unique(el[, 2]))))
Al[cbind(el[, 1], el[, 2])] <- 1
Ac <- Al
repeat {
  keep.r <- rowSums(Ac) >= 2
  keep.c <- colSums(Ac) >= 2
  if (all(keep.r) && all(keep.c)) break
  Ac <- Ac[keep.r, keep.c, drop = FALSE]
}

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

# concept projection, weight = number of distinct works citing both
P.w <- M %*% t(M); diag(P.w) <- 0
G.w <- graph_from_adjacency_matrix(P.w, mode = "undirected", weighted = TRUE, diag = FALSE)
cat("concepts:", nrow(M), "| works with >=1 concept:", sum(colSums(M) > 0),
    "| concept pairs sharing a work:", ecount(G.w), "\n")

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

saveRDS(list(incidence = M, projection = P.w, graph = G.w, works = work.tab),
        "data/kk-index-b-work-concept-network.rds")
cat("works table and network written\n")
