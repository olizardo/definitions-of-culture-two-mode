# Project memory: definitions-of-culture-two-mode

Two-mode network analysis of Boroch's KKCC classification (Kroeber & Kluckhohn, *Culture Concepts*,
1952), from Boroch's article `documents/ROBAFC-5.1.pdf`. Two data sources: Boroch's Table 2 and
appendix (hand-transcribed from the PDF) and K&K's Index A/B (parsed from `documents/Kroeber-kluckhohn.pdf`,
an ABBYY OCR of the 1952 scan).

Open items: `docs/TODO.md`. Completed items are struck through in place, not deleted, so item numbers stay stable for
references in PROVENANCE and the release CHANGELOG. Method, evidence and dated decisions: `docs/PROVENANCE.md`. Data dictionary,
network descriptions and limitations: `README.md`. Do not copy counts into this file; they go stale.

## Layout

- `scripts/`: all pipeline and analysis scripts. Run from the project root; paths are relative to it.
- `data/`: CSV and rds outputs. `docs/`: PROVENANCE.md, TODO.md.
- `figures/`: PNGs in subfolders by source: `boroch/` (main Boroch network, from `analysis-ca-mst-main.R`),
  `kk-index-b/definitions/` (CA and MST on the definitions network), `kk-index-b/works/` (CA and MST on the
  works network, both the works and concept views), and `kk-index-b/degree-works-definitions.png`. The heading
  MSTs are `kk-index-b/definitions/mst-heading-comm-tree.png` and `kk-index-b/works/mst-heading.png`.
  Filenames carry the network or node type; the folder carries the dataset. Scripts create their folders.
- `documents/`: source PDFs and an ignored text copy. `*_djvu.txt` is gitignored; do not commit or release it.
  `documents/pdfcoffee.com-*.pdf` is gitignored, but the file is still tracked at HEAD (see TODO).
- `kk-index-b-two-mode.tex`: the LaTeX draft report on the works and definitions networks. It reads the figures
  and CSVs written by the analysis scripts but does not source them, so rerun the scripts and update the
  numbers by hand.
- Scratch files go in `$PA_SCRATCH_DIR`, not the repo.
- `scripts/kk-group-style.R`: the K&K definition group names (A Descriptive, B Historical, C Normative,
  D Psychological, E Structural, F Genetic, G Incomplete) and their ggstar symbols. Sourced by
  `analysis-mst-definitions-index-b.R` and `analysis-ca-index-b.R`. Change the mapping there only.

## Main networks

Four two-mode networks are the stored Index B data. Projections are derived in the analyses, never stored.

1. Definitions × sub-elements: `kk-index-b-verified-network.rds` (`graph`, `biadjacency`).
2. Definitions × headings: `kk-index-b-heading-network.rds` (`graph`, `biadjacency`).
3. Works × sub-elements: `kk-index-b-work-concept-network-full.rds`, element `two_mode_graph`.
4. Works × headings: same file, element `two_mode_heading_graph`.

The works file also holds the work table (`works`). Attribute values agree across the four networks where
they overlap (checked 2026-10-25). Derive projections with `lcc_2core()` and `sub_work_matrix()` in
`scripts/core-index-b.R`, and apply the LCC and 2-core there, not in the stored file.

The published site and the release folder split the works file into two graph-only files
(`kk-index-b-works-sub-element-network.rds`, `kk-index-b-works-heading-network.rds`) and leave out the work table.
The split files are made from the full file; do not edit the full file's contents to make the split.

The network build reads `data/kkcc-appendix-only-links.csv` (`build-index-b-networks.R`), and the appendix-only links
set the Boroch labels on the code vertices. After a change to that file, rerun the network chain from
`build-index-b-networks.R` on, then the analyses.

## Rebuilding the K&K Index A/B data

