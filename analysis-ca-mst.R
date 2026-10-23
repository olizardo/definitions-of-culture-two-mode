# CA on the largest connected component + maximum spanning trees of the
# Breiger projections of the KKCC two-mode network.
# Follows: tm-ca.html (CA via eigen) and tm-duality.html (projections, MST).
# Input: data/kkcc_two_mode.rds (created by earlier transcription of ROBAFC-5.1.pdf, Table 2)

library(igraph)
library(ggplot2)
library(ggrepel)

set.seed(8427)

d <- readRDS("data/kkcc_two_mode.rds")
A <- d$biadjacency          # concepts (rows) x definitions (cols)
g <- d$graph
def_attrs <- d$def_attrs

dir.create("figures", showWarnings = FALSE)

# ---------------------------------------------------------------- largest component
cl <- components(g)
lcc <- induced_subgraph(g, which(cl$membership == which.max(cl$csize)))
lcc <- induced_subgraph(lcc, order(V(lcc)$type))   # concepts first, then definitions
Al <- as_biadjacency_matrix(lcc)
cat("LCC biadjacency:", nrow(Al), "x", ncol(Al), "edges:", sum(Al), "\n")

# ---------------------------------------------------------------- CA on the LCC
D.pl <- diag(1 / rowSums(Al))
D.gl <- diag(1 / colSums(Al))
P.pg <- D.pl %*% Al        # row-stochastic concept -> definition
P.gp <- D.gl %*% t(Al)     # row-stochastic definition -> concept
P.pp <- P.pg %*% P.gp
P.gg <- P.gp %*% P.pg

CA.p <- lapply(eigen(P.pp), Re)
CA.g <- lapply(eigen(P.gg), Re)
n.triv <- sum(zapsmall(CA.p$values) == 1)   # trivial eigen-dims (connected graph: 1)
stopifnot(n.triv == 1, n.triv == sum(zapsmall(CA.g$values) == 1))

uni.p <- CA.p$vectors[, -1]; val.p <- CA.p$values[-1]
uni.g <- CA.g$vectors[, -1]; val.g <- CA.g$values[-1]

# Z.v scores: unit-variance eigenvectors scaled by sqrt(eigenvalue)
Z.v.p <- uni.p[, 1:2, drop = FALSE] %*% diag(sqrt(val.p[1:2]))
Z.v.g <- uni.g[, 1:2, drop = FALSE] %*% diag(sqrt(val.g[1:2]))
rownames(Z.v.p) <- rownames(Al)
rownames(Z.v.g) <- colnames(Al)

# fix arbitrary sign orientation (SOCIAL positive on both dims)
if (Z.v.p["SOCIAL", 1] < 0) { Z.v.p[, 1] <- -Z.v.p[, 1]; Z.v.g[, 1] <- -Z.v.g[, 1] }
if (Z.v.p["SOCIAL", 2] < 0) { Z.v.p[, 2] <- -Z.v.p[, 2]; Z.v.g[, 2] <- -Z.v.g[, 2] }

# duality check: definition scores recover concept scores as degree-weighted means
stopifnot(cor(as.numeric(P.pg %*% Z.v.g[, 1]), Z.v.p[, 1]) > 0.999,
          cor(as.numeric(P.pg %*% Z.v.g[, 2]), Z.v.p[, 2]) > 0.999)
cat("duality check passed (r > 0.999)\n")

df.p <- data.frame(dim1 = Z.v.p[, 1], dim2 = Z.v.p[, 2],
                   concept = rownames(Al),
                   main_cat = V(lcc)$parent_category[V(lcc)$type == FALSE],
                   is_main  = V(lcc)$is_main[V(lcc)$type == FALSE])
df.g <- data.frame(dim1 = Z.v.g[, 1], dim2 = Z.v.g[, 2],
                   code = colnames(Al),
                   type = def_attrs$type[match(colnames(Al), def_attrs$code)],
                   degree = colSums(Al))

main_cats <- c("SOCIAL","BEHAVIOR","PATTERNS","HABITS","ACTING","HERITAGE",
               "BELIEFS","CUSTOMS","SYMBOL","SYSTEM","ATTITUDES","ADJUSTMENTS",
               "KNOWLEDGE","LANGUAGE","TRANSMISSION","INDUSTRIES")
main_pal <- setNames(c("#E41A1C","#377EB8","#4DAF4A","#984EA3","#FF7F00","#A65628",
                       "#F781BF","#999999","#66C2A5","#FC8D62","#8DA0CB","#E78AC3",
                       "#A6D854","#FFD92F","#B3B3B3","#1B9E77"), main_cats)
types <- sort(unique(def_attrs$type))
type_pal <- setNames(c("#1B9E77","#D95F02","#7570B3","#E7298A","#66A61E","#E6AB02","#666666"), types)


