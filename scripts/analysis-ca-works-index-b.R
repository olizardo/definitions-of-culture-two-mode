# CA for the K&K Index B works network on the largest connected component's
# 2-core of the bipartite incidence (sub-elements x works). Two views of the same
# decomposition:
#   works active (works labelled, sub-elements passive)    -> ca-lcc2core-*
#   concepts active (sub-elements labelled, works passive) -> ca-concepts-lcc2core-*
# Same decomposition as scripts/analysis-ca-index-b.R (CA via eigen, standard
# scores Z = unit-variance eigenvector x sqrt(lambda), duality check). Both views
# share their nonzero eigenvalues, so the scree plot is written once (works view).
# Input: data/kk-index-b-work-concept-network-full.rds (incidence = sub-elements x works).

library(igraph)
library(ggplot2)
library(ggrepel)

set.seed(8427)
invisible(lapply("figures/kk-index-b/works", dir.create, recursive = TRUE, showWarnings = FALSE))

source("scripts/label-authors-index-b.R")
source("scripts/core-index-b.R")
source("scripts/pub-type-style.R")

net <- readRDS("data/kk-index-b-work-concept-network-full.rds")
# Sub-elements x works, restricted to the largest component's 2-core
M <- lcc_2core(sub_work_matrix(net$two_mode_graph))
Ac <- t(M)
cat("2-core:", nrow(Ac), "works x", ncol(Ac), "sub-elements, edges:", sum(Ac), "\n")
n.comp2core <- components(graph_from_biadjacency_matrix(Ac, directed = FALSE))$no
cat("2-core components:", n.comp2core, "\n")
if (n.comp2core != 1)
  warning("2-core is not connected; ", n.comp2core, " trivial eigen-dims will be dropped")

# ------------------------------------------------------------------ CA
# X: rows = active set, columns = passive set. Returns standard scores for both.
fit.ca <- function(X) {
  D.p <- diag(1 / rowSums(X)); D.g <- diag(1 / colSums(X))
  P.pg <- D.p %*% X
  P.gp <- D.g %*% t(X)
  CA.p <- lapply(eigen(P.pg %*% P.gp), Re)
  CA.g <- lapply(eigen(P.gp %*% P.pg), Re)
  n.triv <- sum(zapsmall(CA.p$values) == 1)
  stopifnot(n.triv == sum(zapsmall(CA.g$values) == 1))

  n.keep.p <- length(CA.p$values) - n.triv
  n.keep.g <- length(CA.g$values) - n.triv
  uni.p <- CA.p$vectors[, (n.triv + 1):(n.triv + n.keep.p), drop = FALSE]
  val.p <- CA.p$values[(n.triv + 1):(n.triv + n.keep.p)]
  uni.g <- CA.g$vectors[, (n.triv + 1):(n.triv + n.keep.g), drop = FALSE]
  val.g <- CA.g$values[(n.triv + 1):(n.triv + n.keep.g)]

  ND <- min(5, n.keep.p, n.keep.g)
  Z.p <- uni.p[, 1:ND, drop = FALSE] %*% diag(sqrt(val.p[1:ND]))
  Z.g <- uni.g[, 1:ND, drop = FALSE] %*% diag(sqrt(val.g[1:ND]))
  rownames(Z.p) <- rownames(X); rownames(Z.g) <- colnames(X)
  colnames(Z.p) <- colnames(Z.g) <- paste0("dim", 1:ND)

  # sign alignment through the duality relation, then a deterministic flip
  for (k in 1:ND) {
    if (cor(as.numeric(P.pg %*% Z.g[, k]), Z.p[, k]) < 0) Z.g[, k] <- -Z.g[, k]
    j <- which.max(abs(Z.p[, k]))
    if (Z.p[j, k] < 0) { Z.p[, k] <- -Z.p[, k]; Z.g[, k] <- -Z.g[, k] }
  }
  stopifnot(all(sapply(1:ND, function(k)
    cor(as.numeric(P.pg %*% Z.g[, k]), Z.p[, k]) > 0.999)))
  cat("duality check passed (r > 0.999)\n")
  list(p = Z.p, g = Z.g, val = val.p, ND = ND)
}

# scree plot for the eigenvalues (identical for both views)
scree.plot <- function(val, file) {
  df.scree <- data.frame(dim = seq_along(val), lambda = val)
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
    labs(title = "CA scree plot, works network (Index B work nodes, LCC 2-core)",
         subtitle = "bars: nontrivial eigenvalues; line: cumulative share of inertia",
         x = "Dimension")
  ggsave(file, width = 8, height = 5, dpi = 150, bg = "white")
}