Order: `build-index-b.R` → `build-index-b-crosswalk.R` → `build-index-b-networks.R` →
`build-index-b-verified.R` → `check-index-b-networks.R` → `check-index-b-blocks.R` →
`build-work-authors-index-b.R` → `build-work-concept-network-index-b.R` → `analysis-index-b.R` →
`analysis-ca-index-b.R` → `analysis-ca-works-index-b.R` → `analysis-centrality-index-b.R` →
`analysis-mst-definitions-index-b.R` → `analysis-mst-works-index-b.R` → `analysis-mst-headings-index-b.R`. The definitions analyses read
`data/kk-index-b-verified-network.rds`, not the unfiltered sub-element network. The works build
(`build-work-concept-network-index-b.R`) reads the verified network and the heading network. Run each in a fresh environment: `e <- new.env(); e$norm <- base::norm; sys.source(file, envir = e)`.
A new environment inherits the global session, and a live session may define a `norm` stub that shadows
`base::norm` (the prestige analysis then fails with `unused argument (type = "F")`).
The crosswalk reads its inputs from files; a stale session object once produced wrong output.

After any change, check that: the build runs without errors; every manual-fix key matches a token;
edge and parse-flag counts change only as expected; the validators pass. Then update the counts in
`README.md`.

## Manual fixes (`data/kk-index-b-manual-fixes.csv`)

- Columns: heading, sub_element, ocr_raw, kk_code, action, evidence, new_sub_element, occurrence.
  Actions: `set` (kk_code), `unresolve` (kk_code NA), `rename_sub` (element name only).
- Keys match the PARSED token table, not the exported edges. Use the PRE-correction heading. Heading
  variants (e.g. `adjustive-ajjptive function of culture`, `process ts and means`) are renamed after
  the manual fixes, so the key must use the variant. Copy keys from the parsed output, not the PDF.
- Heading corrections (`apply_heading_corrections()`) move entries after parsing, so a key uses the heading
  before the move: `capabilities` (now carriers of culture); `civilization` (only the civilization element
  stays there; the others are now common or shared patterns). The moved entries keep their pre-correction heading
  in `data/kk-index-b-flagged-audit.csv`. When a key fails with `length(hit) >= 1`, check that file for the heading
  (F-9 was under `civilization`).
- Use `occurrence` for identical tokens under the same heading and sub-element. Blank = all matches.
- Non-code tokens (e.g. "K -i", "B 17") are fixed in `kk-index-b-missing-rows.csv`, not here.
- Evidence must be a quoted CSV field. An unquoted comma or quote shifts the columns and the build
  then fails or silently produces a wrong edge set. Validate with `read.csv()` (8 columns) before rebuilding.
- The file uses CRLF line endings, like the committed copy. Keep them; a LF rewrite makes every line
  show as changed in git.
- Record the basis in the evidence column: printed page, crop resolution, or "user reading, not
  checked on the page image". Do not claim a page check you did not do.
- A remap of a printed code (D-8 → E-8, C-7 → C-I-7, F-9 → E-9, F-4 → F-I-4) is decided from the main text, which takes precedence
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
- A dropped roman I (`C-18` = C-I-8, `F-4` = F-I-4) and a truncated last digit (`D-I-1` for D-I-12) are common.
  Check a printed code without a roman numeral against the Index A author rows before accepting it.
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
- The bibliography (PDF pp. 190–205) runs printed = PDF + 1 on pp. 193–203 (checked on the page images 2026-10-26: PDF 196 prints as p. 197). Read the
  printed number from the page image before citing it.

## Index A

- Index A rows are keyed by `author_raw` + `raw_code`. Copy keys from `data/kk-index-a-authors.csv`.
- Corrections go in `kk-index-a-manual-fixes.csv` (kk_code, author_new, qualifier_new; blank = unchanged).
  A year-qualifier change (for example printed "(1941b)" set to "(1941)") is a manual fix too, and its evidence states the printed form.
  Rows the text layer omits go in `kk-index-a-missing-rows.csv`.
- Known OCR errors: merged entries (`Blumenthal • Boas`, `Carver < 1935)-Couru`), `Tumey-High`
  (Turney-High), `Thumwald` (Thurnwald), and year OCR like `(19 11)`, `(19:8)`. The `ok` flag does not
  mean verified.
- Name spellings and OCR name fixes that do not change a code go in
  `data/kk-index-b-name-decisions.csv` (year, index_name, work_name, basis), not in the Index A fixes.
  The work build reads it. Each row needs a printed-page basis.
