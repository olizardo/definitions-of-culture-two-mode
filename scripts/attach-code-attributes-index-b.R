# Attach per-code source citation attributes and publication type to the
# definitions networks.
#
# Input:  data/kkcc-definition-source-pages.csv (one row per Boroch code: K&K code,
#         Boroch author, year and printed pinpoint, quote opening)
#         data/kk-index-b-verified-network.rds, data/kk-index-b-heading-network.rds
#         data/kk-index-b-works.csv, data/kk-index-b-work-pub-type.csv
# Output: the same .rds files. Code vertices of the verified network carry
#         source_author, source_year, source_page and quote_opening (joined with
#         "; " when a code has more than one Boroch row). Code vertices of both
#         networks carry pub_type, the publication type of the work K&K index
#         under the code (PROVENANCE 21); NA on the other mode and on the codes
#         with no work.
#
# Run after build-index-b-verified.R, which rewrites the verified network.

library(igraph)

path <- "data/kk-index-b-verified-network.rds"
sp <- read.csv("data/kkcc-definition-source-pages.csv", stringsAsFactors = FALSE, na.strings = "")
sp <- sp[!is.na(sp$kk_code) & sp$kk_code != "C-I-Addendum", ]
sp$source_page[is.na(sp$source_page)] <- "none"

join <- function(x) paste(x, collapse = "; ")
agg <- do.call(rbind, lapply(split(sp, sp$kk_code), function(x) data.frame(
  kk_code = x$kk_code[1],
  source_author = join(x$boroch_author),
  source_year = join(x$boroch_year),
  source_page = join(x$source_page),
  quote_opening = join(x$quote_opening),
  stringsAsFactors = FALSE)))

vn <- readRDS(path)
g <- vn$graph
bi0 <- as_biadjacency_matrix(g, sparse = FALSE)

verified <- as_ids(V(g))[!V(g)$type]
stopifnot(all(agg$kk_code %in% V(g)$name))
m <- match(V(g)$name, agg$kk_code)
V(g)$source_author <- agg$source_author[m]
V(g)$source_year <- agg$source_year[m]
V(g)$source_page <- agg$source_page[m]
V(g)$quote_opening <- agg$quote_opening[m]

# publication type of the work K&K index under each code (PROVENANCE 21)
works <- read.csv("data/kk-index-b-works.csv", stringsAsFactors = FALSE)
wl <- do.call(rbind, lapply(seq_len(nrow(works)), function(i)
  data.frame(work = works$work[i],
             kk_code = trimws(strsplit(works$codes[i], ";")[[1]]),
             stringsAsFactors = FALSE)))
pub <- read.csv("data/kk-index-b-work-pub-type.csv", stringsAsFactors = FALSE)
pm <- merge(wl, pub[, c("work", "pub_type")], by = "work", all.x = TRUE)
stopifnot(!anyDuplicated(pm$kk_code), !anyNA(pm$pub_type))
pub.map <- setNames(pm$pub_type, pm$kk_code)

attach_pub <- function(g) {
  V(g)$pub_type <- pub.map[V(g)$name]
  g
}
g <- attach_pub(g)

stopifnot(identical(bi0, as_biadjacency_matrix(g, sparse = FALSE)))
vn$graph <- g
saveRDS(vn, path)
cat("code vertices with source attributes:", sum(!is.na(V(g)$source_page)), "\n")
cat("verified codes with a publication type:", sum(V(g)$type & !is.na(V(g)$pub_type)),
    "without:", paste(V(g)$name[V(g)$type & is.na(V(g)$pub_type)], collapse = ", "), "\n")

# the same attribute on the heading network's code vertices
hpath <- "data/kk-index-b-heading-network.rds"
hn <- readRDS(hpath)
hg <- hn$graph
hbi0 <- as_biadjacency_matrix(hg, sparse = FALSE)
hg <- attach_pub(hg)
stopifnot(identical(hbi0, as_biadjacency_matrix(hg, sparse = FALSE)))
hn$graph <- hg
saveRDS(hn, hpath)
cat("heading codes with a publication type:", sum(V(hg)$type & !is.na(V(hg)$pub_type)), "\n")
