# Highest-degree concepts and codes, and words-normalized code degree (Table 2 of
# the manuscript), on the LCC 2-core. Concept degree is the number of 2-core codes
# that contain the concept; code degree is the number of 2-core concepts the code
# contains. Per-10-word values use n_words (English translation where one exists).
# Ties at the cutoff are kept, so the three lists can run to different lengths.
# Output: data/kk-index-b-top-degree-2core.csv (one row per list position).

library(igraph)

source("scripts/core-index-b.R")

net <- readRDS("data/kk-index-b-verified-network.rds")
vattr <- igraph::vertex_attr(net$graph)
words <- setNames(vattr$n_words, vattr$name)

Ac <- lcc_2core(net$biadjacency)
cdeg <- rowSums(Ac)
kdeg <- colSums(Ac)

codes.all <- colnames(net$biadjacency)
kdeg.all <- setNames(numeric(length(codes.all)), codes.all)
kdeg.all[names(kdeg)] <- kdeg
w <- words[codes.all]
has.text <- !is.na(w)
per10 <- 10 * kdeg.all / w

top.by <- function(x, n = 10) {
  x <- sort(x, decreasing = TRUE)
  x[x >= x[n]]
}
conc.top <- top.by(cdeg)
code.top <- top.by(kdeg.all[has.text])
per10.top <- top.by(per10[has.text])

pad <- function(x) c(x, rep(NA, max(0, 0) ))
len <- max(length(conc.top), length(code.top), length(per10.top))
fill <- function(nm, v) {
  list(name = c(nm, rep(NA, len - length(nm))),
       value = c(round(unname(v), 2), rep(NA, len - length(v))))
}
a <- fill(names(conc.top), conc.top)
b <- fill(names(code.top), code.top)
c3 <- fill(names(per10.top), per10.top)
out <- data.frame(
  concept = a$name, concept_degree = a$value,
  code = b$name, code_degree = b$value,
  code_per10 = c3$name, per10_value = c3$value,
  stringsAsFactors = FALSE)
write.csv(out, "data/kk-index-b-top-degree-2core.csv", row.names = FALSE)
cat("list lengths: concepts", length(conc.top), " codes", length(code.top), " per-10 words", length(per10.top), "\n")
print(out, row.names = FALSE)

cat("codes with a quotation:", sum(has.text), " with zero 2-core degree:", sum(kdeg.all[has.text] == 0), "\n")
cat("concept 2-core degree: mean", round(mean(cdeg), 2), " median", median(cdeg), " max", max(cdeg), "\n")
kd <- kdeg.all[has.text]
cat("code 2-core degree (codes with text): mean", round(mean(kd), 2), " median", median(kd), " max", max(kd), "\n")
kd.nz <- kd[kd > 0]
cat("code 2-core degree (nonzero): mean", round(mean(kd.nz), 2), " median", median(kd.nz), "\n")
cat("per-10 words vs word count, Pearson r:", round(cor(per10[has.text], w[has.text]), 2), "\n")
cat("words vs 2-core degree, all codes with text: Pearson", round(cor(w[has.text], kd), 2),
    " Spearman", round(cor(w[has.text], kd, method = "spearman"), 2), "\n")
cat("same, nonzero 2-core degree:", sum(kd > 0), "codes: Pearson", round(cor(w[has.text][kd > 0], kd.nz), 2),
    " Spearman", round(cor(w[has.text][kd > 0], kd.nz, method = "spearman"), 2), "\n")
