# Chi-square test of K&K group by LDA dominant topic.
# Reads data/kk-index-b-lda-code-theta.csv written by analysis-lda-texts-index-b.R.
# Run from the project root in a fresh environment.

CHISQ_SEED <- 8153
CHISQ_B <- 10000

th <- read.csv("data/kk-index-b-lda-code-theta.csv", check.names = FALSE,
               stringsAsFactors = FALSE)

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
