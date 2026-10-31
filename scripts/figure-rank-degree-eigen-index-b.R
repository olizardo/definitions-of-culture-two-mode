# Percentile rank of degree against percentile rank of two-mode eigenvector
# centrality, for concepts and definitions on the LCC 2-core. The dashed line
# is y = x (identical ranks). Run from the project root.

library(ggplot2)

dir.create("figures/kk-index-b/definitions", recursive = TRUE, showWarnings = FALSE)

el <- read.csv("data/kk-index-b-eigen-centrality-2core-elements.csv")
co <- read.csv("data/kk-index-b-eigen-centrality-2core-codes.csv")

prank <- function(x) (rank(x, ties.method = "average") - 0.5) / length(x)

concepts <- data.frame(mode = "Concepts", node = el$element,
                       degree_pct = prank(el$degree),
                       eigen_pct = prank(el$eigen_centrality))
codes <- data.frame(mode = "Definitions", node = co$code,
                    degree_pct = prank(co$degree),
                    eigen_pct = prank(co$eigen_centrality))
dat <- rbind(concepts, codes)

rho <- sapply(split(dat, dat$mode), function(d) cor(d$degree_pct, d$eigen_pct, method = "spearman"))
cat("Spearman rho, degree vs eigenvector:\n")
print(round(rho, 3))

ann <- data.frame(mode = names(rho), label = paste0("Spearman rho = ", round(rho, 2)))

ggplot(dat, aes(x = degree_pct, y = eigen_pct)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "grey50") +
  geom_point(size = 1.8, color = "grey25", alpha = 0.8) +
  geom_text(data = ann, aes(x = 0.02, y = 0.98, label = label), hjust = 0, vjust = 1, size = 3) +
  facet_wrap(~mode) +
  coord_equal(xlim = c(0, 1), ylim = c(0, 1)) +
  labs(x = "Degree, percentile rank",
       y = "Eigenvector centrality, percentile rank",
       title = "Degree and eigenvector centrality, percentile ranks",
       subtitle = "LCC 2-core. Dashed line: identical percentile ranks (y = x).") +
  theme_minimal(base_size = 10) +
  theme(strip.text = element_text(face = "bold"))
ggsave("figures/kk-index-b/definitions/rank-degree-eigen.png",
       width = 9, height = 4.8, dpi = 150, bg = "white")
