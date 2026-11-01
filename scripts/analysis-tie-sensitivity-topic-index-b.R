# Tie sensitivity of the maximum spanning tree betweenness for the two
# projections of the binary definitions-by-topics network (LDA edge rule,
# m = 1.5), on the largest component's 2-core. The topic projection has
# topics as nodes (weight = shared codes); the code projection has codes as
# nodes (weight = shared topics). Same ensemble and columns as
# scripts/analysis-tie-sensitivity-index-b.R, for Table 3's topic version.
# Reads data/kk-index-b-lda-code-theta.csv and data/kk-index-b-verified-network.rds.
# Run from the project root in a fresh environment.

library(igraph)
source("scripts/core-index-b.R")
source("scripts/tree-ensemble-index-b.R")

M.MULT <- 1.5
TOL <- 1e-9

th <- read.csv("data/kk-index-b-lda-code-theta.csv", check.names = FALSE,
               stringsAsFactors = FALSE)
M <- as.matrix(th[, as.character(1:12)])
rownames(M) <- th$kk_code
B <- sweep(M, 1, rowMeans(M), function(x, r) x - M.MULT * r > TOL) * 1L
colnames(B) <- paste0("T", 1:12)

Ac <- lcc_2core(B)
cat("2-core:", nrow(Ac), "codes x", ncol(Ac), "topics\n")

sensitivity <- function(P, core.deg, label) {
  diag(P) <- 0
  G <- graph_from_adjacency_matrix(P, mode = "undirected", weighted = TRUE, diag = FALSE)
  nodes <- V(G)$name
  ens <- tree.ensemble(G)
  btw <- ens$btw
  n.rep <- nrow(btw)
  # zero-betweenness leaves never count as top ten (name-order ties would otherwise)
  top10 <- t(apply(btw, 1, function(b) rank(-b, ties.method = "min") <= 10 & b > 0))
  rk <- t(apply(-btw, 1, rank, ties.method = "average"))
  out <- data.frame(
    node = nodes,
    core_degree = core.deg[nodes],
    mean_btw = ens$mean,
    sd_btw = apply(btw, 2, sd),
    min_btw = apply(btw, 2, min),
    max_btw = apply(btw, 2, max),
    share_top10 = colMeans(top10),
    share_zero_btw = colMeans(btw == 0),
    mean_rank = colMeans(rk),
    drawn_btw = freeman(ens$tree)[nodes],
    n_trees = n.rep,
    row.names = NULL
  )
  out <- out[order(-out$mean_btw), ]
  out$mean_btw_pct <- round(100 * out$mean_btw, 2)
  cat(label, "(", n.rep, "random trees; drawn tree is member", ens$best, "):\n")
  print(out[, c("node", "mean_btw_pct", "sd_btw", "share_top10", "mean_rank")], row.names = FALSE)
  out
}

top.out <- sensitivity(crossprod(Ac), colSums(Ac), "Topics")
write.csv(top.out, "data/kk-index-b-tie-sensitivity-topics.csv", row.names = FALSE)

cod.out <- sensitivity(tcrossprod(Ac), rowSums(Ac), "Definitions (topic network)")
write.csv(cod.out, "data/kk-index-b-tie-sensitivity-topic-definitions.csv", row.names = FALSE)