# map panels: active points labelled (top by |score| or mass), passive points grey
ca.maps <- function(fit, X, active.label, title, prefix, passive.word, active.word, pub = NULL) {
  df.act <- data.frame(fit$p, name = rownames(X), mass = rowSums(X) / sum(X),
                       label = active.label(rownames(X)))
  # publication type of the active nodes, when given: shape only, no other encoding
  if (!is.null(pub)) df.act$pubtype <- factor(pub[rownames(X)], levels = names(pub.shape.ca))
  shape.aes <- function(m) {
    if (!is.null(pub)) m[["shape"]] <- rlang::quo(pubtype)
    m
  }
  pub.scale <- if (is.null(pub)) NULL else
    scale_shape_manual(values = pub.shape.ca, name = "publication type", drop = FALSE)
  df.pas <- data.frame(fit$g, name = colnames(X))

  top_labels <- function(x, y, n = 20) {
    sx <- abs(df.act[[x]]); sy <- abs(df.act[[y]])
    lab <- rep(FALSE, nrow(df.act))
    lab[order(-sx)[seq_len(min(n, nrow(df.act)))]] <- TRUE
    lab[order(-sy)[seq_len(min(n, nrow(df.act)))]] <- TRUE
    lab[order(-df.act$mass)[seq_len(min(10, nrow(df.act)))]] <- TRUE
    df.act$label[lab]
  }

  panel <- function(x, y, xlab, ylab, subtitle, file) {
    df.lab <- df.act[df.act$label %in% top_labels(x, y), ]
    ggplot() +
      geom_hline(yintercept = 0, color = "grey80") +
      geom_vline(xintercept = 0, color = "grey80") +
      geom_point(data = df.pas, aes(.data[[x]], .data[[y]]),
                 size = 1.4, color = "grey75", alpha = 0.7) +
      geom_point(data = df.act, shape.aes(aes(.data[[x]], .data[[y]])),
                 size = 2.2, color = "grey35", alpha = 0.9) +
      geom_point(data = df.lab, shape.aes(aes(.data[[x]], .data[[y]])),
                 size = 3.2, color = "#1B9E77") +
      geom_label_repel(fill = "white", label.size = 0, color = "#0E5C47",
                       data = df.lab, aes(.data[[x]], .data[[y]], label = label),
                       size = 2.7, fontface = "bold", max.overlaps = Inf,
                       segment.color = "grey70", min.segment.length = 0, seed = 8427,
                       force = 1.5, force_pull = 0.2, point.padding = 0.4,
                       box.padding = 0.35, max.iter = 20000) +
      theme_minimal() +
      pub.scale +
      theme(legend.position = if (is.null(pub)) "none" else "bottom",
            plot.title = element_text(face = "bold", size = 11)) +
      labs(title = title, subtitle = subtitle, x = xlab, y = ylab)
    ggsave(file, width = 9, height = 7, dpi = 150, bg = "white")
  }

  sub <- function(v) paste0(v, "; ", passive.word, " (passive, grey)")
  panel("dim1", "dim2", "First Dimension", "Second Dimension",
        sub(paste0(active.word, " (active; labeled if top by |score| or mass)")),
        paste0(prefix, "-d12.png"))
  panel("dim2", "dim3", "Second Dimension", "Third Dimension",
        sub(paste0("dims 2 vs 3; ", active.word, " (active)")),
        paste0(prefix, "-d23.png"))
  panel("dim4", "dim5", "Fourth Dimension", "Fifth Dimension",
        sub(paste0("dims 4 vs 5; ", active.word, " (active)")),
        paste0(prefix, "-d45.png"))
  invisible(df.act)
}

# ------------------------------------------------- works view (works active)
pub.work <- setNames(net$works$pub_type, net$works$work)
fit.w <- fit.ca(Ac)
cat(sprintf("total inertia (nontrivial): %.3f; top %d dims share %.1f%%\n",
            sum(fit.w$val), fit.w$ND, 100 * sum(fit.w$val[1:fit.w$ND]) / sum(fit.w$val)))
scree.plot(fit.w$val, "figures/kk-index-b/works/ca-lcc2core-scree.png")
ca.maps(fit.w, Ac,
        active.label = function(k) vapply(k, label.authors, character(1)),
        title = "CA of the works network (Index B work nodes, LCC 2-core)",
        prefix = "figures/kk-index-b/works/ca-lcc2core",
        passive.word = "sub-elements", active.word = "works", pub = pub.work)

# ------------------------------------------------ concept view (concepts active)
fit.c <- fit.ca(t(Ac))
ca.maps(fit.c, t(Ac),
        active.label = identity,
        title = "CA of the works network (Index B concept nodes, LCC 2-core)",
        prefix = "figures/kk-index-b/works/ca-concepts-lcc2core",
        passive.word = "works", active.word = "sub-elements (concepts)")

# ------------------------------------------------------------------ scores
write.csv(cbind(work = rownames(Ac), mass = rowSums(Ac) / sum(Ac), fit.w$p),
          "data/kk-index-b-ca-works-lcc2core-works.csv", row.names = FALSE)
write.csv(cbind(element = colnames(Ac), degree = colSums(Ac), fit.w$g),
          "data/kk-index-b-ca-works-lcc2core-subelements.csv", row.names = FALSE)

cat("works CA figures and score CSVs written\n")
