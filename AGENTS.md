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
- `data/`: CSV and rds outputs. `docs/`: PROVENANCE.md, TODO.md.
- `figures/`: PNGs in subfolders by source: `boroch/` (main Boroch network, from `analysis-ca-mst-main.R`),
  `kk-index-b/definitions/` (CA and MST on the definitions network), `kk-index-b/works/` (CA and MST on the
  works network, both the works and concept views), and `kk-index-b/degree-works-definitions.png`.
  Filenames carry the network or node type; the folder carries the dataset. Scripts create their folders.
- `documents/`: source PDFs and an ignored text copy. `*_djvu.txt` is gitignored; do not commit or release it.
  `pdfcoffee.com-…pdf` was untracked from git on 2026-10-25 (staged removal, not yet committed). The file
  stays on disk; the git history still contains it.
- `kk-index-b-two-mode.tex`: the LaTeX draft report on the works and definitions networks. It replaced the
  Quarto report `kkcc-two-mode.qmd`, which was removed. The tex reads figures and CSVs written by the
  analysis scripts; it does not source them, so rerun the scripts and update the numbers by hand.
  `kkcc-two-mode.html` is a stale render of the removed report.
- Scratch files go in `$PA_SCRATCH_DIR`, not the repo.

## Rebuilding the K&K Index A/B data

Order: `build-index-b.R` → `build-index-b-crosswalk.R` → `build-index-b-networks.R` →
`build-index-b-verified.R` → `check-index-b-networks.R` → `check-index-b-blocks.R` →
`build-work-authors-index-b.R` → `build-work-concept-network-index-b.R` → `analysis-index-b.R` →
`analysis-ca-index-b.R` → `analysis-ca-works-index-b.R` → `analysis-centrality-index-b.R` →
`analysis-mst-definitions-index-b.R` → `analysis-mst-works-index-b.R`. The definitions analyses read
`data/kk-index-b-verified-network.rds`, not the unfiltered sub-element network. The works build
(`build-work-concept-network-index-b.R`) also reads the verified network. Run each in a fresh environment: `sys.source(file, envir = new.env())`.
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
- Heading corrections (`apply_heading_corrections()`) move entries after parsing, so a key uses the heading
  before the move: `capabilities` (now carriers of culture); `civilization` (only the civilization element
  stays there; the others are now common or shared patterns).
- Use `occurrence` for identical tokens under the same heading and sub-element. Blank = all matches.
- Non-code tokens (e.g. "K -i", "B 17") are fixed in `kk-index-b-missing-rows.csv`, not here.
- Evidence must be a quoted CSV field. An unquoted comma or quote shifts the columns and the build
  then fails or silently produces a wrong edge set. Validate with `read.csv()` (8 columns) before rebuilding.
- The file uses CRLF line endings, like the committed copy. Keep them; a LF rewrite makes every line
  show as changed in git.
- Record the basis in the evidence column: printed page, crop resolution, or "user reading, not
  checked on the page image". Do not claim a page check you did not do.
- A remap of a printed code (D-8 → E-8, C-7 → C-I-7) is decided from the main text, which takes precedence
  over the printed Index B. Cite the main-text footnote (author, year, page) as the basis and say whether it
  was image-checked.

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
- Main-text footnotes cite the SOURCE's page ("Goldenweiser, 1933: 59"), not the page of the K&K text that
  carries the footnote. Coutu's footnote 8 is on printed p. 61 (PDF 64). The Part III author index is printed
  p. 141 (PDF 143). "Words not included in Index B" is printed pp. 78–79 (PDF 81–82).
- Crops: `pdftoppm -r DPI -x X -y Y -W W -H H` takes pixels (points × DPI / 72). `pdftotext -bbox`
  reports points. Use 300 dpi for normal checks and 400–600 dpi for ambiguous glyphs.
- The ABBYY text layer lacks running headers. Searching a page with `awk -v RS='\f'` also hits
  footnotes; confirm on the image.
