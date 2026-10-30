# Variant of the definitions-network maximum spanning tree (code nodes) with
# author-year labels and publication-type node shapes. The tree construction
# mirrors scripts/analysis-mst-definitions-index-b.R and must stay in step with
# it (same 2-core, same seed for the community detection). Labels and the
# publication type both come from the verified network's code-vertex attributes.

library(igraph)
library(ggraph)
library(ggstar)

set.seed(8427)
dir.create("figures/kk-index-b/definitions", recursive = TRUE, showWarnings = FALSE)

g <- readRDS("data/kk-index-b-verified-network.rds")$graph
comp <- components(g)
gl <- induced_subgraph(g, comp$membership == which.max(comp$csize))
el <- as_edgelist(gl, names = TRUE)
Al <- matrix(0, nrow = length(unique(el[, 1])), ncol = length(unique(el[, 2])),
             dimnames = list(sort(unique(el[, 1])), sort(unique(el[, 2]))))
Al[cbind(el[, 1], el[, 2])] <- 1
Ac <- Al
repeat {
  keep.r <- rowSums(Ac) >= 2
  keep.c <- colSums(Ac) >= 2
  if (all(keep.r) && all(keep.c)) break
  Ac <- Ac[keep.r, keep.c, drop = FALSE]
}

# code x code projection: weight = number of shared sub-elements
P.def <- crossprod(Ac); diag(P.def) <- 0
G.def <- graph_from_adjacency_matrix(P.def, mode = "undirected",
                                     weighted = TRUE, diag = FALSE)
st.def <- mst(G.def, weights = -E(G.def)$weight)
cat("tree edges:", ecount(st.def), "of", vcount(st.def) - 1, "possible\n")
if (!is_connected(st.def)) stop("tree is not connected")

# labels: author and year of each code's quotation, merged from the verified
# network's vertex attributes by node name (same attributes as the tree-nodes CSV)
v.attr <- igraph::vertex_attr(g)
lab <- setNames(paste(v.attr$source_author, v.attr$source_year), v.attr$name)
V(st.def)$label <- lab[V(st.def)$name]
stopifnot(!anyNA(V(st.def)$label))

# shape: publication type, attached to the code vertices by
# scripts/attach-code-attributes-index-b.R (PROVENANCE 21)
V(st.def)$pub_type <- V(g)$pub_type[match(V(st.def)$name, V(g)$name)]
missing <- V(st.def)$name[is.na(V(st.def)$pub_type)]
cat("tree codes without a publication type:", if (length(missing)) paste(missing, collapse = ", ") else "none", "\n")
pub.f <- factor(V(st.def)$pub_type, levels = c("article", "book", "chapter", "other"))
V(st.def)$pub_type <- pub.f

# leading-eigenvector community on the tree; tree betweenness (as in the base figure)
com.tree <- cluster_leading_eigen(st.def)
V(st.def)$comm <- factor(membership(com.tree))
btw <- betweenness(st.def, directed = FALSE, normalized = FALSE)
V(st.def)$btw <- btw

n.comm <- nlevels(V(st.def)$comm)
pal <- setNames(hcl(h = seq(15, 375, length.out = n.comm + 1)[-(n.comm + 1)],
                    c = 65, l = 65), levels(V(st.def)$comm))

lay <- create_layout(st.def, layout = "kk")
p <- ggraph(lay) +
  geom_edge_link(aes(width = weight), color = "grey75", alpha = 0.8) +
  scale_edge_width(range = c(0.3, 1.6), guide = "none") +
  geom_star(data = lay, aes(x = x, y = y, starshape = pub_type, fill = comm, size = btw),
            color = "grey25") +
  scale_fill_manual(values = pal, guide = "none") +
  scale_starshape_manual(values = c(article = 13, book = 15, chapter = 11, other = 23),
                         labels = c(article = "Article", book = "Book",
                                    chapter = "Chapter", other = "Other"),
                         name = "publication type of the code's work",
                         guide = guide_legend(override.aes = list(size = 4, fill = "black"))) +
  scale_size_continuous(range = c(2.5, 9), name = "betweenness (tree)") +
  geom_node_text(aes(label = label), repel = TRUE, size = 2.6,
                 max.overlaps = Inf, seed = 8427, segment.color = NA,
                 force = 0.6, max.iter = 20000) +
  theme_void() +
  theme(plot.title = element_text(face = "bold", size = 13),
        legend.position = "bottom",
        legend.title = element_text(size = 8), legend.text = element_text(size = 7)) +
  labs(title = "Maximum spanning tree, definitions network (code nodes), K&K Index B LCC 2-core",
       subtitle = "ties = shared sub-elements; labels = author and year of the quotation; shape = publication type; node size = betweenness in the tree")
ggsave("figures/kk-index-b/definitions/mst-code-author-pubtype-tree.png", p,
       width = 14, height = 10, dpi = 150, bg = "white")
cat("figure written\n")
