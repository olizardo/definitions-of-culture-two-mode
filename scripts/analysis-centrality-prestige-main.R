# Centrality and status/prestige for the collapsed KKCC network
# (16 main categories x 135 definitions, union binarized).
#
# Centrality follows Borgatti & Everett (1997) two-mode normalizations per
# cent-tm.html: closeness normalized by each set's theoretical maximum
# (larger-set sizes differ), betweenness normalized by set size with the
# formulas swapped because the definitions are the LARGER set here.
#
# Prestige follows prest-tm.html: two-mode Bonacich prestige / biHITS
# (tm.status power iteration), verified against the dual-projection and
# eigenvector/SVD approaches and the Faust (1997) duality relation; plus the
# PageRank family: two-mode PageRank (co-HITS), double-normalized PageRank
# (BGRM, Rui et al. 2007), and square-root normalized BiRank (He et al. 2016).
#
# Inputs: data/kkcc_two_mode_main.rds; def_attrs from data/kkcc_two_mode.rds.

library(igraph)

d <- readRDS("data/kkcc_two_mode_main.rds")
A <- d$biadjacency
g <- d$graph
def_attrs <- readRDS("data/kkcc_two_mode.rds")$def_attrs

dir.create("data", showWarnings = FALSE)

M <- nrow(A)   # concepts (smaller set)
N <- ncol(A)   # definitions (larger set)
stopifnot(is_connected(g),
          identical(V(g)$name, c(rownames(A), colnames(A))),
          min(rowSums(A)) > 0, min(colSums(A)) > 0)

# ------------------------------------------------------------ closeness
D.pg <- distances(g)
n.con <- N + 2 * (M - 1)   # concept normalization: N + 2(M-1)
n.def <- M + 2 * (N - 1)   # definition normalization: M + 2(N-1)
norm.clo <- c(rep(n.con, M), rep(n.def, N))
clo <- setNames(norm.clo / rowSums(D.pg), V(g)$name)

# ------------------------------------------------------------ betweenness
# larger set (definitions): 2(M-1)(N-1) with M = larger set size
n.def.b <- 2 * (N - 1) * (M - 1)
# smaller set (concepts): (1/2)S(S-1) + (1/2)(L-1)(L-2) + (L-1)(S-1)
n.con.b <- (1 / 2) * (M * (M - 1)) + (1 / 2) * ((N - 1) * (N - 2)) +
  (N - 1) * (M - 1)
norm.bet <- c(rep(n.con.b, M), rep(n.def.b, N))
bet.pct <- setNames(betweenness(g) / norm.bet * 100, V(g)$name)

cat("closeness norms: concepts", n.con, "/ definitions", n.def, "\n")
cat("betweenness norms: concepts", n.con.b, "/ definitions", n.def.b, "\n")

# ------------------------------------------------------------ prestige helpers
tm.status <- function(w, z) {
  y <- matrix(1 / ncol(w), ncol(w), 1)  # initial group scores set to a constant
  delta <- 1
  while (delta > 1e-10) {
    o.y <- y
    x <- w %*% o.y                     # row-mode scores from old column scores
    x <- x / norm(x, type = "F")
    y <- z %*% x                       # column-mode scores from new row scores
    y <- y / norm(y, type = "F")
    delta <- max(abs(y - o.y))
  }
  list(p.s = x, g.s = y)
}

status1 <- function(w) {
  x <- rep(1, nrow(w))
  d <- 1
  while (d > 1e-10) {
    o.x <- x
    x <- w %*% o.x
    x <- x / norm(x, type = "F")
    d <- max(abs(x - o.x))
  }
  as.vector(x)
}

inv.deg <- function(k, pow = 1) {
  if (any(k == 0)) {
    stop("Isolated nodes present: remove them or handle them explicitly before normalizing.")
  }
  diag(1 / k^pow)
}

std.sign <- function(v) v * sign(v[which.max(abs(v))])

# ------------------------------------------------------------ two-mode Bonacich prestige (biHITS)
tm.hits <- tm.status(A, t(A))

# verify against the dual-projection approach (Breiger projections)
P <- A %*% t(A)
G <- t(A) %*% A
stopifnot(isTRUE(all.equal(as.vector(tm.hits$p.s), status1(P))),
          isTRUE(all.equal(as.vector(tm.hits$g.s), status1(G))))

