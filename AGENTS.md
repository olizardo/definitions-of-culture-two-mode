# Project memory: definitions-of-culture-two-mode

Two-mode network analysis of Boroch's KKCC classification (Kroeber & Kluckhohn, *Culture Concepts*,
1952), from Boroch's article `documents/ROBAFC-5.1.pdf`. Two data sources: Boroch's Table 2 and
appendix (hand-transcribed from the PDF) and K&K's Index A/B (parsed from `documents/Kroeber-kluckhohn.pdf`,
an ABBYY OCR of the 1952 scan).

Source of truth for counts and open items: `docs/TODO.md` (current state at the top). Method, evidence
and dated decisions: `docs/PROVENANCE.md`. Data dictionary and limitations: `README.md`. Do not copy
counts into this file; they go stale.

## Layout

- `scripts/`: all pipeline and analysis scripts. Run from the project root; paths are relative to it.
- `data/`: CSV and rds outputs. `figures/`: PNGs. `docs/`: PROVENANCE.md, TODO.md.
- `documents/`: source PDFs and an ignored text copy. `*_djvu.txt` is gitignored; do not commit or release it.
  `pdfcoffee.com-…pdf` is tracked in git; its removal is an open decision.
- `kkcc-two-mode.qmd`: the Quarto report. Analysis sections `source()` the scripts at render time.
- Scratch files go in `$PA_SCRATCH_DIR`, not the repo.

## Rebuilding the K&K Index A/B data

Order: `build-index-b.R` → `build-index-b-crosswalk.R` → `analysis-index-b.R` →
`build-index-b-networks.R` → `check-index-b-networks.R` → `check-index-b-blocks.R` →
`analysis-ca-index-b.R`. Run each in a fresh environment: `sys.source(file, envir = new.env())`.
The crosswalk reads its inputs from files; a stale session object once produced wrong output.

After any change, check that: the build runs without errors; every manual-fix key matches a token;
edge and parse-flag counts change only as expected; the validators pass. Then update the counts in
`docs/TODO.md` and `README.md`.

## Manual fixes (`data/kk-index-b-manual-fixes.csv`)

- Columns: heading, sub_element, ocr_raw, kk_code, action, evidence, new_sub_element, occurrence.
  Actions: `set` (kk_code), `unresolve` (kk_code NA), `rename_sub` (element name only).
- Keys match the PARSED token table, not the exported edges. Use the PRE-correction heading. Heading
  variants (e.g. `adjustive-ajjptive function of culture`, `process ts and means`) are renamed after
  the manual fixes, so the key must use the variant. Copy keys from the parsed output, not the PDF.
- Use `occurrence` for identical tokens under the same heading and sub-element. Blank = all matches.
- Non-code tokens (e.g. "K -i", "B 17") are fixed in `kk-index-b-missing-rows.csv`, not here.
- Evidence must be a quoted CSV field. An unquoted comma or quote shifts the columns and the build
  then fails or silently produces a wrong edge set. Validate with `read.csv()` (8 columns) before rebuilding.
- The file uses CRLF line endings, like the committed copy. Keep them; a LF rewrite makes every line
  show as changed in git.
- Record the basis in the evidence column: printed page, crop resolution, or "user reading, not
  checked on the page image". Do not claim a page check you did not do.

## Rules for OCR tokens

- Do NOT add general character rules. The `norm_number()` map (i→1, y→5, etc.) silently produces codes
  from any token, and that is how A-iy, B-iy and D-II-iy became edges. Prefer an explicit manual fix
  with its evidence over a new rule. The existing general rules are a known debt: many ocr_corrected
  edges depend on them (see TODO).
- `j` is printed as 3 or 5 on the scan. It is deliberately unmapped; resolve `j` tokens only from a
  page-image check or a single printed candidate under that sub-element.
- A trailing `a` is read as `3` (`A-103` = A-10a, `C-I-53` = C-I-5a).
- A dropped roman I (`C-18` = C-I-8) and a truncated last digit (`D-I-1` for D-I-12) are common.
- Roman tokens containing H: `norm_roman()` returns III for IH/lH. Check any new roman-slot token that
  contains H.
- `norm_number()` treats a lone `n` or `u` as 11 (`A-n` = A-11).
- Index B element names can absorb code fragments ("adjust \-2o" = adjust plus A-20). Fix the name
  with `rename_sub` and recover the edge with a missing-rows row.
- `is_entry_start()` must not treat an OCR code dash as a heading dash. After any parser change, check
  `pe$entries$heading` for NA.

## Page images and offsets

