# Concept degree against tie-robust tree betweenness. Reads the concept
# projection's tie-sensitivity output (analysis-tie-sensitivity-index-b.R), so
# run that script first. Degree is the number of codes in the 2-core that
# contain the concept (core_degree in that output).

library(igraph)

tie <- read.csv("data/kk-index-b-tie-sensitivity-concepts.csv")

n <- nrow(tie)
cat("concepts:", n, "\n")
cat("concepts that are leaves in every random tree:", sum(tie$share_zero_btw == 1), "\n")
cat("concepts with zero betweenness in some tree:", sum(tie$share_zero_btw > 0), "\n")
cat("median share of trees in which a concept is a leaf:",
    median(tie$share_zero_btw), "\n")
cat("Spearman, 2-core degree vs mean betweenness:",
    round(cor(tie$core_degree, tie$mean_btw, method = "spearman"), 3), "\n")

top.deg <- head(tie[order(-tie$core_degree, -tie$mean_btw), ], 12)
cat("highest-degree concepts:\n")
print(top.deg[, c("node", "core_degree", "mean_btw", "share_zero_btw", "mean_rank")], row.names = FALSE)

write.csv(tie[order(-tie$mean_btw), c("node", "core_degree", "mean_btw", "share_top10", "share_zero_btw", "mean_rank")],
          "data/kk-index-b-concept-degree-betweenness.csv", row.names = FALSE)
