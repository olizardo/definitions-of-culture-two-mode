# Project memory — definitions-of-culture-two-mode

Two-mode network analysis of Boroch's KKCC classification (Kroeber & Kluckhohn Culture
Concepts), from `ROBAFC-5.1.pdf` (Robert Boroch, "A Formal Concept of Culture in the
Classification of Alfred L. Kroeber and Clyde Kluckhohn", Analecta). Data hand-transcribed
from the PDF via pdftotext -layout.

## Data provenance

- **Table 2** (frequential analysis, pp. 66–71 of PDF text): concept categories (rows) x
  definition groups A–G (columns), cells hold definition codes. Transcribed in R and
  verified row-by-row against the printed "Number of uses".
- **Table 1**: group typology — A descriptive, B historical, C normative (C1 rule/way,
  C2 ideas/values), D psychological (D1 adjustments, D2 learning, D3 habits, D4 psychology),
  E structural, F genetic (F1 artefact, F2 ideas, F3 symbols, F4 other), G incomplete.
- Appendix definition tables give author/year/source-page per code. Code inventory:
  A1–A22 + variant A10a; B1–B23; C1-1..C1-22 + C1-5a; C2-1..C2-6; D1-1..D1-17, D2-1..D2-16,
  D3-1..D3-3, D4-1..D4-2; E1–E10; F1-1..F1-21, F2-1..F2-12, F3-1..F3-5, F4-1..F4-6; G1–G7.
- Table 2's "TOTAL USES" counts uses WITH multiplicity; binary matrices deduplicate.
- Table 2 rows mix 16 main categories (caps) and 40 auxiliary notions; main-category row
  excludes its auxiliaries (e.g., SOCIAL 58 + Socially 10 = printed total 68).

## Main reference network (as of 2026-10-23)

- **Collapsed 16 main categories x 135 definitions**, ties = union of auxiliaries into
  parent, binarized: `data/kkcc_biadjacency_main.csv`, `data/kkcc_two_mode_main.rds`
  (301 edges, density 0.139, connected).
- Fine-grained 56 x 135 version kept in `data/kkcc_two_mode.rds` with attributes
  (is_main, parent_category, def_group, def_type on graph; def_attrs data.frame).
  DOING row omitted (singleton, per user); Behaving/Industry are zero-use rows.
- Analysis scripts: `analysis-basic-stats.R` (tm-basic.html style stats),
  `analysis-collapse-main.R` (builds collapsed network),
  `analysis-ca-mst-main.R` (CA via eigen() per tm-ca.html — Z.v scores = unit-variance
  eigenvectors x sqrt(lambda); passive type barycenters radially stretched from origin
  by BARY.SCALE=5 (purely visual, to clear the concept cluster);
  Breiger projections + make.max.st Kruskal max spanning trees via ggraph).
  Legacy fine-grained script: `analysis-ca-mst.R`. Figures in `figures/`, CA score CSVs
  in `data/`. Convention: base pipe, ggplot2, labeled code cells in the Quarto report
  `kkcc-two-mode.qmd` (renamed from kkcc-basic-stats.qmd).
  `analysis-backbone-main.R` (FDSM backbones of both weighted projections via
  backbone::backbone_from_projection, alpha=0.10, trials=10000; SDSM rejected as too
  conservative here; figures kkcc-backbone-main-{concept,definition}.png).
  `analysis-centrality-prestige-main.R` (Borgatti-Everett closeness/betweenness with
  two-mode normalizations — definitions are the LARGER set so formulas swapped vs
  Southern Women tutorial; prestige via tm.status biHITS + cross-checks
  (dual projection, SVD, eigen, Faust duality) + PageRank family
  (co-HITS, BGRM, BiRank); CSVs kkcc-centrality-main.csv,
  kkcc-prestige-{concepts,definitions}-main.csv,
  kkcc-score-means-by-type.csv).

## Gotchas learned here

- igraph `graph_from_biadjacency_matrix()` creates vertices ROWS FIRST (type = FALSE)
  then columns — setting vertex names/attributes in the wrong order silently corrupts
  the graph (edges appear "within-partition" under as_biadjacency_matrix).
- R recycles vectors column-wise in element-wise matrix ops: `A * colSums(A)` and
  `t(A) * rowSums(A)` misalign unless lengths happen to divide. Use matrix products
  (`t(A) %*% rowSums(A)`) or `rep(..., each = nrow(A))`.
- eigen() signs are arbitrary per decomposition; when computing CA for both modes,
  align definition scores to concept scores via the duality relation before plotting.
- ggsave needs `bg = "white"` with theme_void/theme_minimal or PNGs render checkered.
- Custom graph builders must preserve vertex names (make.max.st bug: empty graph got
  numeric names, breaking color/label lookups downstream).
- Disconnected two-mode graphs give multiple lambda=1 eigen-dims in CA; drop ALL of them
  (pruning to 2-core or collapsing modes fixes connectivity).

## Related fix upstream

- Corrected the same knn recycling bug in the course tutorial
  `/home/omarlizardo/projects/ACADEMICS/SOCIOL208/tm-basic.qmd` (knn.p now uses
  `rep(colSums(A), each = nrow(A))`; knn.g uses `t(A) %*% rowSums(A)`). Other SOCIOL208
  pages checked; only tm-basic had the bug.
