# Supplementary Sankeys of the two NMF classifications against K&K's
# disaggregated typology (groups with their roman-numeral subgroups), drawn
# with ggsankeyfier. The manuscript body compares the classifications against
# the seven group letters A-G; here the left side is the subgroup level:
# A, B, C-I, C-II, D-I..D-IV, E, F-I..F-IV, G. A bare C or D code would be a
# Part III statement code, outside the Part II typology; the verified codes
# have none (PROVENANCE 16), so the Part III node stays empty.
#
# Panel 1 (works): the 118 works of the works LCC 2-core, each work's
#   plurality subgroup against its dominant structural NMF factor
#   (analysis-nmf-works-index-b.R). A work whose codes tie across subgroups
#   goes to the grey node.
# Panel 2 (codes): the 167 verified definition codes carrying a text, each code's own
#   subgroup against its dominant text NMF factor
#   (analysis-nmf-texts-index-b.R). The 168 codes are the 167 verified codes
#   plus C-I-Addendum, which the texts analysis includes (PROVENANCE 16).
#   No tie node: a code sits in one subgroup.
#
# Ribbons take the color of their source node; subgroup nodes are colored by
# their group letter (the Okabe-Ito palette of figure-sankey-agreement.R), the
# factor nodes the default ggplot hues, so factor colors do not read as group
# colors.
#
# Reads data/kk-index-b-nmf-works-loads.csv and
# data/kk-index-b-nmf-texts-loads.csv (both carry factor_label), plus the
# works table of the full works file for the works' codes.
#
# Outputs:
#   figures/kk-index-b/nmf/sankey-works-subgroups.png
#   figures/kk-index-b/nmf/sankey-codes-subgroups.png
#   data/kk-index-b-nmf-subgroup-works-crosstab.csv
#   data/kk-index-b-nmf-subgroup-texts-crosstab.csv

library(ggplot2)
library(ggsankeyfier)
library(ggrepel)

source("scripts/kk-group-style.R")

dir.create("figures/kk-index-b/nmf", recursive = TRUE, showWarnings = FALSE)

# subgroup of a K&K code: letter + roman numeral when the code has one; the
# plain-numbered groups (A, B, E, G) have no subgroup level; a bare C or D
# code is a Part III statement code
subgrp <- function(x) {
  vapply(strsplit(trimws(x), "-"), function(pp) {
    if (length(pp) >= 3 && grepl("^[IVX]+$", pp[2])) paste(pp[1], pp[2], sep = "-")
    else if (pp[1] %in% c("C", "D")) "Part III"
    else pp[1]
  }, character(1), USE.NAMES = FALSE)
}

sg.levels <- c("A", "B", "C-I", "C-II", "D-I", "D-II", "D-III", "D-IV",
               "E", "F-I", "F-II", "F-III", "F-IV", "G", "Part III", "tie")
sg.names <- c(A = "A Descriptive", B = "B Historical",
              "C-I" = "C-I Normative", "C-II" = "C-II Normative",
              "D-I" = "D-I Psychological", "D-II" = "D-II Psychological",
              "D-III" = "D-III Psychological", "D-IV" = "D-IV Psychological",
              E = "E Structural",
              "F-I" = "F-I Genetic", "F-II" = "F-II Genetic",
              "F-III" = "F-III Genetic", "F-IV" = "F-IV Genetic",
              G = "G Incomplete", "Part III" = "Part III statements",
              tie = "no unique subgroup")
# nodes colored by group letter (one color, one group); Part III and the tie
# node in greys
letter.of <- c(A = "A", B = "B", "C-I" = "C", "C-II" = "C",
               "D-I" = "D", "D-II" = "D", "D-III" = "D", "D-IV" = "D",
               E = "E", "F-I" = "F", "F-II" = "F", "F-III" = "F", "F-IV" = "F",
               G = "G", "Part III" = "Part III", tie = "tie")
grp.col <- c(A = "#E69F00", B = "#56B4E9", C = "#009E73", D = "#F0E442",
             E = "#0072B2", F = "#D55E00", G = "#CC79A7",
             "Part III" = "grey60", tie = "grey80")
fill.lab <- c(setNames(sprintf("%s %s", names(kk.group.names),
                               unname(kk.group.names)), names(kk.group.names)),
              "Part III" = "Part III statements", tie = "no unique subgroup")

# ggsankeyfier requires one edge per node pair (per-unit duplicates break
# position_sankey), so the long format is built from the aggregated
# transition tables; ribbons take the color of their source node
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

