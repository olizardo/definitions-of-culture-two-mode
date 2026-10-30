# Two-mode network data for the Kroeber & Kluckhohn culture definitions

This repository holds coded two-mode (concept × definition) datasets derived from
two sources on the definitions of culture:

1. **Boroch's Table 2** (frequential analysis of the Kroeber & Kluckhohn classification).
   Kept exactly as published: `data/kkcc_two_mode.rds` (56 notions × 135 definitions)
   and `data/kkcc_two_mode_main.rds` (16 main categories × 135 definitions).
2. **K&K Index B** ("Conceptual elements in definitions"), parsed from the scanned
   monograph. Built independently of Boroch's coding: `data/kk-index-b-*.csv` and
   `data/kk_biadjacency_{subelement,heading}.{rds,csv}`.

The two datasets are related but not interchangeable. Boroch's coding is his own
reading of the definitions; K&K Index B is Kroeber and Kluckhohn's own index of
conceptual elements, keyed to K&K's numbering. The crosswalk and audit files relate
the two.

## Sources

- Kroeber, A. L., & Kluckhohn, C. (1952). *Culture: A Critical Review of Concepts and
  Definitions*. Papers of the Peabody Museum of American Archaeology and Ethnology,
  Harvard University, 47(1). Scanned copy used: `documents/Kroeber-kluckhohn.pdf` (ABBYY
  FineReader 11 OCR, 2013). Index A ("Authors", monograph p. 73) and Index B
  ("Conceptual elements in definitions", pp. 74–78) are parsed from this copy.
- Boroch, R. "A Formal Concept of Culture in the Classification of Alfred L. Kroeber
  and Clyde Kluckhohn." *Analecta*. File: `documents/ROBAFC-5.1.pdf`. Table 2 and the definition
  appendix are hand-transcribed (see `docs/PROVENANCE.md`).
- Moore, C. A. (1980). Literature review on culture definitions. ERIC ED229292
  (`documents/ED229292.pdf`). Used as an external cross-check of author–year citations.

## Files

