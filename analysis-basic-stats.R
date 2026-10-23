# Basic two-mode network statistics for the collapsed KKCC network:
# 16 main culture categories x 135 definitions (union of auxiliary notions).
# Companion script to kkcc-two-mode.qmd; follows tm-basic.html conventions.
# Inputs: data/kkcc_two_mode_main.rds (collapsed) and def_attrs from
# data/kkcc_two_mode.rds (definition type attributes from Table 1).

library(igraph)

d  <- readRDS("data/kkcc_two_mode_main.rds")
A  <- d$biadjacency    # main categories (rows) x definitions (columns)
g  <- d$graph
def_attrs <- readRDS("data/kkcc_two_mode.rds")$def_attrs

## ---- two-mode structure ------------------------------------------------------
n.concepts <- vcount(subgraph(g, V(g)$type == FALSE))
n.defs     <- vcount(subgraph(g, V(g)$type == TRUE))
c(concepts = n.concepts, definitions = n.defs)

sum(A)      # edge count = number of 1s in the biadjacency matrix
ecount(g)

dens <- sum(A) / (nrow(A) * ncol(A))
round(dens, 4)

## ---- degree distributions ----------------------------------------------------
deg.p <- rowSums(A)
deg.g <- colSums(A)
c(mean.deg.p = round(mean(deg.p), 2), mean.deg.g = round(mean(deg.g), 2),
  min.deg.p = min(deg.p),    min.deg.g = min(deg.g),
  max.deg.p = max(deg.p),    max.deg.g = max(deg.g))

c(rowSums = sum(deg.p), colSums = sum(deg.g), edges = sum(A))

tapply(deg.g, def_attrs$type[match(names(deg.g), def_attrs$code)],
       function(x) round(mean(x), 2))

## ---- degree centrality -------------------------------------------------------
round(deg.p / ncol(A), 3)
round(deg.g / nrow(A), 3)[1:10]

head(data.frame(concept = names(deg.p), degree = deg.p)[order(-deg.p), ], 10)
head(data.frame(code = names(deg.g), degree = deg.g,
                type = def_attrs$type[match(names(deg.g), def_attrs$code)])[order(-deg.g), ], 10)

## ---- average nearest-neighbor degree -----------------------------------------
knn.p <- rowSums(A * rep(colSums(A), each = nrow(A))) / rowSums(A)
knn.g <- as.numeric(t(A) %*% deg.p) / colSums(A)
round(mean(knn.p), 2)
round(mean(knn.g), 2)

## ---- degree correlation ------------------------------------------------------
tm.deg.corr <- function(A) {
  knn.p <- as.numeric(rowSums(A * rep(colSums(A), each = nrow(A))) / rowSums(A))
  knn.g <- as.numeric(t(A) %*% rowSums(A)) / colSums(A)
  list(r = cor(c(rowSums(A), colSums(A)), c(knn.p, knn.g)))
}
round(tm.deg.corr(A)$r, 4)

## ---- bipartite checks and modularity -----------------------------------------
is_bipartite(g)
is_directed(g)
all(bipartite_mapping(g)$type == V(g)$type)

V(g)$comm <- as.numeric(V(g)$type) + 1
round(modularity(g, V(g)$comm), 4)

## ---- component structure -----------------------------------------------------
comp <- components(g)
table(comp$csize)
