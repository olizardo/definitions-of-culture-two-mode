# Provenance log

Chain of evidence for the data in this repository, written for readers outside the
project. The README gives the summary; this file gives the reasoning and the evidence.

## 1. Sources

| Source | Role | Copy used |
|---|---|---|
| Kroeber & Kluckhohn (1952), *Culture: A Critical Review of Concepts and Definitions* | Primary source of K&K codes, Index A (authors), Index B (conceptual elements), "Words not included in Index B" | `Kroeber-kluckhohn.pdf`, 219 pp., ABBYY FineReader 11 OCR (2013) |
| Boroch, *Analecta*, "A Formal Concept of Culture in the Classification of Alfred L. Kroeber and Clyde Kluckhohn" | Table 2 (frequential analysis, 56 notions × 135 definitions), definition appendix | `ROBAFC-5.1.pdf`, text extracted with `pdftotext -layout` |
| Moore (1980), ERIC ED229292 | External cross-check of author–year citations (46 quoted citations) | `ED229292.pdf` |

## 2. Boroch Table 2 (transcription)

Table 2 was transcribed by hand from the PDF text and verified row by row against the
printed "Number of uses". Two facts matter for analysis:

- "TOTAL USES" counts uses with multiplicity; the binary matrices deduplicate.
- The 56 rows mix 16 main categories with 40 auxiliary notions. The collapsed network
  (`kkcc_two_mode_main.rds`) unions each auxiliary into its parent. The parent of each auxiliary is
  set from Boroch section 3.2.2 items a)–p) (`scripts/build-concept-categories.R`), not from row position,
  because auxiliaries such as "Habit" and "Belief" print before their parent. Each main category's
  binary tie count is at or below its printed total (`data/kkcc-concept-categories.csv`).

Table 2 has 135 definition columns. Boroch's appendix has 171 codes. The two sets overlap
in 132 codes, and they differ in both directions:

- 3 Table 2 columns have no appendix entry: A10a, C1-5a, and F4-6. A10a and C1-5a are
  variants that appear only as Table 2 columns (checked in `ROBAFC-5.1.pdf` text).
- 39 appendix codes are not in Table 2 (listed in section 4).

So the appendix-only count is 171 − 132 = 39. The earlier figure of 36 came from
171 − 135, which wrongly assumes all 135 Table 2 columns are appendix codes. The
appendix-only list in section 4 is the full set of 39.

## 3. K&K Index B: parsing and normalization

**Extraction.** Index B occupies monograph pp. 74–78 (PDF pp. 77–81). Index A occupies
pp. 73–74 (PDF pp. 76–77). Boundaries were found by text markers ("A: AUTHORS",
"CONCEPTUAL ELEMENTS", "WORDS NOT INCLUDED", "SOME STATEMENTS"), not hard-coded page
numbers. Word-level coordinates from `pdftotext -bbox-layout` were split into left and
right columns at the page midline. Full-width headings split each page in two.

**Tokenization.** Each entry is a heading, a dash (em dash, "- -", or a lowercase
dash-lowercase join), and a body of `element, code, code; element, code. ...`. Words
accumulate into an element name. A code attaches to the current name. A word after a
code run starts a new name. Parenthetical qualifiers ("(1915)", "(see learning)") are
kept as markers, not as codes.

**Normalization.** The OCR errors are systematic and were handled by explicit rules,
logged in `kk-index-b-ocr-corrections.csv`:

| OCR form | normalized | note |
|---|---|---|
| `lV`, `IH`, `1` in roman slot | `IV`, `III`, `I` | roman subgroup |
| `i`, `l`, `I` in number slot | 1 | e.g. `B-i` → B-1 |
| `z` | 2 | `B-zz` → B-22 |
| `y`, `$` | 5 | `F-IV-y` → F-IV-5. `j` is not mapped (see below) |
| `iy`, `iz`, `io` | 17, 12, 10 | two-digit numbers |
| trailing `a` | suffix | `A-ioa` → A-10a (only a literal trailing `a`; an earlier version applied this to any letter and was corrected) |
| lone `n` / `u` | 11 | `A-n` → A-11 |
| `~`, `^` | `-` | `D-I^7` → D-I-7 |

Tokens that could not be normalized, including every `j`, are not guessed. They are written
to `kk-index-b-unresolved.csv` and excluded from the edge list. The `j` rule was removed
after page-image checks showed the scan prints `j` as both 3 and 5 (for example, `D-III-j`
is `D-III-3` in "carriers of culture" and `D-II-j` is `D-II-5` in "social"). Corrections
checked against the page image are in `kk-index-a-manual-fixes.csv` and
`kk-index-b-manual-fixes.csv`. Each row cites its printed evidence.

**Validation so far (before the 2026-10-24 Index A corrections in 3.1).** Index A (186 rows) and Index B (1279 edges, after the recoveries below) was compared on code
coverage. 153 Index B codes also appear in Index A; 16 do not, most of them damaged OCR.
A 20-edge random spot check against the OCR lines found no errors after the normalization
rules. The 138 flagged Index B edges were then checked against the printed page images:
108 codes were confirmed, 26 were corrected, and 4 truncated codes were left unresolved.
Of the Index A tokens the rules could not read, four were corrected and `C-I-Addendum` is
left as printed. Bose's `B-j` was also corrected.

The 198 unflagged OCR-corrected edges were then read against the Index B page images (printed pp. 74-78). Verdicts are in `data/kk-index-b-ocr-audit.csv`: 195 match the printed code, 3 were corrected through the manual-fix table (`C-I` relationships, `A-i` social groupings, `C-I-i` ways), and 1 was corrected by fixing the roman-numeral parser, which read `IH` as `II` (`D-IH-2`, `F-IH-2`). One edge (`E-5` under "v-i") has the right code but sits under the wrong heading. The audit was read at page-image resolution without zoomed crops, so verdicts are a single-reader check, not a double-keyed verification.

### 3.1 Index A corrections (2026-10-24)

The Index A parse had been treated as verified, but only its unresolved tokens had been checked. On 2026-10-24 every row on printed pp. 73–74 (PDF pp. 76–77) was read against the page image at 200 dpi, and disputed lines were re-read at 300 dpi. That found 30 fix rows, each marked `ok` by the parser but wrong in code, year, or author name, and one row (Angyal, B-14, 1941) that is absent from the OCR text layer altogether.

The corrections are in `data/kk-index-a-manual-fixes.csv` (columns `kk_code`, `author_new`, `qualifier_new`) and `data/kk-index-a-missing-rows.csv`. Examples: Wissler A-2 (parsed A-1), Thomas C-II-2 (parsed C-1), Young D-I-5 (parsed D-I-3), Slotkin D-II-15 (parsed D-II-1), Keller D-I-2 (parsed D-I-1), Kelly F-IV-5 (parsed F-IV-3), Henry B-21 (parsed B-11), Dollard E-2 (parsed E-1), Katz D-IV-2 (parsed D-IV-1). OCR-damaged years were restored (Sapir 1921, Thurnwald 1950, Tozzer 1925, Huntington 1945). Merged or misspelled names were fixed: "Carver < 1935)-Couru" is Coutu, "Blumenthal • Boas" is Boas, and "Tumey-High" is Turney-High.

