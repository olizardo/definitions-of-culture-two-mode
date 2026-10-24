# CA for the K&K Index B sub-element network, largest connected component
# 2-core. Follows scripts/analysis-ca-mst-main.R (tm-ca.html): CA via eigen,
# standard scores Z = unit-variance eigenvector x sqrt(lambda).
#
# The full sub-element network is disconnected by design (15 components and 5
# isolated codes), so the CA is computed on the largest component's 2-core,
# which is connected. Inputs: data/kk-index-b-subelement-network.rds.

library(igraph)
library(ggplot2)
library(ggrepel)

set.seed(8427)

dir.create("figures", showWarnings = FALSE)

se <- readRDS("data/kk-index-b-subelement-network.rds")
g <- se$graph
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
  labs(title = "CA scree plot, K&K Index B sub-element network (LCC 2-core)",
       subtitle = "bars: nontrivial eigenvalues; line: cumulative share of inertia",
       x = "Dimension")
ggsave("figures/kk-index-b-ca-subel-lcc2core-scree.png",
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
  ggplot() +
    geom_hline(yintercept = 0, color = "grey80") +
    geom_vline(xintercept = 0, color = "grey80") +
    geom_point(data = df.g, aes(.data[[x]], .data[[y]]),
               size = 1.4, color = "grey75", alpha = 0.7) +
    geom_point(data = df.bary, aes(.data[[x]], .data[[y]], color = group),
               shape = 18, size = 5) +
    geom_text_repel(data = df.bary, aes(.data[[x]], .data[[y]], label = group),
                    size = 3, fontface = "italic", max.overlaps = Inf,
                    segment.color = "grey70", min.segment.length = 0, seed = 8427,
                    force = 1, force_pull = 0.2, point.padding = 0.6,
                    box.padding = 0.45, max.iter = 20000) +
    geom_point(data = df.p, aes(.data[[x]], .data[[y]]),
               size = 2.6, shape = 16, color = "grey35", alpha = 0.9) +
    geom_point(data = df.lab, aes(.data[[x]], .data[[y]]),
               size = 3.4, shape = 16, color = "#1B9E77") +
    geom_text_repel(data = df.lab, aes(.data[[x]], .data[[y]], label = element),
                    size = 2.7, fontface = "bold", max.overlaps = Inf,
                    segment.color = "grey70", min.segment.length = 0, seed = 8427,
                    force = 1.5, force_pull = 0.2, point.padding = 0.4,
                    box.padding = 0.35, max.iter = 20000) +
    scale_color_manual(values = group_pal) +
    theme_minimal() +
    theme(legend.position = "none", plot.title = element_text(face = "bold", size = 11)) +
    labs(title = "CA of the K&K Index B sub-element network (LCC 2-core)",
         subtitle = subtitle, x = xlab, y = ylab)
  ggsave(file, width = 9, height = 7, dpi = 150, bg = "white")
}

ca.panel("dim1", "dim2", "First Dimension", "Second Dimension",
         "sub-elements (active; labeled if top by |score| or mass);
         K&K groups (passive barycenters, diamonds)",
         "figures/kk-index-b-ca-subel-lcc2core-d12.png")
ca.panel("dim2", "dim3", "Second Dimension", "Third Dimension",
         "dims 2 vs 3; sub-elements (active); K&K groups (passive barycenters)",
         "figures/kk-index-b-ca-subel-lcc2core-d23.png")

# ------------------------------------------------------------------ scores
write.csv(cbind(element = rownames(Z.v.p), mass = mass.p, Z.v.p),
          "data/kk-index-b-ca-subel-lcc2core-elements.csv", row.names = FALSE)
write.csv(cbind(code = rownames(Z.v.g), df.g[, c("group", "degree")], Z.v.g),
          "data/kk-index-b-ca-subel-lcc2core-codes.csv", row.names = FALSE)

cat("figures and score CSVs written\n")
