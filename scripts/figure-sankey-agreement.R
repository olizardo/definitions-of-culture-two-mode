# Pairwise Sankeys of the three classifications of the works network, drawn
# with ggsankeyfier. Each of the 118 works of the works LCC 2-core is compared
# pairwise, one panel per pair of classifications: K&K group -> structural
# factor (analysis-nmf-works-index-b.R), K&K group -> works-as-texts factor
# (analysis-nmf-work-texts-index-b.R), structural factor -> works-as-texts
# factor. Ribbon width is works; every ribbon takes the color of its source
# node (in the group panels the works' dominant K&K group, grey for the tie
# node; in the factor panel the source structural factor), so no mixed-flow
# color rule is needed. The figure replaces the earlier three-way Sankey,
# whose middle leg had to borrow a group color that mixed flows do not have
# (2026-10-27).
#
# Reads the two works-level NMF load tables, so it runs after both
# analysis-nmf-works-index-b.R and analysis-nmf-work-texts-index-b.R.
#
# Output: figures/kk-index-b/nmf/nmf-agreement-sankey.png

library(ggplot2)
library(ggsankeyfier)
library(ggrepel)
library(gridExtra)

dir.create("figures/kk-index-b/nmf", recursive = TRUE, showWarnings = FALSE)

s <- read.csv("data/kk-index-b-nmf-works-loads.csv")        # structural
w <- read.csv("data/kk-index-b-nmf-work-texts-loads.csv")   # works-as-texts
m <- merge(s[, c("work", "dominant")], w[, c("work", "dominant", "group")],
           by = "work", suffixes = c(".f1", ".f2"))
m <- m[, c("work", "dominant.f1", "dominant.f2", "group")]
names(m) <- c("work", "dominant.f1", "dominant.f2", "group")
names(m) <- c("work", "f1", "f2", "grp")
m$grp[m$grp == "" | is.na(m$grp)] <- "tie"  # write.csv writes NA as "NA"

str.labels <- c("Way of life", "Transmitted ideas", "Society-individual behavior",
  "Norms and knowledge", "Complex whole", "Social organization",
  "Learning and acquisition")
txt.labels <- c("Goals and ways of living", "Passed down generations",
  "Material vs. non-material", "Symbolic systems", "Definitional formulas",
  "Mental and holistic", "Species and utensils")
grp.names <- c(A = "A Descriptive", B = "B Historical", C = "C Normative",
  D = "D Psychological", E = "E Structural", F = "F Genetic",
  G = "G Incomplete", tie = "no unique group")

# Okabe-Ito palette, grey for the tie node; the structural factors get the
# default ggplot hues, so factor colors do not read as group colors
grp.col <- c(A = "#E69F00", B = "#56B4E9", C = "#009E73", D = "#F0E442",
             E = "#0072B2", F = "#D55E00", G = "#CC79A7", tie = "grey80")
fac.col <- setNames(hcl(h = seq(15, 375, length = 8)[1:7], c = 100, l = 65),
                    as.character(1:7))

# transition tables, one per pair of classifications
tabs <- list(
  grp_f1 = table(grp = factor(m$grp, levels = names(grp.names)),
                 f1 = factor(m$f1, levels = 1:7)),
  grp_f2 = table(grp = factor(m$grp, levels = names(grp.names)),
                 f2 = factor(m$f2, levels = 1:7)),
  f1_f2  = table(f1 = factor(m$f1, levels = 1:7),
                 f2 = factor(m$f2, levels = 1:7)))

# ggsankeyfier requires one edge per node pair (its pivot merges identical
# pairs, and per-work duplicates break the position), so the long format (one
# row per connector, edge_id pairing the two ends of an edge) is built from
# the aggregated transition tables; ribbons take the color of their source node
make_long <- function(tab, from.stage, to.stage) {
  cells <- which(tab > 0, arr.ind = TRUE)
  do.call(rbind, lapply(seq_len(nrow(cells)), function(k) {
    i <- cells[k, 1]; j <- cells[k, 2]
    fn <- dimnames(tab)[[1]][i]; tn <- dimnames(tab)[[2]][j]
    data.frame(n = tab[i, j],
               edge_id = sprintf("%s:%s|%s:%s", from.stage, fn, to.stage, tn),
               connector = c("from", "to"),
               node = c(fn, tn),
               stage = c(from.stage, to.stage),
               src = fn)
  }))
}

long <- rbind(
  make_long(tabs$grp_f1, "grp", "f1"),
  make_long(tabs$grp_f2, "grp", "f2"),
  make_long(tabs$f1_f2,  "f1",  "f2"))
