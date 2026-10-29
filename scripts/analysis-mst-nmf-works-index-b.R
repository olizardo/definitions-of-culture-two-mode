# Maximum spanning tree from the NMF works factors (see
# scripts/analysis-nmf-works-index-b.R): the works x factor loadings of the
# LCC 2-core are binarized at a fixed threshold, projected so that two works
# are tied by the number of NMF factors they share, and the Kruskal maximum
# spanning tree of the projection is drawn.
#
# The threshold is a free parameter, not selected by the data. At 0.10 no
# work drops out and 101 of the 118 works belong to two or more factors.
# Factor labels are the works-NMF labels set in analysis-nmf-works-index-b.R.
#
# Outputs:
#   figures/kk-index-b/nmf/nmf-works-mst.png     work-node tree
#   data/kk-index-b-mst-nmf-works-nodes.csv      node table

THRESH <- 0.10

library(igraph)
library(ggraph)
set.seed(8427)
invisible(dir.create("figures/kk-index-b/nmf", recursive = TRUE, showWarnings = FALSE))

source("scripts/pub-type-style.R")

loads <- read.csv("data/kk-index-b-nmf-works-loads.csv", stringsAsFactors = FALSE)
stopifnot(!anyDuplicated(loads$label), !anyDuplicated(loads$work))

# binarized works x factors biadjacency; factor labels as in the NMF script
Bf <- loads[, paste0("X", 1:7)] > THRESH
rownames(Bf) <- loads$work
stopifnot(all(rowSums(Bf) > 0))

# works projection: edge weight = number of shared factors
Q <- Bf %*% t(Bf) * 1; diag(Q) <- 0
G <- graph_from_adjacency_matrix(Q, mode = "undirected", weighted = TRUE, diag = FALSE)
cat("works:", vcount(G), "| edges:", ecount(G),
    "| components:", components(G)$no, "\n")

# Kruskal maximum spanning tree (minimum spanning tree on -weight)
st <- mst(G, weights = -E(G)$weight)
stopifnot(is_connected(st))
cat("tree edges:", ecount(st), "of", vcount(st) - 1, "\n")
V(st)$btw <- betweenness(st, directed = FALSE, normalized = FALSE)
V(st)$comm <- factor(membership(cluster_leading_eigen(st)))

V(st)$label <- loads$label[match(V(st)$name, loads$work)]
V(st)$pub_type <- loads$pub_type[match(V(st)$name, loads$work)]
stopifnot(!anyNA(V(st)$pub_type), !anyNA(V(st)$label))

pal.for <- function(st) {
  n <- nlevels(V(st)$comm)
  setNames(hcl(h = seq(15, 375, length.out = n + 1)[-(n + 1)], c = 65, l = 65),
           levels(V(st)$comm))
}

p <- ggraph(st, layout = "kk") +
  geom_edge_link(aes(width = weight), color = "grey75", alpha = 0.8) +
  scale_edge_width(range = c(0.3, 1.6), guide = "none") +
  geom_node_point(aes(fill = comm, size = btw, shape = pub_type),
                  color = "grey25", stroke = 0.5) +
  scale_fill_manual(values = pal.for(st), guide = "none") +
  scale_size_continuous(range = c(2.5, 9), name = "betweenness (tree)") +
  scale_shape_manual(values = pub.shape.mst, name = "publication type",
                     guide = guide_legend(override.aes = list(fill = "grey60", size = 4))) +
  geom_node_text(aes(label = label), repel = TRUE, size = 2.6,
                 max.overlaps = Inf, seed = 8427, segment.color = NA,
                 force = 0.6, max.iter = 20000) +
  theme_void() +
  theme(plot.title = element_text(face = "bold", size = 13),
        legend.position = "bottom") +
  labs(title = "Maximum spanning tree, works network (work nodes), NMF factors",
       subtitle = sprintf("binarized works x factor loadings (threshold %.2f); ties = number of NMF factors shared; node size = betweenness; color = community on the tree; shape = publication type",
                          THRESH))
ggsave("figures/kk-index-b/nmf/nmf-works-mst.png", p,
       width = 14, height = 10, dpi = 150, bg = "white")

out <- data.frame(node = V(st)$name,
                  community = as.integer(V(st)$comm),
                  betweenness = V(st)$btw,
                  degree_tree = degree(st),
                  pub_type = V(st)$pub_type,
                  dominant_factor = loads$dominant[match(V(st)$name, loads$work)],
                  dominant_factor_label = loads$factor_label[match(V(st)$name, loads$work)],
                  stringsAsFactors = FALSE)
write.csv(out[order(-out$betweenness), ],
          "data/kk-index-b-mst-nmf-works-nodes.csv", row.names = FALSE)

cat("tree communities:", nlevels(V(st)$comm), "| figures and node table written\n")