| Script | Reads | Writes |
|---|---|---|
| `build-index-b.R` | `documents/Kroeber-kluckhohn.pdf` | Index A, Index B, excluded words, definition registry, OCR correction log, biadjacency matrices |
| `build-index-b-crosswalk.R` | Index B outputs, `kkcc_two_mode.rds`, `kkcc-definition-years.csv`, `kkcc-definition-texts.csv` | Boroch ↔ K&K crosswalk, Table 2 audit |
| `analysis-index-b.R` | verified network, works file (`two_mode_graph`), `kkcc_two_mode.rds` | network statistics, works vs definitions degree figure |
| `build-concept-categories.R` | `kkcc_two_mode.rds` (concept labels), Boroch section 3.2.2 (encoded in the script) | `kkcc-concept-categories.csv` |
| `build-two-mode-networks.R` | `kkcc-concept-categories.csv`, `kkcc-definition-years.csv`, `kkcc-definition-biblio.csv`, fine biadjacency | `kkcc_two_mode.rds`, `kkcc_two_mode_main.rds`, `kkcc_biadjacency_main.csv` |
| `check-two-mode-networks.R` | both networks, definition CSVs | nothing (stops on a mismatch) |
| `build-index-b-networks.R` | `kk-index-b-edges.csv`, `kk-index-b-definitions.csv`, `kk-boroch-crosswalk.csv`, `kkcc-appendix-only-links.csv` | `kk-index-b-subelement-network.rds`, `kk-index-b-heading-network.rds` |
| `build-index-b-verified.R` | `kk-index-b-subelement-network.rds`, `kk-index-b-definitions.csv` | `kk-index-b-verified-network.rds` (the one definitions network every analysis reads), `kk-index-b-excluded-codes.csv` (codes not in Index A, with their sub-elements) |
| `check-index-b-blocks.R` | `documents/Kroeber-kluckhohn.pdf`, `kk-index-b-edges.csv`, `kk-index-b-block-map.csv` | `kk-index-b-block-check.csv`, `kk-index-b-block-check-summary.csv`, `kk-index-b-block-check-review.csv` (earlier 18-row set, previous build), `kk-index-b-block-check-review-current.csv` (page-image verdicts for the current 22 flagged edges, one reader) (machine cross-check of heading assignments; not a human reader) |
| `check-index-b-networks.R` | `kk-index-b-*-network.rds`, `kk-index-b-edges.csv`, `kk-index-b-definitions.csv`, `kk-boroch-crosswalk.csv` | nothing (stops on a mismatch) |
| `kkcc-definition-attrs.R` (helper) | `kkcc_two_mode.rds` | returns the definition table used by the analyses |
| `build-definition-years.R` | Boroch appendix (`documents/ROBAFC-5.1.pdf`) | `kkcc-definition-years.csv` |
| `build-supplement-bibliography.R` | Boroch Supplement Bibliography | `kkcc-supplement-bibliography.csv`, `kkcc-definition-biblio.csv` |
| `build-definition-texts.R` | Boroch appendix | `kkcc-definition-texts.csv` (verbatim; not for release) |
| `build-work-concept-network-index-b.R` | verified network, heading network, `kk-index-b-definitions.csv`, `kk-index-b-name-decisions.csv`, `label-authors-index-b.R` | `kk-index-b-work-concept-network-full.rds` (`two_mode_graph`, `two_mode_heading_graph`, `works`), `kk-index-b-works.csv` |
| `analysis-ca-index-b.R` | verified network | CA of the largest-component 2-core (`lcc_2core()`), MST figures, CA score CSVs |
| `analysis-ca-works-index-b.R` | works file (`two_mode_graph`) | CA of the sub-element × work 2-core (`lcc_2core()`), CA figures, CA score CSVs |
| `analysis-mst-works-index-b.R` | works file (`two_mode_graph`) | Kruskal MSTs of the sub-element and work projections (2-core) |
| `analysis-mst-definitions-index-b.R` | verified network | Kruskal MST of the code projection (2-core) |
| `analysis-centrality-index-b.R` | verified network; works file (`two_mode_graph`) | Two-mode closeness and betweenness on each network's largest component, centrality CSVs |
| `build-index-b-work-citations.R` | `kk-index-b-works.csv`, `kkcc-supplement-bibliography.csv`, `kk-index-b-work-citations-page-checks.csv`, K&K bibliography (`documents/Kroeber-kluckhohn.pdf`) | `kk-index-b-work-citations.csv` (one row per work: K&K and Boroch matches, page-image checks, status) |
| `attach-work-pub-type-index-b.R` | `kk-index-b-work-pub-type.csv`, `kk-index-b-work-concept-network-full.rds` | `kk-index-b-work-concept-network-full.rds` (adds `pub_type` to `works` and to the work vertices of both graphs) |
| `core-index-b.R` (helper) | any two-mode matrix | `lcc_2core()` (largest component, then 2-core) and `sub_work_matrix()` |
| `analysis-ca-mst-main.R` | main two-mode network | CA and Kruskal maximum spanning trees (main network) |
| `analysis-centrality-prestige-main.R` | main network | centrality, prestige and PageRank-family scores |

Scripts live in `scripts/`; `documents/` holds the source PDFs and the Archive text. Run order (from the project root):

1. `scripts/build-definition-years.R`, then `scripts/build-supplement-bibliography.R` (Boroch metadata CSVs)
2. `scripts/build-concept-categories.R` (concept-to-category mapping, from Boroch section 3.2.2)
3. `scripts/build-two-mode-networks.R` (both networks, as igraph objects with node attributes)
4. `scripts/check-two-mode-networks.R` (validation; stops on any mismatch)
5. `scripts/build-index-b.R`
6. `scripts/build-index-b-crosswalk.R`
7. `scripts/build-index-b-networks.R` (K&K Index B sub-element and heading networks, as igraph objects)
8. `scripts/build-index-b-verified.R` (verified sub-element x code network; codes not in Index A are excluded here)
9. `scripts/check-index-b-networks.R` (validation of the Index B igraph objects; stops on any mismatch)
10. `scripts/check-index-b-blocks.R` (machine cross-check of Index B heading assignments against the printed text)
11. `scripts/build-work-authors-index-b.R`, then `scripts/build-work-concept-network-index-b.R` (works file: `two_mode_graph` and `two_mode_heading_graph`)
12. `scripts/analysis-index-b.R`
13. `scripts/analysis-ca-index-b.R` (CA and MST figures for the definitions network), then `analysis-mst-definitions-index-b.R` and `analysis-centrality-index-b.R`
14. `scripts/analysis-ca-works-index-b.R` and `scripts/analysis-mst-works-index-b.R` (works network)
15. `scripts/build-index-b-work-citations.R` (citation table for the works: K&K bibliography and Boroch supplement, with page-image checks; writes `data/kk-index-b-work-citations.csv`)
16. `scripts/attach-work-pub-type-index-b.R` (adds `pub_type` to the works table and both work-vertex sets in the full works file; types are decided per work in `data/kk-index-b-work-pub-type.csv`, with a basis for each row)

