# BTM sensitivity check for the LDA texts analysis (PROVENANCE 37).
#
# Question: does the chi-square association between dominant topic and K&K's
# category depend on the LDA model family? The check refits the same clause
# corpus with a Biterm Topic Model (Yan, Guo, Lan & Cheng 2013), which models
# word co-occurrence patterns (biterms) pooled over the corpus instead of word
# occurrences within documents, and reports the same per-seed statistics the
# LDA chain reports.
#
# Corpus: data/kk-index-b-lda-clauses.csv, written by
# analysis-lda-texts-index-b.R (265 modeled clauses over 170 codes; C-I-7 has
# no surviving clause and stays excluded here, as in the LDA pipeline).
#
# Model: the CRAN BTM package (C++ implementation of the original), k = 12 to
# match the LDA, priors at the paper defaults alpha = 50/k and beta = 0.01,
# 1000 Gibbs iterations, and a co-occurrence window spanning the whole clause,
# so every in-clause term pair is a biterm. Twenty seeds (1 to 20); the corpus
# is too small for one-to-one topic alignment across seeds to be meaningful
# (topics split and merge differently across fits), so nothing is averaged
# across seeds and every statistic is computed per seed. The chi-square and
# the ARI are invariant to topic relabeling, so they need no alignment.
#
# Outputs:
#   data/kk-index-b-btm-sensitivity.csv   per-seed statistics, plus an ensemble row
#   data/kk-index-b-btm-lda-matches.csv   per-LDA-topic best-match cosine

suppressPackageStartupMessages({
  library(BTM)
  library(clue)
})

K <- 12
SEEDS <- 1:20
ITER <- 1000
CHISQ_SEED <- 8153  # same simulated-permutation seed as the LDA chi-square script
CHISQ_B <- 10000

ari <- function(a, b) {
  # Adjusted Rand index (Hubert & Arabie 1985)
  tab <- table(a, b)
  n <- sum(tab)
  si <- sum(choose(tab, 2))
  sa <- sum(choose(rowSums(tab), 2))
  sb <- sum(choose(colSums(tab), 2))
  expected <- sa * sb / choose(n, 2)
  (si - expected) / ((sa + sb) / 2 - expected)
}

cl <- read.csv("data/kk-index-b-lda-clauses.csv", stringsAsFactors = FALSE)
theta_lda <- read.csv("data/kk-index-b-lda-code-theta.csv", stringsAsFactors = FALSE)

# token data frame: one row per token, doc_id is the clause row index
tok_list <- strsplit(cl$tokens, " ")
x <- data.frame(
  doc_id = rep(seq_len(nrow(cl)), times = lengths(tok_list)),
  token = unlist(tok_list),
  stringsAsFactors = FALSE
)
# window spanning the whole clause, so every in-clause pair is a biterm
window <- max(cl$n_words)
cat("clauses:", nrow(cl), "| tokens:", nrow(x), "| window:", window, "\n")

grp <- setNames(theta_lda$group, theta_lda$kk_code)
lda_dom <- setNames(theta_lda$dominant, theta_lda$kk_code)
# LDA profiles restricted to the codes the BTM corpus covers
lda_M <- as.matrix(theta_lda[, paste0("X", seq_len(K))])
rownames(lda_M) <- theta_lda$kk_code
lda_M <- lda_M[names(grp)[names(grp) %in% unique(cl$kk_code)], ]

# code-level topic profiles: clause scores weighted by clause word count
code_theta <- function(sc) {
  d <- data.frame(kk_code = cl$kk_code, n_words = cl$n_words, sc = I(sc))
  parts <- lapply(split(d, d$kk_code), function(g) {
    colSums(g$sc * g$n_words) / sum(g$n_words)
  })
  M <- do.call(rbind, parts[rownames(lda_M)])
  colnames(M) <- paste0("X", seq_len(K))
  M
}

