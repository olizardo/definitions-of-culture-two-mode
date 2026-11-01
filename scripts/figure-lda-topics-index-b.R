# Top terms of each LDA topic, from the seed-ensemble topic-term profiles
# (analysis-lda-texts-index-b.R). One facet per topic, horizontal bars ordered
# by weight. The y axis is keyed by topic and term so each facet orders by its
# own weights; every term is labeled.
#
# Reads data/kk-index-b-lda-topic-terms.csv.
# Outputs figures/kk-index-b/lda/lda-topic-terms.png.

library(ggplot2)

tt <- read.csv("data/kk-index-b-lda-topic-terms.csv", stringsAsFactors = FALSE)
tt <- tt[order(tt$topic, -tt$weight), ]
# y keyed by topic and term, so each facet orders by its own weights
tt$y <- factor(paste(tt$topic, tt$term, sep = "|"),
               levels = rev(paste(tt$topic, tt$term, sep = "|")))
# strip labels as in Table 4 of the manuscript; recheck after any rebuild
topic.labels <- c(
  "individual acquired behavior", "human products and results",
  "transmitted group behavior", "shared group living",
  "biological needs and nature", "acquired habits as complex wholes",
  "cultural order of phenomena", "sum total of group life",
  "material tools and ideas", "customs, beliefs and knowledge",
  "way of life of a people", "man-made environment")
# long labels wrap onto two lines so they fit the strips
strip.lab <- vapply(sprintf("%d %s", 1:12, topic.labels),
                    function(s) paste(strwrap(s, 24), collapse = "\n"), character(1))
tt$topic_label <- factor(strip.lab[tt$topic], levels = strip.lab)

dir.create("figures/kk-index-b/lda", recursive = TRUE, showWarnings = FALSE)
p <- ggplot(tt, aes(x = weight, y = y)) +
  geom_segment(aes(x = 0, xend = weight, y = y, yend = y), color = "grey60") +
  geom_point(size = 2, color = "grey20") +
  facet_wrap(~ topic_label, ncol = 4, scales = "free") +
  scale_y_discrete(labels = function(l) sub("^[0-9]+[|]", "", l)) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.05))) +
  labs(x = NULL, y = NULL,
       subtitle = paste("Top terms of each LDA topic at k = 12; weights are the",
                        "seed-mean topic-term probabilities over 10 aligned fits")) +
  theme_minimal() +
  theme(strip.text = element_text(face = "bold", size = 9),
        axis.text.y = element_text(size = 9, face = "bold"),
        axis.text.x = element_text(size = 6.5),
        panel.grid.minor = element_blank(),
        plot.subtitle = element_text(size = 8))
ggsave("figures/kk-index-b/lda/lda-topic-terms.png", p,
       width = 10, height = 7, bg = "white")
cat("wrote figures/kk-index-b/lda/lda-topic-terms.png\n")
