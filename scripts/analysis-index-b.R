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
kk_sub <- readRDS(file.path(data_dir, "kk_biadjacency_subelement.rds"))
kk_head <- readRDS(file.path(data_dir, "kk_biadjacency_heading.rds"))
boroch <- readRDS(file.path(data_dir, "kkcc_two_mode.rds"))$biadjacency

# Keep the K&K columns that are codes in Index A (the verified universe)
# so that Index-B-only OCR artefacts do not inflate definition counts.
defs <- read.csv(file.path(data_dir, "kk-index-b-definitions.csv"))
verified <- defs$kk_code[defs$in_index_a]
kk_sub_v <- kk_sub[, colnames(kk_sub) %in% verified, drop = FALSE]
kk_sub_v <- kk_sub_v[rowSums(kk_sub_v) > 0, , drop = FALSE]
kk_head_v <- kk_head[, colnames(kk_head) %in% verified, drop = FALSE]
kk_head_v <- kk_head_v[rowSums(kk_head_v) > 0, , drop = FALSE]

stats <- rbind(
  describe_network(boroch, "Boroch Table 2 (56 notions x 135 definitions)"),
  describe_network(kk_head_v, "K&K Index B, heading level (verified codes)"),
  describe_network(kk_sub_v, "K&K Index B, sub-element level (verified codes)")
)
write.csv(stats, file.path(data_dir, "kk-index-b-network-stats.csv"), row.names = FALSE)
stats

degree_df <- rbind(
  data.frame(network = "Boroch Table 2", mode = "definition", degree = colSums(boroch)),
  data.frame(network = "Boroch Table 2", mode = "concept", degree = rowSums(boroch)),
  data.frame(network = "K&K sub-element", mode = "definition", degree = colSums(kk_sub_v)),
  data.frame(network = "K&K sub-element", mode = "concept", degree = rowSums(kk_sub_v))
)

ggplot(degree_df, aes(x = degree)) +
  geom_histogram(binwidth = 1, boundary = 0.5) +
  facet_grid(mode ~ network, scales = "free_y") +
  labs(x = "Degree (number of linked elements)", y = "Count",
       title = "Degree distributions: Boroch Table 2 vs K&K Index B")

ggsave(file.path("figures", "kk-index-b-degree-comparison.png"), bg = "white",
       width = 8, height = 5, dpi = 150)