# verify against the eigenvector approach (SVD of A and eigen of projections)
eig.svd <- svd(A)
eig.p <- eigen(P); eig.g <- eigen(G)
svd.p <- std.sign(eig.svd$u[, 1]); svd.g <- std.sign(eig.svd$v[, 1])
eig.p.s <- std.sign(Re(eig.p$vectors[, 1])); eig.g.s <- std.sign(Re(eig.g$vectors[, 1]))
stopifnot(isTRUE(all.equal(as.vector(tm.hits$p.s), abs(svd.p))),
          isTRUE(all.equal(as.vector(tm.hits$g.s), abs(svd.g))),
          isTRUE(all.equal(as.vector(tm.hits$p.s), abs(eig.p.s))),
          isTRUE(all.equal(as.vector(tm.hits$g.s), abs(eig.g.s))))
lambda <- eig.p$values[1]   # leading eigenvalue of the concept projection

# duality of Bonacich prestige (Faust 1997): each node's score is a weighted
# sum of the other mode's scores, weight = 1/sqrt(lambda)
dual.p <- (A %*% (as.vector(tm.hits$g.s))) * (1 / sqrt(lambda))
dual.g <- (t(A) %*% (as.vector(tm.hits$p.s))) * (1 / sqrt(lambda))
stopifnot(max(abs(dual.p - as.vector(tm.hits$p.s))) < 1e-8,
          max(abs(dual.g - as.vector(tm.hits$g.s))) < 1e-8)
cat("prestige cross-checks passed (dual projection, SVD, eigen, duality)\n")

# ------------------------------------------------------------ PageRank family
D.p <- inv.deg(rowSums(A))
D.g <- inv.deg(colSums(A))

# two-mode PageRank (co-HITS; Deng et al. 2009)
P.n  <- A %*% D.g
G.n  <- t(A) %*% D.p
tm.pr <- tm.status(P.n, G.n)

# double-normalized PageRank (BGRM; Rui et al. 2007)
P.n2 <- D.p %*% A %*% D.g
G.n2 <- D.g %*% t(A) %*% D.p
tm.bgrm <- tm.status(P.n2, G.n2)

# square-root normalized (BiRank; He et al. 2016)
P.n3 <- inv.deg(rowSums(A), pow = 1 / 2) %*% A %*% inv.deg(colSums(A), pow = 1 / 2)
G.n3 <- inv.deg(colSums(A), pow = 1 / 2) %*% t(A) %*% inv.deg(rowSums(A), pow = 1 / 2)
tm.birank <- tm.status(P.n3, G.n3)

# ------------------------------------------------------------ summary tables
std3 <- function(v) round(as.vector(v) / max(as.vector(v)), 3)

con.tab <- data.frame(
  concept = rownames(A), k = rowSums(A),
  hits = std3(tm.hits$p.s), pr = std3(tm.pr$p.s),
  bgrm = std3(tm.bgrm$p.s), birank = std3(tm.birank$p.s)
)
con.tab <- con.tab[order(-con.tab$k), ]
rownames(con.tab) <- NULL
cat("\nconcept prestige scores (ordered by degree):\n")
print(con.tab, row.names = FALSE)

def.tab <- data.frame(
  code = colnames(A), k = colSums(A),
  type = def_attrs$type[match(colnames(A), def_attrs$code)],
  hits = std3(tm.hits$g.s), pr = std3(tm.pr$g.s),
  bgrm = std3(tm.bgrm$g.s), birank = std3(tm.birank$g.s)
)
def.tab <- def.tab[order(-def.tab$k), ]
rownames(def.tab) <- NULL
cat("\ntop 20 definition prestige scores (ordered by degree):\n")
print(head(def.tab, 20), row.names = FALSE)

# ------------------------------------------------------------ centrality tables
cen <- data.frame(
  node = V(g)$name,
  mode = ifelse(seq_len(vcount(g)) <= M, "concept", "definition"),
  k = c(rowSums(A), colSums(A)),
  closeness = round(as.numeric(clo), 4),
  betweenness.pct = round(as.numeric(bet.pct), 3)
)
cen$type <- ifelse(cen$mode == "definition",
                   def_attrs$type[match(cen$node, def_attrs$code)], NA)
