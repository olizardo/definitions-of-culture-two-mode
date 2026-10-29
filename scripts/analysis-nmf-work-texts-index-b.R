# Works-as-texts NMF: each work's document is the concatenation of the
# definition texts of the K&K codes the work sits under.
#
# Works are the 118 works of the works LCC 2-core, the same set as the
# structural works NMF (scripts/analysis-nmf-works-index-b.R). A code's texts
# are assembled exactly as in scripts/analysis-nmf-texts-index-b.R (Table 2
# quotations through the crosswalk, appendix-only quotations through the
# appendix links, K&K-only rows). A work's group is the plurality letter of
# its codes (NA on a tie), as in the structural analysis. Same tokenizer,
# stopwords, df range and TF-IDF as the texts analysis; k = 7 fixed to match
# groups A-G. Reads data/kk-index-b-nmf-texts-loads.csv for the bridge to the
# code-level factors, so it runs after analysis-nmf-texts-index-b.R.
#
# Outputs:
#   data/kk-index-b-nmf-work-texts-stability.csv  ARI stability by k
#   data/kk-index-b-nmf-work-texts-factors.csv    top terms per factor
#   data/kk-index-b-nmf-work-texts-loads.csv      per-work loadings and group
#   data/kk-index-b-nmf-work-texts-agreement.csv  factor x group cross-tab
#   data/kk-index-b-nmf-work-texts-bridge.csv     factor x code-level factor
#   figures/kk-index-b/nmf/nmf-work-texts.png         works x factors heatmap
#   figures/kk-index-b/nmf/nmf-work-texts-factors.png     top terms per factor

library(ggplot2)

dir.create("figures/kk-index-b/nmf", recursive = TRUE, showWarnings = FALSE)

set.seed(3417)

source("scripts/core-index-b.R")
source("scripts/nmf-core.R")
source("scripts/label-authors-index-b.R")

# ---- code-level texts, exactly as the texts NMF builds them ----

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
docs <- aggregate(text ~ kk_code, docs, paste, collapse = " ")
code.text <- docs$text; names(code.text) <- docs$kk_code

# translations of the non-English quotations (PROVENANCE 15); substitute the
# translation for the original where one exists
tr <- read.csv("data/kk-definition-texts-translations.csv")
hit <- match(names(code.text), tr$code)
code.text[!is.na(hit)] <- tr$translation[hit[!is.na(hit)]]

# ---- works of the LCC 2-core, documents from their codes' texts ----

net <- readRDS("data/kk-index-b-work-concept-network-full.rds")
works.tab <- net$works
M <- lcc_2core(sub_work_matrix(net$two_mode_graph))
work.ids <- colnames(M)
cat("2-core works:", length(work.ids), "\n")

work.codes <- works.tab$codes[match(work.ids, works.tab$work)]
stopifnot(!anyNA(work.codes))

doc.text <- vapply(strsplit(work.codes, ";"), function(cs) {
  paste(code.text[cs], collapse = " ")
}, character(1))
n.text <- vapply(strsplit(work.codes, ";"),
                 function(cs) sum(cs %in% names(code.text)), numeric(1))
cat("works with no code text:", sum(n.text == 0), "\n")
keep.work <- n.text > 0
doc.text <- doc.text[keep.work]
work.ids <- work.ids[keep.work]
work.codes <- work.codes[keep.work]
nwords <- vapply(strsplit(doc.text, " "), length, numeric(1))
cat("documents:", length(doc.text), "| words per doc: min", min(nwords),
    "median", median(nwords), "max", max(nwords), "\n")

group.of <- function(codes) {
  gs <- substr(trimws(strsplit(codes, ";")[[1]]), 1, 1)
  tab <- table(gs)
  if (sum(tab == max(tab)) > 1) NA_character_ else names(tab)[which.max(tab)]
}
work.group <- vapply(work.codes, group.of, character(1))
cat("works with a tied dominant group:", sum(is.na(work.group)), "of",
    length(work.group), "\n")

# ---- tokenize, TF-IDF (same conventions as the texts analysis) ----

stopwords <- c("the", "and", "that", "which", "of", "in", "is", "to", "a",
  "by", "or", "as", "be", "it", "for", "with", "are", "on", "not", "from",
  "such", "any", "all", "has", "have", "may", "can", "its", "their", "this",
  "these", "those", "but", "than", "more", "other", "into", "when", "who",
  "one", "two", "been", "was", "were", "also", "an", "at", "so", "no", "we",
  "his", "her", "him", "she", "they", "them", "there", "here", "what",
  "culture", "cultures", "cultural", "society", "social", "man", "men",
  "human", "total", "whole", "way", "ways", "learned", "acquired", "group")

