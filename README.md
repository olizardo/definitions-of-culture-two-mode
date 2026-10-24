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
| `analysis-index-b.R` | biadjacency matrices, `kkcc_two_mode.rds` | network statistics, degree-comparison figure |
| `build-concept-categories.R` | `kkcc_two_mode.rds` (concept labels), Boroch section 3.2.2 (encoded in the script) | `kkcc-concept-categories.csv` |
| `build-two-mode-networks.R` | `kkcc-concept-categories.csv`, `kkcc-definition-years.csv`, `kkcc-definition-biblio.csv`, fine biadjacency | `kkcc_two_mode.rds`, `kkcc_two_mode_main.rds`, `kkcc_biadjacency_main.csv` |
| `check-two-mode-networks.R` | both networks, definition CSVs | nothing (stops on a mismatch) |
| `build-index-b-networks.R` | `kk-index-b-edges.csv`, `kk-index-b-definitions.csv`, `kk-boroch-crosswalk.csv`, `kkcc-appendix-only-links.csv` | `kk-index-b-subelement-network.rds`, `kk-index-b-heading-network.rds` |
| `check-index-b-blocks.R` | `documents/Kroeber-kluckhohn.pdf`, `kk-index-b-edges.csv`, `kk-index-b-block-map.csv` | `kk-index-b-block-check.csv`, `kk-index-b-block-check-summary.csv`, `kk-index-b-block-check-review.csv` (machine cross-check of heading assignments; not a human reader) |
| `kkcc-definition-attrs.R` (helper) | `kkcc_two_mode.rds` | returns the definition table used by the analyses |

Scripts live in `scripts/`; `documents/` holds the source PDFs and the Archive text. Run order (from the project root):

1. `scripts/build-definition-years.R`, then `scripts/build-supplement-bibliography.R` (Boroch metadata CSVs)
2. `scripts/build-concept-categories.R` (concept-to-category mapping, from Boroch section 3.2.2)
3. `scripts/build-two-mode-networks.R` (both networks, as igraph objects with node attributes)
4. `scripts/check-two-mode-networks.R` (validation; stops on any mismatch)
5. `scripts/build-index-b.R`
6. `scripts/build-index-b-crosswalk.R`
7. `scripts/build-index-b-networks.R` (K&K Index B sub-element and heading networks, as igraph objects)
8. `scripts/analysis-index-b.R`
9. `scripts/check-index-b-blocks.R` (machine cross-check of Index B heading assignments against the printed text)

The analysis scripts and the report read definition attributes through `scripts/kkcc-definition-attrs.R`.

Each build script writes a session-info file to `data/`. The R environment is pinned
in `renv.lock` (R 4.5.3). Requires `pdftotext` (poppler) on the PATH.

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
| `ok` | `FALSE` if the token could not be normalized (5 rows, see Limitations) |

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
Index B but has no Index A row). On the page image (2026-10-24) they print as listed; see
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

## Methods

**Index A and Index B parsing.** The scanned pages were read at word level (coordinates
from `pdftotext -bbox-layout`) and split into columns by x-position. This avoids
guessing column gaps in two-column OCR. Full-width headings were located by text
markers, not hard-coded page numbers. Entries were then tokenized. A word after a code
run starts a new element name, and codes attach to the current name.

**OCR normalization.** Code tokens were normalized with an explicit, logged rule set
(`normalize_code()`): roman-numeral variants (`lV`, `IH`, `l`, `1`), digit confusions
(`i`/`l` → 1, `z` → 2, `y` → 5, `o` → 0, lone `n`/`u` → 11). `j` is not mapped:
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

## Verification

- Table 2: the binary matrix has 316 ones. Printed "uses" counts include multiplicity and
  were checked row by row during transcription (see `AGENTS.md`).
