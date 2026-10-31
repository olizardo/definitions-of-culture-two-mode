# Disruption of each concept's removal from the concept maximum spanning trees,
# over the same 1000-tree ensemble used for betweenness. For each tree, removing a
# concept splits the tree into pieces; the cut-off size is the number of concepts
# outside the largest piece. Reports the mean cut-off across trees and the share
# of trees in which the concept is among the ten most disruptive. Run from the
# project root.

library(igraph)

source("scripts/core-index-b.R")
source("scripts/tree-ensemble-index-b.R")

net <- readRDS("data/kk-index-b-verified-network.rds")
Ac <- lcc_2core(net$biadjacency)

P.concept <- Ac %*% t(Ac)
diag(P.concept) <- 0
G.concept <- graph_from_adjacency_matrix(P.concept, mode = "undirected",
                                         weighted = TRUE, diag = FALSE)
nodes <- V(G.concept)$name
N <- length(nodes)

# same seed and draw order as tree.ensemble(), so the trees match the ensemble
set.seed(tree.seed)
cut.off <- matrix(NA_real_, tree.reps, N, dimnames = list(NULL, nodes))
for (r in seq_len(tree.reps)) {
  st <- random.max.tree(G.concept)
  for (j in seq_len(N)) {
    s2 <- delete_vertices(st, j)
    cut.off[r, j] <- (N - 1) - max(components(s2)$csize)
  }
}

rank.r <- t(apply(-cut.off, 1, rank, ties.method = "min"))
out <- data.frame(
  concept = nodes,
  mean_cut_off = colMeans(cut.off),
  sd_cut_off = apply(cut.off, 2, sd),
  share_top10 = colMeans(rank.r <= 10),
  n_trees = tree.reps
)
out <- out[order(-out$mean_cut_off), ]
rownames(out) <- NULL
write.csv(out, "data/kk-index-b-concept-cutpoints.csv", row.names = FALSE)
print(head(out, 15), row.names = FALSE)
