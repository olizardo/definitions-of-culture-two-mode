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
| `y`, `j`, `$` | 5 | `F-IV-y` → F-IV-5 |
| `iy`, `iz`, `io` | 17, 12, 10 | two-digit numbers |
| trailing `a` | suffix | `A-ioa` → A-10a (only a literal trailing `a`; an earlier version applied this to any letter and was corrected) |
| lone `n` / `u` | 11 | `A-n` → A-11 |
| `~`, `^` | `-` | `D-I^7` → D-I-7 |

Tokens that could not be normalized are kept with `parse_flag` and not guessed.

**Validation so far.** Index A (186 rows) and Index B (1275 edges) were compared on code
coverage. 151 codes appear in both. Index B has 36 codes that Index A does not list; most
are damaged OCR (`D-1112`, `C-I-183`), and a few are plausible K&K numbers that Index A's
OCR lost. Five Index A tokens cannot be normalized. A 20-edge random spot check against the
OCR lines found no errors after the fixes above. This is not a full manual audit.

## 4. The 39 appendix-only codes

Boroch's appendix (171 codes) has 39 codes that never appear in Table 2: A21, A22, B17,
B23, C1-7, C1-9, C1-10, C1-12..C1-15, C1-19..C1-22, C2-1, D1-10, D4-1, E4, E5, F1-2,
F1-6, F1-11, F1-12, F1-17..F1-19, F1-21, F2-2, F2-3, F2-6, F2-12, F4-1, F4-2, F4-4,
F4-5, G1, G3, G6. (F4-5 is the code that F4-6 most likely misprints; see section 5.)

Tests against K&K's text point to two mechanisms.

- **Unnumbered quotations.** Some are quotations K&K never numbered in Index B
  (A21 Herskovits 1948:625, A22 Thurnwald 1950, B17 Jacobs & Stern, B23 Radcliffe-Brown,
  C1-7 Gillin & Gillin). For these, K&K's index has no entry at all.
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

- Index A and Index B OCR is not checked against the page image beyond the sample above.
- 39 appendix-only codes have no author or year in this repository, so the crosswalk
  cannot link them.
- Index B element labels are unverified against the page image and may contain residual
  OCR damage.
- Seven Table 2 definitions have ambiguous author-year matches (for example, Kluckhohn &
  Kelly 1945 is quoted for several codes). Those are left unresolved, with candidates
  listed in `kk-boroch-crosswalk.csv`, pending a decision log.
