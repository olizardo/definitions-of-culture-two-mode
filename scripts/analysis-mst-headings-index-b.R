# Maximum spanning tree of the heading projection of the K&K Index B definitions
# network: headings x verified codes; ties = number of codes both headings hold.
# Uses the largest component's 2-core of the heading-by-code matrix
# (scripts/core-index-b.R). Kruskal maximum spanning tree (minimum spanning tree
# on -weight). Writes the node table only; the heading tree figure was removed
# at the user's request (2026-10-31, PROVENANCE 26) and is not used in the
# manuscript.

library(igraph)

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

out <- data.frame(network = "definitions", heading = V(st.def)$name,
                  community = as.integer(V(st.def)$comm),
                  betweenness = V(st.def)$btw, degree_tree = degree(st.def),
                  stringsAsFactors = FALSE)
write.csv(out[order(-out$betweenness), ],
          "data/kk-index-b-mst-headings-nodes.csv", row.names = FALSE)

cat("definitions tree communities:", nlevels(V(st.def)$comm), "\n")
cat("node table written\n")
