# Maximum spanning tree of the definitions (code) projection of the binary
# definitions-by-topics network (LDA edge rule, m = 1.5), on the largest
# component's 2-core (lcc_2core()). Ties between two codes = shared topics
# (edge weight). Layout, labels, star shapes, community colors and betweenness
# follow scripts/analysis-mst-definitions-index-b.R, so the two trees can be
# compared directly. Reads data/kk-index-b-lda-code-theta.csv.

library(igraph)
library(ggraph)
library(ggstar)

source("scripts/core-index-b.R")
source("scripts/tree-ensemble-index-b.R")
source("scripts/kk-group-style.R")

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
cat("2-core:", nrow(Ac), "codes x", ncol(Ac), "topics\n")

# code x code projection: weight = number of shared topics
P.def <- tcrossprod(Ac); diag(P.def) <- 0
G.def <- graph_from_adjacency_matrix(P.def, mode = "undirected",
                                     weighted = TRUE, diag = FALSE)
cat("projection edges:", ecount(G.def), "\n")

ens.def <- tree.ensemble(G.def)
st.def <- ens.def$tree
cat("drawn tree is ensemble member", ens.def$best, "of", tree.reps, "\n")
cat("tree edges:", ecount(st.def), "of", vcount(st.def) - 1, "possible\n")
if (!is_connected(st.def)) stop("tree is not connected")

# labels, group and attributes from the verified network's code vertices
g <- readRDS("data/kk-index-b-verified-network.rds")$graph
v.attr <- igraph::vertex_attr(g)
lab <- setNames(paste(v.attr$source_author, v.attr$source_year), v.attr$name)
V(st.def)$label <- lab[V(st.def)$name]
stopifnot(!anyNA(V(st.def)$label))

V(st.def)$family <- v.attr$kk_group[match(V(st.def)$name, v.attr$name)]
fams <- sort(unique(V(st.def)$family))
stopifnot(length(fams) <= 7, !anyNA(V(st.def)$family))
group.star <- kk.group.star[fams]
group.labels <- setNames(paste0(fams, ": ", kk.group.names[fams]), fams)

set.seed(8427)
com.tree <- cluster_leading_eigen(st.def)
V(st.def)$comm <- factor(membership(com.tree))
cat("tree communities:", nlevels(V(st.def)$comm), "\n")

btw <- ens.def$mean[V(st.def)$name]
V(st.def)$btw <- btw
V(st.def)$highlight <- V(st.def)$name %in% names(sort(btw, decreasing = TRUE))[1:10]
cat("mean normalized betweenness range:", range(btw), "\n")

n.comm <- nlevels(V(st.def)$comm)
pal <- setNames(hcl(h = seq(15, 375, length.out = n.comm + 1)[-(n.comm + 1)],
                    c = 65, l = 65), levels(V(st.def)$comm))

lay <- create_layout(st.def, layout = "kk")
p <- ggraph(lay) +
  geom_edge_link(aes(width = weight), color = "grey75", alpha = 0.8) +
  scale_edge_width(range = c(0.3, 1.6), guide = "none") +
  geom_star(data = lay, aes(x = x, y = y, starshape = family, fill = comm, size = btw),
            color = "grey25") +
  scale_fill_manual(values = pal, guide = "none") +
  scale_starshape_manual(values = group.star, labels = group.labels, name = "definition type (K&K group)",
                         guide = guide_legend(override.aes = list(size = 4, fill = "black"))) +
  scale_size_continuous(range = c(2.5, 9), name = "mean normalized betweenness (ensemble)",
                        guide = guide_legend(override.aes = list(starshape = 15, fill = "grey80"))) +
  # top-ten codes in black and larger; all other labels in grey
  geom_node_text(aes(label = label), data = function(d) d[!d$highlight, ], repel = TRUE,
                 colour = "grey60", size = 2.6, max.overlaps = Inf, seed = 8427,
                 segment.color = NA, force = 0.6, max.iter = 20000) +
  geom_node_text(aes(label = label), data = function(d) d[d$highlight, ], repel = TRUE,
                 colour = "black", size = 3.2, fontface = "bold", max.overlaps = Inf, seed = 8427,
                 segment.color = NA, force = 0.6, max.iter = 20000) +
  theme_void() +
  theme(plot.title = element_text(face = "bold", size = 13),
        legend.position = "bottom",
        legend.title = element_text(size = 8), legend.text = element_text(size = 7)) +
  labs(title = "Maximum spanning tree, definitions-by-topics network (code nodes), LDA topic edges, 2-core",
       subtitle = "ties = shared LDA topics (m = 1.5); labels = author and year; shape = K&K group; node size = mean normalized betweenness (ensemble); black = top ten")
ggsave("figures/kk-index-b/lda/mst-code-author-year-tree-topic-network.png", p,
       width = 14, height = 10, dpi = 150, bg = "white")
cat("figure written\n")