The analysis scripts and the report read definition attributes through `scripts/kkcc-definition-attrs.R`.

The Index B build and crosswalk scripts write session-info files to `data/` (`build-index-b-sessioninfo.txt`, `build-index-b-crosswalk-sessioninfo.txt`). The R environment is pinned
in `renv.lock` (R 4.5.3). Requires `pdftotext` (poppler) on the PATH.

## Main networks

Four two-mode networks are the stored Index B data. Projections (for example, the sub-element projection of
the works network, or the code projection of the definitions network) are derived in the analyses, not stored.

| # | network | stored in | nodes | attributes |
|---|---|---|---|---|
| 1 | definitions × sub-elements | `kk-index-b-verified-network.rds` (`graph`, `biadjacency`) | 470 sub-elements, 171 codes | sub-element and code attributes |
| 2 | definitions × headings | `kk-index-b-heading-network.rds` (`graph`, `biadjacency`) | 53 headings, 171 codes | heading and code attributes |
| 3 | works × sub-elements | `kk-index-b-work-concept-network-full.rds`, `two_mode_graph` | 470 sub-elements, 131 works | sub-element and work attributes |
| 4 | works × headings | same file, `two_mode_heading_graph` | 53 headings, 131 works | heading and work attributes |

Where attributes overlap, the values agree across the four networks (checked 2026-10-25). The raw
`kk-index-b-subelement-network.rds` is the build output that the verified network is filtered from.

## Data dictionary

All files are UTF-8 CSV unless noted.

**`kk-index-a-authors.csv`**: K&K Index A (author → numbered definitions). One row per
author–code pair.