write.csv(cbind(concept = rownames(Z.v.p), Z.v.p), "data/kkcc-ca-concept-scores-lcc.csv",
          row.names = FALSE)
write.csv(cbind(code = rownames(Z.v.g), Z.v.g), "data/kkcc-ca-definition-scores-lcc.csv",
          row.names = FALSE)

# ---------------------------------------------------------------- CA on the 2-core
# iteratively drop degree-1 nodes from both modes until none remain
Ac <- Al
repeat {
  keep.r <- rowSums(Ac) >= 2
  keep.c <- colSums(Ac) >= 2
  if (all(keep.r) && all(keep.c)) break
  Ac <- Ac[keep.r, keep.c, drop = FALSE]
}
cat("2-core biadjacency:", nrow(Ac), "x", ncol(Ac), "edges:", sum(Ac),
    "(dropped", nrow(Al) - nrow(Ac), "concepts,", ncol(Al) - ncol(Ac), "definitions)\n")

D.pc <- diag(1 / rowSums(Ac)); D.gc <- diag(1 / colSums(Ac))
P.pg.c <- D.pc %*% Ac; P.gp.c <- D.gc %*% t(Ac)
CA.pc <- lapply(eigen(P.pg.c %*% P.gp.c), Re)
CA.gc <- lapply(eigen(P.gp.c %*% P.pg.c), Re)
stopifnot(sum(zapsmall(CA.pc$values) == 1) == 1,
          sum(zapsmall(CA.gc$values) == 1) == 1)

uni.pc <- CA.pc$vectors[, -1]; val.pc <- CA.pc$values[-1]
uni.gc <- CA.gc$vectors[, -1]; val.gc <- CA.gc$values[-1]
ND <- 3   # dimensions to compute
Z.v.pc <- uni.pc[, 1:ND, drop = FALSE] %*% diag(sqrt(val.pc[1:ND]))
Z.v.gc <- uni.gc[, 1:ND, drop = FALSE] %*% diag(sqrt(val.gc[1:ND]))
rownames(Z.v.pc) <- rownames(Ac); rownames(Z.v.gc) <- colnames(Ac)
colnames(Z.v.pc) <- colnames(Z.v.gc) <- paste0("dim", 1:ND)
# eigen() signs are arbitrary per decomposition; align definition scores to
# concept scores via the duality relation, then orient SOCIAL positively
for (k in 1:ND) {
  if (cor(as.numeric(P.pg.c %*% Z.v.gc[, k]), Z.v.pc[, k]) < 0) Z.v.gc[, k] <- -Z.v.gc[, k]
}
if (Z.v.pc["SOCIAL", 1] < 0) { Z.v.pc[, 1] <- -Z.v.pc[, 1]; Z.v.gc[, 1] <- -Z.v.gc[, 1] }
if (Z.v.pc["SOCIAL", 2] < 0) { Z.v.pc[, 2] <- -Z.v.pc[, 2]; Z.v.gc[, 2] <- -Z.v.gc[, 2] }
stopifnot(all(sapply(1:ND, function(k)
  cor(as.numeric(P.pg.c %*% Z.v.gc[, k]), Z.v.pc[, k]) > 0.999)))

df.pc <- data.frame(dim1 = Z.v.pc[, 1], dim2 = Z.v.pc[, 2], dim3 = Z.v.pc[, 3],
                    concept = rownames(Ac),
                    main_cat = V(lcc)$parent_category[match(rownames(Ac), V(lcc)$name)],
                    is_main  = V(lcc)$is_main[match(rownames(Ac), V(lcc)$name)])
df.gc <- data.frame(dim1 = Z.v.gc[, 1], dim2 = Z.v.gc[, 2], dim3 = Z.v.gc[, 3],
                    code = colnames(Ac),
                    type = def_attrs$type[match(colnames(Ac), def_attrs$code)],
                    degree = colSums(Ac))

ca.panel <- function(x, y, xlab, ylab, subtitle) {
  ggplot() +
    geom_hline(yintercept = 0, color = "grey80") +
    geom_vline(xintercept = 0, color = "grey80") +
    # hollow shapes with semi-transparency to reduce overplotting
    geom_point(data = df.gc, aes(.data[[x]], .data[[y]], color = type, shape = type),
               size = 2.4, alpha = 0.6, stroke = 0.9) +
    geom_point(data = df.pc, aes(.data[[x]], .data[[y]], color = main_cat), size = 2.6,
               alpha = 0.65, shape = 1, stroke = 1.1) +
    geom_point(data = subset(df.pc, is_main), aes(.data[[x]], .data[[y]], color = main_cat),
               size = 3.6, shape = 16, alpha = 0.9) +
    geom_text_repel(data = df.pc, aes(.data[[x]], .data[[y]], label = concept),
                    size = 2.7, max.overlaps = 30, segment.color = "grey70",
                    min.segment.length = 0, seed = 8427) +
    geom_text_repel(data = df.gc, aes(.data[[x]], .data[[y]], label = code),
                    size = 2.2, max.overlaps = 30, segment.color = "grey70",
                    min.segment.length = 0, seed = 8427) +
    scale_color_manual(values = c(main_pal, type_pal)) +
    scale_shape_manual(values = setNames(rep(2, length(types)), types), guide = "none") +
    theme_minimal() +
    theme(legend.position = "none", plot.title = element_text(face = "bold", size = 11)) +
    labs(title = "CA of the KKCC two-mode network, 2-core (single-degree nodes removed)",
         subtitle = subtitle, x = xlab, y = ylab)
}

