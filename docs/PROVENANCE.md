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
- D2-16 (Aberle et al. 1950): matched to D-II-16 on the quoted text, "Culture is socially transmitted behavior...", which matches the Index B element label. Inferred, not read from Index A.
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
  entry and Boroch. The Index A transcription keeps the printed "(1929)" as a known K&K
  discrepancy. No script reads the Index A year for Myres. Primary-source check (2026-10-24):
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

Total: 174 parsed rows re-headed. The edge file keeps 173 distinct rows: the common-or-shared-patterns block
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

Review sheet: `data/kk-index-b-block-check-review.csv` (17 rows; blank `verdict` and `note` columns for the
page-image reader). Each row names its crop, a 200 dpi image of the assigned block's column, cut from
the scan with `pdftoppm` and kept in the scratch directory, not the repo. The crops are copies of the
scan, so they stay out of any release. Two crops were checked by eye before handoff and both look like
matcher misses: E-2 (`dynamic structural relations`, where the text layer read the code as `F.-2`) and
E-5 (patterns, where the scan prints it as `E-5` and the text layer as `E -j`). The rest are unchecked.

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

- **Heading attribution (corrected 2026-10-24, one reader).** The rules in section 3.5 are applied in `build-index-b.R`. A machine cross-check (section 3.7) puts 1268 of 1285 edges in their assigned block; 17 edges are listed for a page-image check. A human second reader has not checked the rules.
- **Unresolved Index B tokens (open, 2).** Six of the eight were resolved on 2026-10-24 (section 3.4). `D-I` (society) is excluded as a duplicate. `F-I\` (means of adjustment) is unreadable behind a smudge and stays unresolved. Four resolutions rest on printed sequence rather than a clean glyph read; a second reader should check them.
- **Junk sub-element names (resolved 2026-10-24, section 3.6).** All 33 `junk_name` edges and six single-letter `manual_fix` edges are mapped to the element printed in their block. The decisions were read from the text layer, not the page image.
- **Flagged edges.** All 26 FIX rows are in the manual-fix table; their keys and codes match the flagged audit. Two CHECK rows are resolved (`F-1` "adjustments" → F-IV-3; `F-19` "adaptive behavior" → F-I-19). A `B-ji` FIX row merges into an existing `B-5` edge when the build removes duplicates.
- **Unaudited ok rows (open).** 915 `ok` edges have no audit verdict (section 3.3) and have not been checked against the page image. A 50-row random sample (seed 4817) is in `data/kk-index-b-ok-sample.csv`, with blank verdict columns.
- **Manual fixes without an audit row (open).** 62 of the 66 `manual_fix` edges have no row in either audit file (section 3.3, a dated snapshot). Their evidence is the printed citation in `kk-index-b-manual-fixes.csv`. The six 2026-10-24 resolutions are in that group.
- **Index A.** Every row on printed pp. 73–74 was read against the page image (section 3.1). That is a single-reader check, not double-keyed. Sears's `C-I-Addendum` is printed that way and stays unresolved.
- **Crosswalk (resolved 2026-10-24).** A16, A17, A20, C1-11 and B5 are decided in section 3.2, and
  the appendix-only rows A21, C1-12 and C1-13 are in `data/kkcc-appendix-only-links.csv`. The
  one point is that Index A prints Myres B-4a as 1929 while the Part II entry reads 1927; 1927 is the
  publication year of the original Myres book (section 3.2).
- **Appendix-only codes.** The 39 codes have no author or year in `kkcc-definition-years.csv`, so the crosswalk does not link them. The Index A rows for several of them (for example D-I-10 Ford 1942, F-I-1a Willey 1927b, E-4 Redfield, A-20 Thurnwald 1950) do exist; they were not linked.
- **Element labels.** Index B element labels are unverified against the page image and may contain residual OCR damage.
- **Rights (open).** Whether K&K Index B element labels can be released is undecided (see README).