- Index A D-II-7 is Young 1944 (user decision 2026-10-26). The printed index and footnote 7 say 1947; Boroch cites 1947;
  the change is recorded as an Index A manual fix (`kk-index-a-manual-fixes.csv`, evidence states the printed year),
  and the crosswalk has a `match` decision for D2-7 because the author-and-year rule no longer matches. The basis is the
  bibliography entry Young, K. 1944, *Social Psychology* (2nd ed.), printed p. 203 (checked on the page image). The book has printings with different years, so the printing year is not a basis.
- The Part III author index (printed p. 141) credits some authors with lowercase letter-number codes from Part
  III's own groups. Those are not Part II codes, so each attribution needs its own basis. The user-verified
  attributions are in `data/kk-part-iii-author-codes.csv`; `build-index-b.R` appends them to the author table,
  not to `index_a`.
- Authors that K&K cite in the main text but Index A omits: Maquet (C-I-18a), Aberle et al. (D-II-16), Taylor 1950
  (E-17). Sears's `C-I-Addendum` is an addendum linked to a specialty code, not a network code (user decision
  2026-10-25). Codes outside Index A enter the verified network only through `data/kk-index-b-verified-extra-codes.csv`,
  with one basis per code. Taylor's footnote 17 is commentary rather than a definition, so its basis is weaker than
  footnote 16 (Aberle) or 18a (Maquet).

## Crosswalk and Boroch's data

- Boroch's codes are K&K's groups with subgroups written as digits (C1 = C-I, D2 = D-II, F4 = F-IV).
  Within a group Boroch renumbers, so never match by position: the crosswalk matches by author, year,
  group and subgroup. Positional agreement is a check only.
- Hand decisions are in `data/kk-boroch-crosswalk-decisions.csv`, each with a basis.
- Table 2 has 135 definition columns. The appendix has 171 codes; 39 never appear in Table 2 (texts in
  `kkcc-appendix-only-texts.csv`, links in `kkcc-appendix-only-links.csv`). 37 of the 39 are linked to K&K codes,
  and the network uses those links as Boroch labels. F1-21 and G1 have no Index A row.
- Crosswalk hand decisions with a non-author basis: D2-7 (Young 1944, year changed in Index A) and D2-16 (K&K
  footnote 16). Each basis is in `data/kk-boroch-crosswalk-decisions.csv`.
- F4-6 is an off-by-one slip for F4-5 = Kluckhohn & Kelly 1945a: 87 (evidence in PROVENANCE section 5).
- Table 2's "TOTAL USES" counts uses with multiplicity; the binary matrices deduplicate.
- Main categories exclude their auxiliaries (SOCIAL 58 + Socially 10 = printed 68).

## Networks

- igraph `graph_from_biadjacency_matrix()` creates ROWS first (type = FALSE), then columns. Set vertex
  names and attributes in that order, or the graph silently corrupts.
- Custom graph builders must preserve vertex names.
- Disconnected two-mode graphs give several lambda = 1 eigen-dimensions in CA; drop all of them (use the 2-core).
- eigen() signs are arbitrary. Align definition scores to concept scores via the duality relation.
- Build the CA and MST projections from the LCC 2-core (`lcc_2core()`), not from the full stored network.
- Projection weights depend on the rows and columns kept. Removing a work or a sub-element changes the
  weights of the remaining pairs, so a projection of a 2-core must be recomputed from the 2-core matrix,
  not taken as an induced subgraph of the full projection.
- One verified definitions network: `scripts/build-index-b-verified.R` keeps the codes flagged `in_verified`
  (Index A codes, the Part III codes, and the codes in `data/kk-index-b-verified-extra-codes.csv`; `build-index-b.R` defines the flag) and writes `data/kk-index-b-verified-network.rds`. Sub-elements with no verified code are dropped; codes with no Index B edge are kept as isolates. Every definitions analysis (basic stats,
  CA, MST, centrality) reads it. Do not add a second filter in an analysis script. Any code left out of
  the network is listed in `data/kk-index-b-excluded-codes.csv` with its sub-elements. The raw
  `kk-index-b-subelement-network.rds` keeps all codes by design.