| column | meaning |
|---|---|
| `author_raw` | surname as printed (initials kept when printed, e.g. "Ford Clellan S") |
| `kk_code` | normalized K&K code (e.g. `C-I-5a`) |
| `raw_code` | the OCR token before normalization |
| `qualifier` | the printed parenthetical: year, or "(with X, year)" |
| `ok` | `FALSE` if the token could not be normalized (1 row: Sears's `C-I-Addendum`, see Limitations) |

**`kk-index-b-edges.csv`**: the main Index B edge list. One row per heading × element × code,
duplicates removed.

| column | meaning |
|---|---|
| `kk_code` | normalized K&K code |
| `heading` | Index B heading (lower-cased, e.g. "behavior") |
| `sub_element` | element under the heading (lower-cased; e.g. "learned behavior") |
| `ocr_raw` | the OCR token before normalization |
| `parse_flag` | `ok`; `ocr_corrected` (token changed by normalization); `code_not_in_index_a` (code absent from Index A); `junk_name` (element name of 1–2 characters or only digits) |

**`kk-index-b-definitions.csv`**: the K&K definition universe (union of Index A and Index B codes).

| column | meaning |
|---|---|
| `kk_code`, `group`, `subgroup` | code and its letter group / roman subgroup (C, D, F only) |
| `in_index_a`, `in_index_b` | presence in each index |
| `n_index_b_elements` | number of Index B edge rows for this code |
| `index_a_authors` | authors and qualifiers from Index A |

Codes with `in_index_a = FALSE` are Index B codes that Index A does not list. Eight codes
remain (`C-7`, `D-8`, `F-9` are printed without the roman numeral; `D-II-16` is cited in
Index B but has no Index A row; it is in the verified network on K&K footnote 16, Aberle et al. 1950: 102). On the page image (2026-10-24) they print as listed; see
PROVENANCE 3.4. They are kept as printed, not remapped.

**`kk-index-b-words-excluded.csv`**: K&K's "Words not included in Index B". Same layout
as the edge list (`kk_code`, `heading`, `sub_element`, `ocr_raw`). These words are
deliberately outside the Index B vocabulary.

**`kk-index-b-ocr-corrections.csv`**: every OCR token whose normalized form differs
from the printed text (`source`, `raw`, `normalized`). Read this file to audit the
normalization. Rules are in `normalize_code()` and `norm_number()` in `build-index-b.R`.

**`kk-index-a-manual-fixes.csv`** and **`kk-index-b-manual-fixes.csv`**: corrections
checked against the printed page image. Each row gives the parsed token, the corrected
code (or `NA` for unresolved), and the printed evidence. The build applies them and
errors if a key matches no token. For `action = rename_sub`, the row sets `new_sub_element`
and leaves the code and the flags unchanged.

**`kk-index-a-missing-rows.csv`**: Index A rows that the OCR text layer omits entirely,
added from the page image (currently one, Angyal).

**`kk-boroch-crosswalk-decisions.csv`**: hand decisions for crosswalk rows that the rule
cannot settle. Each row gives the decision (`match` or `open`), the K&K code, and the basis.

**`kk-index-b-missing-rows.csv`**: printed Index B edges that the OCR text layer
loses entirely (a mangled code is glued into the following element name, so
nothing parses). Each row gives the heading, sub_element, and kk_code, the
glued OCR fragment, and the printed evidence. The build appends them
(`parse_flag = manual_fix`) and errors if one would duplicate an existing
edge. See the file for the current rows.

**`kk-index-b-ok-sample.csv`**: a 50-row random sample (seed 4817) of the 966 `ok`
edges, checked against the page image on 2026-10-24: `verdict` (all 50 OK), the printed
page, and per-row notes. Single reader; the sample's `heading` column predates the
heading corrections, so verdicts were checked against the current edge list.

**`kk-index-b-unresolved.csv`**: Index B tokens that have no code (for example, every
`j` token, and OCR fragments the rules cannot read). They are excluded from the edge list
and reported here so they can be checked.

**`kk-index-b-flagged-audit.csv`**: verdict for each of the 138 Index B edges that were
flagged for review (codes not in Index A, or junk sub-element names), with the printed
code the page shows.

**`kk-index-b-second-scan-check.csv`**: the 43 flagged edges (10 `code_not_in_index_a`, 33
`junk_name`) checked against the page image of our scan (PROVENANCE 3.4). Columns give the
second-scan text match, the page-image verdict, and the printed page and block.

**`kk_biadjacency_subelement.{rds,csv}`** and **`kk_biadjacency_heading.{rds,csv}`**:
binary matrices (element or heading × K&K code). The `.rds` is a base matrix with
dimnames; the `.csv` has the row label in its first column.

**`kk-boroch-crosswalk.csv`**: one row per Boroch Table 2 definition (135).

| column | meaning |
|---|---|
| `boroch_code` | Boroch's code (e.g. `C1-5a`) |
| `kk_code` | matched K&K code; `NA` unless `match_status == "auto"` |
| `boroch_author`, `boroch_year` | Boroch's metadata from `kkcc-definition-years.csv` |
| `positional_kk` | K&K code implied by position (subgroup digit → roman numeral); a check only |
| `candidates` | all K&K codes matching author, year, group, and subgroup |
| `match_status` | `auto` (one candidate), `ambiguous` (several), `no_kk_match`, or `manual_F4-6_slip` |
| `positional_agrees` | whether the author-year match equals the positional mapping |

**`kk-index-b-audit.csv`**: one row per Boroch Table 2 cell × definition (56 × 135 = 7560),
with status:

| status | meaning |
|---|---|
| `confirmed` | Boroch cell = 1 and Index B links the same definition to the same element |
| `boroch_only` | Boroch cell = 1; Index B does not link the pair |
| `boroch_only_def_unlinked` / `boroch_only_row_unlinked` | Boroch cell = 1, but the definition has no crosswalk match, or the notion label has no Index B label |
| `index_b_only` | Boroch cell = 0; Index B links the pair (pairs Boroch did not code) |
| `def_unlinked` | Boroch cell = 0 and the definition has no crosswalk match |
| `neither` | Boroch cell = 0 and Index B does not link the pair |

`kk-index-b-audit-summary.csv` gives counts by status.

**`kk-index-b-network-stats.csv`**: density, components, and degree summaries for the
Boroch and K&K networks (`analysis-index-b.R`).

**`kk-index-b-subelement-network.rds`**, **`kk-index-b-heading-network.rds`**, **`kk-index-b-verified-network.rds`**:
lists with `biadjacency` (0/1 matrix) and `graph` (igraph, bipartite). The sub-element and heading
networks keep all 171 codes. The Part III statement codes D-5, D-7 and E-17 were removed on 2026-10-30 (PROVENANCE 16), so the sub-element and verified networks have the same nodes (470 sub-elements, 171 codes, after the a/b split in PROVENANCE 17). The verified network
drops codes not flagged `in_verified` and sub-elements left with no verified code. The five codes
with no Index B edge (F-I-5, F-IV-1, F-IV-2, F-IV-4, G-1) are isolates. Vertex `type` is FALSE for element vertices and TRUE for codes.

Vertex attributes, by vertex kind:

| attribute | element vertices | code vertices | meaning |
|---|---|---|---|
| `name` | yes | yes | sub-element label or K&K code |
| `node_type` | `sub_element` or `heading` | NA | which element level the vertex is |
| `headings` | sub-element network and verified only | NA | headings the sub-element appears under, `; `-separated |
| `n_headings` | sub-element network and verified only | NA | number of headings the sub-element appears under |
| `n_subelements` | heading network only | NA | sub-elements under the heading |
| `n_codes` | yes | NA | codes linked to the element |
| `has_junk_name`, `has_manual_fix`, `has_ocr_correction` | sub-element network and verified only | NA | the sub-element has an edge with that parse flag |
| `kk_group`, `kk_subgroup` | NA | yes | K&K group letter and subgroup (e.g. `A`, `I`) |
| `in_index_a`, `in_index_b` | NA | yes | the code appears in Index A / Index B |
| `n_index_b_elements` | NA | yes | Index B elements under the code |
| `index_a_authors` | NA | yes | Index A authors listed under the code |
| `boroch_code`, `boroch_source` | NA | yes | Boroch's code for the same definition (NA if none); `table2` or `appendix-only` |

The works file's two-mode graphs use the same sub-element and heading attributes; work vertices use the work
attributes described under the works file below.

Edge attributes (all three): `n_source_rows` is the number of Index B rows behind the tie, and
`parse_flags` lists the parse flags of those rows, `; `-separated. Graph attributes record the build date,
source files, and a caveat that Index B has not been fully verified.

**`kk-index-b-work-concept-network-full.rds`**: a list with three elements. The two-mode networks are the
stored data; projections are derived in the analyses.

- `two_mode_graph`: sub-element × work bipartite (all 470 sub-elements, all 131 works, no LCC or 2-core
  selection). Sub-element vertices carry the sub-element attributes copied from the verified network
  (`type` FALSE, `node_type` `sub_element`, `headings`, `n_headings`, `n_codes`, `has_junk_name`,
  `has_manual_fix`, `has_ocr_correction`). Work vertices (`type` TRUE, `node_type` `work`) carry `n_codes`,
  `codes`, `n_concepts`, `year` (as printed, letter suffix kept), `decade` (integer), `label` and `pub_type`
  (`article`, `book`, `chapter` or `other`; see `scripts/attach-work-pub-type-index-b.R`).
- `two_mode_heading_graph`: heading × work bipartite. Heading vertices carry `n_subelements` and `n_codes`
  from the heading network; work vertices carry the work attributes. A work is under a heading if one of its
  codes is.
- `works`: the work table (`work`, `n_codes`, `codes`, `n_concepts`, `pub_type`).

Derived in the analyses (`sub_work_matrix()` and `lcc_2core()` in `scripts/core-index-b.R`): the sub-element ×
work matrix, the sub-element projection (ties = works both sub-elements cite), and the work projection (ties =
sub-elements both works cite). The LCC and 2-core are applied there, not in the stored file.

**`kk-definition-texts-kk-only.csv`**: full definition text for the one verified code that Boroch does not
quote anywhere in his Table 2 or appendix (D-III-4, the Part II group D-III page footnote 14). The Part III statement
texts (C-5, D-5, D-7, E-17) were removed on 2026-10-30 (PROVENANCE 16). The text is transcribed from K&K's own
statement, with
the printed citation, the printed page, and a per-row basis in `note`. Like the Boroch text files
(`kkcc-definition-texts.csv`, `kkcc-appendix-only-texts.csv`), it contains verbatim quotations and is not for
release.

**`kk-definition-texts-translations.csv`**: English renderings of the four non-English definition quotations,
substituted for the originals by the two text-based NMF analyses (columns `code`, `language`, `translation`,
`basis`). B-17 (Dietschy) and C-I-18a (Maquet) are French, F-I-5 (Menghin) and F-II-3 (Schmidt) German.
C-I-18a is K&K's own printed English rendering; the other three are working translations not yet verified
against the page images. Like the text files above, it quotes Boroch and K&K and is not for release.

## Methods

**Index A and Index B parsing.** The scanned pages were read at word level (coordinates
from `pdftotext -bbox-layout`) and split into columns by x-position. This avoids
guessing column gaps in two-column OCR. Full-width headings were located by text
markers, not hard-coded page numbers. Entries were then tokenized. A word after a code
run starts a new element name, and codes attach to the current name.

**OCR normalization.** Code tokens were normalized with an explicit, logged rule set
(`normalize_code()`): roman-numeral variants (`lV`, `IH`, `l`, `1`), digit confusions
(`i`/`l` → 1, `z` → 2, `y` → 5, `o` → 0, lone `n`/`u` → 11). These general rules are being replaced by explicit manual fixes where a token matters (see AGENTS.md). `j` is not mapped:
on the scan it is printed as both 3 and 5, so a `j` token is unresolved until checked
against the page image, the suffix `a`
(`ioa` → 10a), and dash variants (`~`, `^`). Every changed token is in
`kk-index-b-ocr-corrections.csv`.

**Crosswalk.** Boroch's numbering is not K&K's numbering (his A10 is Winston 1933; K&K's
A-10 is Linton 1936). The crosswalk therefore matches on author, year, group, and
subgroup, never on position. A match is `auto` only when exactly one K&K code fits.

**Audit.** A Boroch notion row was linked to K&K elements when their normalized labels
were equal (case, hyphens, and a trailing plural "s" ignored). The linkage is
conservative. Boroch's notion labels are his own wording, so many rows (31 cells) are
unlinked and are reported as such, not guessed.

**Non-negative matrix factorization.** Two analyses test whether data-driven factors
recover K&K's groups A–G, fit at k = 7 (one factor per group, fixed rather than
selected). The works analysis factorizes the sub-elements × works biadjacency of the
LCC 2-core; the texts analysis factorizes a TF-IDF matrix of the definition
quotations, one document per K&K code carrying a text. The texts analysis uses a
hand-set stopword list (59 general English stopwords plus 15 omnipresent domain
words: culture, cultures, cultural, society, social, man, men, human, total, whole,
way, ways, learned, acquired, group) and keep
tokens of three letters or more at 2–50% document frequency. The list is defined in
`scripts/analysis-nmf-texts-index-b.R` and is part of the reproducible pipeline;
results depend on it. Neither recovers the groups at better than chance. The four
non-English quotations (B-17 and C-I-18a French, F-I-5 and F-II-3 German) enter as
English translations from `data/kk-definition-texts-translations.csv`: C-I-18a is
K&K's own printed English rendering, the other three are working translations not
yet verified against the page images. Taken as printed, the quotations tokenize
poorly (the tokenizer splits words at accented letters) and only six foreign terms
survive the document-frequency filter (der, des, est, geist, ist, kultur), none
reaching a factor's top 15.

