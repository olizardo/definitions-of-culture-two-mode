# LDA over the definition texts, replacing the texts NMF analysis (PROVENANCE 24).
#
# Documents are clauses: each definition quotation is split into sentences and
# semicolon-separated clauses, so a definition listing several elements is not
# forced into a single topic blend. The clause corpus is built exactly as in the
# texts NMF script it replaces: Boroch Table 2 quotations mapped through the
# crosswalk, the appendix-only texts through the links, the K&K-only rows, and
# the translations substituted for the non-English quotations.
#
# Model: Gibbs LDA at k = 12, fixed to be compared against K&K's typology, over
# 50 seeds; the stored code-level memberships are the seed-mean of the
# clause-level theta, weighted by clause word count. Codes with no surviving
# clause (C-I-7, whose only content word is too rare; D-III-4, whose text is a
# page footnote, not a definition) get a uniform theta and are flagged.
#
# Stopwords: SMART minus protected substantive words, plus the frame words
# (culture, society, social, man), grammatical words settled by hand while
# developing the analysis, and a plural collapse (nouns only; verb forms and
# lives/live excluded).
#
# Outputs:
#   data/kk-index-b-lda-code-theta.csv   one row per verified code
#   data/kk-index-b-lda-topic-terms.csv  ensemble-mean top terms per topic
#   data/kk-index-b-lda-group-ari.csv    agreement with the group letters A-G

suppressPackageStartupMessages({
  library(tm)
  library(topicmodels)
  library(stopwords)
  library(clue)
})

set.seed(2466)  # permutation test seed
K <- 12
SEEDS <- 1:50
ALPHA <- 0.1
FRAME <- c("culture", "society", "social", "man")
GRAMMATICAL <- c("one", "another", "may", "also", "non", "consists", "term", "terms",
                 "definition")
PROTECTED <- c("way", "whole", "made", "common", "passed", "group", "life", "people",
               "human", "behavior", "ideas", "custom", "customs", "sum", "total",
               "transmitted", "learned", "things", "thing", "self", "needs", "use",
               "uses", "used", "given", "mean", "name", "different", "various")
# verb forms and lives (life), which are not plurals of the noun
NO_MERGE <- c("refers", "constitutes", "inherits", "conforms", "adjusts",
              "meets", "describes", "prefers", "lives")
STOP <- setdiff(union(tm::stopwords("en"),
                      stopwords::stopwords("en", source = "smart")), PROTECTED)

# ---- assemble clause corpus (document logic as in the replaced NMF script) ----
cross <- read.csv("data/kk-boroch-crosswalk.csv")
t2 <- read.csv("data/kkcc-definition-texts.csv")
t2$kk_code <- cross$kk_code[match(t2$code, cross$boroch_code)]
stopifnot(setequal(t2$code[is.na(t2$kk_code)], c("A10a", "C1-5a", "F4-6")))
t2 <- t2[!is.na(t2$kk_code), ]
links <- read.csv("data/kkcc-appendix-only-links.csv")
app <- read.csv("data/kkcc-appendix-only-texts.csv")
app$kk_code <- links$kk_row[match(app$code, links$code)]
stopifnot(!anyNA(app$kk_code))
kko <- read.csv("data/kk-definition-texts-kk-only.csv")
# the text column holds the quotation; the statement column is the citation
# string (the replaced NMF script wrongly used statement)
docs <- rbind(
  data.frame(kk_code = t2$kk_code, text = t2$text),
  data.frame(kk_code = app$kk_code, text = app$text),
  data.frame(kk_code = kko$kk_code, text = kko$text)
)
ver <- read.csv("data/kk-index-b-definitions.csv", stringsAsFactors = FALSE)
docs <- docs[docs$kk_code %in% ver$kk_code[ver$in_verified], ]
tr <- read.csv("data/kk-definition-texts-translations.csv")
hit <- match(docs$kk_code, tr$code)
docs$text[!is.na(hit)] <- tr$translation[hit[!is.na(hit)]]
docs <- aggregate(text ~ kk_code, docs, paste, collapse = " ")

