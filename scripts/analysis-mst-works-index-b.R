# Maximum spanning trees from the work-level network (see
# scripts/build-work-concept-network-index-b.R):
#   (1) concept tree: sub-elements, ties = number of distinct works citing both;
#   (2) work tree: works, ties = number of distinct sub-elements both cite.
# Both are Kruskal maximum spanning trees (minimum spanning tree on -weight).
# Node size = betweenness in the tree; color = leading-eigenvector community on
# the tree.

library(igraph)
library(ggraph)

set.seed(8427)
invisible(lapply(c("figures/boroch", "figures/kk-index-b/definitions", "figures/kk-index-b/works"), dir.create, recursive = TRUE, showWarnings = FALSE))

source("scripts/core-index-b.R")

net <- readRDS("data/kk-index-b-work-concept-network-full.rds")
# Sub-elements x works, restricted to the largest component's 2-core
M <- lcc_2core(sub_work_matrix(net$two_mode_graph))
works.tab <- net$works

# work projection: shared sub-elements between two works
Q <- crossprod(M); diag(Q) <- 0
G.work <- graph_from_adjacency_matrix(Q, mode = "undirected", weighted = TRUE, diag = FALSE)
# Concept projection of the 2-core: ties count only the works that were kept
P.c <- M %*% t(M); diag(P.c) <- 0
G.concept <- graph_from_adjacency_matrix(P.c, mode = "undirected", weighted = TRUE, diag = FALSE)

tree.of <- function(gr) {
  st <- mst(gr, weights = -E(gr)$weight)
  cat("  vertices:", vcount(gr), "| graph components:", components(gr)$no,
      "| tree edges:", ecount(st), "of", vcount(gr) - 1, "\n")
  if (!is_connected(st)) stop("tree is not connected")
  V(st)$btw <- betweenness(st, directed = FALSE, normalized = FALSE)
  V(st)$comm <- factor(membership(cluster_leading_eigen(st)))
  st
}

cat("concept network\n"); st.concept <- tree.of(G.concept)
cat("work network\n");    st.work <- tree.of(G.work)

# element names are unique across sub-elements in this LCC (checked earlier);
# work labels are the work keys with initials from the page checks
source("scripts/label-authors-index-b.R")
V(st.work)$label <- vapply(V(st.work)$name, label.authors, character(1))
V(st.concept)$label <- V(st.concept)$name
unlabelled <- V(st.work)$label[!grepl("[A-Z][.]", V(st.work)$label)]
cat("works with an author lacking initials:", length(unlabelled), "\n")
V(st.concept)$label <- V(st.concept)$name

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

tree.plot(st.concept,
          "Maximum spanning tree, works network (sub-element nodes), K&K Index B LCC 2-core",
          "ties = number of distinct works citing both sub-elements; node size = betweenness in the tree; color = leading-eigenvector community on the tree",
          "figures/kk-index-b/works/mst-subelement.png")
tree.plot(st.work,
          "Maximum spanning tree, works network (work nodes), K&K Index B LCC 2-core",
          "ties = number of sub-elements both works cite; node size = betweenness in the tree; color = leading-eigenvector community on the tree",
          "figures/kk-index-b/works/mst-work.png")

tab <- function(st, type) {
  data.frame(type = type, node = V(st)$name, community = as.integer(V(st)$comm),
             betweenness = V(st)$btw, degree_tree = degree(st), stringsAsFactors = FALSE)
}
out <- rbind(tab(st.concept, "concept"), tab(st.work, "work"))
write.csv(out[order(out$type, -out$betweenness), ],
          "data/kk-index-b-mst-works-nodes.csv", row.names = FALSE)

cat("concept tree communities:", nlevels(V(st.concept)$comm),
    "| work tree communities:", nlevels(V(st.work)$comm), "\n")
cat("figures and node table written\n")
