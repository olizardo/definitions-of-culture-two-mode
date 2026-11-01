# Ranks the definitions within each LDA topic by their stored weight on it, for
# the most-representative-definitions table (Table 5 of the manuscript). Writes
# data/kk-index-b-lda-topic-ranking.csv in long format, one row per definition and
# topic. The weights are the stored theta matrix, so no projection is involved.
# Run from the project root in a fresh environment.

th <- read.csv("data/kk-index-b-lda-code-theta.csv", check.names = FALSE,
               stringsAsFactors = FALSE)

# Table 4 labels
topic.labels <- c("individual acquired behavior", "human products and results",
  "transmitted group behavior", "shared group living", "biological needs and nature",
  "acquired habits as complex wholes", "cultural order of phenomena", "sum total of group life",
  "material tools and ideas", "customs, beliefs and knowledge", "way of life of a people",
  "man-made environment")

ranking <- do.call(rbind, lapply(1:12, function(k) {
  w <- th[[as.character(k)]]
  o <- order(-w, th$kk_code)
  data.frame(topic = k, topic_label = topic.labels[k], rank = seq_along(o),
             kk_code = th$kk_code[o], theta = round(w[o], 6),
             n_words = th$n_words[o], n_clauses = th$n_clauses[o])
}))
write.csv(ranking, "data/kk-index-b-lda-topic-ranking.csv", row.names = FALSE)
print(subset(ranking, rank <= 5), row.names = FALSE)
