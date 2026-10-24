# Collapse the fine-grained KKCC two-mode network (56 concept rows) to its
# 16 main categories: each main category inherits the union of its own ties
# and those of its auxiliary notions (binary; ties are OR-ed, not summed).

library(igraph)

d <- readRDS("data/kkcc_two_mode.rds")
A <- d$biadjacency
g <- d$graph

is.main <- V(g)$is_main[match(rownames(A), V(g)$name)]
parent  <- V(g)$parent_category[match(rownames(A), V(g)$name)]

main_cats <- unique(parent[is.main])   # 16 main categories with >= 1 use
Am <- sapply(main_cats, function(m) as.numeric(colSums(A[parent == m, , drop = FALSE]) > 0))
rownames(Am) <- colnames(A)
Am <- t(Am)   # main categories (rows) x definitions (columns)

cat("collapsed biadjacency:", nrow(Am), "x", ncol(Am), "edges:", sum(Am), "\n")
cat("rows with no ties:", paste(rownames(Am)[rowSums(Am) == 0], collapse = ", "), "\n")

# informational check vs the printed category totals: printed totals count uses
# with multiplicity, the collapsed binary matrix counts distinct ties, so the
# binary sums can only be <= the printed totals
uses.printed <- c(SOCIAL = 68, BEHAVIOR = 59, PATTERNS = 32, HABITS = 29,
                  ACTING = 25, HERITAGE = 21, BELIEFS = 20, CUSTOMS = 20,
                  SYMBOL = 18, SYSTEM = 15, ATTITUDES = 12, ADJUSTMENTS = 10,
                  KNOWLEDGE = 8, LANGUAGE = 7, TRANSMISSION = 4, INDUSTRIES = 3)
uses.binary <- rowSums(A)[names(uses.printed)]
stopifnot(all(uses.binary <= uses.printed))
data.frame(printed = uses.printed, binary = uses.binary)

gm <- graph_from_biadjacency_matrix(Am)
V(gm)$type <- c(rep(FALSE, nrow(Am)), rep(TRUE, ncol(Am)))
V(gm)$name <- c(rownames(Am), colnames(Am))
v.def <- which(V(gm)$type)
V(gm)$def_group <- NA
V(gm)$def_group[v.def] <- def_attrs$group[match(V(gm)$name[v.def], def_attrs$code)]
V(gm)$def_type <- NA
V(gm)$def_type[v.def] <- def_attrs$type[match(V(gm)$name[v.def], def_attrs$code)]
V(gm)$node_type <- ifelse(V(gm)$type, "definition", "concept")

stopifnot(is_bipartite(gm), ecount(gm) == sum(Am))

dir.create("data", showWarnings = FALSE)
write.csv(Am, "data/kkcc_biadjacency_main.csv")
saveRDS(list(biadjacency = Am, graph = gm), "data/kkcc_two_mode_main.rds")
cat("saved data/kkcc_biadjacency_main.csv and data/kkcc_two_mode_main.rds\n")
