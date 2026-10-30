# Structural NMF of the definitions network: factorizes the codes x concepts
# biadjacency of the verified network's largest-component 2-core (the same Ac
# as scripts/analysis-ca-index-b.R and analysis-mst-definitions-index-b.R).
# A code's profile is the set of concepts it contains (binary, unweighted); the
# NMF finds additive concept profiles, and the dominant factor per code is
# compared with the K&K group letter by cross-tabulation, ARI and a
# permuted-label baseline, exactly as in the texts analysis
# (scripts/analysis-nmf-texts-index-b.R). k = 7 is fixed to match groups A-G;
# the objective has no elbow and restart stability is flat beyond k = 2.
#
# Outputs:
#   data/kk-index-b-nmf-structural-stability.csv   ARI stability by k
#   data/kk-index-b-nmf-structural-factors.csv     top concepts per factor
#   data/kk-index-b-nmf-structural-loads.csv       per-code loadings and group
#   data/kk-index-b-nmf-structural-agreement.csv   factor x group cross-tab
#   figures/kk-index-b/nmf/nmf-structural-factors.png  top concepts per factor
#   figures/kk-index-b/nmf/nmf-structural.png          codes x factors heatmap
#   (no agreement heatmap, as in the texts analysis)

library(ggplot2)

dir.create("figures/kk-index-b/nmf", recursive = TRUE, showWarnings = FALSE)

set.seed(5283)

source("scripts/nmf-core.R")

# ---- codes x concepts matrix on the LCC 2-core ----

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
cat("2-core:", nrow(Ac), "concepts x", ncol(Ac), "codes\n")

# rows are documents (codes), columns are features (concepts)
V <- t(Ac)
grp <- setNames(V(g)$kk_group, V(g)$name)[rownames(V)]
stopifnot(!anyNA(grp))
cat("codes:", nrow(V), "| groups:",
    paste(sprintf("%s %d", names(table(grp)), table(grp)), collapse = " "), "\n")

# ---- NMF: stability, then the fixed k = 7 fit ----

n.restart <- 10
stability <- data.frame()
for (k in 2:8) {
  runs <- lapply(seq_len(n.restart), function(r) nmf.fit(V, k, seed = 1000 * k + r))
  obj <- vapply(runs, `[[`, numeric(1), "obj")
  a <- lapply(runs, function(f) hard(f$H))
  ari.pairs <- vapply(combn(n.restart, 2, simplify = FALSE),
                      function(p) ari(a[[p[1]]], a[[p[2]]]), numeric(1))
  stability <- rbind(stability, data.frame(k = k, obj = min(obj),
                                           mean_ari = mean(ari.pairs),
                                           min_ari = min(ari.pairs)))
  cat("k =", k, "obj =", sprintf("%.1f", min(obj)),
      "mean ARI =", sprintf("%.3f", mean(ari.pairs)), "\n")
}
write.csv(stability, "data/kk-index-b-nmf-structural-stability.csv", row.names = FALSE)

K <- 7

# factor labels, set by hand from the top concepts in
# data/kk-index-b-nmf-structural-factors.csv; change them there only.
# Labels stay close to the leading concepts. Set 2026-10-31 on the first
# structural fit (PROVENANCE 23). Factor 7 is diffuse: its top loadings are an
# order of magnitude below the other factors'.
factor.labels <- c(
  "Social organization", "Group and way of life", "Norms and knowledge",
  "Society and acquired behavior", "Transmitted ideas", "Complex whole",
  "Systems and skills")

fit <- nmf.fit(V, K, seed = 6241)
cat("fixed k:", K, "obj =", sprintf("%.1f", fit$obj), "\n")

# ---- factor tables ----

# rows are codes, so a factor's concept profile is a row of H and a code's
# loadings are a column of W (normalized to sum to 1 per code)
factors <- do.call(rbind, lapply(seq_len(K), function(j) {
  w <- sort(fit$H[j, ], decreasing = TRUE)
  data.frame(factor = j, rank = seq_along(w), term = names(w),
             loading = round(w, 4))
}))
factors <- factors[factors$rank <= 15, ]
write.csv(factors, "data/kk-index-b-nmf-structural-factors.csv", row.names = FALSE)

