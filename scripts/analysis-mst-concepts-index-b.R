# Maximum spanning tree of the concept (sub-element) projection of the K&K Index B
# definitions network, on the largest component's 2-core (lcc_2core()). Ties
# between two concepts = shared definition codes (edge weight). The drawn tree is
# the ensemble member closest to the mean betweenness over the tree ensemble.
# Run from the project root.

library(igraph)
library(ggplot2)
library(ggraph)

source("scripts/core-index-b.R")
source("scripts/tree-ensemble-index-b.R")

set.seed(8427)
dir.create("figures/kk-index-b/definitions", recursive = TRUE, showWarnings = FALSE)

net <- readRDS("data/kk-index-b-verified-network.rds")
g <- net$graph
Ac <- lcc_2core(net$biadjacency)
cat("2-core:", nrow(Ac), "concepts x", ncol(Ac), "codes, edges:", sum(Ac), "\n")

P.concept <- Ac %*% t(Ac)
diag(P.concept) <- 0
G.concept <- graph_from_adjacency_matrix(P.concept, mode = "undirected",
                                         weighted = TRUE, diag = FALSE)
ens.con <- tree.ensemble(G.concept)
st.concept <- ens.con$tree
cat("concept MST edges:", ecount(st.concept), "of", vcount(st.concept) - 1, "possible\n")

# community on the drawn tree, after the ensemble so the seed state matches the tree
com.tree <- cluster_leading_eigen(st.concept)
V(st.concept)$commtree <- factor(membership(com.tree))

btw <- ens.con$mean[V(st.concept)$name]
V(st.concept)$btw <- btw
# sqrt scaling keeps hubs from dominating the node sizes
V(st.concept)$size <- 2.5 + 5 * sqrt(btw / max(btw))

n.tree <- nlevels(V(st.concept)$commtree)
pal.tree <- setNames(hcl(h = seq(15, 375, length.out = n.tree + 1)[-(n.tree + 1)],
                         c = 65, l = 65),
                     levels(V(st.concept)$commtree))

ggraph(st.concept, layout = "kk") +
  geom_edge_link(color = "grey80", linewidth = 0.4) +
  geom_node_point(aes(fill = commtree, size = size), shape = 21,
                  color = "grey25", stroke = 0.5) +
  # label opacity follows betweenness, so the most central concepts read first
  geom_node_text(aes(label = name, alpha = btw), repel = TRUE, size = 2.5,
                 fontface = "bold", max.overlaps = Inf, seed = 8427,
                 segment.color = NA, force = 0.5, max.iter = 20000) +
  scale_alpha_continuous(range = c(0.35, 1), guide = "none") +
  scale_fill_manual(values = pal.tree, guide = "none") +
  scale_size_identity() +
  theme_void() +
  theme(plot.title = element_text(face = "bold", size = 13)) +
  labs(title = "Maximum spanning tree, definitions network (sub-element nodes), K&K Index B LCC 2-core",
       subtitle = "color = leading-eigenvector community computed on the tree itself; size = mean tree betweenness over the ensemble (sqrt-scaled)")
ggsave("figures/kk-index-b/definitions/mst-subelement-comm-tree.png",
       width = 15, height = 9, dpi = 150, bg = "white")