# sentence split, then semicolon split, at least 3 words per clause
parts <- lapply(seq_len(nrow(docs)), function(i) {
  s <- unlist(strsplit(docs$text[i], "(?<=[.!?])\\s+", perl = TRUE))
  s <- unlist(strsplit(s, "\\s*;\\s*"))
  s <- trimws(s[nzchar(s)])
  data.frame(kk_code = docs$kk_code[i], clause = seq_along(s), text = s)
})
cl <- do.call(rbind, parts)
cl$n_words <- lengths(strsplit(cl$text, "\\s+"))
cl <- cl[cl$n_words >= 3, ]
cat("codes with texts:", length(unique(cl$kk_code)), "| clauses:", nrow(cl), "\n")

# ---- cleaning ----
normalize <- function(x) {
  x <- gsub("\u2019s\\b", "", x)
  x <- gsub("[\u2013\u2014\u2018\u2019\u201c\u201d\u201e\u201f\u00ab\u00bb-]", " ", x)
  x
}
corp <- VCorpus(VectorSource(cl$text))
corp <- tm_map(corp, content_transformer(normalize))
corp <- tm_map(corp, content_transformer(tolower))
corp <- tm_map(corp, removePunctuation)
corp <- tm_map(corp, removeNumbers)
corp <- tm_map(corp, removeWords, c(STOP, FRAME, GRAMMATICAL))
corp <- tm_map(corp, stripWhitespace)

# plural collapse: plural -> singular when both occur (protected words collapse
# too, so "ways" joins "way"; "means" stays apart from "mean" via NO_MERGE)
raw_vocab <- unique(unlist(strsplit(unlist(lapply(corp, as.character)), "\\s+")))
pairs <- data.frame()
for (w in raw_vocab) {
  if (grepl("s$", w) && !grepl("ss$", w) && nchar(w) > 3) {
    sing <- sub("s$", "", w)
    if (sing %in% raw_vocab && !w %in% NO_MERGE) {
      pairs <- rbind(pairs, data.frame(plural = w, singular = sing))
    }
  }
}
if (nrow(pairs)) {
  merge_words <- function(x) {
    for (i in seq_len(nrow(pairs))) {
      x <- gsub(paste0("\\b", pairs$plural[i], "\\b"), pairs$singular[i], x)
    }
    x
  }
  corp <- tm_map(corp, content_transformer(merge_words))
}
cat("plural merges applied:", nrow(pairs), "\n")

dtm0 <- DocumentTermMatrix(corp, control = list(wordLengths = c(3, Inf)))
dm <- as.matrix(dtm0)
dtm <- dtm0[, colSums(dm > 0) >= 2]
keep_rows <- rowSums(as.matrix(dtm)) > 0
dtm <- dtm[keep_rows, ]
cl <- cl[keep_rows, ]
cat("clauses modeled:", nrow(dtm), "| terms:", ncol(dtm), "\n")

# store the modeled clause corpus; the BTM sensitivity script reads it
# (PROVENANCE 37), so the two models always see the same documents
dm_all <- as.matrix(dtm)
clause_rows <- data.frame(
  kk_code = cl$kk_code,
  clause = cl$clause,
  n_words = cl$n_words,
  tokens = apply(dm_all, 1, function(row) paste(rep(colnames(dm_all), times = row), collapse = " ")),
  stringsAsFactors = FALSE
)
write.csv(clause_rows, "data/kk-index-b-lda-clauses.csv", row.names = FALSE)

# ---- LDA ensemble ----
ari <- function(a, b) {
  tab <- table(a, b)
  n <- sum(tab)
  sc <- function(x) sum(choose(x, 2))
  idx <- sc(tab)
  exp_idx <- sc(rowSums(tab)) * sc(colSums(tab)) / choose(n, 2)
  max_idx <- (sc(rowSums(tab)) + sc(colSums(tab))) / 2
  (idx - exp_idx) / (max_idx - exp_idx)
}

fits <- lapply(SEEDS, function(s) LDA(dtm, k = K, method = "Gibbs",
  control = list(seed = s, burnin = 500, iter = 1000, thin = 100, alpha = ALPHA)))
thetas <- lapply(fits, function(f) posterior(f)$topics)
betas <- lapply(fits, function(f) posterior(f)$terms)