- Measures that need a connected network (closeness, betweenness, distances) run on the LCC. The
  normalizations are in `scripts/analysis-centrality-index-b.R`, from Borgatti & Everett (1997) as given at
  https://olizardo.github.io/SOCIOL208/cent-tm.html: closeness `n_Y + 2(n_X − 1)`; betweenness for the larger
  set `2(S−1)(L−1)` and for the smaller set `S(S−1)/2 + (L−1)(L−2)/2 + (L−1)(S−1)`, with L and S the larger
  and smaller set sizes. The betweenness formulas match the page, but the page states them only for its example.
- Two-mode graphs from `graph_from_biadjacency_matrix()` put the sub-elements as FALSE and the second mode
  (codes, headings or works) as TRUE. Pass `type` directly as `is.second`; negating it swaps the roles.
- Element names are not unique across headings ("systems", "accumulated treasury", "language"); a
  sub-element network node merges them. Use the heading network when the heading matters.
- A node attribute that exists on both modes (for example `n_codes`) must be written without overwriting the
  other mode's values. Copy by name and keep existing values on the other vertices.
- The validators check structure, round-trip to the CSVs, and attributes. They do not check the content
  of individual edges.
- The 2-core drops any node with fewer than two links, even if the one link is shared. In the heading
  projections (`analysis-mst-headings-index-b.R`) this drops five headings from each network (diffusion,
  forbidden, the permitted, the psychoanalytic elements, sanction), so they are absent from those trees.

## Works and author labels

- A work is keyed by its author set and year string (`scripts/build-work-concept-network-index-b.R`),
  built from the Index A entries under each code. Codes are categories and can hold several works; a
  work can sit under several codes. Do not treat a code as a work.
- Each entry keeps its own year. A year-less entry is dropped with a warning (e.g. "Kelly" under A-14).
- Bernard's mimeograph is one committee work of four authors, "Committee on Conceptual Integration (Bernard, Blumenthal, Dodd, Hart) 1941". Its Index A qualifier is (1941) by manual fix. Index B has no single-author Bernard 1941 work, and K&K's 1941a Social Forces article is not coded, so it is not in the data. The `group_year` column in the name decisions has no rows and is unused.
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
  Kruskal maximum spanning trees (`mst()` on `-weight`) of projections derived from the two-mode networks.
  Node size is tree betweenness; color is the leading-eigenvector community on the tree. The code-level tree
  labels each node with its K&K code; the works each code holds are in the `works` column of
  `data/kk-index-b-mst-definitions-tree-nodes.csv`.
- Heading MSTs (`scripts/analysis-mst-headings-index-b.R`) are built on the heading projections of both networks,
  after `lcc_2core()`. Ties are shared codes (definitions) or shared works (works). Node table:
  `data/kk-index-b-mst-headings-nodes.csv`. See PROVENANCE section 11.
- Work citations (`scripts/build-index-b-work-citations.R`, output `data/kk-index-b-work-citations.csv`): each work is matched to K&K's bibliography (text layer; surname, year and initials where the label has them) and to Boroch's supplement. Page-image checks in `data/kk-index-b-work-citations-page-checks.csv` override the automatic match, and the automatic K&K match is not evidence on its own. Initials in labels come from name decisions (for example "Kluckhohn C."). Publishers taken from Google Books or the user go in the page-check notes, not in K&K's printed text.
- Page-check `image_status`: `found` (agrees with the image), `corrected` (the automatic match was wrong; the note says why), `year_conflict`, and `quoted_in` (an unpublished source that K&K prints as quoted in another book; the build keeps it attested without a publication). Each page-check row records the K&K entry as printed on the image.
- Boroch sometimes lists one work under two codes (B023/B024, B150/B151). The page-check row names the K&K entry and the first Boroch ID, and the note names the other.
- Text-layer OCR misreads volumes and series (Bain vol. 17 is vol. 27 on the image). Check the image at 300 dpi before recording a volume, and do not copy an OCR value.
- A K&K misprint (for example "Anthrolopogy" for Anthropology) is recorded in the page-check note; the citation line uses the correct spelling.
- Boroch's supplement is not edited. Its errors are noted in the page-check notes (for example B060, whose title is K&K's 1937 festschrift article).
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
- Node labels are unique within a plot. Code nodes are labeled with the K&K code, work nodes with the work label,
  and sub-element nodes with the element name. Do not label a code with the works it holds; those go in the node table.
