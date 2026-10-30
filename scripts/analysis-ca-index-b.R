# CA for the K&K Index B sub-element network, largest connected component
# 2-core. Follows scripts/analysis-ca-mst-main.R (tm-ca.html): CA via eigen,
# standard scores Z = unit-variance eigenvector x sqrt(lambda).
#
# The full sub-element network is disconnected by design (15 components and 5
# isolated codes), so the CA is computed on the largest component's 2-core,
# which is connected. Input: data/kk-index-b-verified-network.rds (built by
# scripts/build-index-b-verified.R; codes not in Index A are excluded).

library(igraph)
library(ggplot2)
library(ggrepel)
library(ggstar)

source("scripts/kk-group-style.R")

set.seed(8427)
invisible(lapply(c("figures/boroch", "figures/kk-index-b/definitions"), dir.create, recursive = TRUE, showWarnings = FALSE))

dir.create("figures", showWarnings = FALSE)

g <- readRDS("data/kk-index-b-verified-network.rds")$graph
code_group <- setNames(V(g)$kk_group, V(g)$name)

# ------------------------------------------------- largest component 2-core
comp <- components(g)
lcc_id <- which.max(comp$csize)
gl <- induced_subgraph(g, comp$membership == lcc_id)
el <- as_edgelist(gl, names = TRUE)
Al <- matrix(0, nrow = length(unique(el[, 1])), ncol = length(unique(el[, 2])),
             dimnames = list(sort(unique(el[, 1])), sort(unique(el[, 2]))))
Al[cbind(el[, 1], el[, 2])] <- 1
cat("LCC:", nrow(Al), "x", ncol(Al), "edges:", sum(Al), "\n")

Ac <- Al
repeat {
  keep.r <- rowSums(Ac) >= 2
  keep.c <- colSums(Ac) >= 2
  if (all(keep.r) && all(keep.c)) break
  Ac <- Ac[keep.r, keep.c, drop = FALSE]
}
cat("2-core:", nrow(Ac), "x", ncol(Ac), "edges:", sum(Ac), "\n")
gc <- graph_from_biadjacency_matrix(Ac, dir = FALSE, multiple = FALSE)
n.comp2core <- components(gc)$no
cat("2-core components:", n.comp2core, "\n")
if (n.comp2core != 1)
  warning("2-core is not connected; ", n.comp2core,
          " trivial eigen-dims will be dropped")

# ------------------------------------------------------------------ CA
D.p <- diag(1 / rowSums(Ac)); D.g <- diag(1 / colSums(Ac))
P.pg <- D.p %*% Ac
P.gp <- D.g %*% t(Ac)
CA.p <- lapply(eigen(P.pg %*% P.gp), Re)
CA.g <- lapply(eigen(P.gp %*% P.pg), Re)
n.triv <- sum(zapsmall(CA.p$values) == 1)
if (n.triv != 1)
  cat("WARNING: 2-core still has", n.triv, "trivial eigen-dims\n")
stopifnot(n.triv == sum(zapsmall(CA.g$values) == 1))

n.keep.p <- length(CA.p$values) - n.triv
n.keep.g <- length(CA.g$values) - n.triv
uni.p <- CA.p$vectors[, (n.triv + 1):(n.triv + n.keep.p), drop = FALSE]
val.p <- CA.p$values[(n.triv + 1):(n.triv + n.keep.p)]
uni.g <- CA.g$vectors[, (n.triv + 1):(n.triv + n.keep.g), drop = FALSE]
val.g <- CA.g$values[(n.triv + 1):(n.triv + n.keep.g)]

ND <- min(5, n.keep.p, n.keep.g)
Z.v.p <- uni.p[, 1:ND, drop = FALSE] %*% diag(sqrt(val.p[1:ND]))
Z.v.g <- uni.g[, 1:ND, drop = FALSE] %*% diag(sqrt(val.g[1:ND]))
rownames(Z.v.p) <- rownames(Ac); rownames(Z.v.g) <- colnames(Ac)
colnames(Z.v.p) <- colnames(Z.v.g) <- paste0("dim", 1:ND)

