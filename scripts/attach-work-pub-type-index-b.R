# Attaches the publication type of each work (data/kk-index-b-work-pub-type.csv)
# to the works table and to the work vertices of both two-mode graphs in
# data/kk-index-b-work-concept-network-full.rds. Run from the project root after
# scripts/build-work-concept-network-index-b.R. The types are decided in the CSV
# (one basis per work) and read from the citation table's labels, so this script
# only attaches; it does not rebuild the network.

library(igraph)

pt <- read.csv("data/kk-index-b-work-pub-type.csv", stringsAsFactors = FALSE)
path <- "data/kk-index-b-work-concept-network-full.rds"
x <- readRDS(path)

stopifnot(
  !anyDuplicated(pt$work),
  setequal(pt$work, x$works$work),
  all(pt$pub_type %in% c("article", "book", "chapter", "other"))
)

x$works$pub_type <- pt$pub_type[match(x$works$work, pt$work)]

attach.type <- function(g) {
  wpos <- which(V(g)$type)
  stopifnot(setequal(V(g)$name[wpos], pt$work))
  val <- rep(NA_character_, vcount(g))
  val[wpos] <- pt$pub_type[match(V(g)$name[wpos], pt$work)]
  vertex_attr(g, "pub_type") <- val
  g
}
x$two_mode_graph <- attach.type(x$two_mode_graph)
x$two_mode_heading_graph <- attach.type(x$two_mode_heading_graph)

stopifnot(
  !anyNA(V(x$two_mode_graph)$pub_type[V(x$two_mode_graph)$type]),
  !anyNA(V(x$two_mode_heading_graph)$pub_type[V(x$two_mode_heading_graph)$type])
)

saveRDS(x, path)
table(x$works$pub_type)
