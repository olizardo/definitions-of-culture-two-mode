# Numbers quoted in the manuscript's tree paragraphs: the duality paragraph, the
# C-I-6 paragraph, the Bidney codes (A-16, C-II-4, C-II-3), F-I-19 and A-17, and
# the top-10 counts. Rebuilds the code tree as analysis-mst-definitions-index-b.R
# and the concept tree as analysis-ca-index-b.R do, on the LCC 2-core, and checks
# the code tree against the stored node table. "manuscript:" notes give the typed
# value. Run from the project root.
# Outputs: data/kk-index-b-tree-quoted-numbers.csv, data/kk-index-b-tree-quoted-codes.csv

library(igraph)

source("scripts/core-index-b.R")

set.seed(8427)

net <- readRDS("data/kk-index-b-verified-network.rds")
g <- net$graph
vattr <- igraph::vertex_attr(g)
words <- setNames(vattr$n_words, vattr$name)
w.all <- words[colnames(net$biadjacency)]
w.all <- w.all[!is.na(w.all)]

Ac <- lcc_2core(net$biadjacency)
codes <- colnames(Ac)
concepts <- rownames(Ac)
cat("2-core:", length(concepts), "concepts x", length(codes), "codes\n")

# code tree, as in analysis-mst-definitions-index-b.R
P.def <- crossprod(Ac); diag(P.def) <- 0
G.def <- graph_from_adjacency_matrix(P.def, mode = "undirected", weighted = TRUE, diag = FALSE)
st.def <- mst(G.def, weights = -E(G.def)$weight)
stopifnot(is_connected(st.def))
N.def <- vcount(st.def)
btw.code <- setNames(betweenness(st.def, directed = FALSE, normalized = FALSE) /
                       ((N.def - 1) * (N.def - 2) / 2), V(st.def)$name)[codes]
com.code <- setNames(membership(cluster_leading_eigen(st.def)), V(st.def)$name)[codes]
deg.tree <- setNames(degree(st.def), V(st.def)$name)[codes]

# concept tree, as in analysis-ca-index-b.R
P.con <- Ac %*% t(Ac); diag(P.con) <- 0
G.con <- graph_from_adjacency_matrix(P.con, mode = "undirected", weighted = TRUE, diag = FALSE)
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
st.con <- make.max.st(G.con)
N.con <- vcount(st.con)
btw.conc <- setNames(betweenness(st.con, directed = FALSE, normalized = FALSE) /
                       ((N.con - 1) * (N.con - 2) / 2), V(st.con)$name)[concepts]

rank.code <- rank(-btw.code, ties.method = "min")
rank.conc <- rank(-btw.conc, ties.method = "min")
# mean betweenness of a code's concepts, and of a concept's codes
mean.conc.btw <- setNames(as.vector(crossprod(Ac, btw.conc)) / colSums(Ac), codes)
mean.code.btw <- setNames(as.vector(Ac %*% btw.code) / rowSums(Ac), concepts)
# percentage of values at or below v
pct <- function(x, v) 100 * mean(x <= v, na.rm = TRUE)
pct.strict <- function(x, v) 100 * mean(x < v, na.rm = TRUE)
half <- length(concepts) / 2
top6.conc <- names(sort(btw.conc, decreasing = TRUE))[1:6]
top4.conc <- names(sort(btw.conc, decreasing = TRUE))[1:4]
top10.codes <- names(sort(btw.code, decreasing = TRUE))[1:10]
inc.c <- function(cd) names(which(Ac[, cd] == 1))
inc.k <- function(cn) names(which(Ac[cn, ] == 1))
nb <- function(cd) sort(names(neighbors(st.def, cd)))
# code with the largest betweenness among each top concept's codes
hub <- sapply(top6.conc, function(cn) { i <- inc.k(cn); i[which.max(btw.code[i])] })
c6 <- inc.c("C-I-6")
c6comm <- com.code["C-I-6"]
top2.c6 <- names(sort(btw.conc[c6], decreasing = TRUE))[1:2]
share2 <- setdiff(codes[Ac[top2.c6[1], ] == 1 & Ac[top2.c6[2], ] == 1], "C-I-6")
comm.size <- table(com.code)

quoted <- c("C-I-6", "A-16", "C-II-4", "C-II-3", "F-I-19", "A-17", "C-I-8", "A-10")
qtab <- data.frame(
  code = quoted,
  author = vattr$source_author[match(quoted, vattr$name)],
  year = vattr$source_year[match(quoted, vattr$name)],
  words = unname(words[quoted]),
  links_2core = unname(colSums(Ac)[quoted]),
  links_full = unname(degree(g)[quoted]),
  btw_code = unname(btw.code[quoted]),
  rank_code = unname(rank.code[quoted]),
  tree_degree = unname(deg.tree[quoted]),
  community = unname(com.code[quoted]),
  community_size = as.integer(comm.size[as.character(com.code[quoted])]),
  pct_mean_conc_btw = unname(sapply(quoted, function(cd) pct(mean.conc.btw, mean.conc.btw[cd]))),
  top4_concepts = unname(sapply(quoted, function(cd)
    paste(sort(intersect(inc.c(cd), top4.conc)), collapse = "; "))),
  concepts_ranked = unname(sapply(quoted, function(cd) {
    cn <- inc.c(cd); cn <- cn[order(rank.conc[cn])]
    paste0(cn, " (", rank.conc[cn], ")", collapse = "; ")
  })),
  tree_neighbors = unname(sapply(quoted, function(cd) paste(nb(cd), collapse = "; "))),
  stringsAsFactors = FALSE)