rows <- list()
best_cos <- matrix(NA_real_, length(SEEDS), K)
for (s in SEEDS) {
  set.seed(s)
  fit <- BTM(x, k = K, alpha = 50 / K, beta = 0.01, iter = ITER, window = window)
  sc <- predict(fit, newdata = x)

  d <- data.frame(kk_code = cl$kk_code, n_words = cl$n_words, sc = I(sc))
  agg <- do.call(rbind, lapply(split(d, d$kk_code), function(g) {
    th <- colSums(g$sc * g$n_words) / sum(g$n_words)
    data.frame(kk_code = g$kk_code[1], dominant = which.max(th), max_w = max(th))
  }))
  agg$group <- grp[agg$kk_code]
  set.seed(CHISQ_SEED)
  ct <- chisq.test(table(agg$group, agg$dominant), simulate.p.value = TRUE, B = CHISQ_B)

  # best-match cosine of each BTM topic against the stored LDA profiles
  M <- code_theta(sc)
  r <- sweep(lda_M, 2, sqrt(colSums(lda_M^2)), "/")
  cph <- sweep(M, 2, sqrt(colSums(M^2)), "/")
  sim <- t(cph) %*% r
  best_cos[s, ] <- apply(sim, 2, max)

  rows[[s]] <- data.frame(
    kind = "single_seed", seed = s,
    chisq = as.numeric(ct$statistic), p_sim = ct$p.value,
    ari_vs_kkgroup = ari(agg$group, agg$dominant),
    ari_vs_lda_dominant = ari(lda_dom[rownames(M)], max.col(M)),
    median_dominant_w = median(agg$max_w)
  )
  cat("seed", s, ": chisq", round(as.numeric(ct$statistic), 1),
      "p", signif(ct$p.value, 2), "\n")
}
out <- do.call(rbind, rows)
out$mean_matched_cos_to_lda <- NA
for (s in SEEDS) out$mean_matched_cos_to_lda[s] <- mean(best_cos[s, ])

# the summary row reports ranges and means over seeds, not a pooled fit
ens <- data.frame(
  kind = "ensemble_summary", seed = NA, chisq = NA, p_sim = NA,
  ari_vs_kkgroup = mean(out$ari_vs_kkgroup),
  ari_vs_lda_dominant = mean(out$ari_vs_lda_dominant),
  median_dominant_w = mean(out$median_dominant_w),
  mean_matched_cos_to_lda = mean(out$mean_matched_cos_to_lda),
  chisq_min = min(out$chisq), chisq_max = max(out$chisq),
  p_sim_max = max(out$p_sim)
)
out$chisq_min <- NA
out$chisq_max <- NA
out$p_sim_max <- NA
out <- rbind(out, ens)

write.csv(out, "data/kk-index-b-btm-sensitivity.csv", row.names = FALSE)
write.csv(data.frame(lda_topic = seq_len(K),
                     mean_best_cos = round(colMeans(best_cos), 3)),
          "data/kk-index-b-btm-lda-matches.csv", row.names = FALSE)

n_sig <- sum(out$p_sim < 0.05, na.rm = TRUE)
cat("\nseeds with p < 0.05:", n_sig, "of", length(SEEDS), "\n")
cat("chi-square range:", round(ens$chisq_min, 1), "to", round(ens$chisq_max, 1),
    "(LDA ensemble 108.0)\n")
cat("ARI vs K&K groups: mean", round(ens$ari_vs_kkgroup, 3),
    "(LDA per-seed range 0.02 to 0.07)\n")
cat("ARI vs LDA dominant partition: mean", round(ens$ari_vs_lda_dominant, 3), "\n")
cat("median dominant weight: mean", round(ens$median_dominant_w, 2), "(LDA 0.33)\n")
cat("best single-topic cosine per LDA topic: ",
    round(min(colMeans(best_cos)), 2), "to", round(max(colMeans(best_cos)), 2), "\n")