- `Kroeber-kluckhohn.pdf` (ABBYY): printed page = PDF page − 3. Index B = PDF pp. 77–81.
- The 229-page copy (`…_compress.pdf`, same file as the tracked pdfcoffee copy): printed = PDF − 6.
- Each new copy needs its own offset. Cite printed page numbers, not a copy's PDF page.
- Crops: `pdftoppm -r DPI -x X -y Y -W W -H H` takes pixels (points × DPI / 72). `pdftotext -bbox`
  reports points. Use 300 dpi for normal checks and 400–600 dpi for ambiguous glyphs.
- The ABBYY text layer lacks running headers. Searching a page with `awk -v RS='\f'` also hits
  footnotes; confirm on the image.
- The Internet Archive copies (`culturecriticalr0000kroe_z3a4`, Scribe OCR) are leads, not evidence:
  their left column is clipped and their Index A digits are weaker than ours.

## Index A

- Index A rows are keyed by `author_raw` + `raw_code`. Copy keys from `data/kk-index-a-authors.csv`.
- Corrections go in `kk-index-a-manual-fixes.csv` (kk_code, author_new, qualifier_new; blank = unchanged).
  Rows the text layer omits go in `kk-index-a-missing-rows.csv`.
- Known OCR errors: merged entries (`Blumenthal • Boas`, `Carver < 1935)-Couru`), `Tumey-High`
  (Turney-High), `Thumwald` (Thurnwald), and year OCR like `(19 11)`, `(19:8)`. The `ok` flag does not
  mean verified.

## Crosswalk and Boroch's data

- Boroch's codes are K&K's groups with subgroups written as digits (C1 = C-I, D2 = D-II, F4 = F-IV).
  Within a group Boroch renumbers, so never match by position: the crosswalk matches by author, year,
  group and subgroup. Positional agreement is a check only.
- Hand decisions are in `data/kk-boroch-crosswalk-decisions.csv`, each with a basis.
- Table 2 has 135 definition columns. The appendix has 171 codes; 39 never appear in Table 2 (texts in
  `kkcc-appendix-only-texts.csv`, links in `kkcc-appendix-only-links.csv`).
- F4-6 is an off-by-one slip for F4-5 = Kluckhohn & Kelly 1945a: 87 (evidence in PROVENANCE section 5).
- Table 2's "TOTAL USES" counts uses with multiplicity; the binary matrices deduplicate.
- Main categories exclude their auxiliaries (SOCIAL 58 + Socially 10 = printed 68).

## Networks

- igraph `graph_from_biadjacency_matrix()` creates ROWS first (type = FALSE), then columns. Set vertex
  names and attributes in that order, or the graph silently corrupts.
- Custom graph builders must preserve vertex names.
- Disconnected two-mode graphs give several lambda = 1 eigen-dimensions in CA; drop all of them (use the 2-core).
- eigen() signs are arbitrary. Align definition scores to concept scores via the duality relation.
- Build the CA and MST projections from the LCC 2-core, not the full network.
- Element names are not unique across headings ("systems", "accumulated treasury", "language"); a
  sub-element network node merges them. Use the heading network when the heading matters.
- The validators check structure, round-trip to the CSVs, and attributes. They do not check the content
  of individual edges.

## Regex and text gotchas (R)

- Default regex is POSIX TRE. Inside a bracket class `\s` is a literal backslash and `s`; use
  `[[:space:]]`. `\s` and `\d` work outside brackets, or use `perl = TRUE`.
- `\\.` does not match a literal period in TRE; use `[.]` or `perl = TRUE`.
- `sub()` with a capture group drops the matched text; to extract a leading token, append `.*$`.
- Normalize ligatures (ﬁ→fi) before matching running headers.
- `grepl()` with a vector of patterns uses only the first pattern.
- `R` recycles vectors column-wise: `A * colSums(A)` misaligns. Use `t(A) %*% rowSums(A)` or `rep(..., each = nrow(A))`.

## Plots and analysis conventions

- Base pipe `|>`; ggplot2; `ggsave(bg = "white")` with theme_void or theme_minimal.
- Put comments above pipeline lines, not after them.
- Analysis that feeds a claim needs its counts and a stated basis; the report should cite the current
  network, not an earlier one.

## Environment

- renv is initialized (R 4.5.3, PPM bookworm binaries). After installing anything new, run
  `renv::snapshot()`. Restart the R session to activate renv.
- `backbone` 3.0.4 is locked and installed in the project library.

## Rights

- `data/kkcc-definition-texts.csv`, `data/kkcc-appendix-only-texts.csv` and the Part II quotations in
  PROVENANCE are verbatim quotations of Boroch and K&K. They stay out of any release.
- The user regards the 1952 K&K monograph as publicly available online, and treats K&K element labels
  as releasable. Boroch's article and its verbatim quotations remain restricted. Availability online
  does not by itself settle redistribution rights; flag this in any release note.
- Cite printed page numbers, not the unofficial scan copies.