# top 8 concepts per factor, horizontal bars
top.terms <- factors[factors$rank <= 8, ]
top.terms$factor <- factor(top.terms$factor, levels = 1:K,
                           labels = factor.labels)
ggplot(top.terms, ggplot2::aes(loading, stats::reorder(term, loading))) +
  ggplot2::geom_col(fill = "grey45") +
  ggplot2::facet_wrap(~ factor, scales = "free") +
  ggplot2::labs(
    title = "Top concepts of each structural-NMF factor",
    subtitle = paste0("k = 7; codes x concepts biadjacency of the definitions",
                      " network, LCC 2-core (149 codes)"),
    x = "concept loading", y = NULL) +
  ggplot2::theme_minimal()
ggplot2::ggsave("figures/kk-index-b/nmf/nmf-structural-factors.png",
                width = 9, height = 6, bg = "white")

Wc <- sweep(fit$W, 1, rowSums(fit$W), "/")
loads <- data.frame(kk_code = rownames(V), group = grp,
                    round(Wc, 4))
loads$dominant <- max.col(Wc)
loads$factor_label <- factor.labels[loads$dominant]
write.csv(loads, "data/kk-index-b-nmf-structural-loads.csv", row.names = FALSE)

# figure: codes x factors loading heatmap (mirrors the texts heatmap)
ord <- order(loads$dominant, -apply(Wc, 1, max))
hm <- data.frame(
  code = factor(rep(rownames(V)[ord], times = K),
                levels = rev(rownames(V)[ord])),
  factor = factor(rep(seq_len(K), each = length(ord)),
                  labels = gsub(" ", "\n", factor.labels)),
  loading = as.vector(t(Wc[ord, ])))
ggplot(hm, aes(factor, code, fill = loading)) +
  geom_tile(color = "white") +
  scale_fill_gradient(low = "grey96", high = "grey25") +
  scale_x_discrete(guide = guide_axis(n.dodge = 2)) +
  labs(title = "Codes x structural-NMF factors, k = 7",
       subtitle = paste0("Loadings sum to 1 per code; codes grouped by dominant",
                         " factor; row labels are K&K codes"),
       x = NULL, y = NULL, fill = "loading") +
  theme_minimal(base_size = 9) +
  theme(axis.text.y = element_text(size = 3.5))
ggsave("figures/kk-index-b/nmf/nmf-structural.png",
       width = 6.5, height = 12, bg = "white")

# ---- agreement with K&K groups ----

dom <- loads$dominant
ct <- table(factor(dom, levels = 1:K), factor(grp, levels = LETTERS[1:7]))
cat("\ncross-tab, dominant factor (rows) x K&K group (cols):\n"); print(ct)
ari.obs <- ari(as.character(dom), grp)
ari.perm <- replicate(1000, ari(as.character(dom), sample(grp)))
cat("\nARI:", sprintf("%.3f", ari.obs),
    "| permuted baseline: mean", sprintf("%.3f", mean(ari.perm)),
    "95th pct", sprintf("%.3f", quantile(ari.perm, 0.95)), "\n")
purity <- vapply(seq_len(K), function(j) {
  gg <- grp[dom == j]
  if (!length(gg)) return(NA_real_)
  max(table(gg)) / length(gg)
}, numeric(1))
cat("purity per factor:", paste(sprintf("%.2f", purity), collapse = " "), "\n")

agree <- data.frame(factor = rep(1:K, times = 7),
                    factor_label = rep(factor.labels, times = 7),
                    group = rep(LETTERS[1:7], each = K),
                    n_codes = as.vector(ct))
write.csv(agree, "data/kk-index-b-nmf-structural-agreement.csv", row.names = FALSE)