sankey.plot <- function(tab, x.labs, node.title, fac.labs) {
  long <- make_long(tab, "sg", "fac")
  long$stage <- factor(long$stage, levels = c("sg", "fac"))
  # position_sankey stacks the first level at the bottom, so reverse the
  # levels to get subgroup A and factor 1 at the top
  long$node <- factor(long$node,
                      levels = c(rev(sg.levels), rev(as.character(1:7))))
  stopifnot(sum(tab) == sum(long$n[long$stage == "sg"]))
  lab.map <- c(setNames(sg.names[sg.levels], paste0("sg.", sg.levels)),
               setNames(fac.labs, paste0("fac.", names(fac.labs))))
  long$lab <- lab.map[paste(long$stage, long$node, sep = ".")]
  stopifnot(!anyNA(long$lab))
  # ribbons take the color of their origin node, keyed by group letter
  long$fill.key <- unname(letter.of[as.character(long$src)])
  brk <- intersect(names(grp.col), unique(long$fill.key))
  pos  <- position_sankey(v_space = "auto", order = "as_is", align = "justify",
                          width = 0.05, split_nodes = FALSE)
  pos.l <- position_sankey(v_space = "auto", order = "as_is", align = "justify",
                           width = 0.05, split_nodes = FALSE, nudge_x = -0.04)
  pos.r <- position_sankey(v_space = "auto", order = "as_is", align = "justify",
                           width = 0.05, split_nodes = FALSE, nudge_x = 0.04)
  ggplot(long, aes(x = stage, y = n, group = node,
                   connector = connector, edge_id = edge_id)) +
    geom_sankeyedge(aes(fill = fill.key), alpha = 0.6,
                    color = "white", linewidth = 0.15, position = pos) +
    geom_sankeynode(fill = "grey25", color = "white", position = pos) +
    # the stat must see the full layer: on a subset, ggsankeyfier re-stacks the
    # nodes and the labels drift off their rectangles. Blank labels on the
    # other stage draw nothing.
    geom_text(aes(label = ifelse(stage == "sg", lab, "")), stat = "sankeynode",
              position = pos.l, hjust = 1, size = 2.3, lineheight = 0.85) +
    geom_text(aes(label = ifelse(stage == "fac", lab, "")), stat = "sankeynode",
              position = pos.r, hjust = 0, size = 2.3) +
    scale_x_discrete(expand = expansion(add = c(0.5, 0.5)), labels = x.labs) +
    scale_fill_manual(values = grp.col, breaks = brk,
                      labels = unname(fill.lab[brk]),
                      name = node.title) +
    labs(x = NULL, y = NULL) +
    theme_void() +
    theme(axis.text.x = element_text(size = 7.5, face = "bold"),
          legend.text = element_text(size = 6.5),
          legend.title = element_text(size = 7, face = "bold"),
          legend.position = "bottom",
          legend.key.size = unit(0.28, "lines"))
}

# ---- panel 1: works, plurality subgroup -> dominant structural factor ----
net <- readRDS("data/kk-index-b-work-concept-network-full.rds")
wt <- net$works
wl <- read.csv("data/kk-index-b-nmf-works-loads.csv")   # the 118 works of the 2-core
idx <- match(wl$work, wt$work)
stopifnot(!anyNA(idx))
plur <- sapply(strsplit(wt$codes[idx], ";"), function(cs) {
  t <- table(subgrp(trimws(cs)))
  m <- max(t)
  if (sum(t == m) == 1) names(t)[t == m] else "tie"
})
sg.used <- sg.levels[sg.levels %in% unique(plur)]
tab.w <- table(subgroup = factor(plur, levels = sg.used),
               factor = factor(wl$dominant, levels = 1:7))
cat("works panel: ", nrow(wl), " works; plurality subgroups ",
    sum(plur != "tie"), ", tie ", sum(plur == "tie"), "\n", sep = "")
write.csv(data.frame(subgroup = rownames(tab.w), as.data.frame.matrix(tab.w),
                     check.names = FALSE),
          "data/kk-index-b-nmf-subgroup-works-crosstab.csv", row.names = FALSE)
# factor number -> hand-set label, from the loads tables
fl <- unique(wl[, c("dominant", "factor_label")])
stopifnot(nrow(fl) == 7L)
fac.labs.w <- setNames(as.character(fl$factor_label), as.character(fl$dominant))
p.works <- sankey.plot(tab.w,
  c(sg = "K&K subgroup", fac = "structural NMF\n(works x sub-elements)"),
  "K&K group", fac.labs.w)
ggsave("figures/kk-index-b/nmf/sankey-works-subgroups.png", p.works,
       width = 7, height = 6, bg = "white")

# ---- panel 2: codes, subgroup -> dominant text factor ----
tl <- read.csv("data/kk-index-b-nmf-texts-loads.csv")
fl.c <- unique(tl[, c("dominant", "factor_label")])
stopifnot(nrow(fl.c) == 7L)
fac.labs.c <- setNames(as.character(fl.c$factor_label), as.character(fl.c$dominant))
sg.c <- subgrp(trimws(tl$kk_code))
sg.c.used <- sg.levels[sg.levels %in% unique(sg.c)]
tab.c <- table(subgroup = factor(sg.c, levels = sg.c.used),
               factor = factor(tl$dominant, levels = 1:7))
cat("codes panel: ", nrow(tl), " codes; subgroups ",
    length(sg.c.used), "\n", sep = "")
write.csv(data.frame(subgroup = rownames(tab.c), as.data.frame.matrix(tab.c),
                     check.names = FALSE),
          "data/kk-index-b-nmf-subgroup-texts-crosstab.csv", row.names = FALSE)
p.codes <- sankey.plot(tab.c,
  c(sg = "K&K subgroup", fac = "text NMF\n(definition quotations)"),
  "K&K group", fac.labs.c)
ggsave("figures/kk-index-b/nmf/sankey-codes-subgroups.png", p.codes,
       width = 7, height = 6, bg = "white")
