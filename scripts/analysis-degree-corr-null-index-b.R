# Degree correlation of the full verified definitions network against a
# degree-preserving null: curveball trades (Strona et al. 2014), which keep
# every concept degree and every code degree. The statistic is the one in
# Table 1, igraph::assortativity_degree(directed = FALSE), reproduced here from
# the edge list and checked against igraph. Run from the project root.

library(igraph)

seed <- 4817
set.seed(seed)
n.null <- 1000
burn.in <- 5
thin <- 1

net <- readRDS("data/kk-index-b-verified-network.rds")
A <- net$biadjacency
storage.mode(A) <- "integer"

# Undirected assortativity by degree: Pearson correlation over the two
# endpoints of each edge, counting each edge in both orientations.
deg.corr <- function(M) {
  rd <- rowSums(M)
  cd <- colSums(M)
  e <- which(M == 1L, arr.ind = TRUE)
  x <- c(rd[e[, 1]], cd[e[, 2]])
  y <- c(cd[e[, 2]], rd[e[, 1]])
  cor(x, y)
}

# Exchange the memberships of rows a and b that they do not share. The pooled
# unshared items are shuffled and split back, so both row sums and column sums hold.
curveball.trade <- function(M, a, b) {
  ia <- which(M[a, ] == 1L)
  ib <- which(M[b, ] == 1L)
  shared <- intersect(ia, ib)
  only.a <- setdiff(ia, ib)
  unshared <- union(only.a, setdiff(ib, ia))
  pool <- unshared[sample.int(length(unshared))]
  n.a <- length(only.a)
  M[a, ] <- 0L
  M[b, ] <- 0L
  M[a, c(shared, pool[seq_len(n.a)])] <- 1L
  M[b, c(shared, pool[seq_along(pool) > n.a])] <- 1L
  M
}

# Burn in for burn.in * nrow(A) trades from the observed matrix, then keep one
# matrix every thin * nrow(A) trades. One chain, so the samples are correlated.
obs <- deg.corr(A)
stopifnot(isTRUE(all.equal(obs, assortativity_degree(
  graph_from_biadjacency_matrix(A, directed = FALSE, multiple = FALSE),
  directed = FALSE))))

step <- nrow(A)
M <- A
for (t in seq_len(burn.in * step)) {
  p <- sample.int(nrow(M), 2)
  M <- curveball.trade(M, p[1], p[2])
}

null.r <- numeric(n.null)
for (i in seq_len(n.null)) {
  for (t in seq_len(thin * step)) {
    p <- sample.int(nrow(M), 2)
    M <- curveball.trade(M, p[1], p[2])
  }
  stopifnot(identical(rowSums(M), rowSums(A)), identical(colSums(M), colSums(A)))
  null.r[i] <- deg.corr(M)
}

summary.row <- data.frame(
  n_concepts = nrow(A),
  n_codes = ncol(A),
  n_edges = sum(A),
  observed_r = obs,
  null_mean = mean(null.r),
  null_sd = sd(null.r),
  z = (obs - mean(null.r)) / sd(null.r),
  p_lower = (1 + sum(null.r <= obs)) / (n.null + 1),
  p_two_sided = (1 + sum(abs(null.r) >= abs(obs))) / (n.null + 1),
  n_null = n.null,
  burn_in_trades = burn.in * step,
  trades_per_null = thin * step,
  seed = seed
)

print(summary.row, digits = 4)
write.csv(summary.row, "data/kk-index-b-degree-corr-null-summary.csv", row.names = FALSE)
