# Two-mode eigenvector centrality (Bonacich 1991) of the K&K Index B definitions
# network, on the largest component's 2-core. Run from the project root.
# The leading singular vectors of the biadjacency matrix give the eigenvector of
# the full bipartite adjacency matrix: the concept vector is u1 and the code
# vector is v1, scaled so the squared entries sum to 1 across both modes.

library(igraph)

source("scripts/core-index-b.R")

net <- readRDS("data/kk-index-b-verified-network.rds")
Ac <- lcc_2core(net$biadjacency)
cat("2-core:", nrow(Ac), "concepts x", ncol(Ac), "codes, edges:", sum(Ac), "\n")

gc <- graph_from_biadjacency_matrix(Ac, directed = FALSE, multiple = FALSE)
stopifnot(components(gc)$no == 1)

s <- svd(Ac, nu = 1, nv = 1)
u1 <- s$u[, 1]
v1 <- s$v[, 1]
if (sum(u1) < 0) { u1 <- -u1; v1 <- -v1 }
stopifnot(all(u1 > 0), all(v1 > 0))
cat("leading singular value:", round(s$d[1], 4), "\n")

ec_concept <- setNames(u1, rownames(Ac)) / sqrt(2)
ec_code <- setNames(v1, colnames(Ac)) / sqrt(2)

# Cross-check against igraph's eigenvector centrality on the same graph.
ev <- eigen_centrality(gc, scale = FALSE)$vector
ev <- ev / sqrt(sum(ev^2))
ours <- c(ec_concept, ec_code)[names(ev)]
stopifnot(max(abs(ev - ours)) < 1e-8)

elements <- data.frame(
  element = rownames(Ac),
  degree = rowSums(Ac),
  eigen_centrality = unname(ec_concept)
)
codes <- data.frame(
  code = colnames(Ac),
  group = substr(colnames(Ac), 1, 1),
  degree = colSums(Ac),
  eigen_centrality = unname(ec_code)
)
elements <- elements[order(-elements$eigen_centrality), ]
codes <- codes[order(-codes$eigen_centrality), ]

write.csv(elements, "data/kk-index-b-eigen-centrality-2core-elements.csv", row.names = FALSE)
write.csv(codes, "data/kk-index-b-eigen-centrality-2core-codes.csv", row.names = FALSE)

head(elements, 10)
head(codes, 10)