# sign alignment through the duality relation, then a deterministic flip:
# on each dimension the element with the largest |score| is positive.
for (k in 1:ND) {
  if (cor(as.numeric(P.pg %*% Z.v.g[, k]), Z.v.p[, k]) < 0) Z.v.g[, k] <- -Z.v.g[, k]
  j <- which.max(abs(Z.v.p[, k]))
  if (Z.v.p[j, k] < 0) { Z.v.p[, k] <- -Z.v.p[, k]; Z.v.g[, k] <- -Z.v.g[, k] }
}
stopifnot(all(sapply(1:ND, function(k)
  cor(as.numeric(P.pg %*% Z.v.g[, k]), Z.v.p[, k]) > 0.999)))
cat("duality check passed (r > 0.999)\n")

inertia <- sum(val.p[1:n.keep.g])
cat(sprintf("total inertia (nontrivial): %.3f; top %d dims share %.1f%%\n",
            inertia, ND, 100 * sum(val.p[1:ND]) / inertia))

# scree plot
df.scree <- data.frame(dim = seq_along(val.p), lambda = val.p)
df.scree$share <- df.scree$lambda / sum(df.scree$lambda)
df.scree$cum <- cumsum(df.scree$share)
n.show <- min(15, nrow(df.scree))
ggplot(df.scree[1:n.show, ], aes(x = dim)) +
  geom_col(aes(y = lambda), fill = "grey65") +
  geom_text(aes(y = lambda + 0.02, label = scales::percent(share, accuracy = 1)),
            vjust = 0, size = 2.7, color = "grey20") +
  geom_point(aes(y = cum * max(df.scree$lambda[1:n.show])), shape = 17, size = 2) +
  geom_line(aes(y = cum * max(df.scree$lambda[1:n.show])), color = "grey30") +
  scale_x_continuous(breaks = 1:n.show) +
  scale_y_continuous(
    expand = expansion(mult = c(0.01, 0.09)),
    name = "eigenvalue",
    sec.axis = sec_axis(~ . / max(df.scree$lambda[1:n.show]),
                        name = "cumulative share of inertia",
                        labels = scales::percent_format(accuracy = 1))) +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold", size = 11)) +
  labs(title = "CA scree plot, definitions network (Index B sub-element nodes, LCC 2-core)",
       subtitle = "bars: nontrivial eigenvalues; line: cumulative share of inertia",
       x = "Dimension")
ggsave("figures/kk-index-b/definitions/ca-lcc2core-scree.png",
       width = 8, height = 5, dpi = 150, bg = "white")

# data frames for plotting
mass.p <- rowSums(Ac) / sum(Ac)
df.p <- data.frame(Z.v.p, element = rownames(Ac), mass = mass.p)
df.g <- data.frame(Z.v.g, code = colnames(Ac),
                   group = code_group[colnames(Ac)],
                   degree = colSums(Ac))
df.g$group[is.na(df.g$group)] <- "?"

# passive barycenters of the K&K groups (A-G) on the code side
groups <- sort(unique(df.g$group))
group.bary <- do.call(rbind, lapply(groups, function(gp) {
  j <- which(df.g$group == gp)
  sapply(paste0("dim", 1:ND), function(d) sum(df.g$degree[j] * df.g[[d]][j]) / sum(df.g$degree[j]))
}))
rownames(group.bary) <- groups
BARY.SCALE <- 5  # purely visual: stretch the passive barycenters out of the cloud
df.bary <- data.frame(group.bary * BARY.SCALE, group = groups)
group_pal <- setNames(c("#E41A1C", "#377EB8", "#4DAF4A", "#984EA3",
                        "#FF7F00", "#A65628", "#F781BF", "#999999"),
                      sort(unique(groups)))

# label the elements that matter on each panel: top by |score| on either
# shown dimension, or top by mass
top_labels <- function(x, y, n = 25) {
  sx <- abs(df.p[[x]]); sy <- abs(df.p[[y]])
  lab <- rep(FALSE, nrow(df.p))
  lab[order(-sx)[seq_len(min(n, nrow(df.p)))]] <- TRUE
  lab[order(-sy)[seq_len(min(n, nrow(df.p)))]] <- TRUE
  lab[order(-df.p$mass)[seq_len(min(10, nrow(df.p)))]] <- TRUE
  df.p$element[lab]
}