## Verification

- Table 2: the binary matrix has 316 ones. Printed "uses" counts include multiplicity and
  were checked row by row during transcription (see `AGENTS.md`).
- Index A: 191 author–code rows after the a/b split (187 before, PROVENANCE 17; 186 from the OCR text, plus 1 restored from the page image).
  190 are resolved, covering 170 distinct codes. Sears's `C-I-Addendum` is printed that
  way; it is an addendum linked to a specialty code and not a network code (user decision 2026-10-25). Every row on printed pp. 73–74 was read against the page image;
  30 rows that the parser had marked `ok` were wrong (codes, years, or names) and are corrected
  in `kk-index-a-manual-fixes.csv` (see `docs/PROVENANCE.md`, 3.1).
- Index B: 1326 edge rows after the a/b split and the variant link decisions (1314 before, PROVENANCE 17). Flags: ok 987, ocr_corrected 209, manual_fix 128, code_not_in_index_a 2. The manual-fix rows include 32 page-image recoveries of former `j` and fragment tokens, each re-checked at higher resolution (`data/kk-index-b-zoom-check.csv`), the six resolutions of 2026-10-24 (PROVENANCE 3.4), and the 2026-10-24 late corrections: A-1 → A-17 and D-I-13 → D-I-15 (page image), and F-IV-3 and A-15 (user readings, not image-checked in this session; PROVENANCE 3.9). 2 edges (C-I-18a and D-II-16) carry codes that Index A does not list. The Part III statement codes D-5, D-7 and E-17 were removed from the edge list on 2026-10-30 (PROVENANCE 16); on the page image the remaining edges print as listed. Two tokens remain unresolved (`kk-index-b-unresolved.csv`): `D-I` (society) and `F-j` (organized), both excluded as duplicates by decision.
- Crosswalk: 127 of 135 Boroch definitions match exactly one K&K code by rule (author,
  year or first-publication year, suffix, group, and subgroup). Eight are set by hand with
  a recorded basis (D3-1, D2-16, A16, A17, A20, C1-11, B5, D2-7), one (F4-6) is a documented
  slip resolution. Positional agreement holds for 69 of 135 rows, which confirms that
  Boroch renumbered.