cen.con <- cen[cen$mode == "concept", ][order(-cen$k[cen$mode == "concept"]), ]
cen.def <- cen[cen$mode == "definition", ][order(-cen$k[cen$mode == "definition"]), ]
cat("\ntop 10 concepts by closeness:\n")
print(head(cen.con[order(-cen.con$closeness), c("node","k","closeness","betweenness.pct")], 10), row.names = FALSE)
cat("\ntop 10 definitions by closeness:\n")
print(head(cen.def[order(-cen.def$closeness), c("node","k","closeness","betweenness.pct")], 10), row.names = FALSE)

# ------------------------------------------------------------ save scores
write.csv(cen, "data/kkcc-centrality-main.csv", row.names = FALSE)
prest.def <- def_attrs[match(colnames(A), def_attrs$code),
                       c("code", "type", "subgroup_code")]
prest.def$k <- colSums(A)
prest.def$hits <- std3(tm.hits$g.s)
prest.def$pr <- std3(tm.pr$g.s)
prest.def$bgrm <- std3(tm.bgrm$g.s)
prest.def$birank <- std3(tm.birank$g.s)
write.csv(prest.def[order(-prest.def$k), ], "data/kkcc-prestige-definitions-main.csv",
          row.names = FALSE)
write.csv(con.tab, "data/kkcc-prestige-concepts-main.csv", row.names = FALSE)

# ------------------------------------------------------------ means by node attributes
# definitions carry a type attribute (the sevenfold classification); concepts in
# the collapsed network have no further attributes beyond degree
m <- merge(prest.def, cen.def[, c("node", "closeness", "betweenness.pct")],
           by.x = "code", by.y = "node")
cols <- c("k", "closeness", "betweenness.pct", "hits", "pr", "bgrm", "birank")
type.means <- aggregate(m[, cols], by = list(type = m$type), FUN = mean)
type.means <- cbind(type = type.means$type,
                    n = as.integer(table(m$type)[type.means$type]),
                    round(type.means[, -1], 3))
type.means <- type.means[order(-type.means$k), ]
cat("\naverage scores by definition type:\n")
print(type.means, row.names = FALSE)
write.csv(type.means, "data/kkcc-score-means-by-type.csv", row.names = FALSE)

# finer subgroup cut: C1/C2, D1-D4, and F1-F4 carry numbered subgroups; the
# other types (A, B, E, G) have none, so their subgroup is just the letter
m$subgrp <- ifelse(grepl("^[CDF][0-9]+-", m$subgroup_code),
                   sub("^([CDF][0-9]+)-.*", "\\1", m$subgroup_code),
                   sub("^([A-G]).*", "\\1", m$subgroup_code))
sg.agg <- aggregate(m[, cols], by = list(subgroup = m$subgrp, type = m$type),
                    FUN = mean)
subgroup.means <- cbind(subgroup = sg.agg$subgroup, type = sg.agg$type,
                        n = as.integer(table(m$subgrp)[sg.agg$subgroup]),
                        round(sg.agg[, cols], 3))
subgroup.means <- subgroup.means[order(subgroup.means$type, subgroup.means$subgroup), ]
rownames(subgroup.means) <- NULL
cat("\naverage scores by definition subgroup:\n")
print(subgroup.means, row.names = FALSE)
write.csv(subgroup.means, "data/kkcc-score-means-by-subgroup.csv", row.names = FALSE)

# decade cut: definitions dated by the quoted edition year of their source
years <- read.csv("data/kkcc-definition-years.csv")
m$decade <- years$decade[match(m$code, years$code)]
cat("definitions without a year (excluded):",
    paste(m$code[is.na(m$decade)], collapse = ", "), "\n")
dec.agg <- aggregate(m[!is.na(m$decade), cols],
                     by = list(decade = m$decade[!is.na(m$decade)]), FUN = mean)
decade.means <- cbind(decade = dec.agg$decade,
                      n = as.integer(table(m$decade)[as.character(dec.agg$decade)]),
                      round(dec.agg[, -1], 3))
decade.means <- decade.means[order(decade.means$decade), ]
rownames(decade.means) <- NULL
cat("\naverage scores by definition decade:\n")
print(decade.means, row.names = FALSE)
write.csv(decade.means, "data/kkcc-score-means-by-decade.csv", row.names = FALSE)