out <- list()
add <- function(section, quantity, value, note = "") {
  out[[length(out) + 1]] <<- data.frame(
    section = section, quantity = quantity,
    value = paste(format(value, digits = 4, trim = TRUE), collapse = " / "),
    note = note, stringsAsFactors = FALSE)
}

# the stored node table must match the tree rebuilt here
csv <- read.csv("data/kk-index-b-mst-definitions-tree-nodes.csv")
stopifnot(setequal(csv$kk_code, codes))
d.btw <- max(abs(btw.code[csv$kk_code] - csv$betweenness))
stopifnot(d.btw < 1e-9)
add("check", "code tree: max abs difference from stored betweenness", d.btw)
add("check", "code tree: communities agree with stored CSV",
    all(com.code[csv$kk_code] == csv$community))
add("check", "concept tree edges (of N - 1)", paste(ecount(st.con), vcount(st.con) - 1, sep = " of "))

add("duality", "r, concept betweenness vs mean betweenness of its codes (Pearson)",
    cor(btw.conc, mean.code.btw[concepts]), "manuscript: 0.08")
add("duality", "same, Spearman", cor(btw.conc, mean.code.btw[concepts], method = "spearman"))
add("duality", "r, code betweenness vs mean betweenness of its concepts (Pearson)",
    cor(btw.code, mean.conc.btw[codes]), "manuscript: 0.04")
add("duality", "same, Spearman", cor(btw.code, mean.conc.btw[codes], method = "spearman"))
# concepts tied at zero betweenness share the average of their ranks
rank.avg <- rank(-btw.conc, ties.method = "average")
for (cd in c("C-I-8", "A-10")) {
  add("duality", paste(cd, "rank in code tree"), rank.code[cd])
  add("duality", paste(cd, "share of its concepts in bottom half of concept ranking"),
      mean(rank.avg[inc.c(cd)] > half), "manuscript: mostly bottom half")
  add("duality", paste(cd, "share of its concepts with zero tree betweenness"),
      mean(btw.conc[inc.c(cd)] < 1e-12))
}
add("duality", "top-6 concepts whose largest-betweenness code is C-I-6", sum(hub == "C-I-6"),
    paste(names(hub), hub, sep = ":", collapse = "; "))
add("duality", "top-6 concepts linked to C-I-6", length(intersect(c6, top6.conc)),
    paste(intersect(c6, top6.conc), collapse = "; "))

add("C-I-6", "quotation words", words["C-I-6"], "manuscript: 64")
add("C-I-6", "percentile of quotation length, 2-core codes",
    pct(words[codes], words["C-I-6"]), "manuscript: 90th")
add("C-I-6", "percentile of quotation length, all codes with a quotation",
    pct(w.all, words["C-I-6"]), "manuscript: 90th")
add("C-I-6", "longest quotation, words", max(w.all), names(which.max(w.all)))
add("C-I-6", "percentile of mean incident-concept betweenness, codes",
    pct(mean.conc.btw, mean.conc.btw["C-I-6"]), "manuscript: 87th")
add("C-I-6", "same, strictly below", pct.strict(mean.conc.btw, mean.conc.btw["C-I-6"]))
add("C-I-6", "codes sharing its two most central concepts, excluding C-I-6", length(share2),
    paste0(paste(top2.c6, collapse = " + "), "; manuscript: 54"))
add("C-I-6", "their mean normalized betweenness", mean(btw.code[share2]), "manuscript: 0.05")
add("C-I-6", "normalized betweenness", btw.code["C-I-6"], "manuscript: 0.71")
top5.c6 <- intersect(c6, top6.conc)
share.any <- setdiff(codes[colSums(Ac[top5.c6, , drop = FALSE]) > 0], "C-I-6")
add("C-I-6", "codes sharing at least one of its five most central concepts, excluding C-I-6",
    length(share.any), paste0(paste(top5.c6, collapse = ", "), "; candidate for manuscript: 54"))
add("C-I-6", "mean normalized betweenness of those codes (five-concept set)",
    mean(btw.code[share.any]), "candidate for manuscript: 0.05")
add("C-I-6", "rank in code tree", rank.code["C-I-6"], "manuscript: first")
add("C-I-6", "tree degree", deg.tree["C-I-6"], "manuscript: 17")
add("C-I-6", "maximum tree degree over codes", max(deg.tree))
add("C-I-6", "community size", comm.size[as.character(c6comm)])
add("C-I-6", "largest community size", max(comm.size), "manuscript: 24, largest")
add("C-I-6", "groups represented in its community",
    length(unique(substr(names(com.code)[com.code == c6comm], 1, 1))), "manuscript: all seven")