# align each seed's topics to seed 1 (Hungarian assignment on the cosine
# similarity of the topic-term profiles); otherwise the seed mean of theta
# averages unrelated topics
cos_sim <- function(A, B) {
  An <- A / sqrt(rowSums(A^2)); Bn <- B / sqrt(rowSums(B^2))
  An %*% t(Bn)
}
base_beta <- betas[[1]]
perm_order <- lapply(seq_along(fits), function(i) {
  if (i == 1) return(seq_len(K))
  cs <- cos_sim(base_beta, betas[[i]])
  as.integer(clue::solve_LSAP(cs, maximum = TRUE))
})
thetas <- lapply(seq_along(fits), function(i) thetas[[i]][, perm_order[[i]], drop = FALSE])
betas <- lapply(seq_along(fits), function(i) betas[[i]][perm_order[[i]], , drop = FALSE])
matched_cos <- vapply(seq_along(fits), function(i) {
  diag(cos_sim(base_beta, betas[[i]]))
}, numeric(K))
cat("topic alignment to seed 1 done; mean matched cosine:",
    round(mean(matched_cos), 3), "\n")

# aggregate theta to codes, weighted by clause word count
sp <- split(seq_len(nrow(thetas[[1]])), cl$kk_code)
agg <- lapply(thetas, function(th) {
  out <- t(vapply(sp, function(ii) {
    w <- cl$n_words[ii]
    as.numeric(crossprod(th[ii, , drop = FALSE], w) / sum(w))
  }, numeric(K)))
  rownames(out) <- names(sp)
  out
})
ens <- Reduce(`+`, agg) / length(agg)

# codes with no surviving clause get a uniform theta and a flag
all_codes <- ver$kk_code[ver$in_verified]
no_clause <- setdiff(all_codes, rownames(ens))
cat("codes with no surviving clause:", paste(no_clause, collapse = ", "), "\n")
uni <- matrix(1 / K, nrow = length(no_clause), ncol = K,
              dimnames = list(no_clause, colnames(ens)))
ens_full <- rbind(ens, uni)

grp <- substr(rownames(ens_full), 1, 1)
dom <- max.col(ens_full, ties.method = "first")
obs <- ari(as.character(dom), grp)
perm <- replicate(999, ari(as.character(dom), sample(grp)))
pval <- (sum(perm >= obs) + 1) / 1000
cat("ensemble dominant-topic ARI vs group letters:", round(obs, 3), "p =", pval, "\n")

# ---- outputs ----
theta_out <- data.frame(kk_code = rownames(ens_full), ens_full, check.names = FALSE)
theta_out$dominant <- dom
theta_out$group <- grp
theta_out$n_clauses <- as.integer(table(factor(cl$kk_code, levels = rownames(ens_full))))
theta_out$n_words <- as.integer(tapply(cl$n_words, factor(cl$kk_code,
  levels = rownames(ens_full)), sum))
write.csv(theta_out, "data/kk-index-b-lda-code-theta.csv", row.names = FALSE)

beta_ens <- Reduce(`+`, betas) / length(betas)
terms_out <- do.call(rbind, lapply(seq_len(K), function(j) {
  o <- order(beta_ens[j, ], decreasing = TRUE)[1:10]
  data.frame(topic = j, rank = seq_along(o), term = colnames(beta_ens)[o],
             weight = beta_ens[j, o])
}))
write.csv(terms_out, "data/kk-index-b-lda-topic-terms.csv", row.names = FALSE)

ari_rows <- do.call(rbind, lapply(seq_along(agg), function(i) {
  d <- max.col(agg[[i]], ties.method = "first")
  g <- grp[match(rownames(ens), rownames(ens_full))]
  data.frame(seed = SEEDS[i], ari = ari(as.character(d), g),
             perm_p = NA, kind = "single_seed")
}))
ari_rows <- rbind(ari_rows, data.frame(seed = NA, ari = obs,
                                       perm_p = pval, kind = "ensemble"))
write.csv(ari_rows, "data/kk-index-b-lda-group-ari.csv", row.names = FALSE)

cat("outputs written:\n",
    "- data/kk-index-b-lda-code-theta.csv (", nrow(theta_out), "codes )\n",
    "- data/kk-index-b-lda-topic-terms.csv\n",
    "- data/kk-index-b-lda-group-ari.csv\n")