Index A now has 187 rows (186 resolved, plus Sears's `C-I-Addendum`), covering 165 codes. Seven Index B codes that were missing from Index A (A-2, B-14, B-21, C-II-2, D-I-5, D-II-15, E-2) now appear there. Ten Index B edges (eight codes) still carry codes Index A does not list:

- `C-7`, `D-8`, `F-9`: printed without the roman numeral on the page (checked at 300 dpi). Candidates such as C-I-7, D-I-8, and F-I-9 exist in Index A, but the codes are kept as printed, not remapped.
- `D-7`, `D-5`, `F-4`, `E-17`: kept as printed. Confirmed on the page image at 200 dpi (section 3.4), not at 300 dpi.
- `D-II-16` (`socially transmitted behavior`): Index A has no Aberle row. The code is cited in Index B, and it is the code the crosswalk assigns to Boroch's D2-16 (see 3.2). Its sub-element is printed
  "socially transmitted", not "socially transmined" (section 3.4).

### 3.2 Crosswalk changes (2026-10-24)

The crosswalk now strips initials from Boroch surnames ("A. Davis" matches Davis Allison), requires a Boroch suffix (a or b) to match when given (White 1949b/1949a resolve to F-III-3/F-III-4), and accepts Boroch's first-publication year (`year_orig`). Benedict A5 is quoted as 1931 but first published 1929, which is K&K's A-4 (1929). Hand decisions are in `data/kk-boroch-crosswalk-decisions.csv`, each with a stated basis:

- D3-1 (Tozzer, no year): matched to D-III-1. The only K&K Tozzer in subgroup D-III; moderate confidence.
- D2-16 (Aberle et al. 1950): matched to D-II-16 on the quoted text, "Culture is socially transmitted behavior...", which matches the Index B element label. K&K's own footnote 16 (printed p. 59, PDF 62) cites "Aberle, et al, 1950: 102" with the same quote; checked on the page image 2026-10-25 (600 dpi). Index A has no Aberle row. D-II-16 was added to the verified network on this basis (user decision 2026-10-25; `data/kk-index-b-verified-extra-codes.csv`).
- A16 → A-14, A17 → A-15, A20 → A-18, C1-11 → C-I-10 (2026-10-24). Each rests on a verbatim
  match between Boroch's appendix text and the K&K Part II quotation printed on the page image
  (printed p. 44 = PDF p. 47 for A16, A17 and A20; printed p. 50 = PDF p. 53 for C1-11). The
  printed item number is taken as the K&K code within the group: items 14, 15 and 18 on p. 44
  are A-14, A-15 and A-18, and item 10 on p. 50 is C-I-10. The printed citations are Kluckhohn
  & Kelly 1945a: 82, 1945a: 96, Herskovits 1948: 154 and Kluckhohn & Kelly 1945a: 84, so each
  matches Boroch's author and year. These are hand decisions, recorded in
  `data/kk-boroch-crosswalk-decisions.csv`.
- Appendix-only (not in the crosswalk, which covers the 135 Table 2 codes): A21 → A-19 and
  C1-12 → C-I-11, both from the same page images (item 19, Herskovits 1948: 625, p. 44; item 11,
  Kluckhohn & Kelly 1945a: 97, p. 50). Recorded in `data/kkcc-appendix-only-links.csv`.
- C1-22 → C-I-Addendum (2026-10-24). K&K prints an addendum after C-I item 19: "Addendum: When this monograph was already in press ... by the biologist, Paul Sears:". The quoted text matches Boroch's C1-22 verbatim, and the printed citation "(1939, 78–79)" was read on the page image (PDF p. 54, printed p. 51, 400 dpi crop; the OCR layer dropped the "1"). The printed folio "51" and running head "Definitions: Group C: Normative" are visible on the page image (200 dpi). Index A's Sears row is C-I-Addendum (1939). The addendum has no number, so the link is the label, not a numbered code. No Index B edge carries it.
- B5 → B-4a (2026-10-24). The printed Part II entry on p. 47 (PDF p. 50) is "4a. Myres, 1927: 16.",
  and its quotation matches Boroch B5 verbatim. The only Myres row in Index A is B-4a, which
  prints "(1929)" on p. 73 (PDF p. 76). So K&K's index and Part II disagree by two years on the
  same entry. Decision (2026-10-24): 1927 is the working year for B-4a, matching the Part II
  entry and Boroch. Applied 2026-10-26: `kk-index-a-manual-fixes.csv` sets B-4a to "(1927)". The
  works build reads that year, so the work is labelled Myres 1927. The printed "(1929)" is a K&K
  index error. The K&K bibliography (printed p. 199, PDF 198) prints "Myres, J. L. 1927. Political
  Ideas of the Greeks. New York", checked on the page image 2026-10-26; it gives no publisher
  beyond "New York". Primary-source check (2026-10-24):
  the Google Books record for Myres, *The Political Ideas of the Greeks* (Abingdon Press, 1927;
  George Slocum Bennett Foundation lectures, 8th series, 1925–26), gives 1927 as the publication
  year, which supports the working year. (The Google Books record is metadata only; it was not
  checked against the book's title page.)

Second-copy check (2026-10-24). The 229-page Adobe paper-capture copy (`documents/kroeber-amp-…
_compress.pdf`, byte-identical to `pdfcoffee.com-…pdf`) was rendered at 150 dpi. Printed p. 44 is
PDF p. 50 and printed p. 50 is PDF p. 56, so the printed-page offset is +6 here, against +3 in
`Kroeber-kluckhohn.pdf`. The same printed citations appear on both: items 14 (1945a: 82), 15
(1945a: 96), 18 (Herskovits 1948: 154), 19 (Herskovits 1948: 625) and 20 (Thurnwald 1950: 104)
on p. 44; items 10 (1945a: 84) and 11 (1945a: 97) on p. 50. The checkpoints are in
`data/kk-page-map.csv`. An automatic page map was not built: the ABBYY scan's text layer lacks the
running headers, and the copy's text-layer page count does not match pdfinfo, so the map is
limited to pages checked by eye.

Result after these decisions: 127 rule matches, 7 hand decisions (D3-1, D2-16, A16, A17, A20,
C1-11, B5), no ambiguous rows, and F4-6 (resolved in section 5). No row is unmatched.

### 3.3 Audit coverage (2026-10-24; snapshot before the resolutions in 3.4)

Coverage of the Index B edges by the audit files, joined on kk_code + heading + sub_element
(`data/kk-index-b-edges.csv`, 1279 edges; `kk-index-b-flagged-audit.csv` and
`kk-index-b-ocr-audit.csv`):

| parse_flag | edges | with an audit row | without |
|---|---|---|---|
| ok | 966 | 51 (flagged audit) | 915 |
| ocr_corrected | 210 | 210 (198 OCR audit, 12 flagged audit) | 0 |
| junk_name | 33 | 33 (flagged audit) | 0 |
| code_not_in_index_a | 10 | 10 (flagged audit) | 0 |
| manual_fix | 60 | 4 (OCR audit) | 56 |

Of the 138 flagged-audit rows, 30 do not join to any edge. They appear to be keyed on uncorrected
tokens (for example F-1, C-18, A-103, D-1112). Their verdicts exist only in the flagged audit.
The 932 unaudited-ok figure in earlier notes could not be reproduced. The join gives 915.
The 56 manual fixes without an audit row are justified by the printed evidence in
`kk-index-b-manual-fixes.csv`, not by an independent verdict.

### 3.4 Page-image pass on flagged and unresolved tokens (2026-10-24)

Source: our scan (`documents/Kroeber-kluckhohn.pdf`), Index B = PDF pp. 77–81 = printed pp. 74–78
(PDF page = printed page + 3). Pages were viewed at 200 dpi, and the unresolved tokens at 400–600
dpi. The Internet Archive copy (`culturecriticalr0000kroe_z3a4`) was used as a lead only: its left
column is clipped at the scan edge, so leading characters are lost. Verdicts are single-reader.

**Flagged codes.** All 10 `code_not_in_index_a` codes print where the edges place them.
Four print under the heading the edges give (D-7 under adjustive-adaptive; D-7 under implicit
culture; D-II-16 under behavior; D-5 under products of human activity). Five print under a different
heading: C-7, F-9 and F-4 under "common or shared patterns" (edges: civilization); D-8 and E-17
under the "carriers of culture" block (edges: capabilities). D-II-16 under "transmission,
non-genetic" is confirmed, with the damaged sub-element described below. All 33 `junk_name` codes
print in the blocks the edges give: customs (9 codes, printed p. 75), capabilities / "a people"
(6, p. 75), the social entry under group reference (11, p. 77), patterns (1, p. 77), social
heritage (2, p. 77), and ways and life-ways (4, p. 78). Their sub-element names remain open.

**Sub-element correction.** The sub-element `socially transmined` is OCR damage for printed
"socially transmitted" (page 78, transmission, non-genetic). It affects four edges (D-II-14,
D-II-16, F-I-19, F-II-10). They are corrected by `rename_sub` rows in
`data/kk-index-b-manual-fixes.csv`, applied by `apply_index_b_fixes()`. Codes and flags are unchanged.

**Unresolved tokens.** Six of the eight were resolved; two remain.

| Token (heading / sub-element) | Decision | Printed basis | Confidence |
|---|---|---|---|
| `A-q` (group reference / society) | A-9 | "A-4, A-9, A-10" in the society list (printed p. 76); A-9 absent from the edges here | high |
| `F-i` (group reference / group) | F-I-6 | "E-9, F-I-6, F-I-19" in the group list (p. 76); F-I-6 absent here | medium-high |
| `F-U` (group reference / group) | B-21 | "B-20, B-21, C-I-3" in the group list (p. 75); glyph unreadable, so assigned by elimination with `F-i` | medium |
| `F-I-i}` (group reference / i) | F-I-13 | between F-I-12 and F-I-16 in the social list (p. 76); F-I-13 is already an edge under heading "social" | medium |
| `F-H-j` (history / ideas) | F-II-5 | immediately after F-II-3 in the ideas list (p. 76); glyph not clearly read | medium-high |
| `A-j` (totality / sum) | A-5 | between A-3 (already an edge) and A-10 in the sum list (p. 78); glyph not clearly read | medium-high |
| `D-I` (group reference / society) | excluded as a duplicate | D-I-12 and D-I-13 both printed (p. 76) and both already edges | not added |
| `F-I\` (process ts and means / means of adjustment) | unresolved | smudge after "F-I-" at the end of the list (p. 77) | none |

Resolutions that rest on printed sequence plus the candidate's absence from the edges are inferences,
not clean glyph reads. A second reader should check `F-U`, `F-I-i}`, `F-H-j` and `A-j`.

**Effect on the build.** Index B edges go from 1279 to 1285. Manual-fix edges go from 60 to 66.
Parse flags: ok 966, ocr_corrected 210, junk_name 33, code_not_in_index_a 10. The crosswalk is
unchanged (127 auto, 2 manual decisions, 1 F4-6, 1 no match, 4 ambiguous).

### 3.5 Heading corrections (2026-10-24)

The text layer assigns some entries to the wrong block heading. The block map
(`data/kk-index-b-block-map.csv`, printed pp. 74–78) gives the printed block for each entry. The rules are in
`apply_heading_corrections()` in `scripts/build-index-b.R`, applied after the manual fixes (which key on the
parsed heading) and before the outputs. Codes and the 1285-edge total are unchanged.

| Parsed heading | Printed block | Edges re-headed | Basis |
|---|---|---|---|
| `capabilities` | carriers of culture | 73 | all entries print under "carriers of culture— individuals, ..." (printed p. 75) |
| `history` | ideas and cognitive processes | 50 | all entries print under "ideas and cognitive processes— ideas, ..." (printed p. 76) |
| `civilization` (36 of 41) | common or shared patterns | 37 | printed civilization block lists only "civilization" (A-1, A-3, B-17, D-I-2, F-I-3), so those 5 stay; one of the 37 rows is a duplicate of G-3 (see below) |
| `symbols` (12 of 26) | systems | 12 | printed systems block lists systems-systems, systems of thought, systems of knowledge |
| `feelings` | forbidden, the | 1 | "forbidden, the— ... D-I-16" |
| `people, a` | permitted, the | 1 | "permitted, the— ... D-I-16" |

The heading `adjustive-ajjptive function of culture` (34 edges) is an OCR misreading of the printed `adjustive-adaptive function of culture`; it is renamed in the same step (checked on the scan, printed p. 74). The heading `process ts and means` (OCR split of the printed `processes and means`, scan p. 77) is renamed the same way. Total: 174 parsed rows re-headed. The edge file keeps 173 distinct rows: the common-or-shared-patterns block
prints G-3 twice (`G-I-j` and `G-j`, both manual fixes to G-3), and the duplicate-removal step keeps one.
All six rules also rename the first element, which carried the block heading text in its name: "carriers of culture-individuals" → "individuals", "ideas and cogni ve processes-ideas"
→ "ideas", "or shared patterns-common" → "common", "systems-systems" → "systems", and "forbidden the-" /
"permitted the-" → "forbidden, the" / "permitted, the". Each rename matches the printed element name.

Side effects, checked on the rebuilt outputs:

- Sub-element matrix: 472 → 471 sub-elements. The "systems" element now shares a row with the
  "patterns, systems, and organization" block, which lists the same 10 codes. The 10 duplicate ties
  go (1193 → 1183) and no code is lost.
- Heading matrix: 51 → 53 headings, 1058 → 1059 ties. F-I-3 is printed under both civilization and
  common or shared patterns, so it gains one tie.
- Audit (`kk-index-b-audit*.csv`) matches on heading and sub-element labels, so pairs change: for
  example, `SYMBOL` no longer links to A-11, which K&K print under systems.
- The crosswalk was rerun. Its codes are unchanged; only the B5 decision note text differs from the
  committed copy, because the decision file was updated and the output was stale.

Not done: a second reader for the civilization and symbols cases, and a sub-element check of the
remaining ~1100 edges (TODO items 14–15).

### 3.6 Junk sub-element decisions (2026-10-24)

The 33 `junk_name` edges had element names that are OCR fragments (`j`, `i`, `y`, `z`, `5`). Each
was mapped to the element printed in the same block, in `data/kk-index-b-junk-decisions.csv`. None was
dropped. The printed lists come from the PDF text layer and were not checked on the page image.

| Parsed heading | Parsed element | Edges | Mapped to | Printed basis |
|---|---|---|---|---|
| customs | `j` | 9 | customs | printed "customs" element list (printed p. 75) |
| carriers of culture | `j` | 6 | a people | printed "a people" list (printed p. 75) |
| group reference | `i` | 11 | social (kept under group reference) | printed "social" element in the group reference block (printed p. 76, PDF p. 79); the same list also prints in the social block (printed p. 77), a printed duplicate |
| patterns, systems, and organization | `5` | 1 | patterns | printed "patterns" list (printed p. 77) |
| social heritage or tradition | `i` | 2 | social heredity | printed "social heredity" list (printed p. 78) |
| ways and life-ways | `y`, `z` | 4 | ways | printed "ways" list (printed p. 78) |

Six `manual_fix` edges carried single-letter element names as well and were mapped the same way: F-III-3
(carriers, `j` → a people), B-13 (customs, `j` → customs; printed "B-ij"), D-II-5, E-3 and F-I-13 (group
reference, `i` → social), and D-I-12 (ways, `y` → ways).

The group reference entries were first moved to the social heading. That collided with the 36 existing
social/social edges (1285 → 1274), so the decision was changed to keep them under group reference. The
earlier note placing this entry on printed p. 77 was also wrong: the group reference copy is on p. 76.

Result: 39 rows in the decisions file. `junk_name` 33 → 0, `manual_fix` 66 → 99. The edge total is still
1285. No single-letter element names remain. Sub-element names go from 471 to 466; the five removed names
are `j`, `i`, `y`, `z` and `5`.

### 3.7 Machine cross-check of heading assignments (2026-10-24)

`scripts/check-index-b-blocks.R` is a machine check, not a second human reader. It takes the PDF text
layer (a separate code path from the build's parser), finds each printed block by its heading followed by a
dash, and asks whether each edge's code appears in its assigned block's printed region. Matching is
OCR-tolerant: each digit accepts its printed look-alikes (1/i/l/t, 5/y/s/$, and so on), eleven may print
as n or u, and a tilde or a space may stand in for a dash.

Result for the 1285 edges: 1268 print in their assigned block. 17 do not, and those are listed in
`data/kk-index-b-block-check-review.csv` for a page-image check. Of the 17, 14 are `manual_fix`, one is
`ocr_corrected`, and two are plain `ok` edges (B-11 and B-22 under `process` in process ts and means). Two earlier
failures were checked by reading and now pass: B-4a (printed "past, B~4a" in the time block) and C-I-15
(printed "C -I-i y" in the ways list).

Limits: the check is block-level only; it does not test the element. A code that prints in another block
does not prove an error, and the tolerant matcher can match one code in several blocks (A-11 matches
several). A pass shows that the code is printed somewhere in the block, not under the element the edge
gives. The check is not a substitute for the human second reader in TODO item 15.

Review sheet: `data/kk-index-b-block-check-review.csv` (17 rows). All 17 were resolved on 2026-10-24 by
reading the printed pages from full-page quadrant crops (300 dpi) and targeted 400–600 dpi zooms, rather
than repairing the original crop locator (which fell back to the column top when a heading match failed).
Final verdicts: 16 OK, 1 CODE_WRONG. The CODE_WRONG row is B-11 under `processes and means / process`:
the print reads "process, B-21, B-22, D-I-6, F-I-16" (400 dpi zoom) and B-11 prints nowhere in the block;
fixed by a `set` row (B-11 → B-21, keyed on the parsed heading "process ts and means") in
`data/kk-index-b-manual-fixes.csv`, and the pipeline was rebuilt (1285 edges unchanged). One evidence note
was amended: the `D-I-15 / material culture / artificial` fix had claimed a clean print of D-I-15, but a
600 dpi zoom on 2026-10-24 shows the roman numeral under an ink blot; the edge is kept with the stated
basis recorded in the manual-fix file. Verdicts were read by one reader.

### 3.8 Glued element names and recovered edges (2026-10-24)

In five places the OCR printed a code so badly (lowercase, missing dashes) that the parser glued it
into the following element name, so the element name is wrong and, in two cases, the printed edge for
the glued code is missing entirely. All were found via the CA of the sub-element network and checked
on the page image:

- behavior: printed "expressing, C-I-17, G-2" (p. 74); parsed as element `7 expressing`. Renamed
  (`rename_sub`, both tokens). No missing edge.
- dynamic structural relations: printed "relationships, C-II-6, F-II-8" (p. 75, 400 dpi); parsed as
  `i-6` with F-II-8. Renamed to `relationships`; C-II-6/relationships already existed from an
  earlier manual fix. No missing edge.
- social heritage or tradition: printed "traditional, B-10, D-I-10, D-I-13, D-III-3" (p. 76); parsed
  as `i>-ii-5 traditional`. Renamed (4 tokens). No missing edge.
- social heritage or tradition: printed "socially inherited, B-2, B-3, B-6" (p. 77); parsed as
  `socially inherited b 2` with B-3, B-6. Renamed (2 tokens); the B-2 edge was lost (the OCR printed
  the code as `b 2`, no dash) and is recovered via the new missing-rows file.
- dynamic structural relations: printed "communicative interaction, F-III-5; interactional fields,
  E-8" (p. 75, 400 dpi); parsed as one glued element with E-8. Renamed to `interactional fields`
  (merging with the element of the same name under totality, culture as comprehensive); the
  F-III-5/communicative interaction edge was lost (OCR printed the code as `i iii- 5`) and is
  recovered via the missing-rows file.

Mechanism: `data/kk-index-b-missing-rows.csv` (heading, sub_element, kk_code, ocr_glued, evidence) is
appended by the new `add_index_b_missing()` in `build-index-b.R`, which errors if a row would
duplicate an existing edge. Recovered edges carry `parse_flag = manual_fix`. After the fixes the
edge list has 1287 rows, 464 sub-elements, 53 headings; sub-element matrix 464 × 174 with 1172 ties,
heading matrix 53 × 174 with 1061 ties. The block check flags F-III-5/communicative interaction as
`code_in_other_block` only because the text layer reads the code as `i iii- 5` (F OCR'd as i); the
printed block is confirmed at 400 dpi (review sheet, verdict OK). One reader; no double-keying.

### 3.9 Current state after the late 2026-10-24 fixes

This section supersedes the earlier statements in 3.4, 3.8 and section 8 about the tokens below. The older sections are kept as the record of what was decided at the time.

- **CODE_WRONG rows, applied (page image).** `A-1` under behavior / motor reactions → `A-17`; `D-I-13` under adjustive-adaptive / "culture is that which is useful" → `D-I-15`. Both are `set` rows in `data/kk-index-b-manual-fixes.csv` (the second is keyed on the pre-correction heading `adjustive-ajjptive function of culture`). The verdict file records them as FIXED_REBUILD.
- **F-I\ (means of adjustment), resolved to F-IV-3 by user reading.** The printed line reads "means of adjustment, D-I-17; F-IV-3". D-I-17 was already an edge. F-IV-3 is printed under "adjustments" too, which is a separate element. This reading was not checked on the page image in this session. It replaces the earlier decision that the token was unreadable behind a smudge.
- **A-i5 (accumulated treasury, totality block), resolved to A-15 by user reading.** This reverses the earlier decision to treat it as a duplicate of the social-heritage copy. The social-heritage copy (A-15, B-13, F-I-15) is unchanged. The totality-block edge is now present. Not checked on the image in this session.
- **Build state.** Index B has 1318 edges: ok 978, ocr_corrected 207, manual_fix 123, code_not_in_index_a 10. There are 472 sub-elements, 53 headings and 2 unresolved tokens (`D-I` society and `F-j` organized, both excluded as duplicates by decision). The sub-element network is 472 x 174 with 1193 ties; the heading network is 53 x 174 with 1085 ties. The block check (committed summary, unchanged by the 2026-10-26 rebuild) puts 1293 edges in their printed block and 25 in another block. The earlier 1296/22 figure was stale.
- **A-20 "adjust" edge.** Traced through the parser (`\-2o` glued into the element name, then `rename_sub` and a `missing-rows` row). The edge is correct. Its block-check flag is a checker limitation: the text layer reads the code as `\-2o`, not `A-20`.
- **F-H-j → F-II-5 (ideas), confirmed by user (2026-10-24).** The edge under "ideas and cognitive processes" (F-II-5, a token inferred by elimination in section 3.4) is the user's reading and is kept.
- **A-j → A-5 (sum), confirmed by user (2026-10-24).** The token under totality ("sum") was resolved by elimination in section 3.4; the user's reading confirms A-5.
- **F-I-i} → F-I-13 (group reference / social), confirmed by user (2026-10-24).** The token sits between F-I-12 and F-I-16 in the social list (p. 76). The user confirms F-I-13 is correct.
- **F-U → B-21 (group reference / group), confirmed by user (2026-10-24).** The token was assigned by elimination in section 3.4 (B-21 absent from the group entry in the OCR; printed list reads B-20, B-j1, ...). The user confirms B-21 is correct under group.
- **"a people" block, confirmed by user visual check (2026-10-25).** The 14 links under carriers of culture (A-3, A-5, A-12, A-19, B-14, B-20, C-I-13, C-I-14, C-I-19, C-II-2, D-I-1, E-8, F-III-3, G-5) are in the verified network. The tokens C-I-1 j, D-I-i and F-III-j map to C-I-13, D-I-1 and F-III-3 by the manual fixes and the junk decisions. The adjustments entry is a separate decision (2026-10-25, user visual check): six links, D-I-2, D-I-3, D-I-9, F-I-4, F-I-9 and F-IV-3. F-IV-3 comes from the F-IV-j token by manual fix. The manual-fix evidence for C-I-13 says it was not checked on the page image; the user has now checked it visually, but the assistant did not.
- **Angyal 1941, p. 187 (B-14), main-text entry, checked by user visual inspection (2026-10-25).** The assistant did not check this page image. The bibliography entry (printed p. 193) is a separate reference.
- **Open after this section.** Second-reader checks for all the user readings above and for the four `F-U`/`F-I-i}`/`F-H-j`/`A-j` resolutions.
- **Build note.** The manual-fix file is CRLF, like the committed copy. A quoting error in one evidence field produced a malformed row during this session; it was corrected and the rebuild verified (1318 edges, 2 unresolved).

## 4. The 39 appendix-only codes

Boroch's appendix (171 codes) has 39 codes that never appear in Table 2: A21, A22, B17,
B23, C1-7, C1-9, C1-10, C1-12..C1-15, C1-19..C1-22, C2-1, D1-10, D4-1, E4, E5, F1-2,
F1-6, F1-11, F1-12, F1-17..F1-19, F1-21, F2-2, F2-3, F2-6, F2-12, F4-1, F4-2, F4-4,
F4-5, G1, G3, G6. (F4-5 is the code that F4-6 most likely misprints; see section 5.)

Tests against K&K's text point to two mechanisms.

- **Unnumbered quotations.** Some are quotations K&K never numbered in Index B
  (A21 Herskovits 1948:625, B17 Jacobs & Stern, B23 Radcliffe-Brown, C1-7 Gillin & Gillin).
  For these, K&K's index has no entry at all. (A22 Thurnwald 1950 was listed here in an
  earlier version. Index A prints it as A-20 (1950), so it is not unnumbered. Earlier parses
  gave 1930, which was an OCR error corrected on 2026-10-24; see 3.1.)
- **Vocabulary reduction.** Some are numbered in K&K's Index B, but only under element
  headings that Boroch's 56-row vocabulary omits. D1-10 (Ford 1942) falls under
  "societal problems / problem-solutions / solving / success of responses". F1-2 (Willey
  1927b) falls under "adaptation to environment / man-made environment". Their definitions
  contain none of the 56 notion words, which is why they could not enter Table 2.

Table 2 is therefore best read as a transposition of K&K's Index B restricted to Boroch's
notion vocabulary, not as an independent coding of all definitions.

### 4.1 Year conflicts in the appendix-only links (2026-10-24)

`data/kkcc-appendix-only-links.csv` flagged seven codes where Boroch's year differed from the
year in K&K's own text, as read from our OCR layer (`documents/Kroeber-kluckhohn.pdf`, PDF page =
printed page + 3). The page images settle all seven. K&K prints the same year as Boroch and
as Index A in every case, so the conflict came from OCR errors in the text layer, not from K&K.

| Code | Boroch | K&K printed citation (printed p.) | Index A row | OCR reading that caused the flag |
|---|---|---|---|---|
| A22 | Thurnwald 1950 | "20. Thurnwald, 1950: 104" (p. 44) | A-20 (1950) | "1930" |
| C1-9 | Linton 1945b | "8. Linton, 1945b: 203" (p. 50) | C-I-8 (1945b) | "1943b" |
| C1-10 | Linton 1945a | "9. Linton, 1945a: 30" (p. 50) | C-I-9 (1945a) | "1943a" |
| E5 | Linton 1945a | "5. Linton, 1945a: 5, 32" (p. 61) | E-5 (1945a) | "1943a" |
| F2-3 | Schmidt 1937 | "3. Schmidt, 1937: 131" (p. 66) | F-II-3 (1937) | "1931" |
| F2-12 | Becker 1950 | "10. Becker, 1950: 251" (p. 67) | F-II-10 (1950) | "1930" |
| F4-2 | Ostwald 1915 | "2. Ostwald, 1915: 192" (p. 70) | F-IV-2 (1915) | "1913" |

Each row was checked on the page image (150 dpi). The Index A rows were already checked against
the page images in 3.1. These seven codes are now linked to the Index A row shown. The year
dispute is closed.

The same pages settle the open rows A16, A17, A20 and A21 (section 3.2), and C1-11 and C1-12
(section 3.2 for C1-11, the appendix-only links for C1-12). C1-13 is now settled too: its quotation is printed as item 12 on
printed p. 51 (PDF p. 54), "Kluckhohn and Kelly, 1945a: 91", which follows items 10 and 11 as C-I-12.
No appendix-only row remains ambiguous.

## 5. The F4-6 resolution

Boroch's Table 2 includes a column F4-6 with no appendix entry. The evidence points to an
off-by-one slip for his own F4-5, which is Kluckhohn & Kelly 1945a: 87.

- K&K's Part II, group F-IV, has exactly five definitions. All five (F4)-tagged works
  appear in the Supplement Bibliography.
- K&K's concept index entry "acting, A-8, C-I-3, C-I-17, F-IV-5" matches Boroch's ACTING
  row cell for cell.
- The code F4-5 appears nowhere in Table 2.

The crosswalk therefore sets F4-6 → Kluckhohn & Kelly 1945a and labels it
`manual_F4-6_slip`. The rule-based matcher would have returned no match, since K&K has no
F-IV-6.

2026-10-26: `kkcc-definition-texts.csv` now fills F4-6's text with F4-5's quotation and
records the copy in a `text_note` column (user decision); A10a and C1-5a, the other two
Table 2 columns without an appendix entry, carry their base codes' text with the same kind
of note. The appendix-only F4-5 row in `kkcc-appendix-only-texts.csv` was corrected on the
same occasion: it lacked the opening clause ("Kluckhohn […] culture includes all those ways
of feeling,") and had absorbed the "Group G Incomplete definitions" banner. Basis: the
`pdftotext -layout` text layer of the Table 13 page (printed p. 93), not a page-image check.

## 6. Boroch's numbering is not K&K's

Boroch's codes are K&K's groups with subgroups written as digits (C1 = C-I, D2 = D-II,
F4 = F-IV). Within a group, however, Boroch renumbers. For example:

- Boroch A10 = Winston 1933. K&K A-10 = Linton 1936. K&K's Winston 1933 is A-9.
- Among the 100 crosswalk matches made by author, year, group, and subgroup, only 48
  agree with the positional mapping.

A positional crosswalk would therefore mislabel about half the definitions. The
crosswalk uses author and year, and positional agreement is reported only as a check.

## 7. Moore (1980) cross-check

Moore's literature review quotes 46 citations. 43 match an author and year in the 135
codes. The exceptions are a Small citation (1908 printing; K&K D-I-1 is Small 1905) and the
two Ford 1942 and Willey 1927b citations, which are the appendix-only codes discussed in
section 4. Moore prints the Ford 1942 quotation at pp. 555, 557. K&K's appendix prints
the same passages at pp. 333, 337. The discrepancy is recorded and not resolved.

## 8. Known gaps

Status as of 2026-10-24. Items marked open need a decision or a page-image check that has not been made.

- **Heading attribution (corrected 2026-10-24, one reader).** The rules in section 3.5 are applied in `build-index-b.R`. The current block check (section 3.9) puts 1293 of 1318 edges in their printed block (committed summary, rechecked 2026-10-26); the 17 review-sheet verdicts in section 3.7 were recorded against the earlier 1285-edge build. A human second reader has not checked the rules.
- **Unresolved Index B tokens (open, 2).** `D-I` (society) and `F-j` (organized) are excluded as duplicates by decision. `F-I\` and `A-i5` were resolved to F-IV-3 and A-15 by the user's reading (section 3.9; not image-checked in this session). Four earlier resolutions rest on printed sequence rather than a clean glyph read; a second reader should check them.
- **Junk sub-element names (resolved 2026-10-24, section 3.6).** All 33 `junk_name` edges and six single-letter `manual_fix` edges are mapped to the element printed in their block. The decisions were read from the text layer, not the page image.

**Garbled element labels (2026-10-24).** The OCR damage in some element names is not in the codes. The
ABBYY text layer carries the same damage, so text checks cannot catch it; the Archive OCR, which lacks it,
flags it. `intcrcorrclated customs` (E-2) is corrected to `intercorrelated customs` by a `rename_sub` row,
checked on the scan crop. The other labels were corrected by `rename_sub` rows on 2026-10-24: `manmade environment` and `sc1 etion` (checked on the scan crops), and `j intcgrared and oninregrared groups`, `non-phvsiological products`, `not ereated`, `reactionfonnat ons`, `constitutional chaners`, `categories of acpons` and `v-i distoned satisfaction` — all seven checked on the scan on 2026-10-24 (per-row evidence in the manual-fix file). Six printed as proposed. One was wrong: the text layer proposed `constitutional changes`, but the 600 dpi crop prints "constitutional charters, A-13" (social institutions block, printed p. 77); the label was corrected to `constitutional charters` and the pipeline rebuilt (edge total and matrix counts unchanged). Element count 466 → 465. The OCR prefixes on `v-j adjusting`, `v-j biopsychological organism` and `i-j rational` were removed by `rename_sub` rows (the remaining words were confirmed as printed by the user).
- **Flagged edges.** All 26 FIX rows are in the manual-fix table; their keys and codes match the flagged audit. Two CHECK rows are resolved (`F-1` "adjustments" → F-IV-3; `F-19` "adaptive behavior" → F-I-19). A `B-ji` FIX row merges into an existing `B-5` edge when the build removes duplicates.
- **Unaudited ok rows (partly checked 2026-10-24).** About 978 `ok` edges (current build) have no audit verdict; the earlier figure of 915 predates the latest build (section 3.3). A 50-row random sample (seed 4817) is in `data/kk-index-b-ok-sample.csv`; all 50 rows were read against the page images on 2026-10-24 (PDF pp. 77-81, quadrant crops at 300 dpi, single reader). Verdict: 50 OK, 0 errors; Clopper-Pearson 95% upper bound on the error rate 7.1% (rule of three: 6%). The sample's heading column predates the heading corrections; verdicts were checked against the current edges, which always matched the printed block. Per-row notes are in the sample file.
- **Manual fixes without an audit row (open).** Most of the 115 current `manual_fix` edges have no row in either audit file (section 3.3, a dated snapshot). Their evidence is the printed citation in `kk-index-b-manual-fixes.csv`. The six 2026-10-24 resolutions are in that group.
- **Index A.** Every row on printed pp. 73–74 was read against the page image (section 3.1). That is a single-reader check, not double-keyed. Sears's `C-I-Addendum` is printed that way. It is an addendum linked to a specialty code and is not a network code (user decision 2026-10-25).
- **Crosswalk (resolved 2026-10-24).** A16, A17, A20, C1-11 and B5 are decided in section 3.2, and
  the appendix-only rows A21, C1-12 and C1-13 are in `data/kkcc-appendix-only-links.csv`. The
  one point was that Index A printed Myres B-4a as 1929 while the Part II entry and the K&K bibliography read 1927. The Index A entry is now corrected to 1927 (`kk-index-a-manual-fixes.csv`, 2026-10-26); the 1929 was a K&K index error (section 3.2).
- **Appendix-only codes.** The 39 codes have no author or year in `kkcc-definition-years.csv`, so the crosswalk does not link them. They are linked to their Index A rows in `data/kkcc-appendix-only-links.csv` (39 linked).
- **G1 and F1-21, page image check (2026-10-25).** G1: Group G, item 1, "Sapir, 1921: 233", printed p. 72 (PDF 75), quotation "Culture may be defined as what a society does and thinks." F1-21: Group F, item 20, "Kluckhohn, 1951a: 86", printed p. 65 (PDF 68), quotation "Culture designates those aspects of the total human environment, tangible and intangible, that have been created by men." Both citations match `kkcc-appendix-only-texts.csv`. G1 has no Index A row and stays unlinked. F1-21 is linked to F-I-20 by user decision (2026-10-25). Its quotation is Group F item 20 in the main text, and Index B lists F-I-20 under tangible and intangible aspects of human environment. Index A's F-I-20 row is F. R. Kluckhohn (1950), not Kluckhohn 1951a, so the link rests on the main-text citation. The crosswalk row for F1-20 (Murdock 1949, mapped to F-I-20) may have the same one-number offset; not checked.

- **G1 linked to G-1 (2026-10-26).** The 2026-10-25 note above is corrected: Index A does have a Sapir G-1 row. Printed p. 74 reads "Sapir, B-2 (1921). B-3 (1924a), G-1 (1921)." (300 dpi page image, PDF 77); the earlier check missed the G-1 row because the parse's OCR year for it was "(19 :1)". That qualifier is now fixed to (1921) in `data/kk-index-a-manual-fixes.csv`, and `data/kkcc-appendix-only-links.csv` links G1 to G-1 (user decision 2026-10-26). Consequences of the rebuild: the works table's "Sapir 1921" row now carries B-2; G-1, and the G-1 code vertex carries the Boroch label G1. Boroch's G1 quotation was already page-checked on 2026-10-25 (paragraph above).
- **Element labels.** Index B element labels are unverified against the page image and may contain residual OCR damage.
- **Definitions without a Boroch text (recorded 2026-10-26).** Four of the 170 verified codes have no quotation in Boroch's Table 2 or appendix, and no matching author-and-year entry exists anywhere in his data: D-5 (Goldenweiser 1933), D-7 (Roheim 1934), D-III-4 (Roberts 1951) and E-17 (Taylor 1950). D-5 and D-7 are Index B codes that Index A does not list, so Boroch's subgroup-based columns cannot carry them; Roberts 1951 and Taylor 1950 are works Boroch does not cite. Their definition texts are now transcribed from K&K's own Part II into `data/kk-definition-texts-kk-only.csv`, one row per code with the printed citation, the printed page and a per-row basis: D-5 and D-7 are Group D statements 5 and 7 (printed p. 103, PDF 105), D-III-4 is the Group D-III page footnote 14 (printed p. 60, PDF 63) — the fourth D-III entry, after three numbered statements — and E-17 is Group E statement 17 (printed p. 123, PDF 125). All four were transcribed from the 300 dpi page images by the assistant; the Roheim citation digits were checked at 600 dpi (the image prints 235–36, the text layer 239). Page numbers are read from the page images; the PDF offsets differ (PDF 63 prints 60, PDF 105 prints 103, PDF 125 prints 123). The file carries verbatim K&K quotations and stays out of any release, like the Boroch text files.
- **Rights (partly decided 2026-10-24).** User note: the 1952 K&K monograph is publicly available online, and K&K element labels are not treated as a barrier (README, Rights). Boroch's article and its verbatim quotations remain restricted; the user has not addressed them.

## 9. Work citations (2026-10-26)

Method. `scripts/build-index-b-work-citations.R` builds `data/kk-index-b-work-citations.csv`, one row per Index B work (134 after the merge in 9.4). Each work is matched to K&K's bibliography in the ABBYY text layer (PDF pp. 190–208) on surname, year and, where the work label carries them, initials. It is also matched to Boroch's supplement bibliography (`data/kkcc-supplement-bibliography.csv`). The automatic K&K match is not evidence on its own: the title check counts shared generic words, and proximity chooses among candidates. Rows checked on the page image are listed in `data/kk-index-b-work-citations-page-checks.csv`, which overrides the automatic match. Open rows are in `docs/TODO.md` (section "Citation list").

9.1 Myres (2026-10-26). Index A prints B-4a as (1929), which is a K&K index error. Part II (printed p. 47) and the K&K bibliography (printed p. 199, PDF 198, checked on the page image) both give 1927. The Index A fix sets B-4a to (1927), so the work is Myres 1927. The bibliography prints "New York" only. The publisher, Abingdon Press, comes from the user and the Google Books record in section 3.2, not from K&K's printed text.

9.2 Young, D-II-7 (2026-10-26). The printed index and footnote 7 say 1947, and Boroch cites 1947 (B123). The K&K bibliography lists "Young, K. 1944. Social Psychology (2nd ed.) New York" (printed p. 203, PDF 202, checked on the page image). The user chose 1944 to follow the bibliography. The book has several printings with different years (7th printing July 1944; 12th printing January 1947), so the printing year is not a basis. The Index A fix and crosswalk decision D2-7 are updated. The 1947 readings in the printed index and footnote are unchanged.

9.3 Roberts 1951 (2026-10-26). Index A (D-III-4) and the main text (p. 3 citation) give 1951. The K&K bibliography prints "Roberts, J. M. 1950" for *Three Navaho Households* (printed p. 201, PDF 200, checked on the page image). The eHRAF record (https://ehrafworldcultures.yale.edu/cultures/nt13/documents/217) gives "Published in 1951" as Museum Papers 40(3). The user confirmed 1951. The row is kept as `year_conflict`, with the bibliography title and series and the 1951 year.

9.4 Committee mimeograph (2026-10-26). "Views on Definition of Culture. Committee on Conceptual Integration. Mimeographed" (1941; unpublished, no publisher) is printed in the K&K bibliography under three names: Blumenthal, A. (printed p. 194, PDF 193), Dodd, S. C. (p. 195) and Hart, H. (p. 196). Boroch lists it under Blumenthal (B076, D1; B077, F4), Dodd (B078, F1) and Hart (B079, F1). The names reflect the committee's members. Index B has Blumenthal 1941 (D-I-9, F-IV-3), Dodd 1941 (F-I-10) and Hart 1941 (F-I-11). These are merged into one document-level work, "Committee on Conceptual Integration (Blumenthal, Dodd, Hart) 1941", with four codes, by three name decisions. The bibliography title has no "the". A Google Scholar record shows the same title, "Blumenthal, Marietta, O.: Committee on Conceptual Integration, 1941". The "the" form was not found in these sources.

9.5 Kluckhohn initials (2026-10-26). The works Kluckhohn 1942, Kluckhohn & Leighton 1946, Kluckhohn 1949a, Kluckhohn 1951a and Kelly & Kluckhohn 1945a are by C. Kluckhohn (bibliography and Boroch). F. R. Kluckhohn published 1950 (Index A F-I-20, the only F. R. work in Index B) and 1951 (*Dominant and Variant Cultural Value Orientations*, not an Index B work). C. Kluckhohn published 1951a (*The Concept of Culture*, PDF 196) and 1951b (not an Index B work). Name decisions put "C." on the five C. works. The citation matcher now checks the initials in the K&K header. If no candidate shows them, it falls back to surname only and notes it.

9.6 Stern (2026-10-26). Index A reads "Stem" for Stern in Jacobs & Stern 1947 (bibliography printed p. 197, PDF 196, checked on the page image). The name decision gives "Stern B.J." for 1947, so the work is "Jacobs & Stern B.J. 1947".

9.7 Other page checks and corrections (2026-10-25 and 2026-10-26). Nimkoff & Ogburn 1940 (printed p. 200, PDF 199): "Ogburn, W. F. and Nimkoff, M. F. 1940. Sociology. Boston." The automatic match (Davis and Dollard, *Children of Bondage*) was wrong. Publisher Houghton Mifflin from Google Books (user link). F. R. Kluckhohn 1950 (printed p. 198, PDF 197) matches the user's reference (Social Forces 28(4): 376–93). Young 1942 (printed p. 203, PDF 202, *Sociology: A Study of Society and Culture*) matches Boroch B091; the CiNii record the user gave could not be read. Gillin 1942 and 1948, Jacobs & Stern 1947, Morris 1948, Murdock 1949a, Titiev 1949, White 1949a, Goldenweiser 1933 and 1937, Osgood 1940 and 1942, and Wissler 1916, 1920 and 1929 were checked on the page images.

9.8 Page offset. On the bibliography pages PDF 193–203 the printed number is the PDF page + 1 (PDF 196 prints as p. 197). This is not the −3 offset of the Index B pages (PDF pp. 77–81), and the project memory is updated to match.

9.9 Publishers. K&K prints places, not publishers, for most entries. Publishers added to the citation table come from the user or from Google Books: Abingdon Press (Myres 1927) and Houghton Mifflin (Nimkoff & Ogburn 1940). Each is recorded in the note of its page-check row, not as K&K's printed text.

9.10 Ford and Lowie page checks. The three Ford works and the two Lowie works were checked on the page images (Ford: PDF 194, printed p. 195; Lowie: PDF 197, printed p. 198). Each K&K entry matches the automatic pick: Ford, C. S. 1939 (Society, Culture, and the Human Organism), Ford, C. S. 1942 (Culture and Human Behavior), Ford, J. A. 1949 (Cultural Dating of Prehistoric Sites in Viru Valley, Peru), Lowie 1934 (An Introduction to Cultural Anthropology) and Lowie 1937 (The History of Ethnological Theory). Boroch agrees for four of the five, but Boroch B060 (Ford 1939) gives the title of Ford's 1937 Keller-festschrift article ("A Sample Comparative Analysis of Material Culture") with the year 1939. That 1937 article is not an Index B work and is not in K&K's 1939 entry. The Boroch row is flagged `both_disagree`; the K&K match is kept on the year and the printed title. The page-check rows are in `data/kk-index-b-work-citations-page-checks.csv`, and the citation table was rebuilt. Only these five rows changed.

9.11 Benedict 1947 and Bernard 1942 (page checks). Both entries are on printed p. 193 (PDF 192), checked on the page image. Benedict, R. 1947 is *Race, Science and Politics* (Rev. ed.), New York (Boroch B114 matches). Bernard, L. L. 1942 is *An Introduction to Sociology*, New York (Boroch B083 matches). Both rows moved from `boroch_only` to `page_checked`.

Bernard 1941b (merged, user decision). Bernard's 1941b entry (printed p. 193, PDF 192) is the committee mimeograph, so it joins the committee work as year 1941, with name "Committee on Conceptual Integration (Bernard, Blumenthal, Dodd, Hart) 1941". The works build keys each work on its year string, and Index A writes this entry as `1941b`. `data/kk-index-b-name-decisions.csv` now has a `group_year` column: the Bernard row maps year 1941b to group year 1941. `build-work-concept-network-index-b.R` applies it in `code.works()` and `canon.names()`. The committee work now has five codes (D-I-9, F-I-9, F-I-10, F-I-11, F-IV-3). The works table has 133 works. Index B has no Bernard 1941a work: the 1941a Social Forces article is not in Index B, and it appears only in Boroch's B075 entry, which is left as Boroch wrote it. The works CA, MST, centrality and degree outputs were not rerun after this change.

9.12 Bogardus 1930 (page check). Printed p. 194 (PDF 193), checked on the page image: Bogardus, E. S. 1930, *Tools in Sociology*, *Sociology and Social Research* 14, pp. 332–41. Boroch B031 matches. The row moves from `boroch_only` to `page_checked`.

9.13 Burkitt 1929 (page check). Printed p. 194 (PDF 193), checked on the page image: Burkitt, M. C. 1929, "Archaeology", *Encyclopaedia Britannica* (14th ed.), New York. Boroch B026 matches. The row moves from `boroch_only` to `page_checked`.

9.14 Haring 1949 (page check). Printed p. 196 (PDF 195), checked on the page image: Haring, D. G. 1949, "Is Culture Definable?", *American Sociological Review* 14, pp. 26–32. Boroch B140 matches. The user supplied https://www.jstor.org/stable/2086442 as the cite. The JSTOR page returned an access challenge in this session, so its metadata is unverified and is not the basis of the row. The row moves from `boroch_only` to `page_checked`.

9.15 Gorer 1949 (page check). Printed p. 196 (PDF 195), checked on the page image: Gorer, G. 1949, *The People of Great Russia*, London. Boroch B139 matches. The row moves from `boroch_only` to `page_checked`.

9.16 Firth 1939 and Redfield 1940 (page checks). Firth, R. 1939, *Primitive Polynesian Economy*, London, printed p. 195 (PDF 194), checked on the page image; Boroch B059 matches. Redfield: K&K prints "REDFIELD, R. Unpublished lectures. Quoted in Ogburn and Nimkoff, 1940" on printed p. 200 (PDF 199). This is a quotation from unpublished lectures, not a published work, and the year is that of the quoting book. A new image status, `quoted_in`, marks such works; the build keeps them as K&K-attested (`kk_status` = `quoted_in`). Boroch B072 cites the same source through Ogburn and Nimkoff. Redfield is removed from the K&K-only list in TODO item 16 because Boroch does cite it. The citation table was rebuilt after these rows were added.

9.17 Sorokin 1937 (page check). Printed p. 202 (PDF 201), checked on the page image: Sorokin, P. A. 1937–41, *Social and Cultural Dynamics*, 4 vols., New York. K&K's year range starts in the Index B year, so the Index B year (1937) stands. Boroch B055 gives the title and place but cites volume 1 only (t. 1); the title is treated as matching. This row moves from `boroch_only` to `page_checked`. With it, no Boroch-only works remain in TODO item 15.

9.18 K&K-only works kept. F. R. Kluckhohn 1950, Goldenweiser 1933 and 1937, Roberts 1951 and Young 1944 are Index B works with K&K entries and no Boroch entry, so the citation table keeps them with their K&K lines and records `boroch_status` = `not_found`. Boroch's absence does not change the works network, which is built from K&K's Index A and B. Redfield 1940 is K&K-attested as a quotation (`quoted_in`) and has a Boroch entry (B072). Linton 1945b was listed as K&K-only in error: Boroch cites it (B106, C1). Its K&K pick is still unchecked (TODO item 12).

9.19 Linton 1945b (page check). Printed p. 198 (PDF 197), checked on the page image: Linton, R. 1945b, *Present World Conditions in Cultural Perspective*, in *The Science of Man in the World Crisis* (ed. R. Linton), pp. 201–21, New York. Boroch B106 matches. The automatic match had chosen a different 1945b line; the K&K entry printed under Kluckhohn (*The Concept of Culture*, mimeographed) is a separate work and is not used. The row moves from `matched_multiple` to `page_checked`.

9.20 Bose 1929 (page check). Printed p. 194 (PDF 193): one K&K entry, Bose, N. K. 1929, *Cultural Anthropology*, Calcutta. The place is partly obscured by a smudge on the scan and was read from the visible letters. Bose is cited twice in K&K: in the bibliography (PDF 193) and in footnote 3 of the main text ("Bose, 1929: 7-8, 24", PDF 86). The bibliography has one entry, which this row records. Boroch has two references with the same title, B023 (code A) and B024 (code B), for the same work. The automatic match was `matched_multiple` because the text layer lists other 1929 entries on the same page, not because K&K has two Bose works. The row moves to `page_checked`.

9.21 Turney-High 1949 (page check). Printed p. 202 (PDF 201), checked on the page image: Turney-High, H. H. 1949, *General Anthropology*, New York, one bibliography entry. Boroch has two references, B150 (code D1) and B151 (code E), for the same work, as with Bose (9.20). The row moves to `page_checked`.

9.22 Bain 1942 (page check). Printed p. 193 (PDF 192), checked on the 300 dpi page image: Bain, R. 1942, "A Definition of Culture", *Sociology and Social Research* vol. 27, pp. 87–94. The text layer (OCR) reads vol. 17, which is a misreading; the image and Boroch B082 both read 27. The row moves to `page_checked`.

9.23 Boas 1930 (page check). Printed p. 194 (PDF 193): Boas, F. 1930, "Anthropology", *Encyclopedia of the Social Sciences* vol. 2, pp. 73–110, New York. One bibliography entry, checked on the image and the text layer. Boroch B030 matches. The row moves from `matched_multiple` to `page_checked`.

9.24 Carr 1945 (page check). Printed p. 194 (PDF 193): Carr, L. J. 1945, "Situational Psychology", *American Journal of Sociology* vol. 51, pp. 136–41. One bibliography entry, checked on the image and the text layer. Boroch B098 matches. The row moves from `matched_multiple` to `page_checked`.

9.25 Davis Allison 1948 (page check). Printed p. 194 (PDF 193): Davis, A. 1948, *Social-Class Influences upon Learning*, Cambridge. One bibliography entry, checked on the image and the text layer. K&K gives the initial only. Boroch B124 matches. The row moves from `matched_multiple` to `page_checked`.

9.26 Davis Kingsley 1949 (page check). Printed p. 194 (PDF 193): Davis, K. 1949, *Human Society*, New York. One bibliography entry, checked on the image and the text layer. K&K gives the initial only. Boroch B137 matches. The row moves from `matched_multiple` to `page_checked`.

9.27 Frank 1948 (page check). Printed p. 195 (PDF 194): Frank, L. K. 1948, *Society as the Patient*, New Brunswick. One bibliography entry, checked on the image and the text layer. Boroch B125 matches. The row moves from `matched_multiple` to `page_checked`.

9.28 Henry 1949 (page check). Printed p. 196 (PDF 195): Henry, J. 1949, "Anthropology and Psychosomatics", *Psychosomatic Medicine* vol. 11, pp. 216–23. One bibliography entry, checked on the image and the text layer. Boroch B141 (code B) matches. The row moves from `matched_multiple` to `page_checked`.

9.29 Lynd 1940 (page check). Printed p. 199 (PDF 198): Lynd, R. S. 1940, *Knowledge for What?*, Princeton. One bibliography entry, checked on the image and the text layer. Boroch B069 (C1) matches. The row moves from `matched_multiple` to `page_checked`.

9.30 Mead 1937 (page check). Printed p. 199 (PDF 198): Mead, M. 1937, *Cooperation and Competition among Primitive Peoples*, New York. One bibliography entry, checked on the image. Boroch B052 (B) matches. The row moves from `matched_multiple` to `page_checked`.

9.31 Rouse 1939 (page check). Printed p. 201 (PDF 200): Rouse, I. 1939, *Prehistory in Haiti*, Yale Publications in Anthrolopogy, no. 21. The page prints "Anthrolopogy", a typo that the user identifies as carried over into the K&K printing from the correct "Anthropology"; the citation uses "Anthropology". Boroch B065 has the same typo in its supplement, which is left unchanged. The row moves from `matched_multiple` to `page_checked`. With this row, no `matched_multiple` works remain, and TODO item 12 is resolved.

9.32 Remaining automatic matches (page checks). The 73 single-candidate automatic matches (`kk_status` = `matched`) were checked against the bibliography page images, PDF 192–202 (printed 193–203), grouped by page. Each K&K line in the page-check file is the entry as printed. 72 agree with the automatic line and with Boroch's record. One is corrected: White 1949b. The automatic match was Kroeber 1949, *The Concept of Culture in Science*, which is not White's work. The page prints "1949b. The Science of Culture. New York." (PDF 202, printed p. 203), which matches Boroch B153. The ten works in the seeded sample of 9.32's predecessor check (Keller 1931, Parsons 1949, Menghin 1934, Malinowski 1931, Schmidt 1937, Thomas 1937, Bidney 1947, Lasswell 1948, Dollard & Miller 1941, Hockett 1950) were checked on the images but are not recorded in the page-check file, so they stay `matched` until recorded. Author order differs from the citation label for Kelly & Kluckhohn 1945a, Dollard & Miller 1941 and Davis Allison & Dollard 1940; the K&K printed order is kept in the entry.

9.33 Publishers added (TODO item 18, closed). Two publishers are added to the citation records, and K&K's printed lines are unchanged. Myres 1927: Abingdon Press, from Google Books (the 1927 record cited in 3.2) and the user. Nimkoff & Ogburn 1940: Houghton Mifflin, from Google Books via the user-supplied link. Each is recorded in the notes of its page-check row, as 9.9 requires. The Myres K&K line had Abingdon Press inside it and is corrected to K&K's printed line, New York.

9.34 Suffix removed from the Bernard data (user decision). The mimeograph entry is the only Bernard 1941 work in Index B, so its year is 1941, not 1941b. Changes: (a) `data/kk-index-a-manual-fixes.csv` sets the qualifier of Bernard F-I-9 to (1941) (the printed index says (1941b); evidence in the file). (b) `data/kk-index-b-name-decisions.csv` has year 1941 for Bernard and an empty `group_year`, so the decision applies directly to year 1941. The `group_year` mechanism in the work build has no rows now and can be removed. The Index B chain was rebuilt (build-index-b through build-index-b-work-citations) with no errors; the validators pass. The works table is unchanged apart from the Bernard label, which is "Committee on Conceptual Integration (Bernard, Blumenthal, Dodd, Hart) 1941". The CA, MST and centrality outputs for works were not rerun and still show the earlier names (TODO item 9).

9.35 Analysis rerun after the Bernard change. The Index B analyses were rerun in order (analysis-index-b, analysis-ca-index-b, analysis-ca-works-index-b, analysis-centrality-index-b, analysis-mst-definitions-index-b, analysis-mst-works-index-b). They run without errors, and the works outputs use "Committee on Conceptual Integration (Bernard, Blumenthal, Dodd, Hart) 1941". The figures were regenerated. Their content was compared with the earlier versions on 2026-10-26 (TODO item 9; section 10). Remaining "1941b" strings are in Boroch's own files (`kkcc-definition-biblio.csv`, `kkcc-supplement-bibliography.csv`), in the printed-index evidence in `kk-index-a-manual-fixes.csv`, and in the name-decision basis text.

9.36 Bernard grouping moved to the name decisions (user decision, 2026-10-26). This amends 9.34: the Index A manual fix that set Bernard F-I-9's qualifier to (1941) is removed, and Index A keeps the printed (1941b). The grouping now lives in `data/kk-index-b-name-decisions.csv`: the Bernard row has year 1941b (the printed qualifier, so the group-year rule matches the entry) and group_year 1941, so `code.works()` moves the entry into the 1941 group and `canon.names()` maps the four names to the committee name. The works key is unchanged, "Committee on Conceptual Integration (Bernard, Blumenthal, Dodd, Hart) 1941", still with five codes. The full chain was rebuilt (build-index-b through the analyses) with the validators passing; the works table is unchanged apart from "Sapir 1921" now carrying G-1 (see the G-1 note in the crosswalk section). 9.34's remark that the group_year mechanism has no rows and can be removed is superseded; the mechanism is now the sole carrier of this decision.

## 10. Works-network figure review (TODO item 9, 2026-10-26)

Scope: the works outputs (`kk-index-b-ca-works-lcc2core-works.csv`, `kk-index-b-centrality-works.csv`, `kk-index-b-mst-works-nodes.csv`) and all works figures in `figures/kk-index-b/works/`, plus `figures/kk-index-b/degree-works-definitions.png`. Compared with the committed (HEAD) versions. Labels were normalized by dropping initials ("Kluckhohn C. 1942" and "Kluckhohn 1942" are one work) before matching.

10.1 Work set. The works in the 2-core fell from 122 to 119 in the CA and MST outputs; the centrality output falls from 596 to 593 nodes, of which 589 are common after normalization. The difference is the work-set decisions made since the committed version, not the 2-core itself: (a) the four Committee-group works (Bernard 1941b, Blumenthal 1941, Dodd 1941, Hart 1941) are one work, the Committee mimeograph, which is 3 fewer works; (b) Young 1946 becomes Young 1944 (the D2-7 decision); (c) Jacobs & Stem 1947 becomes Jacobs & Stern 1947 (spelling); (d) Myres 1929 becomes Myres 1927 in the centrality output (the Abingdon Press record). The 136-to-133 change in the release networks has the same source.

10.2 Confounding. The 2-core change is not separated from the 10.1 changes. The committed outputs were produced before both changes, and rerunning the old chain with only the 2-core change reverted was not done. The attribution of any difference below to the 2-core is therefore not established.

10.3 Values for works present in both versions.
- CA: the masses changed for all 111 common works, as expected from the 2-core and the work set. The first axis matches the old one up to sign (|r| = 0.95; the sign is reversed, as eigen signs are arbitrary). The second axis correlates at r = 0.90. Axes 3 to 5 were not compared numerically.
- Centrality (589 common nodes, all modes): degree, closeness and betweenness correlate at r ≥ 0.9996; degree is identical for 99.3% of nodes. Betweenness leaders are unchanged (social, society, beliefs, group, behavior).
- MST (116 common works): betweenness rank correlation 0.85; the tree degree is identical for 84% of works; the community partitions differ (adjusted Rand index 0.71). The number of communities is 16 in both versions, but the members differ, so the colors in the works MST figure are not comparable with the earlier figure.

10.4 Figures. All works figures were viewed (the old and new versions where a committed version exists). None is broken: the axes, labels, legends, and tree structure are intact. Visible problems, not blocking:
- The works MST: the long "Committee on Conceptual Integration (Bernard, Blumenthal, Dodd, Hart) 1941" label runs across the Gillin and Young K. 1942 labels and crowds them.
- The works CA, dims 4 vs 5: the Committee label is partly covered by the Kelly and Kluckhohn 1945a label.
- The degree figure's work panel includes works with degree 0 (4 works), because it is computed on the full network, not the 2-core. The panel title does not say so.

10.5 Conclusion. The works outputs and figures are consistent with the current data. Centrality is stable. CA positions are moderately stable. MST community membership changed for about a third of the works and should be reported as the current output, not as the earlier one. The label crowding in 10.4 is a presentation issue for a later pass.

10.6 Committee mimeograph in the code tree (decision, 2026-10-26). `figures/kk-index-b/definitions/mst-code-comm-tree.png` shows the mimeograph once per code that holds it (D-I-9, F-I-9, F-I-10, F-I-11, F-IV-3), so the same label appears five times. The user decided to keep five code vertices and not to attach the codes to one work vertex. The one-work treatment still holds for the works network and the citation list (9.4). The same repetition applies to 19 works held by two or more codes; Kelly & Kluckhohn 1945a has the most (8 codes). Later the same day the user pointed out that a code-level tree should be labeled with codes, not works. `scripts/analysis-mst-definitions-index-b.R` now labels each node with its K&K code (for example D-I-9). The works each code holds are in a new `works` column of `data/kk-index-b-mst-definitions-tree-nodes.csv`. The rerun left the communities, betweenness and tree degrees of all 145 codes unchanged (checked against the committed table). The repetition is gone, because the five Committee codes now carry their own labels. The Boroch B075 note in TODO item 20 stays open. The node shape now encodes the K&K definition group, the first letter of the code (A to G), drawn as a filled `ggstar` symbol (A circle, B regular triangle, C square, D rhombus, E triangle down, F pentagon, G hexagon). Fill is the community color. The size legend is drawn with `ggstar` stars too, since the node layer is a `geom_star` layer. The legend is titled "definition type (K&K group)" and gives each letter's category name: A Descriptive, B Historical, C Normative, D Psychological, E Structural, F Genetic, G Incomplete. The names were supplied by the user (2026-10-26); the repo does not record them, and they are set in `scripts/kk-group-style.R`, which both `scripts/analysis-mst-definitions-index-b.R` and `scripts/analysis-ca-index-b.R` read. The definitions CA group centroids (`figures/kk-index-b/definitions/ca-lcc2core-*.png`) use the same symbols and names, so the group reads the same in both figures. Node color is still the community, and it has no legend, as before.

## 11. Heading MSTs (2026-10-26)

`scripts/analysis-mst-headings-index-b.R` builds maximum spanning trees of the heading projections, after the largest component's 2-core (`lcc_2core()`, as for the other projections). Definitions: headings x codes (`data/kk-index-b-heading-network.rds`), ties = codes both headings hold, figure `figures/kk-index-b/definitions/mst-heading-comm-tree.png`. Works: headings x works (`two_mode_heading_graph`), ties = works both headings hold, figure `figures/kk-index-b/works/mst-heading.png`. Node labels are the heading names. Node table: `data/kk-index-b-mst-headings-nodes.csv`.

11.1 The 2-core drops five headings from each projection (diffusion, forbidden, the permitted, the psychoanalytic elements, sanction). Each has one code (definitions) and one work (works). The 2-core drops a node with a single link even when that link is shared, so these five headings can have ties that the figures do not show. Both trees are connected over the remaining 48 headings.

## 12. Goldenweiser's attributions are Part III codes (2026-10-26)

12.1 The question. The text-coverage check (`scripts/check-definition-text-coverage.R`) attached a definition text to 130 of 133 works. Two of the three exceptions were the documented conflicts (D-II-7 Young, F-I-20 Kluckhohn 1951a; 9.2 and the F-I-20 note in the crosswalk section). The third was Goldenweiser 1937, whose only code was E-5. The user asked for a page-image check of Part II group E for a Goldenweiser 1937 quotation.

12.2 The finding. K&K quote Goldenweiser only in Part III, never in Part II. The Part III author index (printed p. 141, PDF 143) prints "Goldenweiser, c-5 (1937), d-5 (1933), f-8 (1933)" (checked at 600 dpi); the text layer misreads c-5 as e-5, and the 2026-10-25 user mapping had followed that misread into a Part II E-5 attribution. The three statements are Part III group c statement 5 (printed p. 99, PDF 101: "Goldenweiser, 1937: 45-46"; the text layer garbles the name as "Goldcnu'ciscr" and misreads 45 as 43), group d statement 5 (printed p. 103: Goldenweiser, 1933: 59) and group f statement 8 (printed p. 127: Goldenweiser, 1933: 63), the last two already recorded. Printed Index A (pp. 73-74) has no Goldenweiser entry at all (image-checked; the OCR text layer drops the whole name there). The acknowledgments page (PDF 4) confirms K&K quoted Goldenweiser's Anthropology (1937). The permissions trail and the Part III index entries leave no Goldenweiser 1937 quotation under Part II group E or anywhere in Part II.

12.3 The change (user decision 2026-10-26: remap and keep the work). `data/kk-part-iii-author-codes.csv`: the Goldenweiser 1937 row is remapped E-5 → C-5 with printed page 99. C-5 enters the verified network through `data/kk-index-b-verified-extra-codes.csv`; it is the first verified code with no Index A entry and no Index B element, so `build-index-b.R` now extends the universe with the verified extras (previously the extras only flagged codes already in the universe). The C-5 statement text is transcribed as the fifth row of `data/kk-definition-texts-kk-only.csv`. The D-5, D-7 and E-17 notes in that file, which called the statements Part II, now name the Part III groups (d, d and e); D-III-4 stays Part II.

12.4 The rebuild. The chain was rerun (build-index-b through the analyses) with the validators passing. The universe grows 170 → 171 codes; the verified network is 472 × 171 with 1193 edges, C-5 an isolate, so every definitions-side LCC, 2-core and derived output is unchanged. The works stay 133. Goldenweiser 1937 moves from E-5 to C-5 and now holds no sub-element and no heading, so it leaves the works LCC (593 → 592 nodes) and the works 2-core (119 → 118 works): the works CA, works MST and works centrality outputs changed content, and manuscript text that names works communities or works counts must be checked against the current output (TODO item 22). The text-to-work match is now complete: every definition text attaches to a work (165 matched, four codes with no work, two documented conflicts), and every work attaches to at least one text except the same two documented conflicts. `scripts/check-definition-text-coverage.R` was fixed to key the K&K-only rows by kk_code: Goldenweiser holds two such rows (C-5 1937 and D-5 1933), and the old author-based match silently keyed both to one code.

## 13. NMF analyses (2026-10-26)

13.1 The question. Whether a data-driven classification recovers K&K's groups A-G. Two analyses, both in base R (no new dependency, `renv.lock` untouched): the shared NMF machinery lives in `scripts/nmf-core.R` (Euclidean multiplicative updates, deterministic given the seed, W columns normalized to unit sum), sourced by both analysis scripts.

13.2 Structural NMF (`scripts/analysis-nmf-works-index-b.R`). Factorizes the sub-elements x works biadjacency of the works LCC 2-core (156 x 118) into W (sub-elements x k) and H (k x works); 10 random restarts per k = 2..8, stability reported as mean and min pairwise ARI of the hard assignments (the ARI helper follows Hubert & Arabie 1985; degenerate partitions return 1). k = 7 was fixed to match K&K's groups A-G, the taxonomy the agreement analysis tests against; the objective falls monotonically with no elbow and stability is flat beyond k = 2, so the data do not pick a k (2026-10-26 the user removed the earlier ad hoc k = 4 solution; k = 7 is now reported throughout). The seven factor profiles read as: way of life (a people, group, behavior patterns), transmitted ideas (ideas, generations, attitudes, passed down), society-individual (behavior, society, individuals), norms and knowledge (beliefs, customs, knowledge, language), complex-whole enumerative (sum, total, beliefs, activities, tools), social organization (social, social heritage, institutions), learning-acquisition (members of a society, acquired, habits). The seven factors are hand-labeled Way of life, Transmitted ideas, Society-individual behavior, Norms and knowledge, Complex whole, Social organization, Learning and acquisition (`factor.labels` in `scripts/analysis-nmf-works-index-b.R`; change labels there only). Dominant-factor counts 12/15/23/15/12/18/8, 15 works with no unique dominant group excluded from the agreement. Outputs: `data/kk-index-b-nmf-works-{factors,loads,stability,agreement}.csv`, figures `figures/kk-index-b/nmf/nmf-works.png` (works x factors loading heatmap, works grouped by dominant factor) and `figures/kk-index-b/nmf/nmf-works-agreement.png` (factor x group heatmap).

13.3 Agreement with K&K groups, works side. A work's group is the plurality letter of its codes (NA on a tie; 15 of 118 tied; works overwhelmingly sit in one group - median 1 group per work, mean 1.19 - so the label is not the weak link). On the same k = 7 fit: ARI 0.029 against a permuted baseline of mean 0.000 (95th pct 0.023). No factor maps onto any group; factor purity 0.20-0.42. The sub-element co-occurrence structure of works does not reproduce A-G.

13.4 Text-based NMF (`scripts/analysis-nmf-texts-index-b.R`). Documents are the 172 K&K codes carrying a definition text (Table 2 quotations mapped through the crosswalk, appendix-only quotations through the appendix links, and the K&K-only rows); a code's group is the first letter of its code. Tokens of 3+ letters; hand-set stopword list including the omnipresent domain words (culture, society, social, man) and the general definitional words (total, whole, learned, acquired); terms kept to 2-50% document frequency (408 of 1066); TF-IDF. Rows are documents, so a factor's term profile is a row of H and a code's loadings are a column of W. Same restart scheme; k = 7 fixed (seed 9137). The seven factors are hand-labeled Utensils and implements, Passed down generations, Feelings and adjustment, Material vs. non-material, Mental and holistic, Symbolic systems, Goals and ways of living (`factor.labels` in `scripts/analysis-nmf-texts-index-b.R`); the labels describe the top terms, and factor 3's top terms include the literal word "kluckhohn", a reminder that on this corpus a factor can be driven by one author's phrasing. Figures `figures/kk-index-b/nmf/nmf-texts-factors.png` (top 8 terms per factor) and `figures/kk-index-b/nmf/nmf-texts-agreement.png` (factor x group heatmap). Non-English texts are taken as printed, with no language handling (recorded 2026-10-27). Four documents are non-English: B-17 (Boroch B18, Dietschy) and C-I-18a (Maquet) in French, F-I-5 and F-II-3 in German. The tokenizer's `[^a-z ]` rule replaces accented letters with spaces, splitting words at the accent ("perpétuation" -> "perp" + "tuation", "c'est" -> "c" + "est"), so most foreign content words never form coherent terms. The English-only stopword list lets six foreign terms survive the document-frequency filter (der, des, est, geist, ist, kultur), each carried by the two or three foreign documents; none reaches any factor's top 15, so the factor profiles and the agreement results are unaffected (checked 2026-10-27 in both factor tables). The works-as-texts analysis (14) copies this tokenizer and inherits the behavior.

13.5 Agreement with K&K groups, text side. ARI 0.018 against a permuted baseline 95th pct of 0.016. The seven factors are recognizable definitional themes (intergenerational transmission: generation, passed down; material traits; mental-holistic; symbolic systems), but none aligns with a group; purity 0.23-0.54.

13.6 Reading. Neither the coding structure nor the definition wording recovers A-G at better than chance. K&K's groups behave as editorial categories, not as latent structure in either signal the corpus carries. The stopword removal of "total" and "whole" may have handicapped group G ("Incomplete") specifically; that choice is recorded here and could be revisited if G's alignment matters. The texts are verbatim quotations and stay out of any release; the fitted term tables name single words, not quotations.

13.7 Manuscript. Both analyses entered `kk-index-b-two-mode.tex` as section "Data-driven types: non-negative matrix factorization" (2026-10-26), with the four figures and a table of the works-factor profiles, and the null-agreement interpretation. The Lee & Seung (2001) entry was added to `references.bib` by hand. The compiled PDF passes with no undefined citations.

## 14. Works-as-texts NMF (2026-10-27)

14.1 The question. After 13 the user asked whether the two works-level signals agree: a work described by its sub-element codings (13.2) versus a work described by the definition texts of its codes. `scripts/analysis-nmf-work-texts-index-b.R` builds the work documents and factorizes them, and also bridges to the code-level texts NMF of 13.4.

14.2 Method. Documents are the 118 works of the works LCC 2-core, the same set as the structural analysis. A work's document is the concatenation of the texts of the K&K codes it sits under (the code texts assembled exactly as in 13.4); no work lacks code text. Document sizes range 7-145 words (median 32), because a work can sit under many codes. Same tokenizer, stopword list, 2-50% document-frequency range and TF-IDF as the texts analysis; 304 of 853 terms kept. k = 7 fixed (seed 7013); 10 restarts per k = 2..8 for the stability diagnostic (mean pairwise ARI 0.63 at k = 7). A work's group is the plurality letter of its codes, NA on a tie (15 of 118 tied), as in 13.3.

14.3 Agreement with K&K groups. ARI 0.011 against a permuted baseline 95th pct of 0.025; factor purity 0.22-0.40. A unit-L2 normalization of the documents (sensitivity check, console only; raw TF-IDF counts favor the longest documents) gives ARI 0.031. Null again: representing a work by its definitions' wording rather than its coding does not recover A-G.

14.4 Bridge to the code-level texts NMF. A work's predicted code-level factor is the majority dominant factor of its codes in `data/kk-index-b-nmf-texts-loads.csv` (103 of 118 works have a unique majority). Works-as-texts vs code-level dominant factors: ARI 0.584 (permuted 95th pct 0.024), with a consistent block permutation (work 1 ↔ code 7, 2 ↔ 2, 3 ↔ 4, 4 ↔ 6, 6 ↔ 5, 7 ↔ 1; work factor 5 diffuse). Expected, not a finding: the work document is the concatenation of the code documents, so the work-level factors are aggregations of the code-level ones. It is a consistency check of the pipeline, not independent evidence.

14.5 Structural vs works-as-texts, same 118 works. ARI 0.016 (permuted 95th pct 0.020); the greedy one-to-one best match of factors covers 28% of works, and the largest single cell holds 8. The two works-level classifications are unrelated cuts. With 13, all three data-driven classifications (structural, code-level texts, works-as-texts) are mutually unrelated except for the mechanical bridge, and none recovers A-G.

14.6 Outputs. `data/kk-index-b-nmf-work-texts-{stability,factors,loads,agreement,bridge}.csv`; figures `figures/kk-index-b/nmf/nmf-work-texts.png` (works x factors loading heatmap, works grouped by dominant factor), `nmf-work-texts-factors.png` (top 8 terms per factor) and `nmf-work-texts-agreement.png` (factor x group heatmap). The factor labels are hand-set and provisional (Goals and ways of living, Passed down generations, Material vs. non-material, Symbolic systems, Definitional formulas, Mental and holistic, Species and utensils). The analysis is not yet in the manuscript (TODO item 23).

## 15. Translations and the 2026-10-27 NMF pass

15.1 Translations. `data/kk-definition-texts-translations.csv` (columns code, language, translation, basis) holds English renderings of the four non-English definition quotations, and both text analyses (13.4, 14.2) substitute the translation for the original after the code documents are assembled. B-17 (Dietschy) and C-I-18a (Maquet) are French, F-I-5 (Menghin) and F-II-3 (Schmidt) German. C-I-18a uses K&K's own English rendering, printed by K&K after the French in footnote 18a. The other three are assistant translations. Each basis cites the text layer with its PDF page (pp. 51, 54, 67, 69); no printed page has been checked on the page image, and the three assistant translations still need the user's verification against the images (TODO item 23).

15.2 The texts NMF refit. The substitution changed the fit. Terms kept 412 of 1018 (was 408 of 1066), agreement with A–G ARI 0.026 (was 0.018; permuted baseline 95th pct 0.017, recompute 0.016, within simulation error). The factor profiles reshuffled, so `factor.labels` in `scripts/analysis-nmf-texts-index-b.R` were re-set, in factor order 1–7: Mental and holistic, Thought and expression, Species and utensils, Material vs. non-material, Passed down generations, Symbolic systems, Feelings and adjustment. Restart stability still isolates k = 2 (mean pairwise ARI 0.89 at k = 2, 0.41–0.62 at k = 3–8). The numbers, labels and figures in 13.4–13.5 describe the pre-translation fit and are superseded. `data/kk-index-b-nmf-texts-tfidf.rds` is now 172 × 412. The manuscript's "Types from the wording of the definitions" subsection carries the new numbers (updated 2026-10-27).

15.3 Agreement heatmaps removed. The factor × group heatmaps `nmf-works-agreement.png` and `nmf-texts-agreement.png` were removed and their plot blocks deleted from both scripts; the `*-agreement.csv` cross-tabs remain and carry the counts. The works-as-texts heatmap `nmf-work-texts-agreement.png` was deleted the same day, and its plot block was removed from `scripts/analysis-nmf-work-texts-index-b.R` with the user's approval. No agreement heatmap is in the manuscript; the agreement results are reported as numbers.

15.4 Works-as-texts refit. The works-as-texts analysis substitutes the translations as well, so 14.2–14.5's numbers, written from the run before the substitution, are superseded where they differ. The current fit (rerun 2026-10-27, deterministic, seed 7013, identical to the morning run it refreshes): terms kept 305 of 840 (was 304 of 853), restart stability at k = 7 mean pairwise ARI 0.616 (was 0.63), agreement ARI 0.010 (permuted 95th pct 0.025, as 14.3), purity 0.23–0.36, dominant-factor counts 13/26/12/23/24/9/11, unit-L2 sensitivity 0.066 (was 0.031).

15.5 The bridge after the texts refit. The bridge reads the texts loads, and the script's previous outputs predated the refit of 15.2, so the rerun refreshed it against the current loads. The refit flipped the majority code-level factor of 83 of the 118 works. The bridge now reads ARI 0.319 (permuted 95th pct 0.023) over the 103 works with a unique majority, in blocks work 2 ↔ code 5 (20 works), 4 ↔ 6 (12), 3 ↔ 4 (9), 6 ↔ 1 (6), 5 ↔ 5 (6) and 7 ↔ 3 (6), with work factor 1 diffuse. Against the pre-refit loads the same work factors bridge at 0.443, so the size of the bridged agreement follows the texts fit. It stays far above the permutation baseline, and 14.4's reading (aggregation of the code documents, a consistency check rather than independent evidence) is unchanged. 14.4's block permutation describes the pre-refit run. The structural-versus-works-as-texts comparison recomputes to ARI 0.018 (14.5 has 0.016), which is what the manuscript reports.

15.6 The factor tree and the Sankey. `scripts/analysis-mst-nmf-works-index-b.R` binarizes the works × factor loadings at 0.10 (a free parameter like k, not data-selected), projects works × factors so a tie counts shared factors, and draws the Kruskal maximum spanning tree of the projection (`figures/kk-index-b/nmf/nmf-works-mst.png`, node table `data/kk-index-b-mst-nmf-works-nodes.csv`). It runs after the works analysis. Its community partition is reproducible only with the script's `set.seed(8427)`, because `cluster_leading_eigen` starts from a random vector; betweenness is unaffected. `scripts/figure-sankey-agreement.R` draws the three-way Sankey of the 118 works, group → structural factor → works-as-texts factor (`figures/kk-index-b/nmf/nmf-agreement-sankey.png`); it runs after both works-level analyses. With the manuscript subsections "A spanning tree of the factor types" and "Three classifications side by side" (both 2026-10-27), all three NMF analyses are in `kk-index-b-two-mode.tex` with the post-translation numbers, so 14.6's closing sentence is stale. Redrawn 2026-10-27, on the user's decision, as three pairwise panels in one figure (group → structural, group → works-as-texts, structural → works-as-texts), each ribbon colored by its source node — in the group panels the works' dominant K&K group, grey for the tie node, in the factor panel the source structural factor. The three-way layout was misleading: its middle leg could only color a flow by the plurality group of the works crossing it, which grayed 22 of the 40 NMF-to-NMF flows (67 of 118 works) and made the middle stage read as mostly indeterminate. The manuscript subsection is renamed "Pairwise agreement of the three classifications".

15.7 The works-as-texts analysis withdrawn from the manuscript (2026-10-29). On the user's decision, the works-as-texts NMF (section 14, refit 15.4) is no longer reported in `kk-index-b-two-mode.tex`. Basis: the 135 Table 2 statements come from 111 distinct author–year pairs (about 1.2 statements per authoring work), so a work-level corpus built from the statements a work authored collapses into the statement-level corpus of 13.4; the corpus that covers all 118 works of the 2-core instead inherits other authors' statements through the codes the work is cited under (`analysis-nmf-work-texts-index-b.R` concatenates the code texts, whoever wrote them), so its documents are the incidence structure filtered through the code texts rather than anything the work itself says. Its chance-level agreement with everything (15.4; 0.018 against the structural factors per 15.5) is consistent with a blending artifact rather than a third signal. The tex now reports two NMF analyses; the works-as-texts subsection, the bridge paragraph, the "Pairwise agreement of the three classifications" subsection with the Sankey figure, and the three-signal sentence of the Interpretation were removed. `scripts/analysis-nmf-work-texts-index-b.R`, `scripts/figure-sankey-agreement.R` and their outputs remain in the repository, superseded for the manuscript; the figures `nmf-work-texts*.png` and `nmf-agreement-sankey.png` are no longer referenced by the tex. Sections 14.6 and 15.6 are historical records of the state before this decision.

15.8 Supplementary subgroup Sankeys (2026-10-29). On the user's request, `scripts/figure-sankey-subgroups.R` draws two Sankeys with K&K's disaggregated typology on the left side: the roman-numeral subgroups C-I, C-II, D-I..D-IV, F-I..F-IV; groups A, B, E, G number their codes plainly and have no subgroup level, so their node is the group itself. A bare C or D code is a Part III statement code (C-5, D-5, D-7), which forms its own node in the codes panel. Panel 1: the 118 works of the works LCC 2-core by plurality subgroup and dominant structural factor (`figures/kk-index-b/nmf/sankey-works-subgroups.png`); 101 works have a unique plurality subgroup and 17 tie, collected in a grey node, and 15 of the 17 tie across the group letters as well (checked 2026-10-29). Panel 2: the 172 text-bearing codes by their own subgroup and dominant text factor (`figures/kk-index-b/nmf/sankey-codes-subgroups.png`); a code sits in one subgroup, so no tie node is needed. Ribbons take the color of their origin node's group letter (the Okabe-Ito palette of `figure-sankey-agreement.R`, one color one group per `scripts/kk-group-style.R`); the tie and Part III nodes are grey, since a mixed node cannot honestly take a group color. The right-side node labels are the factor names from the `factor_label` column of the loads tables. They use plain `geom_text(stat = "sankeynode")` on the FULL layer data, with blank labels on the subgroup stage: the first version passed only the right-stage rows, and ggsankeyfier then re-stacked those seven nodes on their own, so the labels drifted off their rectangles (the top two were visibly low, 2026-10-29). The fixed version was checked numerically: the label y values equal the node midpoints in both panels. `geom_text_repel` with `direction = "y"` also drifts labels off their nodes. The left-side labels keep `geom_text_repel`, where adjacent subgroups can be thin. The same fix was applied to `scripts/figure-sankey-agreement.R` (2026-10-29) for `figures/kk-index-b/nmf/nmf-agreement-sankey.png` (not in the manuscript since the works-as-texts withdrawal, 15.7), which had the same subset problem on both sides: the labels now use the full panel data, blank on the other stage, with plain `geom_text` on both sides. A numeric check on all three panels gives every node exactly one label at its midpoint (maximum deviation 0). The subgroup figures' left labels were moved to the same plain-text method, for the same reason. Cross-tabs: `data/kk-index-b-nmf-subgroup-works-crosstab.csv` and `data/kk-index-b-nmf-subgroup-texts-crosstab.csv`. Both figures are in the manuscript's appendix (`app:subgroup-sankey`), which reports the cross-tab numbers in the text. Gotchas recorded: (a) `x[idx]` with a named character index names the result from the SOURCE vector's names at the matched positions, not the index's names, so building a per-subgroup color table by `palette[key.map]` silently produces duplicate letter names and grey fallback for every roman-numeral key (caught on the first render); (b) `unique()` on a vector whose names were assigned from an integer dropped the names entirely, so the factor-label lookup is built from a two-column data frame instead.


## 16. Part III statement codes removed (2026-10-30)

16.1 Decision. On the user's decision the Part III statement codes are removed from the analysis, since they are K&K's Part III statements (lowercase groups a to f, printed p. 83 onward) and would mix with the Part II definitions. Removed: C-5 (Goldenweiser 1937), D-5 (Goldenweiser 1933), E-17 (Taylor 1950) and D-7 (Roheim 1934). Their printed Index B entries are dropped from the edge list, so the raw sub-element and heading networks no longer hold them either. F-8 (Goldenweiser 1933, Part III f statement 8) was never in the universe. D-III-4 (Roberts 1951) is a Part II page footnote and stays. Earlier the same day the Roheim rows for A-14, D-6 and D-18 were removed (the user's decision: Roheim 1934 is not A-14 or D-6, and D-18 is not a K&K code). The Roheim rows for D-IV-1 (1934) and F-IV-4 (1943) stay: both are Part II codes already in Index A.

16.2 Inputs changed. `data/kk-part-iii-author-codes.csv`: the Part III rows are removed (Goldenweiser C-5, D-5, F-8; Roheim D-7). `data/kk-index-b-verified-extra-codes.csv`: C-5 and E-17 are removed; C-I-18a and D-II-16 stay. `data/kk-definition-texts-kk-only.csv`: the C-5, D-5, D-7 and E-17 records are removed; D-III-4 stays. `data/kk-index-b-work-pub-type.csv`: the Goldenweiser 1933 and 1937 rows are removed. New file `data/kk-index-b-part-iii-codes.csv` lists the four removed codes with their basis; `build-index-b.R` drops their edges after de-duplication.

16.3 Scripts changed. `build-index-b.R`: drops the Part III statement-code edges; `in_part_iii` flags only Part III codes that are not in Index A (none now). `build-index-b-work-citations.R`: page-image checks for works no longer in the network are skipped and printed; the rows stay in the page-check file as a record. `check-definition-text-coverage.R`: counts verified codes only. `analysis-mst-headings-index-b.R`: restricts the heading matrix to verified codes (now a no-op, kept as a guard). `analysis-nmf-texts-index-b.R`: documents are restricted to verified codes, which removes C-I-Addendum (an appendix link to a Sears addendum, not a network code; see 16.5), and the subtitle reads 167. `analysis-nmf-works-index-b.R` and `analysis-nmf-texts-index-b.R`: the hand-set factor labels are reset to the new top terms, because the factor order changed with the data. Works: group behavior, norms and knowledge, way of life, society-individual behavior, learning and acquisition, complex whole, social organization. Texts: symbolic systems, material vs. non-material, species and utensils, goals and persons, feelings and adjustment, passed down generations, mental and holistic. `figure-sankey-subgroups.R`: comments only.

16.4 Effects of the full rebuild (chain from `build-index-b.R` through the analyses, MSTs, NMF, citations, coverage check and the Sankeys; validators passed).
- Universe, networks: 167 codes (was 171). Sub-element network 470 by 167, 1189 ties; heading network 53 by 167, 1080 ties; the raw and verified networks now have the same nodes. Index B edge list: 1314 rows (was 1318); flags ok 978, ocr_corrected 207, manual_fix 127, code_not_in_index_a 2 (C-I-18a, D-II-16).
- Works: 131 (was 133). Goldenweiser 1933 and 1937 leave the works network; Roheim 1934 sits under D-IV-1 only. Works 2-core: 118 works by 156 sub-elements (829 edges). Works LCC: 589 nodes (1144 edges), 10 components.
- Definitions CA, verified network LCC: 464 sub-elements by 158 codes (1183 edges); 2-core 159 by 145 (865 edges). Definitions MST trees unchanged (the removed codes were outside the 2-core).
- Works MST: concept tree 156 concepts and 118 works. Freeman-normalized betweenness: group 71.3% (was social 65.3%), social 63.7%, Kelly & Kluckhohn 1945a 75.4% (was 84.1%). Work-tree communities 6 (was 19). Heading MSTs: 48 headings in each tree.
- Text coverage, verified codes: 167; 166 with a Boroch text and D-III-4 with K&K's text. 162 match one work, 3 have no work (C-I-18a, D-II-16, D-III-1), D-II-7 is the documented conflict, F-I-20 the documented text-matches-another-work case.
- Works NMF (k = 7, fixed): dominant split 17, 20, 10, 21, 21, 14, 15; ARI 0.016 (permuted 95th pct 0.026); threshold 0.10 gives 16, 51, 41, 9 and 1 works with one to five factors; projection 4,383 ties; works MST communities 17.
- Text NMF (k = 7, fixed): 167 documents, 402 terms; ARI 0.018 (permuted 95th pct 0.016); restart agreement 0.44 to 0.76 for k = 3 to 8.
- Sankeys: works panel 118 works, 102 with a plurality subgroup and 16 tied; codes panel 167 codes, 14 subgroups.

16.5 Open items and decisions.
- C-I-Addendum: dropped from the texts analysis on the user's decision (2026-10-30). The appendix link stays in `kkcc-appendix-only-links.csv`; the Sears text is not used by any analysis now.
- Block check: `check-index-b-blocks.R` now prints 1289 of 1314 edges in their printed block and 25 in another block. The page-image review file (`kk-index-b-block-check-review-current.csv`) covers 23 of the 25; the other two are not yet identified. The earlier 1295 and 23 figures predate this rebuild. The edge list and block map are unchanged from HEAD, so the gap is not caused by this change.
- Manuscript: `kk-index-b-two-mode.tex` is updated to the rebuilt numbers and figures, and compiles cleanly (pdflatex, bibtex, pdflatex twice) in a scratch copy. The repository's compile artifacts (`.pdf`, `.log`, `.aux`) are not regenerated.
- Not refreshed: the release folder (`release/two-mode-network-data/`: the `.rds` files, citation table, MANIFEST and CHANGELOG) and the site split works files on `site-source` still hold the pre-removal networks; refresh them at publication. The withdrawn works-as-texts outputs and `figure-sankey-agreement.R` were not rerun.

## 17. Split of the a/b codes (2026-10-30)

17.1 Decision. The user chose to split every K&K code whose Boroch quotations are lettered a and b: A-3, E-5, F-II-4 and F-II-7. Variants take a parenthesized suffix (A-3(a), A-3(b), E-5(a), E-5(b), F-II-4(a), F-II-4(b), F-II-7(a), F-II-7(b)), so they cannot be mistaken for printed letter-suffix codes such as A-10a. K&K prints one Index B entry per code and does not say which variant an entry belongs to, so each parent's Index B links are copied to both variants. The split table is `data/kk-index-b-code-splits.csv`.

17.2 Pipeline. `build-index-b.R` copies each parent's Index A rows and Index B edges to its variants after the manual fixes (`split_codes()`). Crosswalk decisions map Boroch A3 and A4 to A-3(a) and A-3(b), E6 to E-5(b), F2-4 and F2-5 to F-II-4(a) and F-II-4(b), and F2-8 and F2-9 to F-II-7(a) and F-II-7(b). E5 is appendix-only, so its variant is set in `kkcc-appendix-only-links.csv`. The source-page table `data/kkcc-definition-source-pages.csv` carries the variant codes. `scripts/attach-code-attributes-index-b.R` attaches the citation attributes to the code vertices after the verified network is built. `check-index-b-blocks.R` strips the variant suffix before looking for a printed code.

17.3 Counts. Index B edge rows go from 1314 to 1326. The 46 parent edges are copied to the variants (A-3 12, E-5 9, F-II-4 8, F-II-7 17), and 34 edge rows are then removed under 17.8. Verified network 1189 to 1201 edges; heading network 1080 to 1095 edges; codes 167 to 171; sub-elements 470 and headings 53 unchanged. Works stay at 131, and the works table lists two variant codes for Dixon 1928, Blumenthal 1937 and Feibleman 1946. Counted by K&K code, works under two or more codes stay at 19 (17.10). The validators pass (`check-index-b-networks.R`, `check-index-b-blocks.R`). The works networks, the works NMF and the texts NMF are unchanged by 17.8, because a work's sub-element set is the union over its codes.

17.4 Block check. After the suffix fix, 1301 of 1326 edges sit inside their assigned printed block, 25 are printed in another block, and none are unprinted. The 25 are the same as before the split. The page-image review file has not been extended to the variants.

17.5 Keys. Once the split is in place, every key (Boroch author, year, printed pinpoint and quote opening) identifies one code. A-3(a) and A-3(b) both cite Dixon 1928: 3 and differ only by their openings. Before the split, the eight pairs of codes that shared an author-year-page key had different quotations (word overlap 0.07 to 0.57, none identical). That comparison was made in the 2026-10-30 session and is not saved as a file.

17.6 Consequences not yet carried through. (a) The text NMF refits on 171 documents. Each variant now has its own document, and the two-quotation documents of the parents are gone. Its factor order changed, and the hand-set text labels in `analysis-nmf-texts-index-b.R` no longer match the factors: new factors 1 and 6 both resemble old factor 3, and old factor 6 ("Passed down generations") has no counterpart. The labels were reset from the top terms on 2026-10-31 (17.9). (b) The works NMF factors are unchanged (the top six sub-elements of each factor match the earlier run). (c) The manuscript was refreshed on 2026-10-31 (17.10). (d) The site split works files on `site-source` are not refreshed, and nothing is published.

17.7 Release. Release 0.6.0: the three `.rds` files are copied from `data/`, the citations table is rewritten with its release columns, and MANIFEST.md and CHANGELOG.md are updated. The verified network in the release carries the citation attributes from 17.2, including the six-word quote openings (approved by the user).

17.8 Variant link decisions (2026-10-31). Each variant starts with a copy of its parent's links, which K&K does not distinguish. The user chose to assign the links that the quotation text decides. A lexical screen tested each copied sub-element name against the two quotations of its parent. 29 of 41 links match exactly one variant (A-3: 6 b-only and 1 a-only; E-5: 4 b-only and 1 a-only; F-II-4: 5 a-only; F-II-7: 8 b-only and 4 a-only). 8 match both, and 4 match neither. The 29 are recorded in `data/kk-index-b-variant-link-decisions.csv`, with the kept variant and a basis. `build-index-b.R` removes each (variant, sub-element) pair after the split, and removing a pair drops every heading edge with that name, which gives 34 edge rows. The 12 links that match both or neither stay copied to both variants. The screen is a word match, not a reading of the quotation's sense, and a name can appear in one quotation as a generic word (for example "total" or "past"). Each decision is a judgment on the text, not a printed fact, and should be reviewed before the manuscript relies on it.

17.9 Text NMF labels (2026-10-31). The factor labels in `analysis-nmf-texts-index-b.R` were reset from each factor's top eight terms after the split changed the factor order: 1 Order and operation (order, operation, self, superorganic); 2 Feeling, thinking and acting (inevitable, thinking, feeling, equipment); 3 Material vs. non-material (material, non, traits); 4 Goals and persons (certain, others, persons, goals); 5 Symbolic interaction (symbolic, process, interaction); 6 Species-specific ability (events, species, ability); 7 Mental and holistic (mental, holistic, concept). The labels describe the top terms, not clean concepts, and factors 1, 2, 5 and 6 are the least clear.

17.10 Manuscript and plurality counts (2026-10-31). The plurality group of a work (`analysis-nmf-works-index-b.R`) and the plurality subgroup of a work (`figure-sankey-subgroups.R`) now count K&K codes, collapsing the variants of a split code (for example A-3(a) and A-3(b) count once). Without this, Linton 1945a's codes C-I-9 and E-5(a), E-5(b) gave E a plurality over C-I, and the works group count moved. With it, Linton 1945a is again a tie, as before the split. The works ARI is 0.016 (permutation 95th percentile 0.026), and the Sankey works panel has 102 works with a plurality subgroup and 16 tied. The manuscript `kk-index-b-two-mode.tex` was refreshed to the rebuilt numbers and the relabeled text factors (Table 1, the definitions trees and top-10 tables, the NMF text section, the Sankey appendix paragraphs and captions). It compiles cleanly in a scratch copy (no overfull boxes, no undefined references). Its works-network numbers are unchanged, because the works network did not change.

## 18. Works-as-texts analysis removed from the pipeline (2026-10-30)

18.1 Decision. On the user's request, the analyses that take a work as the unit of analysis by pooling the quotations of its codes are removed from the pipeline. That is the works-as-texts NMF (section 14, withdrawn from the manuscript in 15.7) and the three-way agreement Sankey that depends on it (`figure-sankey-agreement.R`, 15.6). Removed: `scripts/analysis-nmf-work-texts-index-b.R`, `scripts/figure-sankey-agreement.R`, `data/kk-index-b-nmf-work-texts-{stability,factors,loads,agreement,bridge}.csv`, and the figures `figures/kk-index-b/nmf/nmf-work-texts.png`, `nmf-work-texts-factors.png` and `nmf-agreement-sankey.png`. All were tracked, so each can be restored from git history.

18.2 Kept. The works-level analyses that use a work's sub-element profile and pool no quotations: the structural NMF (`analysis-nmf-works-index-b.R`, 13.2), the works CA and works MSTs, the works network figures, and the NMF factor tree. The texts NMF pools nothing at the work level, since each document is one code.

18.3 Consequences. The README Methods paragraph now describes two NMF analyses. TODO items 23 and 24 are updated (24 is complete and removed). The comments in `analysis-nmf-works-index-b.R`, `analysis-nmf-texts-index-b.R` and `figure-sankey-subgroups.R` no longer point to the deleted Sankey script. Sections 14, 15.6 and 15.7 are historical records, so their file paths for the removed outputs are no longer valid.

18.4 Checks. A search of the repository and of `main` and `origin/main` found no other reader of the removed files. The remaining scripts changed only in comments, so their outputs are unchanged. The three edited scripts were checked for syntax but not rerun.

## 19. Verbatim copies excluded and the text NMF refit (2026-10-30)

19.1 Decision. The Table 2 columns A10a, C1-5a and F4-6 each repeat another column's quotation word for word: A10 (Winston 1933), C1-5 (Firth 1939) and F4-5 (Kluckhohn and Kelly 1945a). The crosswalk matched each to its parent's K&K code by name and year, so the texts analysis counted each parent's quotation twice. The documents for A-9, C-I-5 and F-IV-5 held two copies each. The crosswalk decisions file has an `exclude` decision for each column (basis: identical text, no appendix entry of its own). `build-index-b-crosswalk.R` clears the code for an excluded column (match_status `excluded_verbatim_copy`), and `analysis-nmf-texts-index-b.R` asserts that exactly these three columns are unmatched and drops them.

19.2 Effect on the networks. The edges, nodes and block check are unchanged. Only the `boroch_code` and `boroch_source` attributes change: A-9 goes from "A10; A10a" to "A10", C-I-5 from "C1-5; C1-5a" to "C1-5", and F-IV-5 from "F4-5; F4-6" to "F4-5". The code-vertex check now accepts one Boroch code per code, and no code carries two quotations except the split variants, which each carry one.

19.3 Text NMF refit. The document count stays at 171, and the terms kept are 403 of 1015. Restart stability at k = 7 falls from mean pairwise ARI 0.878 to 0.555 (minimum 0.278), and at k = 2 it rises from 0.989 to 1.000. Across k = 3 to 8 the mean ARI ranges from 0.48 to 0.70 (was 0.48 to 0.88). Agreement with the A–G groups is ARI 0.012 (permuted 95th percentile 0.016), and the largest single-group share within a factor is 0.54. The fit moves a lot when three of the 171 documents change, so the seven-factor solution is fragile on this corpus.

19.4 Factor labels. The factor order changed, so the labels were reset from the top eight terms: 1 Species-specific ability (events, species, use, dependent, ability); 2 Order and operation (order, operation, self, superorganic); 3 Mental and holistic (concept, mean, holistic, traits, mental); 4 Goals and persons (certain, rather, others, persons); 5 Symbolic process and adjustment (concrete, process, symbolic, experience); 6 Material and transmitted behavior (material, non, transmitted, socially); 7 Passed down generations (generation, passed, down, everything). "Feeling, thinking and acting" no longer appears among the top terms of any factor. The label comment in the script no longer cites author-phrasing words, which do not appear among the top 15 terms now.

19.5 Manuscript and README. The texts section, the NMF introduction (two analyses, the texts stability range), the codes Sankey paragraphs (counts from `data/kk-index-b-nmf-subgroup-texts-crosstab.csv` and the loads table) and the README coverage paragraph are updated. The text section's statement that the three assistant translations were verified against the printed originals was wrong (see 15.1, not yet checked); the manuscript now says so.

## 20. Works network removed from the pipeline and the manuscript (2026-10-30)

20.1 Decision. On the user's decision, the works network is removed. Each work's sub-element set is the union over the codes it sits under, so the works analyses combined several quotations into one unit, the category section 18 set out to remove. The analysis unit is the code: one author-year-page-quote, 171 codes with 171 distinct citation keys (section 19 and the manuscript appendix). The works analyses and their outputs are removed from the pipeline, the manuscript and the README.

20.2 Removed. Scripts: `analysis-ca-works-index-b.R`, `analysis-mst-works-index-b.R`, `analysis-nmf-works-index-b.R`, `analysis-mst-nmf-works-index-b.R`, `attach-work-pub-type-index-b.R`, `pub-type-style.R`. Data: `kk-index-b-work-concept-network-full.rds`, `kk-index-b-ca-works-lcc2core-{subelements,works}.csv`, `kk-index-b-centrality-works.csv`, `kk-index-b-mst-works-nodes.csv`, `kk-index-b-mst-nmf-works-nodes.csv`, `kk-index-b-nmf-works-{factors,loads,stability,agreement}.csv`, `kk-index-b-nmf-subgroup-works-crosstab.csv`, `kk-index-b-work-pub-type.csv`. Figures: the `figures/kk-index-b/works/` folder, `nmf-works.png`, `nmf-works-mst.png`, `sankey-works-subgroups.png`, `degree-works-definitions.png` (replaced by `degree-definitions.png`). All were tracked and can be restored from git history.

20.3 Changed. `build-work-concept-network-index-b.R` writes only the work table (`kk-index-b-works.csv`, with `work`, `n_codes` and `codes`; `n_concepts` is dropped because only the README used it). `analysis-mst-definitions-index-b.R` fills the node table's author column from each code's own `source_author`, `source_year` and `source_page`, in place of the works-table labels (decision A in the plan). The figures are unchanged. `analysis-mst-headings-index-b.R`, `analysis-centrality-index-b.R`, `analysis-index-b.R` and `figure-sankey-subgroups.R` cover the definitions network only. `core-index-b.R` loses `sub_work_matrix()`, which only the works analyses used. The header of `nmf-core.R` no longer names the structural analysis.

20.4 Kept as bibliography (decision B). The work table, its citation list (`kk-index-b-work-citations.csv` and its page-check file), the author page checks and the text-to-author-year check in `check-definition-text-coverage.R`. None of these feeds a network or an analysis. The release (0.6.0) and the `site-source` split files are not changed until publication (decision C), so they still carry the works network.

20.5 Checks. The definitions networks, the CA, the centrality table, the heading tree and the code tree are unchanged. The code tree's community, betweenness and degree columns match the earlier file, and the heading node table's definitions rows are unchanged. The work table matches the earlier table except for the dropped `n_concepts` column. The degree figure was viewed. The CA and tree PNGs changed at byte level only; they were not compared by eye, and the notes say layouts re-render between runs.

20.6 Manuscript. The abstract, the Data and networks section, the overview (Table 1, one column, values recomputed from the verified network and unchanged), the degree figure and text, the works MST subsection and its table, the "Taken together" paragraph, the structural NMF subsection and its table and tree, the NMF interpretation and the works Sankey appendix paragraphs are rewritten or removed. The NMF section now reports the texts analysis only. The largest definitions component is 626 nodes, not 622: the earlier figure predates the a/b split (section 17). The manuscript compiles cleanly in a scratch copy.

20.7 Not done. `AGENTS.md` (the project memory) still describes the works network, and the user memory should be updated with `/savememory`. The release and the site are unchanged (decision C).
