# Open items: K&K Index A/B dataset

Last updated 2026-10-24. Read `AGENTS.md` (project memory) and `docs/PROVENANCE.md` first.
Rebuild order after any change: `build-index-b.R` → `build-index-b-crosswalk.R` →
`analysis-index-b.R`. The Boroch-side outputs (`analysis-collapse-main.R`, then
`build-definition-years.R`, then `build-supplement-bibliography.R`) are separate; rerun them only
if the Boroch data or `kkcc_two_mode.rds` changes.

Page checks use `Kroeber-kluckhohn.pdf` (ABBYY scan, Index B = PDF pp. 77–81, printed pp. 74–78).
Render with `pdftoppm -r 300`, and crop with the `-x -y -W -H` flags, since the full page is hard to read.

## Status (2026-10-24, second pass)

- 1 Heading attribution: OPEN. Needs a block-to-heading map from page images. Not started beyond the listed examples.
- 2 Unresolved tokens: OPEN. Needs a second scan or a decision to accept the exclusion.
- 3 Junk sub-elements: OPEN. Needs a per-case decision.
- 4 Flagged edges: DONE. All 26 FIX rows are in the manual-fix table and match their flagged code. CHECK rows: F-1 "adjustments" and F-19 resolved; F-i (group) and D-I (society) remain under item 2. The code_not_in_index_a edges were checked (see PROVENANCE 3.1): C-7, D-8, F-9 are printed without a roman numeral; the rest are kept as printed.
- 5 Unflagged ok rows: SAMPLE DRAWN, NOT CHECKED. 50-row sample (seed 4817) in `data/kk-index-b-ok-sample.csv`. Fill the verdict columns from the page image.
- 6 Crosswalk: DONE for the rule and the decisions. 2 hand decisions (D3-1, D2-16); 5 open (A16, A17, A20, C1-11, B5). Found and fixed: the crosswalk read a stale session object instead of its input file.
- 7 Index A: DONE. Every row on printed pp. 73–74 was re-read against the page image; 30 fix rows and 1 missing row (Angyal) added. C-I-Addendum is documented as printed.
- 8 Rights: OPEN (user decision).
- 9 Git: committed in logical units (see git log).
- 10 Documentation: DONE for README, PROVENANCE (3.1, 3.2, 4, 8), and AGENTS.md.
- 11 Verification: the build, crosswalk, and analysis run cleanly. All manual-fix keys match. Index B edge count is unchanged at 1279.

## 1. Heading attribution (high priority)

Several heading blocks attach sub-elements to the wrong heading. Codes are right; any analysis
that uses the heading column or `kk_biadjacency_heading.*` is not reliable until this is fixed.

- "carriers of culture" entries sit under `capabilities`.
- "common or shared patterns" entries sit under `civilization`.
- "systems" entries sit under `symbols`.
- "social" and "society" entries sit under `group reference`.
- "ideas and cognitive processes" entries sit under `history`.
- Example: `E-5` under "v-i" (group reference) is printed under "society" (see
  `data/kk-index-b-ocr-audit.csv`, verdict `OK_HEADING_WRONG`).

Plan: build a block → printed-heading map, verified against the page images, and apply it in
`build-index-b.R` (not in the output CSVs). Rebuild the heading matrix.

## 2. Eight unresolved Index B tokens (`data/kk-index-b-unresolved.csv`)

Five have two printed candidates under the same sub-element. They are excluded from the edge list:

- group `F-i` (F-I-6 or F-I-19)
- society `A-q` (A-4 or A-9)
- society `D-I` (D-I-12 or D-I-13)
- ideas `F-H-j` (F-II-3 or F-II-5)
- sum `A-j` (A-3 or A-5)

Three cannot be read on the scan:

- group `F-U` (garbled)
- `i` `F-I-i}` (sub-element is a misattributed label)
- means of adjustment `F-I\` (clipped at the column gutter on printed p. 77)

Options: a better scan or a second copy, or a decision to accept the exclusion. Do not guess.

## 3. Junk sub-element names (33 edges, `parse_flag = junk_name`)

Sub-elements such as `j`, `i`, `v-i` are OCR fragments or misattributed labels. Decide per
case: map to the printed sub-element, or drop from the sub-element matrix and keep the edge in
the heading matrix. Record the decision in `docs/PROVENANCE.md`.

## 4. Flagged edges (`data/kk-index-b-flagged-audit.csv`, 138 rows)

Verdict counts: OK 59, OKJ 34, OKH 15, FIX 26, CHECK 4.

- Confirm that every FIX has been applied in `data/kk-index-b-manual-fixes.csv` (or the build).
- Resolve the 4 CHECK rows. Among them is `F-1` / "adjustments" (raw `F-I`), which is now
  `F-IV-3` through the manual fixes. Confirm the flagged row is replaced, not duplicated.
- Check that the `code_not_in_index_a` edges (56) are real K&K codes and not truncations.
  Examples: `D-7` (no subgroup) and `F-1`.

## 5. Unflagged rows not audited (932 `ok` rows)

The 198 OCR-corrected rows were checked against the scan. The 932 unflagged `ok` rows were not.
Options: a random sample of about 50 for an error-rate estimate, or a full pass.

## 6. Boroch crosswalk (`data/kk-boroch-crosswalk.csv`)

27 definitions have no K&K match and 7 are ambiguous. Review each against K&K author, year,
group, and subgroup. Record decisions with notes. Do not match by position (Boroch renumbered).

## 7. Index A

- `C-I-Addendum` (Sears) is printed that way and stays unresolved. Leave it, or document it as-is.
- Index A has 186 rows and 185 resolved tokens. The one unresolved token is the Sears entry.

## 8. Rights

Whether K&K Index B element labels can be released is undecided. `data/kkcc-definition-texts.csv`
holds verbatim Boroch quotations and must stay out of any release. The page-image checks used an
unofficial scan copy that is not in the repo. Cite printed page numbers, not that copy.

## 9. Git state

The working tree is uncommitted. About 24 entries are modified or untracked, including
`data/kk-index-b-*.csv`, the manual-fix tables, the ocr-audit and zoom-check files, and this file.
Review the diff, then commit in logical units (build fix, manual fixes, audit outputs, docs).

## 10. Documentation to keep in sync

- `README.md` (data dictionary, limitations): update counts after any rebuild.
- `docs/PROVENANCE.md` section 8 (known gaps) and the validation paragraph.
- `AGENTS.md` project memory, "K&K Index A/B dataset" section.
- The old counts (1,247 edges, 40 unresolved) appear in historical notes. Do not update those
  historical notes; update the current-state text only.

## 11. Verification to do after any change

- The build runs without errors. Every manual-fix key matches a token.
- Edge count and parse-flag counts change only as expected.
- Spot-check any new manual fix against the scan at 300 dpi and record it in
  `data/kk-index-b-zoom-check.csv` or `data/kk-index-b-ocr-audit.csv`.
