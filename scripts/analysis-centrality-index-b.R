# Two-mode closeness and betweenness for the K&K Index B definitions network, on
# its largest connected component (LCC).
#
# Normalizations follow Borgatti & Everett (1997) as given at
# https://olizardo.github.io/SOCIOL208/cent-tm.html, with L = size of the larger
# node set and S = size of the smaller set (sub-elements are the larger set here;
# the code checks this):
#   closeness, node in set X:        n_Y + 2(n_X - 1)
#   betweenness, larger set:         2(S - 1)(L - 1)
#   betweenness, smaller set:        S(S - 1)/2 + (L - 1)(L - 2)/2 + (L - 1)(S - 1)
#
# Sub-elements x verified definition codes, taken from the full sub-element graph
# (which also contains unverified codes that can link components), with unverified
# codes removed after the LCC is found.

library(igraph)

g.def <- readRDS("data/kk-index-b-verified-network.rds")$graph
cs <- components(g.def)
g.def.lcc <- induced_subgraph(g.def, cs$membership == which.max(cs$csize))
cat("definitions network: components", cs$no, "| LCC", vcount(g.def.lcc),
    "nodes,", ecount(g.def.lcc), "edges\n")

# closeness and betweenness for a connected bipartite graph; `is.second` marks the
# second mode (definition codes), the first mode is sub-elements
tm.centrality <- function(gr, is.second) {
  n.first <- sum(!is.second); n.second <- sum(is.second)
  first.larger <- n.first >= n.second
  L <- max(n.first, n.second); S <- min(n.first, n.second)
  # node-set sizes and the other set's size, per node
  n.own <- ifelse(is.second, n.second, n.first)
  n.oth <- ifelse(is.second, n.first, n.second)
  is.larger <- ifelse(is.second, !first.larger, first.larger)

  norm.clo <- n.oth + 2 * (n.own - 1)
  D <- distances(gr)
  clo <- norm.clo / rowSums(D)

  norm.bet <- ifelse(is.larger,
                     2 * (S - 1) * (L - 1),
                     S * (S - 1) / 2 + (L - 1) * (L - 2) / 2 + (L - 1) * (S - 1))
  bet <- betweenness(gr, directed = FALSE) / norm.bet * 100

  data.frame(node = V(gr)$name, mode = ifelse(is.second, "second", "first"),
             degree = degree(gr), closeness = round(as.numeric(clo), 4),
             betweenness.pct = round(as.numeric(bet), 4),
             stringsAsFactors = FALSE)
}

# first mode is sub-elements (FALSE), second mode is definition codes (TRUE)
is.second.def <- V(g.def.lcc)$type
cen.def <- tm.centrality(g.def.lcc, is.second.def)

write.csv(cen.def[order(-cen.def$closeness), ],
          "data/kk-index-b-centrality-definitions.csv", row.names = FALSE)

cat("definitions: top 10 by closeness\n")
print(head(cen.def[order(-cen.def$closeness), ], 10), row.names = FALSE)
cat("centrality table written\n")