- Ok-edge sample: a 50-row random sample of the 966 `ok` edges was read against the
  page image (PDF pp. 77–81, quadrant crops at 300 dpi). Verdict: 50 OK, 0 errors;
  Clopper–Pearson 95% upper bound on the error rate is 7.1%. Single reader
  (`data/kk-index-b-ok-sample.csv`).
- Machine block check: `check-index-b-blocks.R` puts 1301 of 1326 edges inside their assigned printed block; 25 are printed in another block, as before the split (PROVENANCE 17). The page-image verdicts in `kk-index-b-block-check-review-current.csv` (2026-10-25) cover 23 of the 25, and the two without a verdict are not yet identified (PROVENANCE 16.5). Of the 23 with verdicts, the 23rd (C-I-7 under "common or shared patterns", from the C-7 remap) was checked against the printed Index B entry, footnote 7 and Index A. All 23 are printed under their assigned heading according to one reader; the PDF text layer does not confirm them (OCR garbles the codes), and F-IV-3 under "means of adjustment" is not legible on the image (the user checked the reading on 2026-10-25). `kk-index-b-block-check-review.csv` holds the earlier 18-row set, keyed to a previous build. This is a machine cross-check plus one reader, not a double-keyed audit.
- Spot check: 20 random Index B edges were compared with their OCR lines after the
  normalization fixes. All 20 were correct on inspection. This is a small sample, not a
  full manual audit.