ca.panel <- function(x, y, xlab, ylab, subtitle, file) {
  lab <- top_labels(x, y)
  df.lab <- df.p[df.p$element %in% lab, ]
  # one label layer for elements and group centroids, so ggrepel keeps them apart
  lab.all <- rbind(
    data.frame(px = df.lab[[x]], py = df.lab[[y]], text = df.lab$element),
    data.frame(px = df.bary[[x]], py = df.bary[[y]],
               text = paste0(df.bary$group, ": ", kk.group.names[df.bary$group])))
  ggplot() +
    geom_hline(yintercept = 0, color = "grey80") +
    geom_vline(xintercept = 0, color = "grey80") +
    geom_point(data = df.g, aes(.data[[x]], .data[[y]]),
               size = 1.4, color = "grey75", alpha = 0.7) +
    geom_star(data = df.bary, aes(.data[[x]], .data[[y]], starshape = group, fill = group),
              color = "grey25", size = 5) +
    geom_point(data = df.p, aes(.data[[x]], .data[[y]]),
               size = 2.6, shape = 16, color = "grey35", alpha = 0.9) +
    geom_point(data = df.lab, aes(.data[[x]], .data[[y]]),
               size = 3.4, shape = 16, color = "#1B9E77") +
    geom_label_repel(fill = "white", label.size = 0, color = "#0E5C47", data = lab.all, aes(px, py, label = text),
                    size = 2.7, fontface = "bold", max.overlaps = Inf,
                    segment.color = "grey70", min.segment.length = 0, seed = 8427,
                    force = 1.5, force_pull = 0.2, point.padding = 0.4,
                    box.padding = 0.35, max.iter = 20000) +
    scale_fill_manual(values = group_pal) +
    scale_starshape_manual(values = kk.group.star[groups], guide = "none") +
    theme_minimal() +
    theme(legend.position = "none", plot.title = element_text(face = "bold", size = 11)) +
    labs(title = "CA of the definitions network (Index B sub-element nodes, LCC 2-core)",
         subtitle = subtitle, x = xlab, y = ylab)
  ggsave(file, width = 9, height = 7, dpi = 150, bg = "white")
}

ca.panel("dim1", "dim2", "First Dimension", "Second Dimension",
         "sub-elements (active; labeled if top by |score| or mass);
         K&K groups (passive barycenters, shape = group)",
         "figures/kk-index-b/definitions/ca-lcc2core-d12.png")
ca.panel("dim2", "dim3", "Second Dimension", "Third Dimension",
         "dims 2 vs 3; sub-elements (active); K&K groups (passive barycenters)",
         "figures/kk-index-b/definitions/ca-lcc2core-d23.png")
ca.panel("dim4", "dim5", "Fourth Dimension", "Fifth Dimension",
         "dims 4 vs 5; sub-elements (active); K&K groups (passive barycenters)",
         "figures/kk-index-b/definitions/ca-lcc2core-d45.png")

# ------------------------------------------------------------------ scores
write.csv(cbind(element = rownames(Z.v.p), mass = mass.p, Z.v.p),
          "data/kk-index-b-ca-subel-lcc2core-elements.csv", row.names = FALSE)
write.csv(cbind(code = rownames(Z.v.g), df.g[, c("group", "degree")], Z.v.g),
          "data/kk-index-b-ca-subel-lcc2core-codes.csv", row.names = FALSE)

# ------------------------------------------------------------------ concept MST
# Maximum spanning tree of the concept (sub-element) projection on the same
# LCC 2-core: ties = shared definition codes; Kruskal max-weight tree.
library(ggraph)

P.concept <- Ac %*% t(Ac); diag(P.concept) <- 0
G.concept <- graph_from_adjacency_matrix(P.concept, mode = "undirected",
                                         weighted = TRUE, diag = FALSE)
