# Power law vs truncated exponential fits to the concept (sub-element) degree
# distribution of the verified definitions network. Run from the project root.
# Method: Clauset, Shalizi & Newman (2009) discrete MLE; Vuong (1989) test.

library(igraph)

net <- readRDS("data/kk-index-b-verified-network.rds")
# Rows of the biadjacency are concepts (sub-elements); columns are codes.
x_all <- as.numeric(rowSums(net$biadjacency))
stopifnot(length(x_all) == nrow(net$biadjacency), all(x_all >= 1))

# Hurwitz zeta sum_{k >= q} k^-a: direct sum plus Euler-Maclaurin tail.
hzeta <- function(a, q, N = 1e5) {
  k <- q:(q + N - 1)
  M <- q + N
  sum(k^-a) + M^(1 - a) / (a - 1) + 0.5 * M^-a + a * M^(-a - 1) / 12
}

# Per-observation log-likelihoods on x >= xmin.
# Power law: P(x) = x^-a / zeta(a, xmin).
# Exponential truncated at xmin: P(x) = exp(-l x) / sum_{k >= xmin} exp(-l k).
loglik_pl <- function(a, x, xmin) -a * log(x) - log(hzeta(a, xmin))
loglik_exp <- function(l, x, xmin) {
  k <- xmin:(xmin + 5000)
  -l * x - log(sum(exp(-l * k)))
}

fit_pl <- function(x, xmin) {
  o <- optimize(function(a) -sum(loglik_pl(a, x, xmin)), c(1.01, 6))
  list(alpha = o$minimum, ll = -o$objective)
}
fit_exp <- function(x, xmin) {
  o <- optimize(function(l) -sum(loglik_exp(l, x, xmin)), c(1e-4, 5))
  list(lambda = o$minimum, ll = -o$objective)
}

# Vuong's test on the pointwise log-likelihood ratio, power law minus exponential.
vuong <- function(x, xmin, a, l) {
  r <- loglik_pl(a, x, xmin) - loglik_exp(l, x, xmin)
  z <- sum(r) / (sqrt(length(r)) * sd(r))
  c(LR = sum(r), vuong_z = z, p_two_sided = 2 * pnorm(-abs(z)))
}

# KS distance between the empirical CDF and the fitted power law CDF.
ks_pl <- function(x, xmin, a) {
  support <- xmin:max(x)
  pmf <- support^-a / hzeta(a, xmin)
  max(abs(ecdf(x)(support) - cumsum(pmf)))
}

xmins <- sort(unique(x_all))
xmins <- xmins[xmins <= quantile(x_all, 0.9)]

rows <- lapply(xmins, function(xm) {
  xt <- x_all[x_all >= xm]
  p <- fit_pl(xt, xm)
  e <- fit_exp(xt, xm)
  v <- vuong(xt, xm, p$alpha, e$lambda)
  data.frame(
    xmin = xm, n = length(xt),
    alpha = p$alpha, lambda = e$lambda,
    ll_pl = p$ll, ll_exp = e$ll,
    LR_pl_minus_exp = unname(v["LR"]),
    vuong_z = unname(v["vuong_z"]),
    p_two_sided = unname(v["p_two_sided"]),
    KS_pl = ks_pl(xt, xm, p$alpha)
  )
})
res <- do.call(rbind, rows)
res[, -1] <- signif(res[, -1], 4)

dir.create("data", showWarnings = FALSE)
write.csv(res, "data/kk-index-b-concept-degree-fit.csv", row.names = FALSE)
res
