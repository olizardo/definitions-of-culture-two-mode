# Attach per-code source citation attributes to the verified definitions network.
#
# Input:  data/kkcc-definition-source-pages.csv (one row per Boroch code: K&K code,
#         Boroch author, year and printed pinpoint, quote opening)
#         data/kk-index-b-verified-network.rds
# Output: the same .rds, with code vertices carrying source_author, source_year,
#         source_page and quote_opening. A code with more than one Boroch row
#         has its values joined with "; ". Sub-element vertices get NA.
#
# Run after build-index-b-verified.R, which rewrites the network.

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

stopifnot(identical(bi0, as_biadjacency_matrix(g, sparse = FALSE)))
vn$graph <- g
saveRDS(vn, path)
cat("code vertices with source attributes:", sum(!is.na(V(g)$source_page)), "\n")