- Index A: 187 author–code rows (186 from the OCR text, plus 1 restored from the page image).
  186 are resolved, covering 165 distinct K&K codes. Sears's `C-I-Addendum` is printed that
  way and stays unresolved. Every row on printed pp. 73–74 was read against the page image;
  30 rows that the parser had marked `ok` were wrong (codes, years, or names) and are corrected
  in `kk-index-a-manual-fixes.csv` (see `docs/PROVENANCE.md`, 3.1).
- Index B: 1285 edge rows. 210 rows are OCR-corrected: 198 were each read against the page
  image (`data/kk-index-b-ocr-audit.csv`), and 12 were checked in the flagged audit. 66 rows
  come from the manual-fix table. These include 32 page-image recoveries of former `j` and
  fragment tokens, each re-checked at higher resolution (`data/kk-index-b-zoom-check.csv`),
  and six resolutions of unresolved tokens on 2026-10-24 (PROVENANCE 3.4). 10 edges (8 codes)
  carry codes that Index A does not list; on the page image they print as listed. Two tokens
  remain unresolved (`kk-index-b-unresolved.csv`): `D-I` (society) is excluded as a duplicate,
  and `F-I\` (means of adjustment) is unreadable behind a smudge.
- Crosswalk: 127 of 135 Boroch definitions match exactly one K&K code by rule (author,
  year or first-publication year, suffix, group, and subgroup). Seven are set by hand with
  a recorded basis (D3-1, D2-16, A16, A17, A20, C1-11, B5), one (F4-6) is a documented
  slip resolution. Positional agreement holds for 69 of 135 rows, which confirms that
  Boroch renumbered.
- Ok-edge sample: a 50-row random sample of the 966 `ok` edges was read against the
  page image (PDF pp. 77–81, quadrant crops at 300 dpi). Verdict: 50 OK, 0 errors;
  Clopper–Pearson 95% upper bound on the error rate is 7.1%. Single reader
  (`data/kk-index-b-ok-sample.csv`).
- Machine block check: `check-index-b-blocks.R` puts 1268 of 1285 edges inside their
  assigned printed block; the 17 others are in `kk-index-b-block-check-review.csv` with
  verdicts read from page-image crops. This is a machine cross-check plus one reader,
  not a double-keyed audit.
- Spot check: 20 random Index B edges were compared with their OCR lines after the
  normalization fixes. All 20 were correct on inspection. This is a small sample, not a
  full manual audit.
- Moore (1980) cross-check and the F4-6 resolution: see `docs/PROVENANCE.md`.

## Known limitations

- **OCR noise.** Index B and Index A come from ABBYY OCR of a 1952 scan. Some codes
  remain damaged after normalization. Of the Index A tokens that the rules could not read,
  the page image was used to correct them, and 30 Index A rows that the parser had marked
  `ok` were wrong in code, year, or name (`docs/PROVENANCE.md`, 3.1). `C-I-Addendum` is
  printed that way and remains unresolved. Index B has 2 unresolved tokens
  (`kk-index-b-unresolved.csv`): `D-I` is excluded as a duplicate, and `F-I\` is unreadable
  behind a smudge. Both are excluded from the edge list rather than guessed. Six other
  tokens were resolved on the page image (PROVENANCE 3.4); four of those rest on printed
  sequence and the candidate's absence, not a clean glyph read. Some printed codes lack a subgroup (e.g. `D-7`); these are
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
and both K&K and Boroch are copyrighted. Keep that file out of the release manifest
until a rights decision is made. The K&K Index B element labels are short index words,
but they are still K&K's wording; confirm they are acceptable for release before
publication. The scanned PDFs are not part of the release.

## Suggested citation

Dataset (replace the bracketed fields before release):

> [Author] (2026). *K&K Index B two-mode dataset and Boroch Table 2 crosswalk* [Data set].
> Version [x]. [Repository URL]. Derived from Kroeber & Kluckhohn (1952) and Boroch,
> *Analecta* (ROBAFC-5.1).

License recommendation: CC-BY 4.0 for the derived coded data, once the rights review
above is complete. Code: a permissive open-source license (MIT or Apache-2.0).