- A definition group is the first letter of the code (A–G, the K&K categories). Draw it with the ggstar symbols in
  `scripts/kk-group-style.R` wherever definition groups appear, so one symbol means one group across figures.
- Where labels must stay readable together (the definitions CA), put them in one `geom_label_repel` layer so
  ggrepel keeps them apart.

## Environment

- renv is initialized (R 4.5.3, PPM bookworm binaries). Do not run `renv::snapshot()` blindly: it records every
  package the dependency scan finds, which on 2026-10-26 added 22 unrelated packages (bslib, knitr, and others).
  Record specific packages with `renv::record("pkg@version")`, then check that `git diff renv.lock` shows only the
  intended additions. Restart the R session to activate renv.
- `ggstar` 1.0.6 is installed and recorded in `renv.lock` with its dependencies (`ggiraph`, `gdtools`, `fontquiver`,
  `fontBitstreamVera`, `fontLiberation`, `htmlwidgets`). `gdtools` builds from source and needs the system cairo
  headers (`libcairo2-dev`, `libfontconfig1-dev`, `libfreetype-dev`). Installed 2026-10-26.
- `backbone` 3.0.4: as of 2026-10-25 its entry is deleted from `renv.lock` in the working tree but not committed
  (not done by the assistant). No script uses it since the backbone analysis was removed. Confirm before committing.
  Remove it with `renv::remove("backbone")` and `renv::snapshot()` once that is confirmed.

## Release and publication

- The release is the two-mode network data in `release/two-mode-network-data/`, version 0.2.0: three `.rds` files
  (the four stored Index B networks), `kk-index-b-work-citations.csv`, `MANIFEST.md` and `CHANGELOG.md`.
  Versioning: a minor bump for added data or changed network contents, a patch for fixes that leave the structure
  alone. Each change goes in `CHANGELOG.md` with its version and date. The `.rds` files are copies of `data/`:
  refresh them when the data changes, and update the dimensions in `MANIFEST.md`. The citation file keeps core
  columns only (Boroch references and match status); K&K page text and review notes stay out. The Boroch two-mode networks
  (`kkcc_two_mode*.rds`) are not in the release. Keep them out unless the user changes this.
- Published site: GitHub Pages from the `gh-pages` branch of `origin` (`olizardo/definitions-of-culture-two-mode`),
  at https://olizardo.github.io/definitions-of-culture-two-mode/. The site source is
  `~/projects/ACADEMICS/kkcc-two-mode-data/` (a local Quarto project, not in this repo; `website/` renders to `docs/`).
- Publish by cloning `gh-pages` into a scratch directory, replacing its contents with the rendered `docs/`, copying the
  `.rds` files into `data/` and `.nojekyll` into the root, committing, and pushing as a fast-forward. Never force-push.
  Do not push `master`/`main` from this repo as part of a site update. Pushes need the user's approval.
- The repo's `main` has uncommitted work (see TODO) and is not part of the publication.

## Rights

- `data/kkcc-definition-texts.csv`, `data/kkcc-appendix-only-texts.csv` and the Part II quotations in
  PROVENANCE are verbatim quotations of Boroch and K&K. They stay out of any release.
- References in the Boroch bibliography (`kkcc-definition-biblio.csv`, `bib_ref`, `kkcc-supplement-bibliography.csv`) are
  public references and may be included (user decision, 2026-10-25).
- The release citation table gives Boroch's references and K&K match status only. K&K bibliography lines and page
  snippets are left out; whether they may be released has not been settled.
- The user regards the 1952 K&K monograph as publicly available online, and treats K&K element labels
  as releasable. Boroch's article and its verbatim quotations remain restricted. Availability online
  does not by itself settle redistribution rights; flag this in any release note.
- Boroch's article is posted on PhilPapers (https://philpapers.org/archive/ROBAFC-5.pdf). The assistant could not
  access that URL (HTTP 403), so its posting terms are unverified. The local copy, `documents/ROBAFC-5.1.pdf`
  (MD5 767c5c651a991d0de5c368afd4f0f7eb), has no copyright or license notice. A public posting does not by itself
  settle redistribution.
- Cite printed page numbers, not the unofficial scan copies.
