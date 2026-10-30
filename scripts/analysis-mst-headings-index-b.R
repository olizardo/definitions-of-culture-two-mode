# Maximum spanning tree of the heading projection of the K&K Index B definitions
# network: headings x verified codes; ties = number of codes both headings hold.
# Uses the largest component's 2-core of the heading-by-code matrix
# (scripts/core-index-b.R). Kruskal maximum spanning tree (minimum spanning tree
# on -weight). Node size = betweenness in the tree; color = leading-eigenvector
# community on the tree; labels = heading.

library(igraph)
library(ggraph)

set.seed(8427)
invisible(lapply(c("figures/kk-index-b/definitions"), dir.create, recursive = TRUE, showWarnings = FALSE))

source("scripts/core-index-b.R")

# The stored heading network holds every Index B code; keep the verified codes only.
ver.codes <- colnames(readRDS("data/kk-index-b-verified-network.rds")$biadjacency)
def.h <- readRDS("data/kk-index-b-heading-network.rds")$biadjacency[, ver.codes, drop = FALSE]
def.h <- def.h[rowSums(def.h) > 0, , drop = FALSE]

# heading projection: ties = shared codes
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
cat("headings dropped by the 2-core: definitions", nrow(def.h) - nrow(M.def), "\n")
st.def <- tree.of(heading.proj(M.def), "definitions")

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

out <- data.frame(network = "definitions", heading = V(st.def)$name,
                  community = as.integer(V(st.def)$comm),
                  betweenness = V(st.def)$btw, degree_tree = degree(st.def),
                  stringsAsFactors = FALSE)
write.csv(out[order(-out$betweenness), ],
          "data/kk-index-b-mst-headings-nodes.csv", row.names = FALSE)

cat("definitions tree communities:", nlevels(V(st.def)$comm), "\n")
cat("figure and node table written\n")
