# Maximum spanning tree of the topic (second-mode) projection of the binary
# definitions-by-topics network (LDA edge rule, m = 1.5), on the largest
# component's 2-core. Ties between two topics = shared codes (edge weight).
# Same ensemble, drawn-tree rule and seeds as the code tree in
# scripts/analysis-mst-topic-network-index-b.R. Labels are the Table 4 topic labels.
# Reads data/kk-index-b-lda-code-theta.csv.

library(igraph)
library(ggraph)

source("scripts/core-index-b.R")
source("scripts/tree-ensemble-index-b.R")

set.seed(8427)
dir.create("figures/kk-index-b/lda", recursive = TRUE, showWarnings = FALSE)

M.MULT <- 1.5
TOL <- 1e-9

th <- read.csv("data/kk-index-b-lda-code-theta.csv", check.names = FALSE,
               stringsAsFactors = FALSE)
M <- as.matrix(th[, as.character(1:12)])
rownames(M) <- th$kk_code
B <- sweep(M, 1, rowMeans(M), function(x, r) x - M.MULT * r > TOL) * 1L
colnames(B) <- paste0("T", 1:12)

Ac <- lcc_2core(B)
P.top <- crossprod(Ac); diag(P.top) <- 0
G.top <- graph_from_adjacency_matrix(P.top, mode = "undirected",
                                     weighted = TRUE, diag = FALSE)

ens.top <- tree.ensemble(G.top)
st.top <- ens.top$tree
cat("drawn tree is ensemble member", ens.top$best, "of", tree.reps, "\n")
cat("tree edges:", ecount(st.top), "of", vcount(st.top) - 1, "possible\n")
if (!is_connected(st.top)) stop("tree is not connected")

set.seed(8427)
com.tree <- cluster_leading_eigen(st.top)
V(st.top)$comm <- factor(membership(com.tree))
cat("tree communities:", nlevels(V(st.top)$comm), "\n")

btw <- ens.top$mean[V(st.top)$name]
V(st.top)$btw <- btw

# Table 4 labels, with the topic number as in the table
topic.labels <- c("individual acquired behavior", "human products and results",
  "transmitted group behavior", "shared group living", "biological needs and nature",
  "acquired habits as complex wholes", "cultural order of phenomena", "sum total of group life",
  "material tools and ideas", "customs, beliefs and knowledge", "way of life of a people",
  "man-made environment")
num <- as.integer(sub("T", "", V(st.top)$name))
V(st.top)$label <- paste(num, topic.labels[num])

n.comm <- nlevels(V(st.top)$comm)
pal <- setNames(hcl(h = seq(15, 375, length.out = n.comm + 1)[-(n.comm + 1)],
                    c = 65, l = 65), levels(V(st.top)$comm))

lay <- create_layout(st.top, layout = "kk")
p <- ggraph(lay) +
  geom_edge_link(aes(width = weight), color = "grey70", alpha = 0.9) +
  scale_edge_width(range = c(0.4, 3), name = "shared codes") +
  geom_node_point(aes(fill = comm, size = btw), shape = 21, color = "grey25", stroke = 0.5) +
  scale_fill_manual(values = pal, guide = "none") +
  scale_size_continuous(range = c(3, 12), name = "mean normalized betweenness (ensemble)") +
  geom_node_text(aes(label = label), repel = TRUE, size = 3.2, max.overlaps = Inf,
                 seed = 8427, segment.color = NA, force = 1, max.iter = 20000) +
  theme_void() +
  theme(plot.title = element_text(face = "bold", size = 13),
        legend.position = "bottom", legend.title = element_text(size = 8),
        legend.text = element_text(size = 7)) +
  labs(title = "Maximum spanning tree, definitions-by-topics network (topic nodes), LDA topics, 2-core",
       subtitle = "ties = shared codes (edge width); labels = Table 4 topics; size = mean normalized betweenness (ensemble); color = community on the tree shown")
ggsave("figures/kk-index-b/lda/mst-topic-nodes-tree.png", p,
       width = 11, height = 8, dpi = 150, bg = "white")
cat("figure written\n")
