# Structural NMF of the works x sub-elements matrix.
#
# Factorizes the 0/1 sub-elements x works biadjacency of the LCC 2-core into
# W (sub-elements x k) and H (k x works), V ~= W H. Factors are mixtures of
# sub-elements; each work's column of H gives its loadings on the factors.
# A soft, parts-based alternative to the CA on the same matrix.
#
# NMF is the Euclidean multiplicative update in base R, with multiple random
# restarts per k and a stability diagnostic: mean pairwise ARI between the
# hard assignments (each work's argmax factor) across restarts.
#
# Outputs:
#   data/kk-index-b-nmf-works-factors.csv    sub-element loadings per factor
#   data/kk-index-b-nmf-works-loads.csv      work loadings per factor
#   data/kk-index-b-nmf-works-stability.csv  ARI stability by k
#   data/kk-index-b-nmf-works-agreement.csv  factor x group cross-tab
#   figures/kk-index-b/nmf/nmf-works.png     works x factors loading heatmap
#   (the agreement heatmaps were removed 2026-10-27 in favor of the Sankey,
#   scripts/figure-sankey-agreement.R; the agreement CSVs remain)

library(ggrepel)

dir.create("figures/kk-index-b/nmf", recursive = TRUE, showWarnings = FALSE)

set.seed(3417)

source("scripts/core-index-b.R")
source("scripts/nmf-core.R")
source("scripts/label-authors-index-b.R")
source("scripts/pub-type-style.R")

net <- readRDS("data/kk-index-b-work-concept-network-full.rds")
works.tab <- net$works

# sub-elements x works (rows = features, columns = documents), LCC 2-core
M <- lcc_2core(sub_work_matrix(net$two_mode_graph))
cat("matrix:", nrow(M), "sub-elements x", ncol(M), "works\n")

# k is fixed at 7 to match K&K's seven definition groups A-G, the taxonomy the
# agreement analysis tests against. The stability table across k = 2..8 is a
# diagnostic only: neither the objective (monotone, no elbow) nor restart
# stability selects a k on its own.
K <- 7

# factor labels, set by hand from the profiles in
# data/kk-index-b-nmf-works-factors.csv; change them there only
factor.labels <- c(
  "Way of life", "Transmitted ideas", "Society-individual behavior",
  "Norms and knowledge", "Complex whole", "Social organization",
  "Learning and acquisition")

n.restart <- 10
k.range <- 2:8
stability <- data.frame()
fits <- list()
for (k in k.range) {
  runs <- lapply(seq_len(n.restart), function(r) nmf.fit(M, k, seed = 1000 * k + r))
  obj <- vapply(runs, `[[`, numeric(1), "obj")
  best <- runs[[which.min(obj)]]
  a <- lapply(runs, function(f) hard(f$H))
  ari.pairs <- vapply(combn(n.restart, 2, simplify = FALSE), function(p) ari(a[[p[1]]], a[[p[2]]]), numeric(1))
  fits[[as.character(k)]] <- best
  stability <- rbind(stability, data.frame(k = k, obj = min(obj),
                                           mean_ari = mean(ari.pairs),
                                           min_ari = min(ari.pairs)))
  cat("k =", k, "obj =", sprintf("%.1f", min(obj)),
      "mean ARI =", sprintf("%.3f", mean(ari.pairs)),
      "min ARI =", sprintf("%.3f", min(ari.pairs)), "\n")
}
write.csv(stability, "data/kk-index-b-nmf-works-stability.csv", row.names = FALSE)

# ---- factor tables ----

cat("fixed k:", K, "\n")
fit <- fits[[as.character(K)]]

# top sub-elements per factor (W columns, unit-sum normalized)
factors <- do.call(rbind, lapply(seq_len(K), function(j) {
  w <- sort(fit$W[, j], decreasing = TRUE)
  data.frame(factor = j, rank = seq_along(w),
             sub_element = names(w), loading = round(w, 4))
}))
write.csv(factors, "data/kk-index-b-nmf-works-factors.csv", row.names = FALSE)

