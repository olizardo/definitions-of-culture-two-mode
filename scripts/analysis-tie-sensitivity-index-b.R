# Tie sensitivity of the maximum spanning tree betweenness, for the definitions
# (code) projection and the concept (sub-element) projection of the 2-core.
# Each projection gets an ensemble of random maximum spanning trees
# (scripts/tree-ensemble-index-b.R). The mean Freeman-normalized betweenness over
# the ensemble is the reported betweenness, with its spread, the share of trees
# in which a node is in the top ten, and its mean rank. The drawn tree of each
# figure is the ensemble member closest to that mean.

library(igraph)
source("scripts/tree-ensemble-index-b.R")

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

sensitivity <- function(P, core.deg, label) {
  diag(P) <- 0
  G <- graph_from_adjacency_matrix(P, mode = "undirected", weighted = TRUE, diag = FALSE)
  nodes <- V(G)$name
  ens <- tree.ensemble(G)
  btw <- ens$btw
  n.rep <- nrow(btw)
  top10 <- t(apply(btw, 1, function(b) nodes %in% names(sort(b, decreasing = TRUE))[1:10]))
  rk <- t(apply(-btw, 1, rank, ties.method = "average"))
  out <- data.frame(
    node = nodes,
    core_degree = core.deg[nodes],
    mean_btw = ens$mean,
    sd_btw = apply(btw, 2, sd),
    min_btw = apply(btw, 2, min),
    max_btw = apply(btw, 2, max),
    share_top10 = colMeans(top10),
    share_zero_btw = colMeans(btw == 0),
    mean_rank = colMeans(rk),
    drawn_btw = freeman(ens$tree)[nodes],
    n_trees = n.rep,
    row.names = NULL
  )
  out <- out[order(-out$mean_btw), ]
  out$mean_btw_pct <- round(100 * out$mean_btw, 2)
  cat(label, "(", n.rep, "random trees; drawn tree is member", ens$best, "):\n")
  print(head(out[, c("node", "mean_btw_pct", "sd_btw", "share_top10", "mean_rank")], 12), row.names = FALSE)
  out
}

def.out <- sensitivity(crossprod(Ac), colSums(Ac), "Definitions")
write.csv(def.out, "data/kk-index-b-tie-sensitivity-definitions.csv", row.names = FALSE)

con.out <- sensitivity(tcrossprod(Ac), rowSums(Ac), "Concepts")
write.csv(con.out, "data/kk-index-b-tie-sensitivity-concepts.csv", row.names = FALSE)