- The Internet Archive copies (`culturecriticalr0000kroe_z3a4`, Scribe OCR) are leads, not evidence:
  their left column is clipped and their Index A digits are weaker than ours.
- The bibliography (PDF pp. 190–205) does not follow the −3 offset: PDF 192 prints as p. 193. Read the
  printed number from the page image before citing it.

## Index A

- Index A rows are keyed by `author_raw` + `raw_code`. Copy keys from `data/kk-index-a-authors.csv`.
- Corrections go in `kk-index-a-manual-fixes.csv` (kk_code, author_new, qualifier_new; blank = unchanged).
  Rows the text layer omits go in `kk-index-a-missing-rows.csv`.
- Known OCR errors: merged entries (`Blumenthal • Boas`, `Carver < 1935)-Couru`), `Tumey-High`
  (Turney-High), `Thumwald` (Thurnwald), and year OCR like `(19 11)`, `(19:8)`. The `ok` flag does not
  mean verified.
- Name spellings and OCR name fixes that do not change a code go in
  `data/kk-index-b-name-decisions.csv` (year, index_name, work_name, basis), not in the Index A fixes.
  The work build reads it. Each row needs a printed-page basis.
- Index A D-II-7 is now Young 1946 (user decision 2026-10-25). The printed index says 1947 and Boroch cites 1947;
  the change is recorded as an Index A manual fix (`kk-index-a-manual-fixes.csv`, evidence states the printed year),
  and the crosswalk has a `match` decision for D2-7 because the author-and-year rule no longer matches. The basis is the
  book record (Kimball Young, *Handbook of Social Psychology*, Google Books gives 1946); not checked on a page image.
- The Part III author index (printed p. 141) credits some authors with lowercase letter-number codes from Part
  III's own groups. Those are not Part II codes, so each attribution needs its own basis. The user-verified
  attributions are in `data/kk-part-iii-author-codes.csv`; `build-index-b.R` appends them to the author table,
  not to `index_a`.

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
- The works build prunes codes and concepts with fewer than two links, so a code with one element (D-5) can
  be in the verified network and still drop out of the projections.
- One verified definitions network: `scripts/build-index-b-verified.R` keeps the codes flagged `in_verified`
  (Index A codes, the Part III codes, and the codes in `data/kk-index-b-verified-extra-codes.csv`; `build-index-b.R` defines the flag) and writes `data/kk-index-b-verified-network.rds`. Every definitions analysis (basic stats,
  CA, MST, centrality) reads it. Do not add a second filter in an analysis script. Excluded codes and their
  sub-elements are in `data/kk-index-b-excluded-codes.csv`; they are unverified and still need checking
  against the printed index (TODO). The raw `kk-index-b-subelement-network.rds` keeps them by design.
- Measures that need a connected network (closeness, betweenness, distances) run on the LCC. The
  normalizations are in `scripts/analysis-centrality-index-b.R`, from Borgatti & Everett (1997) as given at
  https://olizardo.github.io/SOCIOL208/cent-tm.html: closeness `n_Y + 2(n_X − 1)`; betweenness for the larger
  set `2(S−1)(L−1)` and for the smaller set `S(S−1)/2 + (L−1)(L−2)/2 + (L−1)(S−1)`, with L and S the larger
  and smaller set sizes. The betweenness formulas match the page, but the page states them only for its example.
- Two-mode graphs from `graph_from_biadjacency_matrix()` put the sub-elements as FALSE and the second mode
  (codes or works) as TRUE. Pass `type` directly as `is.second`; negating it swaps the roles.
- Element names are not unique across headings ("systems", "accumulated treasury", "language"); a
  sub-element network node merges them. Use the heading network when the heading matters.
- The validators check structure, round-trip to the CSVs, and attributes. They do not check the content
  of individual edges.

## Works and author labels

- A work is keyed by its author set and year string (`scripts/build-work-concept-network-index-b.R`),
  built from the Index A entries under each code. Codes are categories and can hold several works; a
  work can sit under several codes. Do not treat a code as a work.
