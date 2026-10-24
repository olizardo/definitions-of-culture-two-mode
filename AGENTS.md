# Project memory — definitions-of-culture-two-mode

Two-mode network analysis of Boroch's KKCC classification (Kroeber & Kluckhohn Culture
Concepts), from `ROBAFC-5.1.pdf` (Robert Boroch, "A Formal Concept of Culture in the
Classification of Alfred L. Kroeber and Clyde Kluckhohn", Analecta). Data hand-transcribed
from the PDF via pdftotext -layout.

## Project layout (reorganized 2026-10-24)

- Scripts are in `scripts/`. Bare script names elsewhere in this file mean `scripts/<name>`.
  Scripts use paths relative to the project root, so run them from there.
- Source PDFs and the Archive text are in `documents/` (`ROBAFC-5.1.pdf`, `Kroeber-kluckhohn.pdf`,
  `ED229292.pdf`, `pdfcoffee.com-…pdf` (tracked in git), `kroeber-amp-…_compress.pdf` (untracked, byte-identical to the pdfcoffee copy), `papersofpeabodymvol47no1peab_djvu.txt`; the last is gitignored).
  Page-image checks use `Kroeber-kluckhohn.pdf` (ABBYY, 219 pp.); see the 2026-10-24 section below for page offsets.
  Read `documents/...` for the PDF paths below.
- Deleted as stale (recoverable from git history): `analysis-basic-stats.R` (superseded by inline
  chunks in the report), legacy `analysis-ca-mst.R` and its `kkcc-ca-*-lcc.csv` / `*-2core.csv`
  outputs, and the unused `kkcc_biadjacency.csv` and `kkcc_definition_attributes.csv`.
- `docs/` holds PROVENANCE.md and TODO.md. `figures/` and `data/` are unchanged.

## Data provenance

- **Table 2** (frequential analysis, pp. 66–71 of PDF text): concept categories (rows) x
  definition groups A–G (columns), cells hold definition codes. Transcribed in R and
  verified row-by-row against the printed "Number of uses".
- **Table 1**: group typology — A descriptive, B historical, C normative (C1 rule/way,
  C2 ideas/values), D psychological (D1 adjustments, D2 learning, D3 habits, D4 psychology),
  E structural, F genetic (F1 artefact, F2 ideas, F3 symbols, F4 other), G incomplete.
- Appendix definition tables give author/year/source-page per code. Code inventory:
  author/year/decade now extracted from the PDF appendix by `build-definition-years.R`
  into `data/kkcc-definition-years.csv` and attached as node attributes (author, year,
  decade) on definition vertices of BOTH rds graphs. Year = the
  quoted edition year (the one before "source-page"); year_orig keeps re-edition years
  like A5 "(1929)13, 1931"; year_suffix (the "a" in "1945a:") disambiguates same-year
  works in the bibliography. One NA by design: D3-1 Tozzer (PDF says "data", footnote
  "missing (before 1930)"). F4-6 is RESOLVED (inferred): Boroch's Table 2 "F4-6" is an
  off-by-one slip for his own F4-5 = Kluckhohn & Kelly 1945a: 87 — evidence: K&K Part II
  F-IV has exactly 5 definitions, all 5 (F4)-tagged works appear in the Supplement
  Bibliography, K&K's concept index "acting, A-8, C-I-3, C-I-17, F-IV-5" matches
  Boroch's ACTING row cell-for-cell, and F4-5 occurs nowhere in Table 2.
  CAVEAT (2026-10-23, later same day — supersedes the "structural omissions" reading):
  Boroch's Table 2 is almost certainly a transposition of K&K's own "Index B: Conceptual
  elements in definitions" (monograph p. 74). Of the 39, only 27 texts contain NONE of
  the 56 notion words lexically (verified for D1-10, F1-2); 12 do contain notion words
  (A21, A22, B17, B23, C1-7, C1-9, C1-12, C1-19, C1-22, F1-17, F2-12, F4-5). Verified
  split of mechanisms: (a) some are quotes K&K NEVER NUMBERED — A21 Herskovits 1948:625
  (K&K index numbers only A-18/A-19 for 1948), B17 Jacobs & Stern (only B-16), B23 Radcliffe-Brown (only B-22), C1-7 Gillin &
  Gillin (only C-I-6) — hence no Index B entry at all; (b) D1-10 (Ford 1942) and
  F-I-1a (Willey 1927b) ARE in Index B but only under element headings Boroch's
  56-row vocabulary omits ("societal problems/problem-solutions/solving/success of
  responses"; "adaptation to environment/man-made environment") — so in K&K's own terms
  they DO have concept ties. So Table 2's 135 = definitions with ≥1 Index-B element
  falling inside Boroch's reduced 56-notion vocabulary; the 39 are a mix of unnumbered
  K&K quotes and vocabulary-reduction casualties. Rebuilding incidence directly from
  K&K Index B (in K&K numbering) would be the complete dataset — a different provenance
  than Boroch's Table 2.
  Superseded 2026-10-24: attributes are now attached by scripts/build-two-mode-networks.R
  (see the 2026-10-24 rebuild section); the old patch-in-place steps were removed.
- Code inventory:
  A1–A22 + variant A10a; B1–B23; C1-1..C1-22 + C1-5a; C2-1..C2-6; D1-1..D1-17, D2-1..D2-16,
  D3-1..D3-3, D4-1..D4-2; E1–E10; F1-1..F1-21, F2-1..F2-12, F3-1..F3-5, F4-1..F4-6; G1–G7.
- Table 2's "TOTAL USES" counts uses WITH multiplicity; binary matrices deduplicate.
- Table 2 rows mix 16 main categories (caps) and 40 auxiliary notions; main-category row
  excludes its auxiliaries (e.g., SOCIAL 58 + Socially 10 = printed total 68).
- Table 2 vs Boroch's own appendix (checked 2026-10-23 against ROBAFC-5.1 pdftotext):
  39 codes appear in his appendix definition tables but NOWHERE in Table 2 — A21, A22,
  B17, B23, C1-7, C1-9, C1-10, C1-12..C1-15, C1-19..C1-22, C2-1, D1-10 (Ford 1942),
  D4-1, E4, E5, F1-2 (Willey 1927b), F1-6, F1-11, F1-12, F1-17..F1-19, F1-21, F2-2,
  F2-3, F2-6, F2-12, F4-1, F4-2, F4-4, F4-5, G1, G3, G6. Count: appendix 171 − 132
  shared = 39. Table 2 columns A10a, C1-5a, F4-6 have no appendix entry (171 − 135 = 36
  was wrong). Mechanism (verified for D1-10 and
  F1-2): their definition texts contain NONE of the 56 notion categories, so they can't
  appear in any Table 2 cell; they are structural omissions, not transcription errors
  (Table 2 extraction matches our 135 exactly, modulo F4-6 slip and A10a/C1-5a variants).
  So the 135-code universe < Boroch's appendix (171 codes, no variants) < K&K's ~300.
  Cross-check with Moore 1980 (ED229292.pdf in project root, Colleen A. Moore literature
  review): of her 46 quoted citations, 43 match author+year in the 135; Small "1908" is
  D1-1 cited to a 1908 printing; Ford 1942 = K&K D-I-10 / Boroch appendix D1-10; Willey
  1927b = K&K F-I-1a / Boroch appendix F1-2 (both verbatim-quoted by Moore). K&K's
  appendix prints Ford 1942 quote pages as 333, 337 while Boroch and Moore print 555, 557.

## Main reference network (as of 2026-10-23)

- **Collapsed 16 main categories x 135 definitions**, ties = union of auxiliaries into
  parent, binarized: `data/kkcc_biadjacency_main.csv`, `data/kkcc_two_mode_main.rds`
  (301 edges, density 0.139, connected).
- Fine-grained 56 x 135 version kept in `data/kkcc_two_mode.rds` with attributes
  (is_main, parent_category, def_group, def_type on the igraph graph). Rebuilt 2026-10-24: no def_attrs
  element any more; use `scripts/kkcc-definition-attrs.R`.
  DOING row omitted (singleton, per user). No zero-use rows in the current network (checked 2026-10-24).
- Analysis scripts: basic stats are inline chunks in the report (`analysis-basic-stats.R` was
  deleted 2026-10-24), the collapse step (now in `build-two-mode-networks.R`; `analysis-collapse-main.R` was removed 2026-10-24),
  `analysis-ca-mst-main.R` (CA via eigen() per tm-ca.html — Z.v scores = unit-variance
  eigenvectors x sqrt(lambda); passive type barycenters radially stretched from origin
  by BARY.SCALE=5 (purely visual, to clear the concept cluster);
  Breiger projections + make.max.st Kruskal max spanning trees via ggraph).
  The legacy fine-grained `analysis-ca-mst.R` was deleted 2026-10-24. Figures in `figures/`, CA score CSVs
  in `data/`. Convention: base pipe, ggplot2, labeled code cells in the Quarto report
  `kkcc-two-mode.qmd` (renamed from kkcc-basic-stats.qmd). The report now contains the
  basic-stats sections PLUS sections for CA, MSTs, backbones, centrality/prestige,
  mean scores by node attributes, and definition provenance (Supplement Bibliography
  matching + F4-6 resolution, anchor sec-provenance); analysis sections `source()` the
  scripts above at
  render time (backbone's Monte Carlo output is wrapped in capture.output).
  `analysis-backbone-main.R` (FDSM backbones of both weighted projections via
  backbone::backbone_from_projection, alpha=0.10, trials=10000; SDSM rejected as too
  conservative here; figures kkcc-backbone-main-{concept,definition}.png).
  `analysis-centrality-prestige-main.R` (Borgatti-Everett closeness/betweenness with
  two-mode normalizations — definitions are the LARGER set so formulas swapped vs
  Southern Women tutorial; prestige via tm.status biHITS + cross-checks
  (dual projection, SVD, eigen, Faust duality) + PageRank family
  (co-HITS, BGRM, BiRank); CSVs kkcc-centrality-main.csv,
  kkcc-prestige-{concepts,definitions}-main.csv,
  kkcc-score-means-by-{type,subgroup,decade}.csv).
  `build-definition-texts.R` (full definition text per code from the PDF appendix into
  data/kkcc-definition-texts.csv; handles wrapped citations, marginal cross-refs
  ("or gr. B", "; or D1", "(N. sentence)"), roman-numeral/wrapped page numbers,
  author continuations ("Moore," / "and Kelly, 1945a: 82"), merged running headers;
  F4-6 is NA (no appendix entry); ligatures (ﬁ→fi) normalized).
  `build-supplement-bibliography.R` (parses the article's Supplement Bibliography,
  pp. 94-99, into data/kkcc-supplement-bibliography.csv — 163 entries with year,
  year_suffix, year_quoted (parenthesized re-edition; NOTE: bibliography convention is
  bare year = first publication, paren = edition quoted, MIRRORED vs the appendix's
  "(1929)13, 1931" style), authors_raw (surnames), tag (group A-G), footnote,
  reference; matches each of the 135 definition codes to its entry by group tag +
  surnames + year/suffix into data/kkcc-definition-biblio.csv (match_status:
  auto/manual D3-1/inferred F4-6=B103), fills F4-6's author/year/decade into the
  years CSV, and attaches vertex attributes bib_entry, author_canonical, bib_ref to
  definition vertices of BOTH graphs (plus def_attrs columns). Superseded 2026-10-24: the graph
  attachment was removed; the CSVs are inputs to `build-two-mode-networks.R`.
  Gotchas hit while parsing: R's TRE mis-parses "[?]"-style classes (use perl=TRUE);
  gregexpr+sub(sub,"") erases the whole match — post-process the match text instead;
  scan.authors needs (?![[:alpha:]]) after initials so title capitals don't match.

## Environment

- renv initialized (renv.lock, .Rprofile, project library, R 4.5.3, PPM bookworm
  binaries). backbone 3.0.4 is locked and installed in the project library; after
  installing anything new run `renv::snapshot()`. R session must be restarted to
  activate renv.
- Decade means (kkcc-score-means-by-decade.csv) use the quoted edition year; sample is
  thin at the margins (1870s/1900s/1910s have 1-2 definitions each; 1940s n=71 since
  F4-6 was assigned to Kluckhohn & Kelly 1945a).

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
- R default regex is POSIX TRE: inside a bracket class, `\s` is a LITERAL backslash-s,
  so `[,\s]` matches comma, backslash, or the letter "s" (it silently turned
  "Burgess" into "Burge"). Use `[[:space:]]` in classes; `\s`/`\d` shorthands only
  outside brackets (or use perl=TRUE).
- PDF appendix parsing (pdftotext -layout): citation years can wrap to their own line
  or attach to author continuation lines; entries also split mid-word ("Radcliffe– /
  Brown"). Column gaps (2+ spaces) separate author from definition text; sub() with a
  capture group drops the matched text, so extracting a leading token needs ".*$"
  appended to the pattern.
- More TRE regex traps (build-definition-texts.R): `\\.` does NOT match a literal
  period in default TRE (use `[.]` or perl = TRUE); pdftotext running headers contain
  the ﬁ ligature ("Classiﬁcation"), so normalize ligatures BEFORE matching header
  text; wrapped table titles ("...deﬁni- / tions") and right-margin-merged banners
  ("...text. Robert Boroch") need both line-level filters and final-substring cleanup.
  When adding perl=TRUE programmatically, beware lines whose call is followed by a
  trailing comment (regex-anchored injection misses them).
- K&K scan OCR traps, verified against page images. Do NOT add general rules for these:
  - `j` is printed as both 3 and 5 on the scan; it is unmapped and tokens with `j` stay
    unresolved until checked (`D-III-j` = D-III-3, `B-ij` = B-13, `D-II-j` = D-II-5).
  - A trailing variant `a` is read as `3` (`A-103` = A-10a, `C-I-53` = C-I-5a).
  - A dropped roman `I` (`C-18` = C-I-8, `F-14` = F-I-4) and a truncated last digit
    (`D-I-1` for D-I-12) are common. Check against the page image.
- The parser keeps unparseable code tokens as rows with `kk_code` NA. Manual fixes are applied
  before the edge deduplication, which keys on kk_code + heading + sub_element.
- `norm_roman()` in `build-index-b.R` replaced H with I after the other substitutions, so
  "IH" became "II" (D-IH-2 and F-IH-2 were wrong). Fixed 2026-10-24 by returning III for IH/lH
  first. Check any new roman-slot token that contains H.
- Manual-fix actions: `set` (kk_code), `unresolve` (kk_code NA), and `rename_sub` (sets
  `new_sub_element`; keeps the code and flags; applied in `apply_index_b_fixes()`). Keys must match
  the full parsed token table, not the exported `kk-index-b-edges.csv`, which keeps resolved codes
  only. Unresolved tokens are absent from that export. A key with no match stops the build.
- Page mapping: our scan's PDF page = printed page + 3 (PDF 77 = printed 74). The 229-page copy is printed + 6 (see the 2026-10-24 section). The Archive Scribe
  scan is printed + 16 (PDF 90 = printed 74). The Archive scan's left column is clipped at the scan
  edge, so its text loses leading characters: use it only as a lead.
- Pixel crops: `pdftoppm -r DPI -x X -y Y -W W -H H` takes pixels (points × DPI / 72). Coordinates
  from `pdftotext -bbox` are in points.
- Resolving a token from printed sequence plus the candidate's absence from the edges is a
  page-image inference: state the basis in the manual-fix evidence column.

## Related fix upstream

- Corrected the same knn recycling bug in the course tutorial
  `/home/omarlizardo/projects/ACADEMICS/SOCIOL208/tm-basic.qmd` (knn.p now uses
  `rep(colSums(A), each = nrow(A))`; knn.g uses `t(A) %*% rowSums(A)`). Other SOCIOL208
  pages checked; only tm-basic had the bug.

## K&K Index A/B dataset (updated 2026-10-24)

- Pipeline, in order: `build-index-b.R` → `build-index-b-crosswalk.R` → `analysis-index-b.R`.
  It parses `Kroeber-kluckhohn.pdf` (ABBYY OCR of the 1952 scan). Outputs:
  `data/kk-index-a-authors.csv`, `kk-index-b-edges.csv` (resolved codes only),
  `kk-index-b-unresolved.csv`, `kk-index-b-definitions.csv`, `kk-index-b-ocr-corrections.csv`,
  `kk_biadjacency_*`, `kk-boroch-crosswalk.csv`. The crosswalk matches Boroch's codes to K&K
  by author, year, group, and subgroup, never by position.
- Page-image corrections are NOT hand-edited into outputs. They are in
  `data/kk-index-a-manual-fixes.csv` (author_raw, raw_code → kk_code, author_new,
  qualifier_new; blank = unchanged) plus `data/kk-index-a-missing-rows.csv` (rows the OCR text
  layer omits), and
  `data/kk-index-b-manual-fixes.csv` (heading, sub_element, ocr_raw → kk_code; `NA` means
  unresolved). The build applies them and errors if a key matches no token. Add corrections
  there, then rebuild. Copy key strings from the parsed edges file, not from the PDF.
- `data/kk-index-b-flagged-audit.csv`: verdicts (OK / OKH / OKJ / FIX / CHECK) for the 138
  flagged edges, keyed to the printed page evidence.
- Current counts (rebuilt 2026-10-24, after the Index A page-image pass): Index A 187 rows
  (186 resolved, 165 codes; `kk-index-a-missing-rows.csv` adds Angyal). Sears's `C-I-Addendum`
  stays unresolved. Index B 1285 edges (10 code_not_in_index_a, 0 junk_name, 210 ocr_corrected,
  99 manual_fix, 966 ok; the 33 junk names were resolved 2026-10-24); 2 unresolved (`D-I` excluded as a duplicate, `F-I\` smudged). Crosswalk (updated 2026-10-24): 127 auto, 7 hand decisions
  (see the 2026-10-24 section), 1 F4-6, 0 ambiguous, 0 unmatched. Hand decisions are in
  `kk-boroch-crosswalk-decisions.csv`.
- Index A manual fixes now carry `author_new` and `qualifier_new` as well as `kk_code`. Blank means
  unchanged. Keys are author_raw + raw_code; copy them from `kk-index-a-authors.csv`.
- Gotcha: `build-index-b-crosswalk.R` used to pick up a stale `index_a` from the session when it
  was run without the build. Scripts must read their inputs from files. Verify by rebuilding in
  a fresh environment after any change.
- Audit scope: the 138 flagged edges, all 198 OCR-corrected edges
  (`data/kk-index-b-ocr-audit.csv`), the 32 recovered j/fragment tokens and the 8 unresolved
  tokens (`data/kk-index-b-zoom-check.csv`) were checked against the printed pages of the scan
  (Index B = PDF pp. 77-81). 915 `ok` edges have no audit verdict (PROVENANCE 3.3); the 50-row
  ok-sample was checked 2026-10-24 (all 50 OK, Clopper-Pearson 95% upper bound 7.1%; the sample's
  heading column predates the heading corrections, so verdicts were scored against the current
  edges). The OCR-corrected
  audit was read at 200 dpi and the recoveries at 300-400 dpi, by one reader; there is no
  double-keyed check. Do not describe the dataset as fully verified.
- 2026-10-24 zoom pass: the 10 code_not_in_index_a and 33 junk_name codes were checked against our
  scan's page images (printed pp. 74-78). The 8 unresolved tokens were zoomed at 400-600 dpi. Six
  resolved: `A-q`→A-9, `F-i`→F-I-6, `F-U`→B-21, `F-I-i}`→F-I-13, `F-H-j`→F-II-5, `A-j`→A-5. For
  `F-U`, `F-I-i}`, `F-H-j` and `A-j` the glyph is not clearly read, so the basis is printed sequence
  plus the candidate's absence from the edges. Recorded in `data/kk-index-b-manual-fixes.csv`
  (evidence column) and `data/kk-index-b-second-scan-check.csv`.
- Heading corrections are applied in `build-index-b.R` (`apply_heading_corrections()`, 2026-10-24),
  from the block map `data/kk-index-b-block-map.csv`: `capabilities` (73) → carriers of culture;
  `history` (50) → ideas and cognitive processes; `civilization` → common or shared patterns except
  the five "civilization" elements (A-1, A-3, B-17, D-I-2, F-I-3); `symbols` → systems where the element
  starts with "systems" (12); `feelings` (1) → forbidden, the; `people, a` (1) → permitted, the.
  174 parsed rows re-headed (173 distinct edges after dedup; G-3 is printed twice in that block); the edge
  total is still 1285. Several first elements also carried the block
  heading in their names (e.g. "carriers of culture-individuals"); these are renamed to the printed
  element. One reader, no double-keying. The "social" and "society" entries under group reference are
  not errors (both print there). Also 2026-10-24: `adjustive-ajjptive` → `adjustive-adaptive` and
  `process ts and means` → `processes and means` are OCR heading variants, renamed in the same step.
- Junk element names and labels (2026-10-24): `data/kk-index-b-junk-decisions.csv` (39 rows, PROVENANCE 3.6)
  maps the 33 junk_name edges and six single-letter manual_fix edges to printed elements. Garbled labels are
  fixed by `rename_sub` rows: intercorrelated customs, man-made environment and selection (checked on the scan);
  distorted satisfaction, integrated and unintegrated groups, non-physiological products, not created,
  reaction-formations, constitutional charters, categories of actions, and the prefix removals adjusting,
  biopsychological organism, rational. All label fixes were checked on the scan 2026-10-24; six printed as
  proposed, but "constitutional changes" was WRONG — the print reads "constitutional charters, A-13"
  (600 dpi), corrected and rebuilt (PROVENANCE 3.6).
- Machine cross-check (2026-10-24, PROVENANCE 3.7): `scripts/check-index-b-blocks.R` puts 1268 of 1285 edges in
  their assigned printed block. The 17 others are in `data/kk-index-b-block-check-review.csv` with provisional
  verdicts (final 2026-10-24): 16 OK, 1 CODE_WRONG (B-11 under process is a misread of B-21, fixed by a
  `set` row keyed on "process ts and means"; pipeline rebuilt, 1285 edges unchanged). The CHECK crops were wrong
  (the crop locator fell back to the column top), so they need regenerating. This is not a human reader.
- Rights: `data/kkcc-definition-texts.csv` holds verbatim Boroch quotations and stays out of
  any release. Whether the K&K Index B element labels can ship is still undecided. The page-image
  checks used an unofficial scan copy that is not in the repo. Cite printed page numbers, not
  that copy.
- Open decisions: the 2 remaining unresolved tokens need a better source; decide the rights questions above. A second reader
  should check `F-U`, `F-I-i}`, `F-H-j` and `A-j`.
- Index B recoveries (2026-10-24): `j` tokens were resolved only where the printed entry under
  that sub-element had one candidate (e.g. "carriers" prints C-II-3 and no C-II-5). The printed
  candidate check is per sub-element, not per printed page; treat as a page-image inference.
- `F-19` in the "behavior" entry is printed without the roman I; read as F-I-19 (the adaptive
  behavior entry under adjustive-adaptive confirms it).
- Documentation: `README.md` (data dictionary, methods, limitations, rights) and
  `docs/PROVENANCE.md` (evidence for F4-6, appendix-only codes, Moore, OCR rules). Both were
  updated on 2026-10-24.
- 2026-10-24 rebuild: both networks are built by `scripts/build-two-mode-networks.R` as igraph 2.3.3
  objects with node attributes (concept: is_main, parent_category, list_item, printed_uses, n_uses;
  definition: def_group, def_subgroup, def_type, author, year, decade, bib fields). The concept-to-category
  mapping comes from `scripts/build-concept-categories.R`. `check-two-mode-networks.R` validates the result.
  The fine network is disconnected by design (7 components); the main network is connected.
  `analysis-collapse-main.R` was removed; the step it performed is in the builder.
- K&K Index B networks (2026-10-24): `scripts/build-index-b-networks.R` builds igraph objects
  `data/kk-index-b-subelement-network.rds` (465 sub-elements x 174 codes, 1171 ties) and
  `data/kk-index-b-heading-network.rds` (53 headings x 174 codes, 1059 ties), each list(biadjacency, graph).
  Counts as of 2026-10-24 after the label fixes (before the heading correction: 472 x 1193 and 51 x 1058). Code vertices carry the Index A/B flags, authors, and the Boroch code (Table 2 crosswalk plus linked
  appendix-only codes; F-IV-5 carries both F4-5 and F4-6). Element vertices carry headings, junk-name,
  manual-fix and OCR-correction flags. Matrices match the kk_biadjacency_*.rds files exactly.
  Heading attribution is corrected (see the K&K Index A/B section); the remaining heading-level caveat
  is the single-reader check.

## Second pass (2026-10-24): Index A verification and crosswalk

- Every Index A row on printed pp. 73-74 (PDF pp. 76-77) was re-read at 200 dpi, with 300 dpi
  crops for disputed lines. 30 manual-fix rows (codes, years, author names) and 1 missing row
  (Angyal B-14 1941, absent from the OCR text layer) were added. Index A is now 187 rows, 186
  resolved, 165 codes. Key OCR errors to watch for: `Blumenthal • Boas` and `Carver < 1935)-Couru`
  (merged entries), `Hiller * Hockett`, `Tumey-High` (Turney-High), `Thumwald` (Thurnwald), and
  year OCR like `(19 11)`, `(19:8)`, `(194$)`. The original `ok` flag does not mean verified.
- Printed facts now confirmed on the page image: Thurnwald A-20 (1950), not 1930; Wissler A-2
  (1920), not A-1; Thomas C-II-2 (1937); Young D-I-5 (1934); Kelly F-IV-5 (with Kluckhohn, 1945a),
  which corroborates the F4-6 resolution; Henry B-21 (1949); Slotkin D-II-15 (1950); Dollard E-2.
- Crosswalk (`build-index-b-crosswalk.R`) now reads `kk-index-a-authors.csv` itself. It also strips
  initials from Boroch surnames ("A. Davis"), requires a Boroch suffix (a/b) to match when given,
  and accepts `year_orig` (first publication). Result: 127 auto, 2 hand decisions, 4 ambiguous,
  1 no match. Hand decisions go in `data/kk-boroch-crosswalk-decisions.csv`: D3-1 → D-III-1
  (Tozzer, no year; moderate confidence) and D2-16 → D-II-16 (quoted text "socially transmitted
  behavior"; Aberle has no Index A row). Open rows A16, A17, A20, C1-11 and B5 were resolved on
  2026-10-24 (see the 2026-10-24 section below). Positional agreement is 69 of 135,
  which is expected given renumbering.
- Index B codes printed without a roman numeral: `C-7`, `D-8`, and `F-9` were verified at
  300 dpi as printed that way. They are kept as printed, not remapped. `D-7`, `D-5`, `F-4`,
  `E-17` are kept too; verified on the page image at 200 dpi on 2026-10-24, not at 300 dpi.
- Index B edge count is 1285 (1279 before the 2026-10-24 resolutions). 10 edges (8 codes) are not
  in Index A.
- Two public Internet Archive copies of the 1952 monograph (Peabody Papers vol. 47 no. 1) were
  located and checked. `culturecriticalr0000kroe_z3a4` has a Scribe OCR text PDF (252 pp.) and a
  `_djvu.txt` (882 KB). `culture0000unse` is access-restricted and its text returns HTTP 401.
  A text file copy, `documents/papersofpeabodymvol47no1peab_djvu.txt`, is gitignored
  (`documents/*_djvu.txt`). Do not commit or release it: rights are unresolved. Downloaded PDFs and text are in the scratch directory.
- Independent OCR: tesseract 5 (eng) is installed. Run at 300 dpi on the Archive PDF, it agreed
  with every corrected Index A row checked. The Archive's OCR is weaker than ours on Index A
  (digit and i/1 confusions, wrapped Kluckhohn/Kelly lines lose their author), so disagreements
  with it are leads, not evidence against our rows.
- Open items are tracked in `docs/TODO.md`. Remaining work: the 2
  unresolved Index B tokens, the sub-element check
  of the remaining ~1100 edges, a human second reader, and the rights decision.
  Junk names, the heading and label fixes, and the `analysis-index-b.R` rerun were done on 2026-10-24.


## Appendix-only texts, crosswalk decisions, page checks (2026-10-24)

- The 39 appendix-only codes (PROVENANCE section 4; the earlier "36" is stale): texts in
  `data/kkcc-appendix-only-texts.csv` (author, year, suffix, verbatim text; B17 and F4-5 authors
  fixed by hand). Links in `data/kkcc-appendix-only-links.csv`: 32 linked (25 by a unique row,
  7 year-checked on page images), 3 with no Index A row (C1-20 Maquet; F1-21, which has no group-F
  row; G1 Sapir, whose only Index A row is B-2), C1-22 Sears → C-I-Addendum (resolved 2026-10-24:
  printed addendum in C-I, verbatim text match, citation read on page image), 0 unresolved, 0 ambiguous. Decided 2026-10-24: A21 → A-19, C1-12 → C-I-11,
  C1-13 → C-I-12.
- Table 2 hand decisions (7, all in `kk-boroch-crosswalk-decisions.csv`): D3-1, D2-16 (earlier),
  A16 → A-14, A17 → A-15, A20 → A-18, C1-11 → C-I-10, B5 → B-4a. Basis: a verbatim match
  between Boroch's text and the printed Part II quotation, plus the printed citation. The printed
  item number is the K&K code within the group (items 14, 15, 18 on printed p. 44 = A-14, A-15,
  A-18; item 10 on p. 50 = C-I-10).
- Myres B-4a: Part II prints "4a. Myres, 1927: 16." (printed p. 47), and Index A prints "(1929)"
  (printed p. 73). User decision 2026-10-24: 1927 is the working year, supported by the Google Books
  record for the original book (Abingdon Press, 1927; metadata only). The Index A transcription
  stays as printed. No script reads the Myres index year.
- The year conflicts flagged for seven appendix-only codes (A22, C1-9, C1-10, E5, F2-3, F2-12,
  F4-2) were OCR errors in our raw text layer (it read 1943 for Linton 1945, 1931 for Schmidt
  1937, 1930 for Becker 1950, 1930 for Thurnwald 1950, 1913 for Ostwald 1915). The printed years
  agree with Boroch and Index A. Do not take years from the raw text layer without a page check.
- Page offsets. `Kroeber-kluckhohn.pdf` (ABBYY): printed = PDF − 3 (checked on printed 17, 44,
  46, 50, 61, 62, 66, 67, 70). The 229-page copy (`…_compress.pdf`): printed = PDF − 6 (checked on
  printed 35, 37, 44, 50, 53). `data/kk-page-map.csv` holds checkpoints only. An automatic map was
  not built: the ABBYY text layer has no running headers, and the copy's text-layer page count
  does not match pdfinfo, so use `pdftoppm` numbering for the copy.
- Index A printed pp. 73-74 = PDF 76-77 in the scan.
- Gotchas:
  - `build-definition-texts.R` `grab()` calls `grepl(JUNK, ...)` with a vector of patterns, so only
    the first pattern is used, and R warns on every line. The committed texts are unaffected: a
    rebuild matched exactly, because later cleanup removes the same headers. The filter is still
    not doing what it says; fix it by testing each pattern, not the first.
  - Searching page text with `awk -v RS='\f'` finds the page, but short phrases also match
    footnotes. The B5 search first hit "horticulture" in a footnote on printed p. 36. Confirm on the
    image.
  - The copies of the book in `documents/` are the same text. Each new copy needs a page offset of
    its own, so do not assume an offset from another copy.
- Rights: `data/kkcc-definition-texts.csv`, `data/kkcc-appendix-only-texts.csv` and the Part II
  quotations in PROVENANCE are verbatim quotations of Boroch or K&K. They stay out of any release.
  `pdfcoffee.com-…pdf` is tracked in git; the untracked `…_compress.pdf` is the same file. Do not
  commit more copies; whether to remove the tracked one is an open decision.

## Session 2026-10-24 (later): rebuilds, coverage limits, block map

- Concept mapping: `scripts/build-concept-categories.R` writes `data/kkcc-concept-categories.csv`
  (56 concepts → 16 categories) from the printed list in Boroch section 3.2.2, items a)–p). Parents are not
  taken from row position (auxiliaries such as "Habit" print before their parent). DOING (item q) has no row.
- Two-mode networks rebuilt by `scripts/build-two-mode-networks.R` (igraph 2.3.3 objects; rds = list(biadjacency,
  graph)). Fine: 191 vertices, 316 edges, 7 components by design. Main: 151 vertices, 301 edges, connected.
  Definition attributes come from the years and biblio CSVs; verbatim texts are not embedded.
  `scripts/check-two-mode-networks.R` validates the result. `def_attrs` is no longer stored in the rds;
  read it with `scripts/kkcc-definition-attrs.R` (`subgroup_code` is the full code, which the
  subgroup regex depends on). `analysis-collapse-main.R` was removed (git history only).
- The patch-in-place steps are removed from `build-definition-years.R`, `build-supplement-bibliography.R`
  and `build-definition-texts.R`; they now use the fine matrix's columns as the code universe.
- Regression check after the rebuild: centrality, prestige and score-mean CSVs match HEAD after sorting; the
  CA scores are unchanged. The report renders from a scratch copy with text unchanged apart from
  script paths; the committed `kkcc-two-mode.html` was updated. `figures/kkcc-mst-main-definition.png`
  changed bytes but looks the same on inspection; the cause is not identified.
- Text data: 135 Boroch Table 2 texts (F4-6 has none) and 39 appendix-only texts. Of the 174 distinct K&K codes
  in Index A/B, 163 link to a Boroch text; 11 do not (C-7, C-I-18a, D-5, D-7, D-8, D-III-4, E-17, F-4, F-9,
  F-I-20, G-1). K&K Part II definitions outside the index are not covered (the earlier estimate of about 300
  total is unverified).
- C1-22 resolved: K&K's printed addendum to C-I (Sears 1939, 78–79; PDF p. 54, printed p. 51 by the folio on
  the page image). Index A's `C-I-Addendum` is the label; the addendum is unnumbered.
- Concept links exist only for two sources: Boroch's Table 2 (135 definitions × 56 notions; Boroch's
  categories) and K&K Index B (169 codes; K&K sub-elements and headings). Other K&K definitions have no concept
  link in our data. The two networks connect through the crosswalk (130 K&K codes).
- K&K Index B networks: `scripts/build-index-b-networks.R` writes `data/kk-index-b-subelement-network.rds`
  (472 × 174, 1193 ties, 646 vertices, 15 components including 5 isolated codes) and
  `data/kk-index-b-heading-network.rds` (51 × 174, 1058 ties). Both were built before the 2026-10-24 heading
  correction; the current counts are in the K&K Index A/B section above (465 × 174, 1171 ties; 53 × 174, 1059 ties).
- Heading block map: `data/kk-index-b-block-map.csv` lists the 53 printed blocks on PDF pp. 77–81 (printed
  pp. 74–78). Heading errors found by the comparison: see the heading attribution item above. Sub-element
  verification of the remaining ~1100 edges is open (TODO items 13–17).