long$panel <- rep(c("grp_f1", "grp_f2", "f1_f2"),
                  c(sum(tabs$grp_f1 > 0), sum(tabs$grp_f2 > 0),
                    sum(tabs$f1_f2 > 0)) * 2)
long$stage <- factor(long$stage, levels = c("grp", "f1", "f2"))
# position_sankey stacks the first level at the bottom, so reverse the levels
# to get A and factor 1 at the top
long$node <- factor(long$node,
                    levels = c(rev(names(grp.names)), as.character(rev(1:7))))
stopifnot(all(vapply(tabs, sum, numeric(1)) == nrow(m)))

# label lookup keyed by stage and node, so no type coercion across stages
node.labs <- c(
  setNames(grp.names, paste0("grp.", names(grp.names))),
  setNames(str.labels, paste0("f1.", 1:7)),
  setNames(txt.labels, paste0("f2.", 1:7)))
lab.key <- paste(long$stage, long$node, sep = ".")
long$lab <- node.labs[lab.key]
stopifnot(!anyNA(long$lab))

panel.plot <- function(panel, x.labs, fill.values, fill.labels, fill.name,
                       legend = TRUE) {
  d <- long[long$panel == panel, ]
  pos  <- position_sankey(v_space = "auto", order = "as_is", align = "justify",
                          width = 0.05, split_nodes = FALSE)
  pos.l <- position_sankey(v_space = "auto", order = "as_is", align = "justify",
                           width = 0.05, split_nodes = FALSE, nudge_x = -0.04)
  pos.r <- position_sankey(v_space = "auto", order = "as_is", align = "justify",
                           width = 0.05, split_nodes = FALSE, nudge_x = 0.04)
  stages <- as.character(sort(unique(d$stage)))
  p <- ggplot(d, aes(x = stage, y = n, group = node,
                     connector = connector, edge_id = edge_id)) +
    geom_sankeyedge(aes(fill = src), alpha = 0.6,
                    color = "white", linewidth = 0.15, position = pos) +
    geom_sankeynode(fill = "grey25", color = "white", position = pos) +
    # ggrepel keeps multi-line node labels from colliding; segments off, the
    # nudge in the position object already sits the label beside its node
    geom_text_repel(aes(label = lab), stat = "sankeynode",
                    position = pos.l, hjust = 1, size = 2.3, lineheight = 0.85,
                    direction = "y", segment.colour = NA, min.segment.length = 0,
                    seed = 61, data = subset(d, stage == stages[1])) +
    geom_text_repel(aes(label = lab), stat = "sankeynode",
                    position = pos.r, hjust = 0, size = 2.3, lineheight = 0.85,
                    direction = "y", segment.colour = NA, min.segment.length = 0,
                    seed = 61, data = subset(d, stage == stages[2])) +
    scale_x_discrete(expand = expansion(add = c(0.5, 0.5)), labels = x.labs) +
    scale_fill_manual(values = fill.values, breaks = names(fill.values),
                      labels = fill.labels, name = fill.name) +
    labs(x = NULL, y = NULL) +
    theme_void() +
    theme(axis.text.x = element_text(size = 7.5, face = "bold"),
          legend.text = element_text(size = 6.5),
          legend.title = element_text(size = 7, face = "bold"),
          legend.position = if (legend) "bottom" else "none",
          legend.key.size = unit(0.28, "lines"))
  if (!legend) p <- p + guides(fill = "none")
  p
}

p.grp.str <- panel.plot("grp_f1",
  c(grp = "K&K group", f1 = "structural NMF\n(works x sub-elements)"),
  grp.col, grp.names, "K&K group", legend = TRUE)
p.grp.txt <- panel.plot("grp_f2",
  c(grp = "K&K group", f2 = "works-as-texts NMF\n(works x quotations)"),
  grp.col, grp.names, "K&K group", legend = FALSE)
p.str.txt <- panel.plot("f1_f2",
  c(f1 = "structural NMF\n(works x sub-elements)",
    f2 = "works-as-texts NMF\n(works x quotations)"),
  fac.col, str.labels, "structural factor", legend = TRUE)

ggsave("figures/kk-index-b/nmf/nmf-agreement-sankey.png",
       gridExtra::arrangeGrob(p.grp.str, p.grp.txt, p.str.txt, ncol = 1,
                              heights = c(1.15, 0.85, 1.15)),
       width = 9, height = 9, bg = "white")
