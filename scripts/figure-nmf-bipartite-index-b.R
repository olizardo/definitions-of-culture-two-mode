# Weighted bipartite plot of the structural NMF (k = 7): each definition code on
# the left, each factor on the right, and an edge for every positive loading with
# width proportional to the loading. Codes are ordered by dominant factor. Reads
# the outputs of analysis-nmf-structural-index-b.R. Run from the project root.

library(ggplot2)

K <- 7
loads <- read.csv("data/kk-index-b-nmf-structural-loads.csv", stringsAsFactors = FALSE)
lab <- read.csv("data/kk-index-b-nmf-structural-agreement.csv", stringsAsFactors = FALSE)
lab <- unique(lab[order(lab$factor), c("factor", "factor_label")])
stopifnot(nrow(lab) == K)

Xm <- as.matrix(loads[, paste0("X", 1:K)])
loads$maxw <- Xm[cbind(seq_len(nrow(loads)), loads$dominant)]
loads <- loads[order(loads$dominant, -loads$maxw), ]
loads$y <- rev(seq_len(nrow(loads)))

edges <- do.call(rbind, lapply(seq_len(K), function(k) {
  w <- loads[[paste0("X", k)]]
  keep <- w > 0
  data.frame(kk_code = loads$kk_code[keep], y = loads$y[keep], factor = k, loading = w[keep])
}))

fac.y <- sapply(seq_len(K), function(k) mean(loads$y[loads$dominant == k]))
edges$yend <- fac.y[edges$factor]
fac <- data.frame(factor = seq_len(K), y = fac.y, label = paste0(lab$factor_label, " (", table(factor(loads$dominant, levels = seq_len(K))), " codes)"))

ggplot() +
  geom_segment(data = edges, aes(x = 0, xend = 1, y = y, yend = yend, linewidth = loading),
               color = "grey45", alpha = 0.6, lineend = "round") +
  scale_linewidth(range = c(0.05, 2.2), name = "loading") +
  geom_point(data = loads, aes(x = 0, y = y), size = 1.1, color = "grey20") +
  geom_point(data = fac, aes(x = 1, y = y), size = 4, color = "grey20") +
  geom_text(data = fac, aes(x = 1.03, y = y, label = label), hjust = 0, size = 3.2, fontface = "bold") +
  scale_x_continuous(limits = c(-0.05, 1.9)) +
  theme_void() +
  theme(plot.title = element_text(face = "bold", size = 13),
        legend.position = "bottom") +
  labs(title = "Structural NMF (k = 7), definitions (codes) and factors, K&K Index B LCC 2-core",
       subtitle = "left: definition codes, ordered by dominant factor; right: factors; edge width = loading of the code on the factor")
ggsave("figures/kk-index-b/nmf/nmf-structural-bipartite.png", width = 13, height = 11, dpi = 150, bg = "white")
