# Node table and community summary for the code tree of the definitions-by-topics
# network (figures/kk-index-b/lda/mst-code-author-year-tree-topic-network.png).
# Same tree as scripts/analysis-mst-topic-network-index-b.R: the drawn tree is the
# ensemble member closest to the mean betweenness, and communities use the same seed.
# Writes data/kk-index-b-topic-tree-nodes.csv and
# data/kk-index-b-topic-tree-communities.csv. Run from the project root in a fresh
# environment, with igraph attached first.

library(igraph)
source("scripts/core-index-b.R")
source("scripts/tree-ensemble-index-b.R")

M.MULT <- 1.5
TOL <- 1e-9

th <- read.csv("data/kk-index-b-lda-code-theta.csv", check.names = FALSE,
               stringsAsFactors = FALSE)
M <- as.matrix(th[, as.character(1:12)])
rownames(M) <- th$kk_code
B <- sweep(M, 1, rowMeans(M), function(x, r) x - M.MULT * r > TOL) * 1L
colnames(B) <- paste0("T", 1:12)
Ac <- lcc_2core(B)

P.def <- tcrossprod(Ac); diag(P.def) <- 0
G.def <- graph_from_adjacency_matrix(P.def, mode = "undirected", weighted = TRUE, diag = FALSE)
ens.def <- tree.ensemble(G.def)
st.def <- ens.def$tree
set.seed(8427)
com.tree <- cluster_leading_eigen(st.def)
V(st.def)$comm <- as.integer(membership(com.tree))
nodes <- V(st.def)$name

g <- readRDS("data/kk-index-b-verified-network.rds")$graph
va <- igraph::vertex_attr(g)
idx <- match(nodes, va$name)

btw <- ens.def$mean[nodes]
rank.top <- names(sort(btw, decreasing = TRUE))
th.idx <- match(nodes, th$kk_code)
w.len <- th$n_words[th.idx]
w.pct <- vapply(w.len, function(v) mean(th$n_words <= v, na.rm = TRUE), numeric(1))

# topic weights: largest and second largest
ord <- t(apply(M[nodes, ], 1, function(r) order(r, decreasing = TRUE)[1:2]))

# component sizes left when a node is removed from the drawn tree
removal <- vapply(nodes, function(v) {
  cs <- components(delete_vertices(st.def, v))$csize
  paste(sort(cs, decreasing = TRUE), collapse = " ")
}, character(1))

nb <- lapply(seq_along(nodes), function(i) V(st.def)$name[neighbors(st.def, i)])

nodes.out <- data.frame(
  kk_code = nodes,
  source_author = va$source_author[idx],
  source_year = va$source_year[idx],
  kk_group = substr(nodes, 1, 1),
  betweenness = btw,
  top10 = nodes %in% rank.top[1:10],
  betweenness_rank = match(nodes, rank.top),
  core_degree = rowSums(Ac)[nodes],
  tree_degree = degree(st.def),
  community = V(st.def)$comm,
  n_words = w.len,
  length_percentile = round(100 * w.pct, 1),
  dominant_topic = ord[, 1],
  dominant_weight = round(M[nodes, ][cbind(seq_along(nodes), ord[, 1])], 3),
  second_topic = ord[, 2],
  second_weight = round(M[nodes, ][cbind(seq_along(nodes), ord[, 2])], 3),
  tree_neighbors = vapply(nb, paste, character(1), collapse = " "),
  removal_components = removal,
  stringsAsFactors = FALSE
)
nodes.out <- nodes.out[order(nodes.out$betweenness_rank), ]
write.csv(nodes.out, "data/kk-index-b-topic-tree-nodes.csv", row.names = FALSE)

comm.out <- do.call(rbind, lapply(sort(unique(V(st.def)$comm)), function(c) {
  members <- nodes[V(st.def)$comm == c]
  data.frame(community = c, n_codes = length(members),
             groups = paste(names(table(substr(members, 1, 1))),
                            as.integer(table(substr(members, 1, 1))), sep = ":", collapse = " "),
             top10_members = paste(intersect(members, rank.top[1:10]), collapse = " "),
             stringsAsFactors = FALSE)
}))
comm.out <- comm.out[order(-comm.out$n_codes), ]
write.csv(comm.out, "data/kk-index-b-topic-tree-communities.csv", row.names = FALSE)

cat("drawn tree member", ens.def$best, "; communities", nrow(comm.out), "\n")
print(nodes.out[nodes.out$top10, c("kk_code", "source_author", "source_year", "betweenness",
                                   "core_degree", "tree_degree", "community", "n_words",
                                   "length_percentile", "dominant_topic", "removal_components")],
      row.names = FALSE)
print(comm.out, row.names = FALSE)