tok <- function(x) {
  x <- tolower(x)
  x <- gsub("[^a-z ]", " ", x)
  strsplit(x, " +")[[1]]
}
toks <- lapply(doc.text, tok)
toks <- lapply(toks, function(w) w[nchar(w) >= 3 & !(w %in% stopwords)])

df <- table(unlist(lapply(toks, unique)))
keep <- names(df)[df >= 2 & df <= 0.5 * length(toks)]
cat("terms kept:", length(keep), "of", length(unique(unlist(toks))), "\n")

D <- matrix(0, nrow = length(toks), ncol = length(keep),
            dimnames = list(work.ids, keep))
for (i in seq_along(toks)) {
  w <- toks[[i]]
  w <- w[w %in% keep]
  if (length(w)) D[i, ] <- table(factor(w, levels = keep))
}
idf <- log(nrow(D) / colSums(D > 0))
V <- sweep(D, 2, idf, `*`)

# ---- NMF: stability diagnostic, then the fixed k = 7 fit ----

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
write.csv(stability, "data/kk-index-b-nmf-work-texts-stability.csv",
          row.names = FALSE)

K <- 7
fit <- nmf.fit(V, K, seed = 7013)
cat("fixed k:", K, "obj =", sprintf("%.1f", fit$obj), "\n")

# factor labels, set by hand from the profiles in
# data/kk-index-b-nmf-work-texts-factors.csv; change them there only. Labels
# stay close to the top terms; factor 5 is quotation and definitional
# boilerplate rather than a theme, a reminder that a document can be driven
# by author phrasing.
factor.labels <- c(
  "Goals and ways of living", "Passed down generations",
  "Material vs. non-material", "Symbolic systems", "Definitional formulas",
  "Mental and holistic", "Species and utensils")

# ---- factor tables ----

factors <- do.call(rbind, lapply(seq_len(K), function(j) {
  w <- sort(fit$H[j, ], decreasing = TRUE)
  data.frame(factor = j, rank = seq_along(w), term = names(w),
             loading = round(w, 4))
}))
factors <- factors[factors$rank <= 15, ]
write.csv(factors, "data/kk-index-b-nmf-work-texts-factors.csv",
          row.names = FALSE)

# top 8 terms per factor, horizontal bars (loadings are unit-sum per factor)
top.terms <- factors[factors$rank <= 8, ]
top.terms$factor <- factor(top.terms$factor, levels = 1:K,
                           labels = factor.labels)
ggplot(top.terms, aes(loading, stats::reorder(term, loading))) +
  geom_col(fill = "grey45") +
  facet_wrap(~ factor, scales = "free") +
  labs(title = "Top terms of each works-as-texts NMF factor",
       subtitle = paste0("k = 7; documents are works of the works LCC 2-core,",
                         " texts concatenated from their codes' definitions"),
       x = "term loading", y = NULL) +
  theme_minimal()
ggsave("figures/kk-index-b/nmf/nmf-work-texts-factors.png",
       width = 9, height = 6, bg = "white")

# ---- work loadings and the works x factors heatmap ----

Wc <- sweep(fit$W, 1, rowSums(fit$W), "/")
loads <- data.frame(work = work.ids, round(Wc, 4))
loads$dominant <- max.col(Wc)
loads$factor_label <- factor.labels[loads$dominant]
loads$label <- vapply(loads$work, label.authors, character(1))
loads$pub_type <- works.tab$pub_type[match(loads$work, works.tab$work)]
loads$group <- work.group[match(loads$work, work.ids)]

# bridge: the dominant code-level texts factor of the work's codes (majority,
# NA on a tie), from data/kk-index-b-nmf-texts-loads.csv
tloads <- read.csv("data/kk-index-b-nmf-texts-loads.csv")
loads$bridge <- vapply(strsplit(work.codes, ";"), function(cs) {
  f <- tloads$dominant[match(cs, tloads$kk_code)]
  f <- f[!is.na(f)]
  if (!length(f)) return(NA_integer_)
  tab <- table(f)
  if (sum(tab == max(tab)) > 1) NA_integer_ else as.integer(names(tab)[which.max(tab)])
}, integer(1))
write.csv(loads, "data/kk-index-b-nmf-work-texts-loads.csv", row.names = FALSE)

cat("\nwork counts per dominant factor:\n"); print(table(loads$dominant))