ca.panel("dim1", "dim2", "First Dimension", "Second Dimension",
         "circles: concepts (by main category); triangles: definitions (by type)")
ggsave("figures/kkcc-ca-lcc-2core.png", width = 9, height = 7, dpi = 150)

ca.panel("dim2", "dim3", "Second Dimension", "Third Dimension",
         paste0("dimensions 2 vs 3; eigenvalues ",
                paste(round(val.pc[2:3], 3), collapse = ", ")))
ggsave("figures/kkcc-ca-lcc-2core-d23.png", width = 9, height = 7, dpi = 150)

write.csv(cbind(concept = rownames(Z.v.pc), Z.v.pc), "data/kkcc-ca-concept-scores-2core.csv",
          row.names = FALSE)
write.csv(cbind(code = rownames(Z.v.gc), Z.v.gc), "data/kkcc-ca-definition-scores-2core.csv",
          row.names = FALSE)

# ---------------------------------------------------------------- Breiger projections
P.concept <- A %*% t(A)     # shared definitions
P.def     <- t(A) %*% A     # shared concepts
diag(P.concept) <- 0; diag(P.def) <- 0

G.concept <- graph_from_adjacency_matrix(P.concept, mode = "undirected",
                                         weighted = TRUE, diag = FALSE)
G.def     <- graph_from_adjacency_matrix(P.def, mode = "undirected",
                                         weighted = TRUE, diag = FALSE)

# maximum spanning tree: Kruskal on decreasing weights (equivalent to
# mst() on 1/weights); avoids cycles, stops at N-1 edges
make.max.st <- function(gr) {
  el <- as_edgelist(gr, names = FALSE)   # numeric ids; st has the same vertex order
  w  <- E(gr)$weight
  idx <- order(w, decreasing = TRUE)
  st <- make_empty_graph(n = vcount(gr), directed = FALSE)
  for (i in idx) {
    cand <- add_edges(st, el[i, ])
    if (is_acyclic(cand)) st <- cand
    if (ecount(st) == vcount(gr) - 1) break
  }
  st
}

st.concept <- make.max.st(G.concept)
st.def     <- make.max.st(G.def)
cat("concept MST edges:", ecount(st.concept), "of", vcount(st.concept) - 1, "possible\n")
cat("definition MST edges:", ecount(st.def), "of", vcount(st.def) - 1, "possible\n")

# ---------------------------------------------------------------- MST visualizations
plot.mst <- function(st, vcol, vlabel = NA, title) {
  plot(st, layout = layout_as_tree(st), edge.width = 3,
       edge.color = "lightgray",
       vertex.size = 5, vertex.color = vcol, vertex.frame.color = "lightgray",
       vertex.label = vlabel, vertex.label.cex = 0.7, vertex.label.dist = 1,
       main = title)
}

# concept MST: colored by main category, main categories labeled
png("figures/kkcc-mst-concept-projection.png", width = 1400, height = 1000, res = 120)
par(mar = c(1, 1, 2, 1))
vc <- V(st.concept)$name
plot.mst(st.concept,
         vcol = main_pal[V(st.concept)$parent_category],
         vlabel = ifelse(V(st.concept)$is_main, vc, NA),
         title = "Maximum spanning tree, concept projection")
legend("bottomleft", legend = names(main_pal), pch = 19, col = main_pal,
       title = "main category", cex = 0.6, bty = "n", ncol = 2)
dev.off()

png("figures/kkcc-mst-definition-projection.png", width = 1600, height = 1100, res = 120)
par(mar = c(1, 1, 2, 1))
vd <- V(st.def)$name
deg.d <- colSums(A)[match(vd, colnames(A))]
plot.mst(st.def,
         vcol = type_pal[def_attrs$type[match(vd, def_attrs$code)]],
         vlabel = ifelse(deg.d >= 5, vd, NA),
         title = "Maximum spanning tree, definition projection")
legend("bottomleft", legend = names(type_pal), pch = 15, col = type_pal,
       title = "definition type", cex = 0.6, bty = "n")
dev.off()

cat("figures written to figures/\n")
