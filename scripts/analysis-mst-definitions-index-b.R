# Maximum spanning tree of the definitions (code) projection of the K&K Index B
# sub-element network, on the largest component's 2-core (same Ac as
# scripts/analysis-ca-index-b.R). Ties between two codes = shared sub-elements
# (edge weight). Nodes labeled with their K&K code; colored by
# leading-eigenvector community computed on the tree; sized by tree betweenness.

library(igraph)
library(ggraph)
library(ggstar)

set.seed(8427)
invisible(lapply(c("figures/boroch", "figures/kk-index-b/definitions", "figures/kk-index-b/works"), dir.create, recursive = TRUE, showWarnings = FALSE))

g <- readRDS("data/kk-index-b-verified-network.rds")$graph
comp <- components(g)
gl <- induced_subgraph(g, comp$membership == which.max(comp$csize))
el <- as_edgelist(gl, names = TRUE)
Al <- matrix(0, nrow = length(unique(el[, 1])), ncol = length(unique(el[, 2])),
             dimnames = list(sort(unique(el[, 1])), sort(unique(el[, 2]))))
Al[cbind(el[, 1], el[, 2])] <- 1
Ac <- Al
repeat {
  keep.r <- rowSums(Ac) >= 2
  keep.c <- colSums(Ac) >= 2
  if (all(keep.r) && all(keep.c)) break
  Ac <- Ac[keep.r, keep.c, drop = FALSE]
}
cat("2-core:", nrow(Ac), "elements x", ncol(Ac), "codes; components:",
    components(graph_from_biadjacency_matrix(Ac, dir = FALSE))$no, "\n")

# code x code projection: weight = number of shared sub-elements
P.def <- crossprod(Ac); diag(P.def) <- 0
G.def <- graph_from_adjacency_matrix(P.def, mode = "undirected",
                                     weighted = TRUE, diag = FALSE)
cat("projection edges:", ecount(G.def), "\n")

# maximum spanning tree = minimum spanning tree on negated weights
st.def <- mst(G.def, weights = -E(G.def)$weight)
cat("tree edges:", ecount(st.def), "of", vcount(st.def) - 1, "possible\n")
if (!is_connected(st.def)) stop("tree is not connected")

# "Author Year" labels from the Index A entry; the first author-year pair is
# used, with "+" appended when the entry names more than one author-year pair
defs <- read.csv("data/kk-index-b-definitions.csv", stringsAsFactors = FALSE)
ia <- setNames(defs$index_a_authors, defs$kk_code)
# Label = the authors of the first work (every entry sharing its year string,
# joined with " & ") and that year, with any printed letter. Co-authored works
# list both authors. "+" marks an entry with two or more distinct works, i.e.
# two distinct year strings.
make.label <- function(s) {
  if (is.na(s) || s == "") return(NA_character_)
  entry.year <- regmatches(s, regexpr("[0-9]{3,4}[a-z]?", s))
  parts <- trimws(strsplit(s, ";")[[1]])
  surname <- trimws(sub("\\s*\\(.*$", "", parts))
  year <- vapply(parts, function(p) {
    m <- regmatches(p, regexpr("[0-9]{3,4}[a-z]?", p))
    if (length(m)) m else entry.year
  }, character(1), USE.NAMES = FALSE)
  first.year <- year[1]
  authors <- unique(surname[year == first.year])
  label <- paste(paste(authors, collapse = " & "), first.year)
  paste0(label, if (length(unique(year)) > 1) " +" else "")
}
# Labels come from the works each code holds (data/kk-index-b-works.csv, built by
# scripts/build-work-concept-network-index-b.R), with initials from
# scripts/label-authors-index-b.R. A code with several works lists them joined by " / ".
source("scripts/label-authors-index-b.R")
works.tab <- read.csv("data/kk-index-b-works.csv", stringsAsFactors = FALSE)
code.works.map <- list()
for (i in seq_len(nrow(works.tab))) {
  for (k in strsplit(works.tab$codes[i], "; ")[[1]])
    code.works.map[[k]] <- c(code.works.map[[k]], works.tab$work[i])
}
works.lab <- vapply(V(st.def)$name, function(k) {
  ws <- code.works.map[[k]]
  if (is.null(ws)) return("")
  paste(vapply(ws, label.authors, character(1)), collapse = " / ")
}, character(1))
# Nodes are labeled with their code; the works each code holds go to the node table
V(st.def)$label <- V(st.def)$name
# shape encodes the K&K definition group (first letter of the code, A-G)
V(st.def)$family <- substr(V(st.def)$name, 1, 1)
fams <- sort(unique(V(st.def)$family))
stopifnot(length(fams) <= 7)
source("scripts/kk-group-style.R")
group.star <- kk.group.star[fams]
group.labels <- setNames(paste0(fams, ": ", kk.group.names[fams]), fams)

# leading-eigenvector community on the tree; tree betweenness
com.tree <- cluster_leading_eigen(st.def)
V(st.def)$comm <- factor(membership(com.tree))
cat("tree communities:", nlevels(V(st.def)$comm), "\n")
btw <- betweenness(st.def, directed = FALSE, normalized = FALSE)
V(st.def)$btw <- btw
cat("betweenness range:", range(btw), "\n")

n.comm <- nlevels(V(st.def)$comm)
pal <- setNames(hcl(h = seq(15, 375, length.out = n.comm + 1)[-(n.comm + 1)],
                    c = 65, l = 65), levels(V(st.def)$comm))

# layout computed once so the star layer and the edges share node positions
lay <- create_layout(st.def, layout = "kk")
p <- ggraph(lay) +
  geom_edge_link(aes(width = weight), color = "grey75", alpha = 0.8) +
  scale_edge_width(range = c(0.3, 1.6), guide = "none") +
  geom_star(data = lay, aes(x = x, y = y, starshape = family, fill = comm, size = btw),
            color = "grey25") +
  scale_fill_manual(values = pal, guide = "none") +
  scale_starshape_manual(values = group.star, labels = group.labels, name = "definition type (K&K group)",
                         guide = guide_legend(override.aes = list(size = 4, fill = "black"))) +
  scale_size_continuous(range = c(2.5, 9), name = "betweenness (tree)") +
  geom_node_text(aes(label = label), repel = TRUE, size = 2.6,
                 max.overlaps = Inf, seed = 8427, segment.color = NA,
                 force = 0.6, max.iter = 20000) +
  theme_void() +
  theme(plot.title = element_text(face = "bold", size = 13),
        legend.position = "bottom",
        legend.title = element_text(size = 8), legend.text = element_text(size = 7)) +
  labs(title = "Maximum spanning tree, definitions network (code nodes), K&K Index B LCC 2-core",
       subtitle = "ties = shared sub-elements; labels = K&K code; shape = definition type; node size = betweenness in the tree")
ggsave("figures/kk-index-b/definitions/mst-code-comm-tree.png", p,
       width = 14, height = 10, dpi = 150, bg = "white")

tree.out <- data.frame(kk_code = V(st.def)$name, works = works.lab,
                       community = as.integer(V(st.def)$comm),
                       betweenness = btw, degree_tree = degree(st.def))
write.csv(tree.out[order(-tree.out$betweenness), ],
          "data/kk-index-b-mst-definitions-tree-nodes.csv", row.names = FALSE)
cat("figure and node table written\n")
