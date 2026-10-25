# Maximum spanning trees of the heading projections of the K&K Index B networks:
#   (1) definitions: headings x codes; ties = number of codes both headings hold;
#   (2) works: headings x works; ties = number of works both headings hold.
# Both use the largest component's 2-core of the heading-by-second-mode matrix
# (scripts/core-index-b.R). Kruskal maximum spanning trees (minimum spanning tree
# on -weight). Node size = betweenness in the tree; color = leading-eigenvector
# community on the tree; labels = heading.

library(igraph)
library(ggraph)

set.seed(8427)
invisible(lapply(c("figures/kk-index-b/definitions", "figures/kk-index-b/works"), dir.create, recursive = TRUE, showWarnings = FALSE))

source("scripts/core-index-b.R")

def.h <- readRDS("data/kk-index-b-heading-network.rds")$biadjacency
works.h <- igraph::as_biadjacency_matrix(
  readRDS("data/kk-index-b-work-concept-network-full.rds")$two_mode_heading_graph, sparse = FALSE)

# heading projection: ties = shared second-mode nodes (codes or works)
heading.proj <- function(M) {
  P <- M %*% t(M); diag(P) <- 0
  graph_from_adjacency_matrix(P, mode = "undirected", weighted = TRUE, diag = FALSE)
}

tree.of <- function(gr, label) {
  st <- mst(gr, weights = -E(gr)$weight)
  cat(label, "| headings:", vcount(gr), "| graph components:", components(gr)$no,
      "| tree edges:", ecount(st), "of", vcount(gr) - 1, "\n")
  if (!is_connected(st)) stop("tree is not connected: ", label)
  V(st)$btw <- betweenness(st, directed = FALSE, normalized = FALSE)
  V(st)$comm <- factor(membership(cluster_leading_eigen(st)))
  V(st)$label <- V(st)$name
  st
}

M.def <- lcc_2core(def.h)
M.works <- lcc_2core(works.h)
cat("headings dropped by the 2-core: definitions", nrow(def.h) - nrow(M.def),
    "| works", nrow(works.h) - nrow(M.works), "\n")
st.def <- tree.of(heading.proj(M.def), "definitions")
st.works <- tree.of(heading.proj(M.works), "works")

pal.for <- function(st) {
  n <- nlevels(V(st)$comm)
  setNames(hcl(h = seq(15, 375, length.out = n + 1)[-(n + 1)], c = 65, l = 65),
           levels(V(st)$comm))
}

tree.plot <- function(st, title, subtitle, file) {
  p <- ggraph(st, layout = "kk") +
    geom_edge_link(aes(width = weight), color = "grey75", alpha = 0.8) +
    scale_edge_width(range = c(0.3, 1.6), guide = "none") +
    geom_node_point(aes(fill = comm, size = btw), shape = 21,
                    color = "grey25", stroke = 0.5) +
    scale_fill_manual(values = pal.for(st), guide = "none") +
    scale_size_continuous(range = c(2.5, 9), name = "betweenness (tree)") +
    geom_node_text(aes(label = label), repel = TRUE, size = 2.6,
                   max.overlaps = Inf, seed = 8427, segment.color = NA,
                   force = 0.6, max.iter = 20000) +
    theme_void() +
    theme(plot.title = element_text(face = "bold", size = 13),
          legend.position = "bottom") +
    labs(title = title, subtitle = subtitle)
  ggsave(file, p, width = 14, height = 10, dpi = 150, bg = "white")
}

tree.plot(st.def,
          "Maximum spanning tree, definitions network (heading nodes), K&K Index B LCC 2-core",
          "ties = number of codes both headings hold; node size = betweenness in the tree; color = leading-eigenvector community on the tree",
          "figures/kk-index-b/definitions/mst-heading-comm-tree.png")
tree.plot(st.works,
          "Maximum spanning tree, works network (heading nodes), K&K Index B LCC 2-core",
          "ties = number of works both headings hold; node size = betweenness in the tree; color = leading-eigenvector community on the tree",
          "figures/kk-index-b/works/mst-heading.png")

tab <- function(st, network) {
  data.frame(network = network, heading = V(st)$name, community = as.integer(V(st)$comm),
             betweenness = V(st)$btw, degree_tree = degree(st), stringsAsFactors = FALSE)
}
out <- rbind(tab(st.def, "definitions"), tab(st.works, "works"))
write.csv(out[order(out$network, -out$betweenness), ],
          "data/kk-index-b-mst-headings-nodes.csv", row.names = FALSE)

cat("definitions tree communities:", nlevels(V(st.def)$comm),
    "| works tree communities:", nlevels(V(st.works)$comm), "\n")
cat("figures and node table written\n")
