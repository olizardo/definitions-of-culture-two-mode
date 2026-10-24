# Backbone extraction of the weighted projections of the collapsed KKCC network
# (16 main categories x 135 definitions, union binarized).
# Weighted projection edge weight = number of shared definitions;
# backbone = edges significantly STRONGER than expected under the
# Fixed Degree Sequence Model (FDSM), alpha = 0.10, one-tailed.
# FDSM chosen over SDSM after model comparison: on this small sparse network
# SDSM keeps almost nothing (2 concept / 0 definition edges).
# Uses backbone::backbone_from_projection() (Neal 2022, PLOS One), which takes
# the bipartite matrix itself, not the projection.
# Inputs: data/kkcc_two_mode_main.rds; def_attrs from data/kkcc_two_mode.rds.

library(igraph)
library(ggplot2)
library(ggraph)
library(ggrepel)
library(backbone)

set.seed(8427)

d <- readRDS("data/kkcc_two_mode_main.rds")
A <- d$biadjacency
def_attrs <- readRDS("data/kkcc_two_mode.rds")$def_attrs

dir.create("figures", showWarnings = FALSE)

main_cats <- c("SOCIAL","BEHAVIOR","PATTERNS","HABITS","ACTING","HERITAGE",
               "BELIEFS","CUSTOMS","SYMBOL","SYSTEM","ATTITUDES","ADJUSTMENTS",
               "KNOWLEDGE","LANGUAGE","TRANSMISSION","INDUSTRIES")
main_pal <- setNames(c("#E41A1C","#377EB8","#4DAF4A","#984EA3","#FF7F00","#A65628",
                       "#F781BF","#999999","#66C2A5","#FC8D62","#8DA0CB","#E78AC3",
                       "#A6D854","#FFD92F","#B3B3B3","#1B9E77"), main_cats)
types <- sort(unique(def_attrs$type))
type_pal <- setNames(c("#1B9E77","#D95F02","#7570B3","#E7298A","#66A61E","#E6AB02","#666666"), types)

# ---- weighted projections (shared definitions) and their FDSM backbones
P.p <- A %*% t(A)        # concepts x concepts
P.g <- t(A) %*% A        # definitions x definitions
diag(P.p) <- 0; diag(P.g) <- 0

bb.p <- backbone_from_projection(A,    model = "fdsm", alpha = 0.10, trials = 10000)
bb.g <- backbone_from_projection(t(A), model = "fdsm", alpha = 0.10, trials = 10000)

sumry <- function(P, B) {
  n <- nrow(P)
  data.frame(
    edges_projection = sum(P[upper.tri(P)] > 0),
    density_projection = sum(P[upper.tri(P)] > 0) / choose(n, 2),
    edges_backbone = sum(B[upper.tri(B)] > 0),
    density_backbone = sum(B[upper.tri(B)] > 0) / choose(n, 2),
    max_weight = max(P)
  )
}
cat("concept mode:\n");   print(sumry(P.p, bb.p), row.names = FALSE)
cat("definition mode:\n"); print(sumry(P.g, bb.g), row.names = FALSE)

# ---- concept backbone graph
G.bb.p <- graph_from_adjacency_matrix(bb.p, mode = "undirected", diag = FALSE,
                                      weighted = NULL)
V(G.bb.p)$category <- V(G.bb.p)$name
cat("concept backbone edges:", ecount(G.bb.p), "\n")

ggraph(G.bb.p, layout = "kk") +
  geom_edge_link(color = "grey70", linewidth = 0.6) +
  geom_node_point(aes(fill = category), shape = 21, size = 9,
                  color = "grey30", stroke = 0.8) +
  geom_node_text(aes(label = name), repel = TRUE, size = 3.4,
                 fontface = "bold", max.overlaps = 30, seed = 8427,
                 nudge_y = -0.15, point.padding = 0.2,
                 force = 0.3, max.iter = 20000, segment.color = NA) +
  scale_fill_manual(values = main_pal, guide = "none") +
  theme_void() +
  theme(plot.title = element_text(face = "bold", size = 13)) +
  labs(title = "FDSM backbone (alpha = 0.10), concept projection (shared definitions)")
ggsave("figures/kkcc-backbone-main-concept.png", width = 11, height = 7.5,
       dpi = 150, bg = "white")

# ---- definition backbone graph
G.bb.g <- graph_from_adjacency_matrix(bb.g, mode = "undirected", diag = FALSE,
                                      weighted = NULL)
V(G.bb.g)$type <- def_attrs$type[match(V(G.bb.g)$name, def_attrs$code)]
V(G.bb.g)$degree <- degree(G.bb.g)
cat("definition backbone edges:", ecount(G.bb.g),
    "of", sum(P.g[upper.tri(P.g)] > 0), "in the binarized projection\n")

# label the most connected backbone nodes only
n.show <- 30
show <- V(G.bb.g)$name[order(-V(G.bb.g)$degree)][seq_len(min(n.show, sum(V(G.bb.g)$degree > 0)))]

set.seed(8427)
ggraph(G.bb.g, layout = "fr") +
  geom_edge_link(color = "grey80", linewidth = 0.4) +
  geom_node_point(aes(fill = type, size = degree),
                  shape = 21, color = "grey30", stroke = 0.4) +
  geom_text_repel(data = function(x) x[x$name %in% show, ],
                  aes(x, y, label = name), size = 2.4, fontface = "bold",
                  max.overlaps = 30, seed = 8427, segment.color = "grey60",
                  segment.size = 0.25, force = 0.5) +
  scale_fill_manual(values = type_pal) +
  scale_size_continuous(range = c(1.5, 5), guide = "none") +
  theme_void() +
  theme(plot.title = element_text(face = "bold", size = 13),
        legend.position = "bottom") +
  labs(title = "FDSM backbone (alpha = 0.10), definition projection",
       fill = "Definition type")
ggsave("figures/kkcc-backbone-main-def.png", width = 11, height = 8,
       dpi = 150, bg = "white")
