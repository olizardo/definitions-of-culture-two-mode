# Shared NMF machinery, base R only.
#
# Euclidean multiplicative-update NMF, deterministic given the seed. Used by
# the structural analysis (scripts/analysis-nmf-works-index-b.R) and the
# text-based analysis (scripts/analysis-nmf-texts-index-b.R).
#
# nmf.fit(V, k, seed): V >= 0, rows are documents (or works), columns are
# features. Returns W (rows x k, columns normalized to unit sum) and
# H (k x cols, rescaled so W %*% H still approximates V).
# ari(a, b): adjusted Rand index (Hubert & Arabie 1985), base R.
# hard(H): each column's argmax factor (H is k x columns).

nmf.fit <- function(V, k, seed) {
  set.seed(seed)
  W <- matrix(runif(nrow(V) * k), nrow(V), k)
  H <- matrix(runif(k * ncol(V)), k, ncol(V))
  eps <- 1e-10
  obj <- function() sum((V - W %*% H)^2)
  prev <- obj()
  repeat {
    H <- H * (crossprod(W, V) + eps) / (crossprod(W, W %*% H) + eps)
    W <- W * ((V %*% t(H)) + eps) / ((W %*% H %*% t(H)) + eps)
    cur <- obj()
    if (abs(prev - cur) / (prev + eps) < 1e-8) break
    prev <- cur
  }
  # normalize columns of W to unit sum so factors are comparable across runs
  s <- colSums(W)
  list(W = sweep(W, 2, s, "/"), H = sweep(H, 1, s, "*"), obj = cur)
}

hard <- function(H) max.col(t(H))  # each column's argmax factor

ari <- function(a, b) {
  tab <- table(a, b)
  n <- sum(tab)
  comb <- function(x) sum(choose(x, 2))
  R <- comb(rowSums(tab)); C <- comb(colSums(tab)); S <- comb(as.vector(tab))
  index <- S
  expected <- R * C / choose(n, 2)
  denom <- (R + C) / 2 - expected
  if (denom == 0) return(1)  # degenerate: both partitions pair-identical
  (index - expected) / denom
}