make.max.st <- function(gr) {
  el <- as_edgelist(gr, names = FALSE)
  idx <- order(E(gr)$weight, decreasing = TRUE)
  st <- make_empty_graph(n = vcount(gr), directed = FALSE)
  V(st)$name <- V(gr)$name
  for (i in idx) {
    cand <- add_edges(st, el[i, ])
    if (is_acyclic(cand)) st <- cand
    if (ecount(st) == vcount(gr) - 1) break
  }
  st
}
st.concept <- make.max.st(G.concept)
cat("concept MST edges:", ecount(st.concept), "of", vcount(st.concept) - 1, "possible\n")

# node attributes: printed Index B heading block, projection community,
# tree betweenness and a sqrt-scaled node size (sqrt keeps hubs from dominating)
sub_idx <- which(V(g)$node_type == "sub_element")
head_map <- setNames(sub(";.*$", "", V(g)$headings[sub_idx]), V(g)$name[sub_idx])
h <- head_map[V(st.concept)$name]; h[is.na(h)] <- "?"
V(st.concept)$heading <- h

com.proj <- cluster_leading_eigen(G.concept, weights = E(G.concept)$weight)
V(st.concept)$comm <- factor(membership(com.proj)[V(st.concept)$name])
com.tree <- cluster_leading_eigen(st.concept)
V(st.concept)$commtree <- factor(membership(com.tree))

btw <- betweenness(st.concept, directed = FALSE, normalized = FALSE)
V(st.concept)$btw <- btw
V(st.concept)$size <- 2.5 + 5 * sqrt(btw / max(btw))

# palettes
hs <- sort(unique(h)); n.h <- length(hs)
heading_pal <- setNames(hcl(h = rep(c(15, 75, 135, 195, 255, 315, 45, 105, 165, 225, 285, 345),
                                    length.out = n.h),
                            c = 60, l = rep(c(62, 78), length.out = n.h)), hs)
n.tree <- nlevels(V(st.concept)$commtree)
pal.tree <- setNames(hcl(h = seq(15, 375, length.out = n.tree + 1)[-(n.tree + 1)],
                         c = 65, l = 65),
                     levels(V(st.concept)$commtree))

mst.plot <- function(fill_vals, fill_scale, subtitle, file, size_by_btw = FALSE,
                     legend = "none") {
  V(st.concept)$fillv <- fill_vals
  node_layer <- if (size_by_btw) {
    geom_node_point(aes(fill = fillv, size = size), shape = 21,
                    color = "grey25", stroke = 0.5)
  } else {
    geom_node_point(aes(fill = fillv), shape = 21, size = 4.5,
                    color = "grey25", stroke = 0.5)
  }
  p <- ggraph(st.concept, layout = "kk") +
    geom_edge_link(color = "grey80", linewidth = 0.4) +
    node_layer +
    geom_node_text(aes(label = name), repel = TRUE, size = 2.5,
                   fontface = "bold", max.overlaps = Inf, seed = 8427,
                   segment.color = NA, force = 0.5, max.iter = 20000) +
    fill_scale +
    scale_size_identity() +
    theme_void() +
    theme(plot.title = element_text(face = "bold", size = 13),
          legend.position = if (legend == "none") "none" else "bottom",
          legend.title = element_text(size = 8),
          legend.text = element_text(size = 5.5),
          legend.key.size = unit(0.22, "cm")) +
    labs(title = "Maximum spanning tree, definitions network (sub-element nodes), K&K Index B LCC 2-core",
         subtitle = subtitle)
  if (legend == "heading")
    p <- p + guides(fill = guide_legend(title = "Index B heading", ncol = 9, byrow = TRUE))
  ggsave(file, p, width = 15, height = 9, dpi = 150, bg = "white")
}

mst.plot(V(st.concept)$commtree, scale_fill_manual(values = pal.tree),
         "color = leading-eigenvector community computed on the tree itself; size = tree betweenness (sqrt-scaled)",
         "figures/kk-index-b/definitions/mst-subelement-comm-tree.png", size_by_btw = TRUE)

cat("figures and score CSVs written\n")