- Main networks: the sub-element, heading and work attributes agree across the four networks (0 mismatches),
  and the derived counts (`n_codes`, `n_subelements`) match each network's own edges (checked 2026-10-25).
- Moore (1980) cross-check and the F4-6 resolution: see `docs/PROVENANCE.md`.

## Known limitations

- **Definition text coverage.** Boroch's appendix supplies a full quoted text for 166 of the
  167 verified definitions; the one without one, D-III-4, carries K&K's own quotation instead
  (`kk-definition-texts-kk-only.csv`, a Part II page footnote). Seven K&K codes carry two
  Boroch quotations each, and three Table 2 columns inherit a base code's text, so coverage
  is counted by code, not by quotation. Every definition text also attaches to a work by
  author and year, with five explained exceptions (`scripts/check-definition-text-coverage.R`):
  two codes hold no work because Index A omits their authors (C-I-18a Maquet, D-II-16
  Aberle et al.), one because its entry has no year and the work key requires
  one (D-III-1 Tozzer), and two documented conflicts kept as printed (D-II-7 Young 1947/1944,
  F-I-20 Kluckhohn 1951a against F. R. Kluckhohn 1950). In the other direction, every work
  attaches to at least one definition text, except the same two documented conflicts.
- **OCR noise.** Index B and Index A come from ABBYY OCR of a 1952 scan. Some codes
  remain damaged after normalization. Of the Index A tokens that the rules could not read,
  the page image was used to correct them, and 30 Index A rows that the parser had marked
  `ok` were wrong in code, year, or name (`docs/PROVENANCE.md`, 3.1). `C-I-Addendum` is
  printed that way; it is not a network code (user decision 2026-10-25). Index B has 2 unresolved tokens
  (`kk-index-b-unresolved.csv`): `D-I` (society) and `F-j` (organized), both excluded as
  duplicates by decision. Other tokens were resolved as recorded in PROVENANCE 3.4 and 3.9.
  Four of the earlier resolutions rest on printed sequence and the candidate's absence, not a
  clean glyph read. The late readings `F-I\` (now F-IV-3) and `A-i5` (now A-15) are the user's,
  not yet checked on the image. Some printed codes lack a subgroup (e.g. `D-7`); these are
  kept as printed.
- **Element labels.** The `sub_element` labels are short index words. The 33 garbled
  labels (former `junk_name` rows) are mapped to the printed elements
  (`kk-index-b-junk-decisions.csv`); the label fixes were checked on the scan (one
  text-layer proposal, "constitutional changes", was wrong and corrected to the printed
  "constitutional charters"). Other labels are unverified against the page image beyond
  the audits above.
- **Boroch's coding is semantic, not lexical.** A Table 2 row such as "BEHAVIOR" is
  not always a K&K Index B heading. The audit reports this rather than correcting it.
- **Vocabulary reduction.** Boroch's 56 notions, his 171 appendix codes, and K&K's full
  numbering (around 300 definitions) are different universes. Table 2 has 135 columns:
  132 are also in the appendix, 3 (A10a, C1-5a, F4-6) have no appendix entry, and 39
  appendix codes are not in Table 2. Those 39 are listed in `docs/PROVENANCE.md`,
  section 4. They have no author/year metadata in this repository, so they cannot be
  crosswalked yet. (The difference is 171 − 132 = 39, not 171 − 135 = 36.)
- **F4-6.** Boroch's F4-6 is a slip for his own F4-5 (Kluckhohn & Kelly 1945a). The
  resolution is documented in `docs/PROVENANCE.md`, not inferred by the rule.
- **Page discrepancy.** K&K's appendix prints the Ford 1942 quotations at pp. 333, 337;
  Boroch and Moore print pp. 555, 557.

## Rights

The release is intended to ship **derived coded data** (incidence matrices, codes,
authors, years, element labels). It should not ship verbatim definition text.
`data/kkcc-definition-texts.csv` contains verbatim quotations from Boroch's appendix,
and both K&K and Boroch are copyrighted. The same applies to
`data/kk-definition-texts-kk-only.csv` (verbatim K&K Part II quotations). Keep both out
of the release manifest
until a rights decision is made. The K&K Index B element labels are short index words,
but they are still K&K's wording; confirm they are acceptable for release before
publication. The scanned PDFs are not part of the release.

User note (2026-10-24): the 1952 K&K monograph is publicly available online, and the user does not regard K&K element labels as a rights barrier. Availability online does not by itself settle redistribution rights, so the K&K labels may ship on that basis. Boroch's article (ROBAFC-5.1) and its verbatim quotations are not covered by this note and remain under the restriction above.

## Suggested citation

Dataset (replace the bracketed fields before release):

> [Author] (2026). *K&K Index B two-mode dataset and Boroch Table 2 crosswalk* [Data set].
> Version [x]. [Repository URL]. Derived from Kroeber & Kluckhohn (1952) and Boroch,
> *Analecta* (ROBAFC-5.1).

License recommendation: CC-BY 4.0 for the derived coded data, once the rights review
above is complete. Code: a permissive open-source license (MIT or Apache-2.0).