# work loadings: H scaled so each work's loadings sum to 1 (composition)
Hc <- fit$H
Hc <- sweep(Hc, 2, colSums(Hc), "/")
loads <- data.frame(work = colnames(M), t(round(Hc, 4)))
loads$dominant <- max.col(t(Hc))
loads$factor_label <- factor.labels[loads$dominant]
loads$label <- vapply(loads$work, label.authors, character(1))
loads$pub_type <- works.tab$pub_type[match(loads$work, works.tab$work)]
write.csv(loads, "data/kk-index-b-nmf-works-loads.csv", row.names = FALSE)

cat("\nwork counts per dominant factor:\n"); print(table(loads$dominant))

# ---- figure: works x factors loading heatmap ----

# works ordered by dominant factor, then by their largest loading
ord <- order(loads$dominant, -apply(Hc, 2, max))
lab.levels <- loads$label[ord]
stopifnot(!anyDuplicated(lab.levels))
hm <- data.frame(
  work = factor(rep(lab.levels, times = K), levels = rev(lab.levels)),
  factor = factor(rep(seq_len(K), each = length(ord)),
                  labels = gsub(" ", "\n", factor.labels)),
  loading = as.vector(Hc[, ord]))

ggplot2::ggplot(hm, ggplot2::aes(factor, work, fill = loading)) +
  ggplot2::geom_tile(color = "white") +
  ggplot2::scale_fill_gradient(low = "grey96", high = "grey25") +
  ggplot2::scale_x_discrete(guide = ggplot2::guide_axis(n.dodge = 2)) +
  ggplot2::labs(
    title = "Works x NMF factors, k = 7",
    subtitle = paste0("Loadings sum to 1 per work;",
                      " works grouped by dominant factor"),
    x = NULL, y = NULL, fill = "loading") +
  ggplot2::theme_minimal(base_size = 9) +
  ggplot2::theme(axis.text.y = ggplot2::element_text(size = 4.2))
ggplot2::ggsave("figures/kk-index-b/nmf/nmf-works.png",
                width = 6.5, height = 9, bg = "white")

# ---- agreement with K&K's groups A-G ----
# K&K's own classification of a definition is the first letter of its code.
# A work spans several codes, so its group is the plurality letter (NA on a
# tie). The dominant factor of the same k = 7 fit is compared with the
# dominant group: cross-tabulation, ARI, and an ARI baseline from permuted
# group labels (what agreement a random grouping of the same sizes would get).

dom7 <- loads$dominant

group.of <- function(codes) {
  gs <- substr(trimws(strsplit(codes, ";")[[1]]), 1, 1)
  tab <- table(gs)
  if (sum(tab == max(tab)) > 1) NA_character_ else names(tab)[which.max(tab)]
}
work.group <- vapply(works.tab$codes[match(colnames(M), works.tab$work)],
                     group.of, character(1))
n.tie <- sum(is.na(work.group))
cat("works with a tied dominant group:", n.tie, "of", length(work.group), "\n")

ct <- table(factor(dom7, levels = 1:7), factor(work.group, levels = LETTERS[1:7]))
cat("\ncross-tab, dominant NMF factor (rows) x dominant K&K group (cols):\n")
print(ct)
ok <- !is.na(work.group)
ari.obs <- ari(as.character(dom7[ok]), work.group[ok])
ari.perm <- replicate(1000, {
  ari(as.character(dom7[ok]), sample(work.group[ok]))
})
cat("\nARI:", sprintf("%.3f", ari.obs),
    "| permuted baseline: mean", sprintf("%.3f", mean(ari.perm)),
    "95th pct", sprintf("%.3f", quantile(ari.perm, 0.95)), "\n")

# group purity per factor: the share of a factor's works in its largest group
purity <- vapply(seq_len(7), function(j) {
  g <- work.group[dom7 == j]
  if (!length(g)) return(NA_real_)
  max(table(g, useNA = "no")) / length(g)
}, numeric(1))
cat("purity per factor:", paste(sprintf("%.2f", purity), collapse = " "), "\n")

agree <- data.frame(factor = rep(1:7, times = 7),
                    factor_label = rep(factor.labels, times = 7),
                    group = rep(LETTERS[1:7], each = 7),
                    n_works = as.vector(ct))
write.csv(agree, "data/kk-index-b-nmf-works-agreement.csv", row.names = FALSE)