a16.c <- inc.c("A-16")
add("A-16", "quotation words", words["A-16"], "manuscript: 34")
add("A-16", "percentile of mean incident-concept betweenness, codes",
    pct(mean.conc.btw, mean.conc.btw["A-16"]), "manuscript: 68th")
add("A-16", "same, strictly below", pct.strict(mean.conc.btw, mean.conc.btw["A-16"]))
add("A-16", "linked concepts, 2-core", length(a16.c))
add("A-16", "linked concepts, full network", degree(g)[["A-16"]])
add("A-16", "linked concepts among six most central", sum(a16.c %in% top6.conc),
    paste0(paste(intersect(a16.c, top6.conc), collapse = "; "), "; manuscript: three"))
add("A-16", "linked concepts with zero tree betweenness", sum(btw.conc[a16.c] < 1e-12),
    "manuscript: six")
add("A-16", "linked concepts outside the 2-core (no tree betweenness)",
    degree(g)[["A-16"]] - length(a16.c))
add("A-16", "rank in code tree", rank.code["A-16"], "manuscript: third")
add("A-16", "tree degree", deg.tree["A-16"])
comp.after <- sort(components(delete_vertices(st.def, "A-16"))$csize, decreasing = TRUE)
add("A-16", "component sizes after removing A-16 from code tree",
    paste(comp.after, collapse = " / "), "manuscript: four components")

ms <- list(
  "C-II-4" = "manuscript: 40 words; 13 links; 3 of top 4; rank 4; same community as C-II-3 only",
  "C-II-3" = "manuscript: 40 words; 11 links; 2 of top 4; rank 5; same community as C-II-4 only",
  "F-I-19" = "manuscript: 70 words; 15 links; 3 of top 4; rank 2; 8 tree neighbors incl. C-II-3, A-17; same community as A-17",
  "A-17" = "manuscript: 65 words; 13 links; rank 6; 1 of six most central (behavior); tree neighbors C-I-8, D-II-8, F-I-19, F-II-6")
for (cd in c("C-II-4", "C-II-3", "F-I-19", "A-17")) {
  add(cd, "quotation words", words[cd], ms[[cd]])
  add(cd, "linked concepts, 2-core", length(inc.c(cd)))
  add(cd, "linked concepts, full network", degree(g)[[cd]])
  add(cd, "rank in code tree", rank.code[cd])
  add(cd, "linked concepts among four most central", sum(inc.c(cd) %in% top4.conc),
      paste(sort(intersect(inc.c(cd), top4.conc)), collapse = "; "))
  add(cd, "linked concepts among six most central", sum(inc.c(cd) %in% top6.conc))
  add(cd, "tree neighbors", length(nb(cd)), paste(nb(cd), collapse = "; "))
  add(cd, "community", com.code[cd])
  add(cd, "same community as C-I-6", com.code[cd] == c6comm)
  add(cd, "same community as A-16", com.code[cd] == com.code["A-16"])
}
add("C-II-4", "same community as C-II-3", com.code["C-II-4"] == com.code["C-II-3"])
add("F-I-19", "same community as A-17", com.code["F-I-19"] == com.code["A-17"])
add("C-II-3", "concept rank of 'members of a society'", rank.conc["members of a society"],
    "manuscript: seventh")
for (cn in c("learning", "habits", "ideas", "mass", "techniques", "totality", "transmission"))
  add("A-17", paste("concept betweenness:", cn), btw.conc[cn],
      "manuscript: learning 0.145, habits 0.133, ideas 0.062; the others none")

top10.auth <- vattr$source_author[match(top10.codes, vattr$name)]
s <- sort(btw.code, decreasing = TRUE)
add("top10", "codes with a C or F prefix", sum(substr(top10.codes, 1, 1) %in% c("C", "F")),
    "manuscript: five")
add("top10", "codes by Bidney", sum(top10.auth == "Bidney"), "manuscript: three")
add("top10", "codes by Linton", sum(top10.auth == "Linton"), "manuscript: two")
add("top10", "codes by Kroeber", sum(top10.auth == "Kroeber"), "manuscript: two (A-17, B-18)")
add("top10", "gap between 10th and 11th code betweenness", s[10] - s[11], "tie check")

out <- do.call(rbind, out)
write.csv(out, "data/kk-index-b-tree-quoted-numbers.csv", row.names = FALSE)
write.csv(qtab, "data/kk-index-b-tree-quoted-codes.csv", row.names = FALSE)
print(out, right = FALSE)
print(qtab)
cat("\nTop 10 concepts, normalized betweenness x 100:\n")
print(round(100 * sort(btw.conc, decreasing = TRUE)[1:10], 2))
cat("\nTop 12 codes, normalized betweenness x 100:\n")
print(round(100 * s[1:12], 2))
