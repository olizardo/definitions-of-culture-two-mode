# Text-based NMF of the definition quotations, tested against K&K's groups.
#
# Documents are K&K codes that carry a definition text: Boroch's Table 2
# quotations (mapped to K&K codes through the crosswalk), the appendix-only
# quotations (through the appendix links) and the K&K-only rows (C-5, D-5,
# D-7, E-17, D-III-4). A code's group is the first letter of the code.
#
# The corpus is small (about 170 documents of ~30 words), so: tokens of three
# letters or more, a hand-set stopword list including the omnipresent domain
# words (culture, society, social, man), terms kept to 2-50% document
# frequency, and TF-IDF weighting. The NMF (nmf-core.R) is fit at k = 7 to
# match groups A-G; the dominant factor per code is compared with the group
# by cross-tabulation, ARI and a permuted-label baseline. The same script
# reports the k = 2..8 stability table, but k is fixed, as in the works
# analysis.
#
# Outputs:
#   data/kk-index-b-nmf-texts-stability.csv   ARI stability by k
#   data/kk-index-b-nmf-texts-factors.csv     top terms per factor
#   data/kk-index-b-nmf-texts-loads.csv       per-code loadings and group
#   data/kk-index-b-nmf-texts-agreement.csv   factor x group cross-tab
#   figures/kk-index-b/nmf/nmf-texts-factors.png     top terms per factor
#   figures/kk-index-b/nmf/nmf-texts-agreement.png   factor x K&K group heatmap

library(ggplot2)

dir.create("figures/kk-index-b/nmf", recursive = TRUE, showWarnings = FALSE)

set.seed(3417)

source("scripts/nmf-core.R")

# ---- assemble documents ----

cross <- read.csv("data/kk-boroch-crosswalk.csv")
t2 <- read.csv("data/kkcc-definition-texts.csv")
t2$kk_code <- cross$kk_code[match(t2$code, cross$boroch_code)]
stopifnot(!anyNA(t2$kk_code))

links <- read.csv("data/kkcc-appendix-only-links.csv")
app <- read.csv("data/kkcc-appendix-only-texts.csv")
app$kk_code <- links$kk_row[match(app$code, links$code)]
stopifnot(!anyNA(app$kk_code))

kko <- read.csv("data/kk-definition-texts-kk-only.csv")
kko$text <- kko$statement  # same column name for the pipeline below

docs <- rbind(
  data.frame(kk_code = t2$kk_code, text = t2$text),
  data.frame(kk_code = app$kk_code, text = app$text),
  data.frame(kk_code = kko$kk_code, text = kko$text)
)
# concatenate the texts of a code held by several Boroch rows
docs <- aggregate(text ~ kk_code, docs, paste, collapse = " ")
docs$group <- substr(docs$kk_code, 1, 1)
cat("documents:", nrow(docs), "| groups:",
    paste(sort(table(docs$group)), names(table(docs$group)), collapse = " "), "\n")

# ---- tokenize and weight ----

stopwords <- c("the", "and", "that", "which", "of", "in", "is", "to", "a",
  "by", "or", "as", "be", "it", "for", "with", "are", "on", "not", "from",
  "such", "any", "all", "has", "have", "may", "can", "its", "their", "this",
  "these", "those", "but", "than", "more", "other", "into", "when", "who",
  "one", "two", "been", "was", "were", "also", "an", "at", "so", "no", "we",
  "his", "her", "him", "she", "they", "them", "there", "here", "what",
  # domain words present in nearly every definition; downweighting them by
  # removal keeps the factors on distinguishing content
  "culture", "cultures", "cultural", "society", "social", "man", "men",
  "human", "total", "whole", "way", "ways", "learned", "acquired", "group")

tok <- function(x) {
  x <- tolower(x)
  x <- gsub("[^a-z ]", " ", x)
  strsplit(x, " +")[[1]]
}
toks <- lapply(docs$text, tok)
names(toks) <- docs$kk_code
toks <- lapply(toks, function(w) w[nchar(w) >= 3 & !(w %in% stopwords)])

vocab <- sort(unique(unlist(toks)))
df <- table(unlist(lapply(toks, unique)))
keep <- names(df)[df >= 2 & df <= 0.5 * length(toks)]
cat("terms kept:", length(keep), "of", length(vocab), "\n")

# document x term counts, then TF-IDF
D <- matrix(0, nrow = nrow(docs), ncol = length(keep),
            dimnames = list(docs$kk_code, keep))
for (i in seq_len(nrow(docs))) {
  w <- toks[[i]]
  w <- w[w %in% keep]
  if (length(w)) D[i, ] <- table(factor(w, levels = keep))
}
idf <- log(nrow(D) / colSums(D > 0))
V <- sweep(D, 2, idf, `*`)

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
write.csv(stability, "data/kk-index-b-nmf-texts-stability.csv", row.names = FALSE)

