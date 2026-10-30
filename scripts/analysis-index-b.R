# Network description of the K&K Index B dataset, compared with Boroch's
# Table 2 network. Descriptive only; no inferential claims.
#
# Requires build-index-b.R (data/kk_biadjacency_*.rds) and kkcc_two_mode.rds.

library(igraph)
library(ggplot2)

to_bipartite <- function(m) {
  g <- graph_from_biadjacency_matrix(m, directed = FALSE, mode = "all", multiple = FALSE)
  g
}

describe_network <- function(m, label) {
  g <- to_bipartite(m)
  comp <- components(g)
  deg_mode <- degree(g)
  rows <- rownames(m)
  cols <- colnames(m)
  data.frame(
    network = label,
    concepts = nrow(m),
    definitions = ncol(m),
    edges = ecount(g),
    density = round(ecount(g) / (nrow(m) * ncol(m)), 3),
    components = comp$no,
    largest_component = max(comp$csize),
    isolated_concepts = sum(rowSums(m) == 0),
    isolated_definitions = sum(colSums(m) == 0),
    median_concept_degree = median(rowSums(m)),
    max_concept_degree = max(rowSums(m)),
    median_definition_degree = median(colSums(m)),
    max_definition_degree = max(colSums(m))
  )
}

data_dir <- "data"
kk_head <- readRDS(file.path(data_dir, "kk_biadjacency_heading.rds"))
boroch <- readRDS(file.path(data_dir, "kkcc_two_mode.rds"))$biadjacency

# Keep the K&K columns that are codes in Index A (the verified universe)
# so that Index-B-only OCR artefacts do not inflate definition counts.
defs <- read.csv(file.path(data_dir, "kk-index-b-definitions.csv"))
verified <- defs$kk_code[defs$in_verified]
kk_sub_v <- readRDS(file.path(data_dir, "kk-index-b-verified-network.rds"))$biadjacency
kk_head_v <- kk_head[, colnames(kk_head) %in% verified, drop = FALSE]
kk_head_v <- kk_head_v[rowSums(kk_head_v) > 0, , drop = FALSE]

stats <- rbind(
  describe_network(boroch, "Boroch Table 2 (56 notions x 135 definitions)"),
  describe_network(kk_head_v, "K&K Index B, heading level (verified codes)"),
  describe_network(kk_sub_v, "K&K Index B, sub-element level (verified codes)")
)
write.csv(stats, file.path(data_dir, "kk-index-b-network-stats.csv"), row.names = FALSE)
stats

# Degree distributions of the definitions network, from its two node sets.
degree_df <- rbind(
  data.frame(panel = "Concepts", degree = rowSums(kk_sub_v)),
  # codes with no sub-elements (isolates) are left out of this degree panel
  data.frame(panel = "Definitions",
             degree = colSums(kk_sub_v)[colSums(kk_sub_v) > 0])
)
degree_df$panel <- factor(degree_df$panel, levels = unique(degree_df$panel))

# x ticks per panel: the panel's lowest integer degree, then multiples of 5.
# lim is the expanded range: bars reach 0.5 beyond each integer and the scale adds 0.6.
degree.breaks <- function(lim) {
  pad <- 0.5 + 0.6
  lo <- round(lim[1] + pad); hi <- round(lim[2] - pad)
  m <- seq(0, hi, by = 5)
  unique(c(lo, m[m > lo]))
}

dir.create(file.path("figures", "kk-index-b"), recursive = TRUE, showWarnings = FALSE)
ggplot(degree_df, aes(x = degree)) +
  geom_histogram(binwidth = 1, boundary = 0.5, fill = "grey40", color = "white") +
  # each panel has its own axes so bar heights read against their own scale
  facet_wrap(~ panel, ncol = 2, scales = "free", axes = "all") +
  scale_x_continuous(breaks = degree.breaks, expand = expansion(add = 0.6)) +
  theme_minimal() +
  labs(x = "Degree (number of linked nodes)", y = "Count",
       title = "Degree distributions: K&K Index B definitions network")
ggsave(file.path("figures", "kk-index-b", "degree-definitions.png"), bg = "white",
       width = 8, height = 6, dpi = 150)