- The work-year parser keeps each entry's year with that entry (fixed 2026-10-25). `regmatches()` had dropped
  year-less entries and shifted every later year onto the wrong entry. A year-less entry is dropped with a
  warning (e.g. "Kelly" under A-14).
- Co-authored works list every author sharing the year. A co-author written as a prefix of a full name
  in the same year group takes the full name (`canon.names()`), unless `kk-index-b-name-decisions.csv`
  says otherwise. The prefix rule once merged two different Gillins; the decision file now overrides it.
- Labels: `scripts/label-authors-index-b.R` holds the initials lookup (from the page checks in
  `data/kk-index-b-work-authors-page-checks.csv`) and `label.authors()`. Year-specific keys
  (`"Woodward|1940"`) cover surnames with two initial forms. Authors with no entry stay unlabelled and
  the analysis script reports them.
- "+" in a label means two or more distinct works (distinct year strings) in one entry. Co-authored
  versions of one work get no "+".
- `data/kk-index-b-work-authors.csv` is the parser output (surname + year match to the bibliography
  text layer). It is not verified; the page-check CSV is the verified record. The parser drops headings
  split across lines (Kelly is the main gap) and misses some years.
- The MSTs (`scripts/analysis-mst-works-index-b.R`, `scripts/analysis-mst-definitions-index-b.R`) are
  Kruskal maximum spanning trees (`mst()` on `-weight`). Node size is tree betweenness; color is the
  leading-eigenvector community on the tree. The code-level tree labels each code with the works it holds.
- Figure subtitles must describe what the labels show.
- Titles name the network ("definitions network", "works network") and the node type, so each figure says
  where it came from. CA labels use `geom_label_repel` with a white fill so they stay readable over the points.

## Regex and text gotchas (R)

- Default regex is POSIX TRE. Inside a bracket class `\s` is a literal backslash and `s`; use
  `[[:space:]]`. `\s` and `\d` work outside brackets, or use `perl = TRUE`.
- `\\.` does not match a literal period in TRE; use `[.]` or `perl = TRUE`.
- `sub()` with a capture group drops the matched text; to extract a leading token, append `.*$`.
- Normalize ligatures (ﬁ→fi) before matching running headers.
- `grepl()` with a vector of patterns uses only the first pattern.
- `R` recycles vectors column-wise: `A * colSums(A)` misaligns. Use `t(A) %*% rowSums(A)` or `rep(..., each = nrow(A))`.
- `dir.create()` takes one path; `dir.create(c(...))` errors with "invalid 'path' argument". Loop with `lapply`.
- ggplot2 4.0.3 is installed. `facetted_pos_scales()` is gone; for per-panel x ticks, use a breaks function
  on `scale_x_continuous()`. Its limits are the expanded range, not the data range.

## Plots and analysis conventions

- Base pipe `|>`; ggplot2; `ggsave(bg = "white")` with theme_void or theme_minimal.
- Put comments above pipeline lines, not after them.
- Analysis that feeds a claim needs its counts and a stated basis; the report should cite the current
  network, not an earlier one.

## Environment

- renv is initialized (R 4.5.3, PPM bookworm binaries). After installing anything new, run
  `renv::snapshot()`. Restart the R session to activate renv.
- `backbone` 3.0.4 is still in `renv.lock`, but no script uses it since the backbone analysis was removed.
  Remove it with `renv::remove("backbone")` and `renv::snapshot()` once that is confirmed.

## Rights

- `data/kkcc-definition-texts.csv`, `data/kkcc-appendix-only-texts.csv` and the Part II quotations in
  PROVENANCE are verbatim quotations of Boroch and K&K. They stay out of any release.
- The user regards the 1952 K&K monograph as publicly available online, and treats K&K element labels
  as releasable. Boroch's article and its verbatim quotations remain restricted. Availability online
  does not by itself settle redistribution rights; flag this in any release note.
- Cite printed page numbers, not the unofficial scan copies.
