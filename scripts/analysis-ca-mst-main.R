# CA and maximum spanning trees for the collapsed KKCC network
# (16 main categories x 135 definitions, union binarized).
# Follows tm-ca.html (CA via eigen) and tm-duality.html (Breiger projections, MST).
# Inputs: data/kkcc_two_mode_main.rds; def_attrs from data/kkcc_two_mode.rds.

library(igraph)
library(ggplot2)
library(ggrepel)

set.seed(8427)

d  <- readRDS("data/kkcc_two_mode_main.rds")
A  <- d$biadjacency
g  <- d$graph
def_attrs <- readRDS("data/kkcc_two_mode.rds")$def_attrs

dir.create("figures", showWarnings = FALSE)

main_cats <- c("SOCIAL","BEHAVIOR","PATTERNS","HABITS","ACTING","HERITAGE",
               "BELIEFS","CUSTOMS","SYMBOL","SYSTEM","ATTITUDES","ADJUSTMENTS",
               "KNOWLEDGE","LANGUAGE","TRANSMISSION","INDUSTRIES")
main_pal <- setNames(c("#E41A1C","#377EB8","#4DAF4A","#984EA3","#FF7F00","#A65628",
                       "#F781BF","#999999","#66C2A5","#FC8D62","#8DA0CB","#E78AC3",
                       "#A6D854","#FFD92F","#B3B3B3","#1B9E77"), main_cats)
types <- sort(unique(def_attrs$type))
type_pal <- setNames(c("#1B9E77","#D95F02","#7570B3","#E7298A","#66A61E","#E6AB02","#666666"), types)

# ---------------------------------------------------------------- CA (full network)
D.p <- diag(1 / rowSums(A)); D.g <- diag(1 / colSums(A))
P.pg <- D.p %*% A
P.gp <- D.g %*% t(A)
CA.p <- lapply(eigen(P.pg %*% P.gp), Re)
CA.g <- lapply(eigen(P.gp %*% P.pg), Re)
n.triv <- sum(zapsmall(CA.p$values) == 1)
cat("trivial eigen-dims:", n.triv, "\n")
stopifnot(n.triv == sum(zapsmall(CA.g$values) == 1))

uni.p <- CA.p$vectors[, -1]; val.p <- CA.p$values[-1]
uni.g <- CA.g$vectors[, -1]; val.g <- CA.g$values[-1]
ND <- 5
Z.v.p <- uni.p[, 1:ND, drop = FALSE] %*% diag(sqrt(val.p[1:ND]))
Z.v.g <- uni.g[, 1:ND, drop = FALSE] %*% diag(sqrt(val.g[1:ND]))
rownames(Z.v.p) <- rownames(A); rownames(Z.v.g) <- colnames(A)
colnames(Z.v.p) <- colnames(Z.v.g) <- paste0("dim", 1:ND)
for (k in 1:ND) {
  if (cor(as.numeric(P.pg %*% Z.v.g[, k]), Z.v.p[, k]) < 0) Z.v.g[, k] <- -Z.v.g[, k]
}
if (Z.v.p["SOCIAL", 1] < 0) { Z.v.p[, 1] <- -Z.v.p[, 1]; Z.v.g[, 1] <- -Z.v.g[, 1] }
if (Z.v.p["SOCIAL", 2] < 0) { Z.v.p[, 2] <- -Z.v.p[, 2]; Z.v.g[, 2] <- -Z.v.g[, 2] }
stopifnot(all(sapply(1:ND, function(k)
  cor(as.numeric(P.pg %*% Z.v.g[, k]), Z.v.p[, k]) > 0.999)))
cat("duality check passed (r > 0.999)\n")

