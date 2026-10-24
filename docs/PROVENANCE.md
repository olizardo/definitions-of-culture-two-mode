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
  (`kkcc_two_mode_main.rds`) unions each auxiliary into its parent.

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
- `D-7`, `D-5`, `F-4`, `E-17`: kept as printed. Not verified at 300 dpi.
- `D-II-16` (`socially transmitted behavior`): Index A has no Aberle row. The code is cited in Index B, and it is the code the crosswalk assigns to Boroch's D2-16 (see 3.2).

### 3.2 Crosswalk changes (2026-10-24)

The crosswalk now strips initials from Boroch surnames ("A. Davis" matches Davis Allison), requires a Boroch suffix (a or b) to match when given (White 1949b/1949a resolve to F-III-3/F-III-4), and accepts Boroch's first-publication year (`year_orig`). Benedict A5 is quoted as 1931 but first published 1929, which is K&K's A-4 (1929). Hand decisions are in `data/kk-boroch-crosswalk-decisions.csv`, each with a stated basis:

- D3-1 (Tozzer, no year): matched to D-III-1. The only K&K Tozzer in subgroup D-III; moderate confidence.
- D2-16 (Aberle et al. 1950): matched to D-II-16 on the quoted text, "Culture is socially transmitted behavior...", which matches the Index B element label. Inferred, not read from Index A.
- Open: A16 and A17 (Kluckhohn & Kelly 1945a; K&K A-14 and A-15), A20 (Herskovits 1948; A-18 and A-19), C1-11 (Kluckhohn & Kelly 1945a; C-I-10, 11, 12), and B5 (Myres 1927; K&K B-4a is 1929, so the year conflicts). These need a check of the quoted text. They are not assigned by position.

Result: 127 rule matches, 2 hand decisions, 4 ambiguous, 1 unmatched, and F4-6 (resolved in section 5).

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

- **Heading attribution (open).** Sub-elements printed under "carriers of culture", "common or shared patterns", "systems", "social"/"society", and "ideas and cognitive processes" are attached to the wrong heading. Codes are unaffected, but heading-level analyses are not reliable. A block-to-heading map has not been built.
- **Unresolved Index B tokens (open, 8).** Five have two printed candidates; three are unreadable on the scan. They are excluded from the edge list. Resolving them needs a second scan or a decision to accept the exclusion. The CHECK rows for `F-i` (group) and `D-I` (society) are in this set.
- **Junk sub-element names (open, 33 edges).** Sub-elements such as `j`, `i`, and `y` are OCR fragments or misattributed labels. The per-case decision (map to the printed sub-element, or drop from the sub-element matrix and keep in the heading matrix) has not been made.
- **Flagged edges.** All 26 FIX rows are in the manual-fix table; their keys and codes match the flagged audit. Two CHECK rows are resolved (`F-1` "adjustments" → F-IV-3; `F-19` "adaptive behavior" → F-I-19). A `B-ji` FIX row merges into an existing `B-5` edge when the build removes duplicates.
- **Unaudited ok rows (open).** The 932 unflagged `ok` rows have not been checked against the page image. A 50-row random sample (seed 4817) is in `data/kk-index-b-ok-sample.csv`, with blank verdict columns.
- **Index A.** Every row on printed pp. 73–74 was read against the page image (section 3.1). That is a single-reader check, not double-keyed. Sears's `C-I-Addendum` is printed that way and stays unresolved.
- **Crosswalk (open, 5).** A16, A17, A20, C1-11, and B5 need a text check (section 3.2).
- **Appendix-only codes.** The 39 codes have no author or year in `kkcc-definition-years.csv`, so the crosswalk does not link them. The Index A rows for several of them (for example D-I-10 Ford 1942, F-I-1a Willey 1927b, E-4 Redfield, A-20 Thurnwald 1950) do exist; they were not linked.
- **Element labels.** Index B element labels are unverified against the page image and may contain residual OCR damage.
- **Rights (open).** Whether K&K Index B element labels can be released is undecided (see README).