ord <- order(loads$dominant, -apply(Wc, 1, max))
lab.levels <- loads$label[ord]
stopifnot(!anyDuplicated(lab.levels))
hm <- data.frame(
  work = factor(rep(lab.levels, times = K), levels = rev(lab.levels)),
  factor = factor(rep(seq_len(K), each = length(ord)),
                  labels = gsub(" ", "\n", factor.labels)),
  loading = as.vector(t(Wc[ord, ])))
ggplot(hm, aes(factor, work, fill = loading)) +
  geom_tile(color = "white") +
  scale_fill_gradient(low = "grey96", high = "grey25") +
  scale_x_discrete(guide = guide_axis(n.dodge = 2)) +
  labs(title = "Works x works-as-texts NMF factors, k = 7",
       subtitle = paste0("Loadings sum to 1 per work;",
                         " works grouped by dominant factor"),
       x = NULL, y = NULL, fill = "loading") +
  theme_minimal(base_size = 9) +
  theme(axis.text.y = element_text(size = 4.2))
ggsave("figures/kk-index-b/nmf/nmf-work-texts.png",
       width = 6.5, height = 9, bg = "white")

# ---- agreement with K&K groups ----

dom <- loads$dominant
ok <- !is.na(loads$group)
ct <- table(factor(dom, levels = 1:K),
            factor(loads$group, levels = LETTERS[1:7]))
cat("\ncross-tab, dominant factor (rows) x dominant K&K group (cols):\n")
print(ct)
ari.obs <- ari(as.character(dom[ok]), loads$group[ok])
ari.perm <- replicate(1000, ari(as.character(dom[ok]), sample(loads$group[ok])))
cat("\nARI:", sprintf("%.3f", ari.obs),
    "| permuted baseline: mean", sprintf("%.3f", mean(ari.perm)),
    "95th pct", sprintf("%.3f", quantile(ari.perm, 0.95)), "\n")
purity <- vapply(seq_len(K), function(j) {
  g <- loads$group[dom == j]
  if (!length(g)) return(NA_real_)
  max(table(g, useNA = "no")) / length(g)
}, numeric(1))
cat("purity per factor:", paste(sprintf("%.2f", purity), collapse = " "), "\n")

agree <- data.frame(factor = rep(1:K, times = 7),
                    factor_label = rep(factor.labels, times = 7),
                    group = rep(LETTERS[1:7], each = 7),
                    n_works = as.vector(ct))
write.csv(agree, "data/kk-index-b-nmf-work-texts-agreement.csv",
          row.names = FALSE)

# ---- bridge to the code-level texts NMF ----
# the work document is the concatenation of its codes' documents, so the
# work-level factors are aggregations of the code-level ones; agreement here
# is a consistency check of the pipeline, not an independent result.

okb <- ok & !is.na(loads$bridge)
ctb <- table(Work = factor(dom[okb], levels = 1:K),
             CodeLevel = factor(loads$bridge[okb], levels = 1:K))
cat("\nbridged works (unique majority code factor):", sum(okb), "of",
    nrow(loads), "\n")
print(ctb)
arib <- ari(as.character(dom[okb]), as.character(loads$bridge[okb]))
arib.perm <- replicate(1000, ari(as.character(dom[okb]),
                                 sample(as.character(loads$bridge[okb]))))
cat("bridged ARI:", sprintf("%.3f", arib),
    "| permuted baseline: mean", sprintf("%.3f", mean(arib.perm)),
    "95th pct", sprintf("%.3f", quantile(arib.perm, 0.95)), "\n")
bridge <- data.frame(work_factor = rep(1:K, times = K),
                     code_factor = rep(1:K, each = K),
                     n_works = as.vector(ctb))
write.csv(bridge, "data/kk-index-b-nmf-work-texts-bridge.csv",
          row.names = FALSE)

# ---- sensitivity: unit-L2 document vectors (length normalization) ----
# document sizes range widely (a work can sit under many codes), so the raw
# TF-IDF counts favor long documents; the console check repeats the fit on
# unit-L2 rows.

rs <- sqrt(rowSums(V^2))
Vn <- V / ifelse(rs == 0, 1, rs)  # zero-count documents stay zero
fitn <- nmf.fit(Vn, K, seed = 7013)
domn <- max.col(sweep(fitn$W, 1, rowSums(fitn$W), "/"))
arin <- ari(as.character(domn[ok]), loads$group[ok])
cat("L2-normalized variant ARI:", sprintf("%.3f", arin), "\n")