# scree plot: nontrivial eigenvalues and cumulative share of inertia
df.scree <- data.frame(dim = seq_along(val.p), lambda = val.p)
df.scree$share <- df.scree$lambda / sum(df.scree$lambda)
df.scree$cum <- cumsum(df.scree$share)
n.show <- min(15, nrow(df.scree))
ggplot(df.scree[1:n.show, ], aes(x = dim)) +
  geom_col(aes(y = lambda), fill = "grey65") +
  geom_text(aes(y = lambda + 0.03, label = scales::percent(share, accuracy = 1)),
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
  labs(title = "CA scree plot, collapsed KKCC network",
       subtitle = "bars: nontrivial eigenvalues; line: cumulative share of inertia",
       x = "Dimension")
ggsave("figures/kkcc-ca-main-scree.png", width = 8, height = 5, dpi = 150, bg = "white")

df.p <- data.frame(Z.v.p, concept = rownames(A))
df.g <- data.frame(Z.v.g,
                   code = colnames(A),
                   type = def_attrs$type[match(colnames(A), def_attrs$code)],
                   degree = colSums(A))

# ---------------------------------------------------------------- CA (2-core)
Ac <- A
repeat {
  keep.r <- rowSums(Ac) >= 2
  keep.c <- colSums(Ac) >= 2
  if (all(keep.r) && all(keep.c)) break
  Ac <- Ac[keep.r, keep.c, drop = FALSE]
}
cat("2-core:", nrow(Ac), "x", ncol(Ac), "edges:", sum(Ac), "\n")

D.pc <- diag(1 / rowSums(Ac)); D.gc <- diag(1 / colSums(Ac))
P.pg.c <- D.pc %*% Ac; P.gp.c <- D.gc %*% t(Ac)
CA.pc <- lapply(eigen(P.pg.c %*% P.gp.c), Re)
CA.gc <- lapply(eigen(P.gp.c %*% P.pg.c), Re)
stopifnot(sum(zapsmall(CA.pc$values) == 1) == 1,
          sum(zapsmall(CA.gc$values) == 1) == 1)
uni.pc <- CA.pc$vectors[, -1]; val.pc <- CA.pc$values[-1]
uni.gc <- CA.gc$vectors[, -1]; val.gc <- CA.gc$values[-1]
Z.v.pc <- uni.pc[, 1:ND, drop = FALSE] %*% diag(sqrt(val.pc[1:ND]))
Z.v.gc <- uni.gc[, 1:ND, drop = FALSE] %*% diag(sqrt(val.gc[1:ND]))
rownames(Z.v.pc) <- rownames(Ac); rownames(Z.v.gc) <- colnames(Ac)
colnames(Z.v.pc) <- colnames(Z.v.gc) <- paste0("dim", 1:ND)
for (k in 1:ND) {
  if (cor(as.numeric(P.pg.c %*% Z.v.gc[, k]), Z.v.pc[, k]) < 0) Z.v.gc[, k] <- -Z.v.gc[, k]
}
if (Z.v.pc["SOCIAL", 1] < 0) { Z.v.pc[, 1] <- -Z.v.pc[, 1]; Z.v.gc[, 1] <- -Z.v.gc[, 1] }
if (Z.v.pc["SOCIAL", 2] < 0) { Z.v.pc[, 2] <- -Z.v.pc[, 2]; Z.v.gc[, 2] <- -Z.v.gc[, 2] }
stopifnot(all(sapply(1:ND, function(k)
  cor(as.numeric(P.pg.c %*% Z.v.gc[, k]), Z.v.pc[, k]) > 0.999)))

df.pc2 <- data.frame(Z.v.pc, concept = rownames(Ac))
df.gc2 <- data.frame(Z.v.gc, code = colnames(Ac),
                     type = def_attrs$type[match(colnames(Ac), def_attrs$code)])

# ---------------------------------------------------------------- CA plots
# categories emphasized (active); definitions as faint context dots;
# definition type as passive supplementary barycenters (diamonds)
mass.g <- colSums(A) / sum(A)   # CA column masses
type.bary <- do.call(rbind, lapply(types, function(tp) {
  j <- which(df.g$type == tp)
  sapply(paste0("dim", 1:ND), function(d) sum(mass.g[j] * df.g[[d]][j]) / sum(mass.g[j]))
}))
rownames(type.bary) <- types
# supplementary points are rescaled by a constant (purely visual): a radial
# stretch from the origin so the barycenters clear the dense concept cluster
BARY.SCALE <- 5
df.bary <- data.frame(type.bary * BARY.SCALE, type = types)

ca.panel.type <- function(x, y, xlab, ylab, subtitle, file) {
  ggplot() +
    geom_hline(yintercept = 0, color = "grey80") +
    geom_vline(xintercept = 0, color = "grey80") +
    geom_point(data = df.g, aes(.data[[x]], .data[[y]]),
               size = 1.4, color = "grey75", alpha = 0.7) +
    geom_point(data = df.bary, aes(.data[[x]], .data[[y]], color = type),
               shape = 18, size = 5) +
    geom_text_repel(data = df.bary, aes(.data[[x]], .data[[y]], label = type),
                    size = 3, fontface = "italic", max.overlaps = Inf,
                    segment.color = "grey70", min.segment.length = 0, seed = 8427,
                    force = 1, force_pull = 0.2, point.padding = 0.6,
                    box.padding = 0.45, max.iter = 20000) +
    geom_point(data = df.p, aes(.data[[x]], .data[[y]], color = concept),
               size = 4.6, shape = 16, alpha = 0.95) +
    geom_text_repel(data = df.p, aes(.data[[x]], .data[[y]], label = concept),
                    size = 3.2, fontface = "bold", max.overlaps = Inf,
                    segment.color = "grey70", min.segment.length = 0, seed = 8427,
                    force = 1.5, force_pull = 0.2, point.padding = 0.5,
                    box.padding = 0.4, max.iter = 20000) +
    scale_color_manual(values = c(main_pal, type_pal)) +
    theme_minimal() +
    theme(legend.position = "none", plot.title = element_text(face = "bold", size = 11)) +
    labs(title = "CA of the collapsed KKCC network",
         subtitle = subtitle, x = xlab, y = ylab)
  ggsave(file, width = 9, height = 7, dpi = 150, bg = "white")
}

ca.panel.type("dim1", "dim2", "First Dimension", "Second Dimension",
              "main categories (active, filled); definition types (passive barycenters, diamonds)",
              "figures/kkcc-ca-main.png")
ca.panel.type("dim2", "dim3", "Second Dimension", "Third Dimension",
              "dims 2 vs 3; main categories (active, filled); definition types (passive barycenters, diamonds)",
              "figures/kkcc-ca-main-d23.png")
ca.panel.type("dim4", "dim5", "Fourth Dimension", "Fifth Dimension",
              "dims 4 vs 5; main categories (active, filled); definition types (passive barycenters, diamonds)",
              "figures/kkcc-ca-main-d45.png")

write.csv(cbind(concept = rownames(Z.v.p), Z.v.p), "data/kkcc-ca-concept-scores-main.csv",
          row.names = FALSE)
write.csv(cbind(code = rownames(Z.v.g), Z.v.g), "data/kkcc-ca-definition-scores-main.csv",
          row.names = FALSE)
write.csv(cbind(concept = rownames(Z.v.pc), Z.v.pc), "data/kkcc-ca-concept-scores-main-2core.csv",
          row.names = FALSE)
write.csv(cbind(code = rownames(Z.v.gc), Z.v.gc), "data/kkcc-ca-definition-scores-main-2core.csv",
          row.names = FALSE)

# ---------------------------------------------------------------- Breiger projections
P.concept <- A %*% t(A); diag(P.concept) <- 0   # shared definitions
P.def     <- t(A) %*% A;  diag(P.def) <- 0      # shared categories

G.concept <- graph_from_adjacency_matrix(P.concept, mode = "undirected",
                                         weighted = TRUE, diag = FALSE)
G.def     <- graph_from_adjacency_matrix(P.def, mode = "undirected",
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
st.def     <- make.max.st(G.def)
cat("concept MST edges:", ecount(st.concept), "of", vcount(st.concept) - 1, "possible\n")
cat("definition MST edges:", ecount(st.def), "of", vcount(st.def) - 1, "possible\n")

library(ggraph)

# concept projection: nodes filled by main category, all nodes labeled
lo.c <- as.data.frame(layout_as_tree(st.concept)); names(lo.c) <- c("x", "y")
lo.c$x <- lo.c$x * 1.4
ggraph(st.concept, layout = lo.c) +
  geom_edge_link(color = "grey80", linewidth = 0.5) +
  geom_node_point(aes(fill = name), shape = 21, size = 9,
                  color = "grey30", stroke = 0.8) +
  geom_node_text(aes(label = name), repel = TRUE, size = 3.4,
                 fontface = "bold", max.overlaps = 30, seed = 8427,
                 nudge_y = -0.15, point.padding = 0.2,
                 force = 0.3, max.iter = 20000, segment.color = NA) +
  scale_fill_manual(values = main_pal, guide = "none") +
  scale_y_continuous(expand = expansion(mult = c(0.06, 0.08))) +
  theme_void() +
  theme(plot.title = element_text(face = "bold", size = 13)) +
  labs(title = "Maximum spanning tree, concept projection (shared definitions)")
ggsave("figures/kkcc-mst-main-concept.png", width = 11, height = 7.5, dpi = 150, bg = "white")

# definition projection: nodes filled by definition type, all nodes labeled,
# size proportional to degree
V(st.def)$type <- def_attrs$type[match(V(st.def)$name, def_attrs$code)]
V(st.def)$degree <- degree(st.def)
lo.d <- as.data.frame(layout_as_tree(st.def)); names(lo.d) <- c("x", "y")
lo.d$x <- lo.d$x * 2
ggraph(st.def, layout = lo.d) +
  geom_edge_link(color = "grey80", linewidth = 0.4) +
  geom_node_point(aes(fill = type, size = degree),
                  shape = 21, color = "grey30", stroke = 0.6, alpha = 0.9) +
  geom_node_text(aes(label = name), repel = TRUE, size = 2.2,
                 max.overlaps = 40, seed = 8427) +
  scale_fill_manual(values = type_pal) +
  scale_size_continuous(range = c(2, 6)) +
  theme_void() +
  theme(plot.title = element_text(face = "bold", size = 13),
        legend.position = "bottom",
        legend.title = element_text(size = 9),
        legend.text = element_text(size = 8)) +
  guides(fill = guide_legend(nrow = 1, override.aes = list(size = 3))) +
  labs(title = "Maximum spanning tree, definition projection (shared categories)",
       fill = "definition type", size = "degree")
ggsave("figures/kkcc-mst-main-definition.png", width = 13, height = 8, dpi = 150, bg = "white")

cat("figures written to figures/\n")