K <- 7

# factor labels, set by hand from the profiles in
# data/kk-index-b-nmf-texts-factors.csv; change them there only. On a corpus
# this small some factors are partly author phrasing (factor 3's top terms
# include the literal word "kluckhohn"), so labels stay close to the terms.
factor.labels <- c(
  "Utensils and implements", "Passed down generations",
  "Feelings and adjustment", "Material vs. non-material",
  "Mental and holistic", "Symbolic systems", "Goals and ways of living")

fit <- nmf.fit(V, K, seed = 9137)
cat("fixed k:", K, "obj =", sprintf("%.1f", fit$obj), "\n")

# ---- factor tables ----

# rows are documents, so a factor's term profile is a row of H and a code's
# loadings are a column of W (normalized to sum to 1 per code)
factors <- do.call(rbind, lapply(seq_len(K), function(j) {
  w <- sort(fit$H[j, ], decreasing = TRUE)
  data.frame(factor = j, rank = seq_along(w), term = names(w),
             loading = round(w, 4))
}))
factors <- factors[factors$rank <= 15, ]
write.csv(factors, "data/kk-index-b-nmf-texts-factors.csv", row.names = FALSE)

# top 8 terms per factor, horizontal bars (loadings are unit-sum per factor)
top.terms <- factors[factors$rank <= 8, ]
top.terms$factor <- factor(top.terms$factor, levels = 1:K,
                           labels = factor.labels)
ggplot(top.terms, ggplot2::aes(loading, stats::reorder(term, loading))) +
  ggplot2::geom_col(fill = "grey45") +
  ggplot2::facet_wrap(~ factor, scales = "free") +
  ggplot2::labs(
    title = "Top terms of each text-NMF factor",
    subtitle = "k = 7; TF-IDF document x term matrix of 172 definition codes",
    x = "term loading", y = NULL) +
  ggplot2::theme_minimal()
ggplot2::ggsave("figures/kk-index-b/nmf/nmf-texts-factors.png",
                width = 9, height = 6, bg = "white")

Wc <- sweep(fit$W, 1, rowSums(fit$W), "/")
loads <- data.frame(kk_code = rownames(V), group = docs$group,
                    round(Wc, 4))
loads$dominant <- max.col(Wc)
loads$factor_label <- factor.labels[loads$dominant]
write.csv(loads, "data/kk-index-b-nmf-texts-loads.csv", row.names = FALSE)

# ---- agreement with K&K groups ----

dom <- loads$dominant
ct <- table(factor(dom, levels = 1:K), factor(docs$group, levels = LETTERS[1:7]))
cat("\ncross-tab, dominant factor (rows) x K&K group (cols):\n"); print(ct)
ari.obs <- ari(as.character(dom), docs$group)
ari.perm <- replicate(1000, ari(as.character(dom), sample(docs$group)))
cat("\nARI:", sprintf("%.3f", ari.obs),
    "| permuted baseline: mean", sprintf("%.3f", mean(ari.perm)),
    "95th pct", sprintf("%.3f", quantile(ari.perm, 0.95)), "\n")
purity <- vapply(seq_len(K), function(j) {
  g <- docs$group[dom == j]
  if (!length(g)) return(NA_real_)
  max(table(g)) / length(g)
}, numeric(1))
cat("purity per factor:", paste(sprintf("%.2f", purity), collapse = " "), "\n")

agree <- data.frame(factor = rep(1:K, times = 7),
                    factor_label = rep(factor.labels, times = 7),
                    group = rep(LETTERS[1:7], each = K),
                    n_codes = as.vector(ct))
write.csv(agree, "data/kk-index-b-nmf-texts-agreement.csv", row.names = FALSE)

ggplot(agree, ggplot2::aes(group, factor(factor, levels = K:1,
                   labels = rev(factor.labels)), fill = n_codes)) +
  ggplot2::geom_tile(color = "white") +
  ggplot2::geom_text(ggplot2::aes(label = ifelse(n_codes > 0, n_codes, "")),
                     size = 3.2) +
  ggplot2::scale_fill_gradient(low = "grey92", high = "grey35",
                               guide = "none") +
  ggplot2::labs(
    title = "Text NMF at k = 7 versus K&K's groups",
    subtitle = "Dominant factor (rows) against K&K group (columns)",
    x = "K&K group", y = "NMF factor") +
  ggplot2::theme_minimal()
ggplot2::ggsave("figures/kk-index-b/nmf/nmf-texts-agreement.png",
                width = 6.5, height = 4.6, bg = "white")
