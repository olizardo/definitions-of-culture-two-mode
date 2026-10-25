# Canonical verified sub-element x definition-code network for K&K Index B.
#
# Keeps only codes in K&K Index A or the user-verified Part III attributions (in_verified in kk-index-b-definitions.csv)
# and drops sub-elements left with no verified code. Codes that are not in Index A
# are written to a separate table so they stay traceable. Every definitions-network
# analysis (basic stats, CA, MST, centrality) reads this object.
#
# Input:  data/kk-index-b-subelement-network.rds, data/kk-index-b-definitions.csv
# Output: data/kk-index-b-verified-network.rds  (list: biadjacency, graph)
#         data/kk-index-b-excluded-codes.csv     (codes not in Index A, with their sub-elements)

library(igraph)

se <- readRDS("data/kk-index-b-subelement-network.rds")
g.full <- se$graph
defs <- read.csv("data/kk-index-b-definitions.csv")
verified.codes <- defs$kk_code[defs$in_verified]

is.code <- V(g.full)$type
excluded <- is.code & !(V(g.full)$name %in% verified.codes)

excluded.list <- lapply(V(g.full)$name[excluded], function(code) {
  subs <- as_ids(neighbors(g.full, code))
  data.frame(kk_code = code, n_subelements = length(subs),
             subelements = paste(sort(subs), collapse = "; "), stringsAsFactors = FALSE)
})
# An empty exclusion set gives a zero-row table with the same columns.
excluded.tab <- if (length(excluded.list)) do.call(rbind, excluded.list) else
  data.frame(kk_code = character(), n_subelements = integer(), subelements = character())
excluded.tab <- excluded.tab[order(excluded.tab$kk_code), ]
write.csv(excluded.tab, "data/kk-index-b-excluded-codes.csv", row.names = FALSE)

g.v <- delete_vertices(g.full, excluded)
# Drop sub-elements left with no verified code; keep codes with no Index B edge as isolates.
subs.v <- V(g.v)[!V(g.v)$type]
g.v <- delete_vertices(g.v, subs.v[degree(g.v, subs.v) == 0])
bip <- as_biadjacency_matrix(g.v, sparse = FALSE)
stopifnot(all(colnames(bip) %in% verified.codes),
          ncol(bip) == length(verified.codes),
          all(rowSums(bip) > 0), sum(bip) == ecount(g.v))

saveRDS(list(biadjacency = bip, graph = g.v), "data/kk-index-b-verified-network.rds")
cat("verified network:", nrow(bip), "sub-elements x", ncol(bip), "codes,", sum(bip), "edges\n")
cat("excluded codes:", nrow(excluded.tab), "(", sum(excluded.tab$n_subelements), "edges )\n")
