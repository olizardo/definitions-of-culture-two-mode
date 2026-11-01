# Chi-square test of K&K group by LDA dominant topic, and Table 5 network
# statistics for the binary definitions-by-topics network (edge rule m = 1.5).
# Reads data/kk-index-b-lda-code-theta.csv written by analysis-lda-texts-index-b.R.
# Run from the project root in a fresh environment, with igraph attached first.

library(igraph)

M_MULT <- 1.5
TOL <- 1e-9
CHISQ_SEED <- 8153
CHISQ_B <- 10000

th <- read.csv("data/kk-index-b-lda-code-theta.csv", check.names = FALSE,
               stringsAsFactors = FALSE)
topic.cols <- as.character(1:12)
M <- as.matrix(th[, topic.cols])
rownames(M) <- th$kk_code

# ---- chi-square: K&K group by dominant topic ----
# Expected counts are mostly below 5, so the p-value is simulated.
tb <- table(th$group, factor(th$dominant, levels = 1:12))
set.seed(CHISQ_SEED)
ch <- suppressWarnings(chisq.test(tb, simulate.p.value = TRUE, B = CHISQ_B))
chisq_out <- data.frame(
  statistic = unname(ch$statistic),
  df = NA_integer_,
  simulated_p = ch$p.value,
  replicates = CHISQ_B,
  seed = CHISQ_SEED,
  n_codes = sum(tb),
  table_rows = nrow(tb),
  table_cols = ncol(tb),
  cells_expected_lt5 = sum(ch$expected < 5),
  cells_total = length(ch$expected)
)
write.csv(chisq_out, "data/kk-index-b-lda-chisq.csv", row.names = FALSE)
print(chisq_out)

# ---- binary network: code linked to topic when weight > m times code's row mean ----
E <- sweep(M, 1, rowMeans(M), function(x, r) x - M_MULT * r > TOL) * 1L
colnames(E) <- paste0("T", topic.cols)

rules <- read.csv("data/kk-index-b-lda-edge-rules.csv")
stopifnot(sum(E) == rules$edges[rules$rule == "row-mean multiple" & rules$param == M_MULT])

g <- graph_from_biadjacency_matrix(E, directed = FALSE)
codes <- which(!V(g)$type)
topics <- which(V(g)$type)
nC <- length(codes)
nT <- length(topics)
dg <- degree(g)
kn <- knn(g)$knn

# Same conventions as Table 1: variance over all nodes (isolates included),
# k_nn over non-isolated nodes.
side <- function(block, idx, n_iso) {
  data.frame(
    block = block,
    statistic = c("mean_degree", "min_degree", "max_degree", "degree_variance", "mean_knn",
                  "isolated"),
    value = c(mean(dg[idx]), min(dg[idx]), max(dg[idx]), var(dg[idx]),
              mean(kn[idx][dg[idx] > 0]), n_iso)
  )
}
net_stats <- rbind(
  data.frame(block = "network",
             statistic = c("edges", "density", "degree_correlation"),
             value = c(ecount(g), ecount(g) / (nC * nT),
                       assortativity_degree(g, directed = FALSE))),
  side("topics", topics, sum(dg[topics] == 0)),
  side("definitions", codes, sum(dg[codes] == 0))
)
write.csv(net_stats, "data/kk-index-b-lda-network-stats.csv", row.names = FALSE)
print(net_stats)
