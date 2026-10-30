# Largest connected component, then its 2-core, of a 0/1 bipartite matrix whose
# rows and columns are the two modes. The 2-core repeatedly drops any row or
# column with fewer than two links. Returns the reduced matrix, same orientation.
lcc_2core <- function(M) {
  g <- igraph::graph_from_biadjacency_matrix(M, directed = FALSE, multiple = FALSE)
  comp <- igraph::components(g)
  lcc <- which.max(comp$csize)
  keep.r <- comp$membership[seq_len(nrow(M))] == lcc
  keep.c <- comp$membership[nrow(M) + seq_len(ncol(M))] == lcc
  Ac <- M[keep.r, keep.c, drop = FALSE]
  repeat {
    kr <- rowSums(Ac) >= 2
    kc <- colSums(Ac) >= 2
    if (all(kr) && all(kc)) break
    Ac <- Ac[kr, kc, drop = FALSE]
  }
  Ac
}
