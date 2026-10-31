# Shared helpers for the maximum spanning tree ensembles of the two projections
# (definitions and concepts). Projection weights tie heavily, so a maximum
# spanning tree is not unique. Each tree is built by Kruskal's method with tied
# edges in a random order, under a fixed seed. Betweenness is the mean of the
# Freeman-normalized values over the ensemble. The drawn tree is the ensemble
# member whose betweenness vector is closest (squared distance) to that mean.
# Sourced by analysis-tie-sensitivity-index-b.R, analysis-mst-definitions-index-b.R
# and analysis-ca-index-b.R.

library(igraph)

tree.seed <- 7319
tree.reps <- 1000

# Kruskal on a random tie order: edges sorted by decreasing weight, ties in a
# random order, added unless they close a cycle (union-find)
random.max.tree <- function(G) {
  ed <- as_edgelist(G, names = FALSE)
  w <- E(G)$weight
  n <- vcount(G)
  ord <- order(-w, runif(length(w)))
  parent <- seq_len(n)
  find <- function(x) {
    while (parent[x] != x) x <- parent[x]
    x
  }
  keep <- logical(length(w))
  for (i in ord) {
    a <- find(ed[i, 1])
    b <- find(ed[i, 2])
    if (a != b) {
      parent[a] <- b
      keep[i] <- TRUE
      if (sum(keep) == n - 1) break
    }
  }
  st <- make_empty_graph(n = n, directed = FALSE)
  V(st)$name <- V(G)$name
  st <- add_edges(st, as.vector(t(ed[keep, , drop = FALSE])))
  E(st)$weight <- w[keep]
  st
}

# Freeman normalization for a tree: raw betweenness / ((N - 1)(N - 2) / 2)
freeman <- function(st) {
  N <- vcount(st)
  betweenness(st, directed = FALSE, normalized = FALSE) / ((N - 1) * (N - 2) / 2)
}

# Ensemble of random maximum spanning trees of G, seeded. Returns the matrix of
# normalized betweenness (one row per tree), the mean over trees, the closest
# member (tree) and its index.
tree.ensemble <- function(G, n.rep = tree.reps, seed = tree.seed) {
  set.seed(seed)
  nodes <- V(G)$name
  btw <- matrix(NA_real_, n.rep, length(nodes), dimnames = list(NULL, nodes))
  trees <- vector("list", n.rep)
  for (r in seq_len(n.rep)) {
    trees[[r]] <- random.max.tree(G)
    btw[r, ] <- freeman(trees[[r]])
  }
  mean.btw <- colMeans(btw)
  M <- matrix(mean.btw, n.rep, length(nodes), byrow = TRUE)
  best <- which.min(rowSums((btw - M)^2))
  list(btw = btw, mean = mean.btw, tree = trees[[best]], best = best)
}
