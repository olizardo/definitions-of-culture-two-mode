# Project memory: definitions-of-culture-two-mode

Two-mode network analysis of Boroch's KKCC classification (Kroeber & Kluckhohn, *Culture Concepts*, 1952), from Boroch's article `documents/ROBAFC-5.1.pdf`. Two data sources: Boroch's Table 2 and appendix (hand-transcribed from the PDF), and K&K's Index A/B (parsed from `documents/Kroeber-kluckhohn.pdf`, an ABBYY OCR of the 1952 scan).

Open items: `docs/TODO.md`. Dated decisions and evidence: `docs/PROVENANCE.md` (cite by section). Data dictionary, network descriptions and limitations: `README.md`. Release history: `release/two-mode-network-data/CHANGELOG.md`. Do not copy counts into this file; they go stale.

## Layout

- `scripts/`: pipeline and analysis scripts, run from the project root in a fresh environment (see Rebuilding). Shared helpers: `core-index-b.R` (`lcc_2core()`, `sub_work_matrix()`), `nmf-core.R`, `kk-group-style.R` (group names and ggstar symbols; change the mapping there only), `pub-type-style.R`, `label-authors-index-b.R`.
- `data/`: CSV and rds outputs. `docs/`: PROVENANCE.md, TODO.md.
- `figures/`: PNGs by source: `boroch/`, `kk-index-b/definitions/`, `kk-index-b/works/`, `kk-index-b/nmf/`. Filenames carry the network or node type; the folder carries the dataset. Scripts create their folders. The heading MSTs are generated but not used in the manuscript.
- `documents/`: source PDFs and an ignored text copy. `*_djvu.txt` is gitignored; do not commit or release it. `documents/pdfcoffee.com-*.pdf` is gitignored but still tracked (see TODO).
- `kk-index-b-two-mode.tex`: the LaTeX draft report. It reads the figures and CSVs but does not source them, so rerun the scripts and update numbers by hand, following "Manuscript numbers" below. Citations are natbib (`abbrvnat`). The bibliography is `\bibliography{references,library}`; `library.bib` is a gitignored symlink to the user's `~/My Library.bib`. Compile with pdflatex, bibtex, pdflatex twice. A clean compile has no overfull boxes and no undefined references.
- The compile artifacts (`kk-index-b-two-mode.{aux,log,out,fls,fdb_latexmk,pdf}`) are tracked in git and show as modified after every compile. Do not commit them unless asked.
- MST betweenness in the tables is Freeman-normalized and pasted in by hand from `data/kk-index-b-mst-*.csv`.
- Scratch files go in `$PA_SCRATCH_DIR`, not the repo.

## Main networks

Four two-mode networks are the stored Index B data. Projections are derived in the analyses, never stored.

1. Definitions × sub-elements: `kk-index-b-verified-network.rds` (`graph`, `biadjacency`).
2. Definitions × headings: `kk-index-b-heading-network.rds` (`graph`, `biadjacency`).
3. Works × sub-elements: `kk-index-b-work-concept-network-full.rds`, element `two_mode_graph`.
4. Works × headings: same file, element `two_mode_heading_graph`.

The works file also holds the work table (`works`). Attribute values agree across the four networks where they overlap. Derive projections with `lcc_2core()` and `sub_work_matrix()` in `scripts/core-index-b.R`, applying the LCC and 2-core there, not in the stored file. The stored networks hold only the verified codes: the Part III statement codes (C-5, D-5, D-7, E-17) were removed from the edge list on 2026-10-30 (PROVENANCE 16), so the raw sub-element and heading networks have the same nodes as the verified network.

The release folder holds the full works file, with the work table. The site holds two graph-only split files (`kk-index-b-works-sub-element-network.rds` = `two_mode_graph`, `kk-index-b-works-heading-network.rds` = `two_mode_heading_graph`). No script makes the split. It is made by hand from the full file and must be regenerated each time it is published. Do not edit the full file's contents to make the split.

The network build reads `data/kkcc-appendix-only-links.csv`, and those links set the Boroch labels on the code vertices. After a change to that file, rerun the network chain from `build-index-b-networks.R` on, then the analyses.

## Rebuilding the K&K Index A/B data

Order: `build-index-b.R` → `build-index-b-crosswalk.R` → `build-index-b-networks.R` → `build-index-b-verified.R` → `check-index-b-networks.R` → `check-index-b-blocks.R` → `build-work-concept-network-index-b.R` → `build-work-authors-index-b.R` → `attach-work-pub-type-index-b.R` → `analysis-index-b.R` → `analysis-ca-index-b.R` → `analysis-ca-works-index-b.R` → `analysis-centrality-index-b.R` → `analysis-mst-definitions-index-b.R` → `analysis-mst-works-index-b.R` → `analysis-mst-headings-index-b.R`.

- The definitions analyses read `data/kk-index-b-verified-network.rds`, not the sub-element network. The two have the same nodes since 2026-10-30, but the verified file is still the input.
- `build-work-authors-index-b.R` reads the works table that `build-work-concept-network-index-b.R` writes, so it must run after it.
- After the analyses: `build-index-b-work-citations.R`, `check-definition-text-coverage.R`, `analysis-nmf-works-index-b.R`, `analysis-nmf-texts-index-b.R`, `analysis-mst-nmf-works-index-b.R`, `figure-sankey-subgroups.R`. `analysis-nmf-work-texts-index-b.R` is withdrawn, and `figure-sankey-agreement.R` is not in the manuscript; neither is needed for a rebuild.
- Scripts call `source()` for their shared helpers (`label.authors()`, `lcc_2core()`, `kk-group-style.R`). Unless the run environment overrides `source`, those helpers land in the global environment and a fresh environment cannot see them. Use `e$source <- function(file, local = FALSE, ...) sys.source(file, envir = e)` alongside `e$norm`, and set the parent to `parent.env(globalenv())` so no global variable can satisfy a name.
- Run each script in a fresh environment: `e <- new.env(); e$norm <- base::norm; sys.source(file, envir = e)`, with an empty global environment. A live session's variables can silently satisfy a bare name and corrupt the run, and the crosswalk reads its inputs from files, so a stale session object gives wrong output.
- After any change, check that the build runs without errors, every manual-fix key matches a token, edge and parse-flag counts change only as expected, and the validators pass. Then update the counts in `README.md`.

## Manual fixes (`data/kk-index-b-manual-fixes.csv`)

- Columns: heading, sub_element, ocr_raw, kk_code, action, evidence, new_sub_element, occurrence. Actions: `set` (kk_code), `unresolve` (kk_code NA), `rename_sub` (element name only).
- Keys match the PARSED token table, not the exported edges. Use the PRE-correction heading, and the heading variant if one applies (variants are renamed after the manual fixes). Copy keys from the parsed output, not the PDF.
- Heading corrections (`apply_heading_corrections()`) move entries after parsing, so a key uses the heading before the move (for example `capabilities`, `civilization`). Moved entries keep their pre-correction heading in `data/kk-index-b-flagged-audit.csv`. When a key fails with `length(hit) >= 1`, check that file.
- Use `occurrence` for identical tokens under the same heading and sub-element. Blank means all matches.
- Non-code tokens (for example "K -i", "B 17") are fixed in `kk-index-b-missing-rows.csv`, not here.
- Evidence must be a quoted CSV field. An unquoted comma or quote shifts the columns and the build then fails or silently produces a wrong edge set. Validate with `read.csv()` (8 columns) before rebuilding.
- The file uses CRLF line endings. Keep them, or every line shows as changed in git.
- Record the basis in the evidence column: printed page, crop resolution, or "user reading, not checked on the page image". Do not claim a page check you did not do.
- A remap of a printed code (D-8 → E-8, C-7 → C-I-7, F-9 → E-9, F-4 → F-I-4) is decided from the main text, which takes precedence over the printed Index B. Cite the main-text footnote (author, year, page) and say whether it was image-checked.

## Rules for OCR tokens

- Do NOT add general character rules. The `norm_number()` map (i→1, y→5, etc.) silently produces codes from any token; that is how A-iy, B-iy and D-II-iy became edges. Prefer an explicit manual fix with its evidence. The existing general rules are a known debt (see TODO).
- `j` is printed as 3 or 5 on the scan. It is deliberately unmapped; resolve `j` tokens only from a page-image check or a single printed candidate under that sub-element.
- A trailing `a` is read as `3` (`A-103` = A-10a).
- A dropped roman I (`C-18` = C-I-8) and a truncated last digit (`D-I-1` for D-I-12) are common. Check a printed code without a roman numeral against the Index A author rows before accepting it.
- Roman tokens containing H: `norm_roman()` returns III for IH/lH. Check any new roman-slot token that contains H.
- `norm_number()` treats a lone `n` or `u` as 11 (`A-n` = A-11).
- Index B element names can absorb code fragments ("adjust \-2o" = adjust plus A-20). Fix the name with `rename_sub` and recover the edge with a missing-rows row.
- `is_entry_start()` must not treat an OCR code dash as a heading dash. After any parser change, check `pe$entries$heading` for NA.

## Page images and offsets

- `Kroeber-kluckhohn.pdf` (ABBYY): printed page = PDF page − 3, but the offset drifts through the book. Read the printed number from the page image before citing it.
- Part II, Definitions (printed 41–81) holds groups A–G with roman-numeral subgroups. Index A and Index B are at printed 73–78. Part III, Some Statements About Culture (printed 83 onward), has its own groups a–f with plain numbers and its own author index (printed p. 141). Part III group headings: a 84, b 95, c 99, d 102, f 125 (printed).
- The 229-page copy (`…_compress.pdf`, the same file as the tracked pdfcoffee copy): printed = PDF − 6. Each new copy needs its own offset. Cite printed page numbers, not a copy's PDF page.
- Main-text footnotes cite the SOURCE's page, not the page of the K&K text that carries the footnote.
- The bibliography (PDF pp. 190–205) runs printed = PDF + 1 on pp. 193–203. Read the printed number from the image.
- Crops: `pdftoppm -r DPI -x X -y Y -W W -H H` takes pixels (points × DPI / 72); `pdftotext -bbox` reports points. Use 300 dpi for normal checks and 400–600 for ambiguous glyphs.
- The ABBYY text layer lacks running headers, and a page search also hits footnotes; confirm on the image.
- The Internet Archive copies (`culturecriticalr0000kroe_z3a4`) are leads, not evidence: their left column is clipped and their Index A digits are weaker.

## Index A

- Index A rows are keyed by `author_raw` + `raw_code`. Copy keys from `data/kk-index-a-authors.csv`.
- Corrections go in `kk-index-a-manual-fixes.csv` (kk_code, author_new, qualifier_new; blank = unchanged). A year-qualifier change is a manual fix too, and its evidence states the printed form. Rows the text layer omits go in `kk-index-a-missing-rows.csv`.
- Known OCR errors: merged entries (`Blumenthal • Boas`), `Tumey-High` (Turney-High), `Thumwald` (Thurnwald), and year OCR like `(19 11)`. The `ok` flag does not mean verified.
- Name spellings and OCR name fixes that do not change a code go in `data/kk-index-b-name-decisions.csv` (year, index_name, work_name, basis), not in the Index A fixes. Each row needs a printed-page basis.
- D-II-7 is Young 1944 by user decision. The printed index and footnote say 1947, and the change is an Index A manual fix whose evidence states the printed year. The crosswalk has a `match` decision for D2-7. The basis is the bibliography entry (printed p. 203, checked on the image), not the printing year, because the book has printings with different years.
- The Part III author index credits some authors with lowercase codes from Part III's own groups. Those are not Part II codes, so each attribution needs its own basis. The Part III statement codes (C-5, D-5, D-7, E-17) were removed from the analysis on 2026-10-30 (PROVENANCE 16), and their attributions are gone from `data/kk-part-iii-author-codes.csv`. Only the Roheim D-IV-1 and F-IV-4 rows remain, duplicating Index A rows. `build-index-b.R` appends the file's rows to the author table, not to `index_a`. Check each attribution on the page image, not the text layer: the text layer misread c-5 as e-5. The OCR also drops some names on the Index A pages (Goldenweiser is absent from the Index A text layer), so a missing author may still be printed there.
- Authors K&K cite in the main text but Index A omits: Maquet (C-I-18a), Aberle et al. (D-II-16). Sears's `C-I-Addendum` is an addendum linked to a specialty code, not a network code (user decision). Codes outside Index A enter the verified network only through `data/kk-index-b-verified-extra-codes.csv`, with one basis per code. Extras extend the universe in `build-index-b.R`, so an extra may have no Index A entry and no Index B element. Part III statement codes are out of the analysis: each one is listed in `data/kk-index-b-part-iii-codes.csv` with its basis, and `build-index-b.R` drops its Index B edges. Any new Part III statement code needs a row there.
- K&K's printed text gives three codes a) and b) quotations inside one numbered footnote: E-5 (footnote 5, Linton 1945a), F-II-4 (footnote 4, Blumenthal 1937) and F-II-7 (footnote 7, Feibleman 1946, "tentative" and "final" definitions). Index A and Index B print one entry per code, so these are one network code each. Boroch splits each into two codes (E5/E6, F2-4/F2-5, F2-8/F2-9). A letter suffix on a K&K code (A-10a, B-4a, C-I-5a, F-I-1a, C-I-18a) is a separate printed code, not a quotation variant.
- Those codes and A-3 are split into variants, A-3(a)/(b), E-5(a)/(b), F-II-4(a)/(b) and F-II-7(a)/(b), by user decision on 2026-10-30 (PROVENANCE 17). The split table is `data/kk-index-b-code-splits.csv`; Index B links are copied to both variants, then 29 variant-specific links are removed on the quotation-text screen (`data/kk-index-b-variant-link-decisions.csv`, PROVENANCE 17.8). The page-image check of footnote 5 is still open. The OCR of footnote 5 reads "Linton, 1943a: 3, 32", while Boroch and `kkcc-appendix-only-links.csv` give 1945a: 5, 32. Check the page image before any split. The footnote is on PDF page 64 of `Kroeber-kluckhohn.pdf`; read the printed page from the image.

## Crosswalk and Boroch's data

- Boroch's codes are K&K's groups with subgroups written as digits (C1 = C-I, D2 = D-II). Boroch renumbers within a group, so never match by position: the crosswalk matches by author, year, group and subgroup. Positional agreement is a check only.
- Group A renumbers one ahead of K&K from A4 on, because Boroch splits Dixon 1928 into A3 and A4 (both K&K A-3, now A-3(a) and A-3(b) after the 2026-10-30 split, PROVENANCE 17). Boroch A5 is Benedict = K&K A-4. The crosswalk has this right (checked against the printed Group A page). Use named columns in `data/kk-boroch-crosswalk.csv`, never position.
- Hand decisions are in `data/kk-boroch-crosswalk-decisions.csv`, each with a basis.
- Appendix codes that never appear in Table 2 enter the network through `kkcc-appendix-only-texts.csv` and `kkcc-appendix-only-links.csv`. F1-21 is linked to F-I-20 on the main-text citation. G1 is linked to G-1 (printed Index A p. 74).
- F4-6 is an off-by-one slip for F4-5 = Kluckhohn & Kelly 1945a (PROVENANCE section 5).
- The crosswalk has rows for both A10 and A10a, and both match K&K A-9 on the auto match. K&K prints A-10a as a separate code (Lowie 1937, Index A), so the A10a match is doubtful and has not been checked on the page image.
- Table 2's "TOTAL USES" counts uses with multiplicity; the binary matrices deduplicate.

## Networks

- igraph `graph_from_biadjacency_matrix()` creates ROWS first (type = FALSE), then columns. Set vertex names and attributes in that order, or the graph silently corrupts. Custom graph builders must preserve vertex names.
- Two-mode graphs put the sub-elements as FALSE and the second mode (codes, headings or works) as TRUE. Pass `type` directly as `is.second`; negating it swaps the roles.
- Disconnected two-mode graphs give several lambda = 1 eigen-dimensions in CA; drop all of them (use the 2-core). eigen() signs are arbitrary; align definition scores to concept scores via the duality relation.
- Build CA and MST projections from the LCC 2-core (`lcc_2core()`). Projection weights depend on the rows and columns kept, so a 2-core projection must be recomputed from the 2-core matrix, not taken as an induced subgraph of the full projection.
- The verified definitions network is built by `scripts/build-index-b-verified.R`. It keeps the codes flagged `in_verified` (Index A codes and the verified extras; `build-index-b.R` defines the flag). Every definitions analysis reads it. Do not add a second filter in an analysis script. Codes left out are listed in `data/kk-index-b-excluded-codes.csv`, which has been empty since 2026-10-30, when the Part III statement codes were removed from the edge list. Code names are the columns of the verified network's `biadjacency`, and `data/kk-index-b-definitions.csv` has one row per code, which is the verified set, with group, Index A and Index B flags. The heading MST also keeps only the verified codes (a guard; the raw heading network is the same set).
- Measures that need a connected network (closeness, betweenness, distances) run on the LCC. The normalizations are in `scripts/analysis-centrality-index-b.R`, from Borgatti & Everett (1997). The betweenness formulas match the source page, which states them only for its example.
- Element names are not unique across headings ("systems", "language"). A sub-element network node merges them; use the heading network when the heading matters.
- A node attribute that exists on both modes (for example `n_codes`) must be written without overwriting the other mode's values.
- The validators check structure, round-trips and attributes. They do not check the content of individual edges.
- The 2-core drops any node with fewer than two links, even if the one link is shared. In the heading projections this drops several headings (diffusion, forbidden, the permitted, the psychoanalytic elements, sanction), so they are absent from those trees.

## Works and author labels

- A work is keyed by its author set and year string (`scripts/build-work-concept-network-index-b.R`), built from the Index A entries under each code. Each code maps to exactly one work (checked 2026-10-30: 164 codes with works, no code has entries with more than one year; C-I-18a, D-II-16 and D-III-1 have no work). A work can sit under several codes: 112 of 131 works sit under one code, 19 under two to eight (Kelly & Kluckhohn C. 1945a under eight). Do not treat a code as a work.
- Each entry keeps its own year. A year-less entry is dropped with a warning. Kelly's warnings are noise: the only Kelly work is the co-authored Kluckhohn & Kelly 1945a, which every Kelly code also gets through Kluckhohn's entry. Tozzer's `D-III-1 (n.d.)` is the consequential year-less drop, which is why D-III-1 has no work.
- Goldenweiser 1933 (under D-5) and 1937 (under C-5) were attached only to Part III codes and were removed with them on 2026-10-30 (PROVENANCE 16). Roheim 1934 stays, under D-IV-1 only. Page-image checks for removed works stay in the page-check file as a record and are skipped by the citation build.
- Bernard's mimeograph is one committee work of four authors, "Committee on Conceptual Integration (Bernard, Blumenthal, Dodd, Hart) 1941". Index A keeps the printed qualifier (1941b); the name-decisions row sets group_year 1941, which moves the entry into that work (PROVENANCE 9.36).
- Co-authored works list every author sharing the year. A co-author written as a prefix of a full name in the same year group takes the full name (`canon.names()`), unless `kk-index-b-name-decisions.csv` says otherwise.
- Labels: `scripts/label-authors-index-b.R` holds the initials lookup (from `data/kk-index-b-work-authors-page-checks.csv`) and `label.authors()`. Year-specific keys (`"Woodward|1940"`) cover surnames with two initial forms. Authors with no entry stay unlabelled and the analysis script reports them.
- "+" in a label means two or more distinct works in one entry. Co-authored versions of one work get no "+".
- `data/kk-index-b-work-authors.csv` is parser output, not verified. The page-check CSV is the verified record.
- Work citations (`scripts/build-index-b-work-citations.R`, output `data/kk-index-b-work-citations.csv`) match each work to K&K's bibliography and Boroch's supplement. Page-image checks in `data/kk-index-b-work-citations-page-checks.csv` override the automatic match; the automatic K&K match is not evidence on its own. Check volumes and series on the image at 300 dpi, since the text layer misreads them. Record a K&K misprint in the page-check note and spell the citation correctly. Boroch's supplement is not edited; its errors go in the notes.
- Page-check `image_status`: `found`, `corrected` (the note says why), `year_conflict`, and `quoted_in` (an unpublished source K&K prints as quoted in another book).
- Boroch sometimes lists one work under two codes. The page-check row names the K&K entry and the first Boroch ID; the note names the other.
- Publication type (`pub_type`: article, book, chapter, other) is decided per work in `data/kk-index-b-work-pub-type.csv` (work, pub_type, basis). Chapters are entries in edited volumes or reference works; numbered monograph series are books. Uncertain cases are coded `other` and the basis says so. The basis column is not released.
- `scripts/attach-work-pub-type-index-b.R` adds `pub_type` to the works table and the work vertices. It must run after every rebuild by `build-work-concept-network-index-b.R`, which overwrites that file. It changes no edge or weight.
- `scripts/pub-type-style.R` holds the shapes for the works CA and the work MST. Sub-element views have no type.
- Definition texts: `data/kkcc-definition-texts.csv` (Table 2 quotations by Boroch code), `kkcc-appendix-only-texts.csv`, and `kk-definition-texts-kk-only.csv` (codes Boroch does not quote: since 2026-10-30 only the D-III-4 page footnote; the Part III statement texts C-5, D-5, D-7 and E-17 were removed). `kk-definition-texts-kk-only.csv` is keyed by kk_code, never by author, because an author match can key several codes to one text.
- `scripts/check-definition-text-coverage.R` is read-only. It checks that every verified definition carries a text and each text attaches to a work. The documented exceptions (D-II-7, F-I-20) and the codes with no work are listed in the script and in PROVENANCE.
- MSTs (`scripts/analysis-mst-works-index-b.R`, `scripts/analysis-mst-definitions-index-b.R`) are Kruskal maximum spanning trees of the projections, with `mst()` on `-weight`. Node size is tree betweenness; color is the leading-eigenvector community. The code-level tree's works per code are in `data/kk-index-b-mst-definitions-tree-nodes.csv`. Heading MSTs (`scripts/analysis-mst-headings-index-b.R`) read the heading projections after `lcc_2core()`; see PROVENANCE section 11.
- Community partitions use `cluster_leading_eigen`, which starts from a random vector. Set the script's seed (`set.seed()` at the top) or the partition is not reproducible. Betweenness is deterministic.
- Figure subtitles must describe what the labels show. Titles name the network and the node type.

## Definition texts and rights

- The definition texts (`data/kkcc-definition-texts.csv`, `data/kkcc-appendix-only-texts.csv`, `data/kk-definition-texts-kk-only.csv`) and the Part II quotations in PROVENANCE are verbatim quotations of Boroch and K&K. They stay out of any release. The NMF term tables name single words, not quotations, and may be released.
- References in the Boroch bibliography (`kkcc-definition-biblio.csv`, `bib_ref`, `kkcc-supplement-bibliography.csv`) are public references and may be included (user decision).
- The release citation table gives Boroch's references and K&K match status only. K&K bibliography lines and page snippets stay out; whether they may be released has not been settled.
- The user regards the 1952 K&K monograph as publicly available online and treats K&K element labels as releasable. Boroch's article and its verbatim quotations remain restricted. Online availability does not by itself settle redistribution; flag this in any release note.
- Boroch's article is posted on PhilPapers (https://philpapers.org/archive/ROBAFC-5.pdf), but the assistant could not access that URL (HTTP 403), so its posting terms are unverified. The local copy (`documents/ROBAFC-5.1.pdf`, MD5 767c5c651a991d0de5c368afd4f0f7eb) has no license notice.
- Cite printed page numbers, not the unofficial scan copies.

## NMF analyses

- `scripts/nmf-core.R` holds the shared base-R NMF (Euclidean multiplicative updates, seeded and deterministic; W columns normalized to unit sum), an ARI helper (Hubert & Arabie) and `hard()`. Do not add an NMF package; the implementation is deliberate.
- The manuscript reports two analyses at k = 7, one factor per K&K group:
  - Structural: `scripts/analysis-nmf-works-index-b.R` factorizes the sub-elements × works matrix of the works 2-core.
  - Texts: `scripts/analysis-nmf-texts-index-b.R` factorizes a TF-IDF matrix of the definition quotations, one document per verified K&K code carrying a text (Table 2 via the crosswalk, appendix-only via the links, plus the K&K-only rows). The stopword list is hand-set in the script. Translations substitute for the non-English quotations (`data/kk-definition-texts-translations.csv`); the three assistant translations still need the user's check against the page images (TODO).
- k = 7 is fixed to match the taxonomy under test, not selected by the data: the objective has no elbow and restart stability is flat beyond k = 2. Do not reintroduce the removed k = 4 solution.
- Both analyses find chance-level agreement with A–G. Report that as the result; do not recreate agreement heatmaps (the `*-agreement.csv` cross-tabs are the record).
- Works-as-texts (`scripts/analysis-nmf-work-texts-index-b.R`) is WITHDRAWN from the manuscript (2026-10-29, PROVENANCE 15.7). Each work's document concatenates the texts of its codes, so it holds mostly other authors' statements inherited through citation. Authorship is nearly one-to-one, so a document built from a work's own statements reduces to the texts analysis. Its outputs (`data/kk-index-b-nmf-work-texts-*.csv`, `nmf-work-texts*.png`) are superseded records. Do not reintroduce it in the manuscript without the user's decision.
- Hardening the works factors: `scripts/analysis-mst-nmf-works-index-b.R` binarizes the works × factor loadings at a free threshold (0.10; a parameter, not data-selected), projects so ties count shared factors, and draws the Kruskal MST. Its community partition is reproducible only with the script's seed.
- Factor labels are hand-set `factor.labels` vectors in each analysis script; change them there only. The factor order follows the data and changed on 2026-10-30 when the Part III codes were removed, so check each factor's top terms against its label after every rebuild (both NMF scripts were reset that day). Labels describe top terms, not clean concepts, and on this corpus a factor can be driven by one author's phrasing. Key on the numeric `dominant` column, not the label; the loads tables carry `factor_label` for display.
- Outputs: `data/kk-index-b-nmf-works-*.csv`, `data/kk-index-b-nmf-texts-*.csv`, `data/kk-index-b-nmf-texts-tfidf.rds`; figures in `figures/kk-index-b/nmf/`. Heatmap row labels must be unique (`stopifnot(!anyDuplicated)`).
- Subgroup Sankeys (`scripts/figure-sankey-subgroups.R`) draw K&K's roman-numeral subgroups (letter plus numeral for C, D, F; A, B, E, G have none; bare C or D codes are Part III statements) against the factors. The works panel uses each work's plurality subgroup, with ties in a grey node; the codes panel uses each code's own subgroup. Ribbons take the origin group's color; grey marks ties. The Part III node is empty since 2026-10-30 (no verified bare C or D code). Cross-tabs: `data/kk-index-b-nmf-subgroup-{works,texts}-crosstab.csv`. They are in the manuscript appendix (`app:subgroup-sankey`). The appendix paragraphs after each Sankey quote cross-tab cells, per-factor shares and lifts, which are typed by hand. Recheck them whenever the cross-tabs change, and do not treat single-work or three-code cells as strong evidence.
- `scripts/figure-sankey-agreement.R` draws three pairwise Sankeys including the withdrawn works-as-texts analysis. It is not in the manuscript; the PNG is a record, not a current figure.

## Manuscript numbers (`kk-index-b-two-mode.tex`)

- Terms in the manuscript: "concepts" are sub-elements, "definitions" are K&K codes, and "works" are works. A definition is a code, not a scholar. A scholar can hold several codes, and some codes carry several authors, so do not write "N scholars' definitions". The disaggregated level is the work-by-code membership (a work listed under a code); a work can sit under several codes.
- Recheck procedure after any data or analysis change: copy `data/`, `scripts/`, `figures/` and `README.md` to a scratch copy (not `.git` or `documents/`). In the R session, `setwd()` to the copy and clear the global environment. Run the analysis scripts in fresh environments (`e <- new.env(); e$norm <- base::norm; sys.source(...)`), in the order of Rebuilding, then `analysis-mst-nmf-works-index-b.R` and `figure-sankey-subgroups.R`. Keep the printed output and restore the working directory afterwards.
- Compare the regenerated `data/` CSVs with the stored ones using `cmp`. A clean run reproduced the stored CSVs. Do not compare PNGs this way: tree layouts differ between runs even when the data are unchanged. Check figures by viewing them.
- Where each manuscript number comes from: the analysis scripts print the component counts and LCC sizes (`analysis-centrality-index-b.R`), the 2-core sizes (`analysis-ca-index-b.R`, `analysis-ca-works-index-b.R`), the tree node counts, and the NMF ARI, purity, tie counts and edge counts (`analysis-nmf-*-index-b.R`, `analysis-mst-nmf-works-index-b.R`). The appendix cross-tabs are in `data/kk-index-b-nmf-subgroup-{works,texts}-crosstab.csv`.
- Table 1 (network summary) is not produced by any script. Its values are: density = edges / (concepts × second-mode nodes); mean degree over each mode, including isolates; mean k_nn over the non-isolated nodes with `igraph::knn()`; degree correlation with `igraph::assortativity_degree(directed = FALSE)`. The knn values reproduced the earlier table exactly, so the method is the one to keep. `kk-index-b-network-stats.csv` gives only some of these.
- MST tables use Freeman normalization for a tree: raw `betweenness(normalized = FALSE)` divided by (N − 1)(N − 2)/2, with N the tree's vertex count. The code-level definitions tree matches this in its CSV. The concept-level definitions tree has no node CSV; take its betweenness from `st.concept` in `analysis-ca-index-b.R`. The works trees are in `data/kk-index-b-mst-works-nodes.csv`, and the NMF tree is in `data/kk-index-b-mst-nmf-works-nodes.csv`.
- Before listing a top-10 by betweenness, check for ties at the cutoff. On 2026-10-30 neither works tree had a tie at tenth place, and the definitions trees had none either. Recheck after any rebuild.
- The NMF threshold numbers (single-factor counts at 0.10 and 0.30) come from `data/kk-index-b-nmf-works-loads.csv`. Recompute them if the threshold or the loads change.
- Prose about tree layout, community colors and which region a node heads is not produced by any script. Check it against the figure. On 2026-10-30 the works concept tree, the works work tree and the NMF factor tree were checked against their figures. The definitions tree descriptions were last checked before 2026-10-30; their data have not changed since.
- Figure subtitles and `factor.labels` vectors hard-code counts and labels. Update them by hand when a count or factor order changes (the text-NMF subtitle carried a stale count until 2026-10-30).
- Compile check: copy the tex, `figures/`, `references.bib` and `library.bib` (`cp -L`, to dereference the symlink) to the scratch copy, then run pdflatex, bibtex, pdflatex twice there. The repo's compile artifacts stay as they are unless the user asks to rebuild them.
- The tex's uncommitted working copy has changes that are not in git. Check `git diff` before assuming a line is committed.

## Regex and text gotchas (R)

- Default regex is POSIX TRE. Inside a bracket class `\s` is a literal backslash and `s`; use `[[:space:]]`. `\s` and `\d` work outside brackets, or use `perl = TRUE`.
- `\\.` does not match a literal period in TRE; use `[.]` or `perl = TRUE`.
- `sub()` with a capture group drops the matched text; to extract a leading token, append `.*$`.
- `grepl()` with a vector of patterns uses only the first pattern.
- `R` recycles vectors column-wise: `A * colSums(A)` misaligns. Use `t(A) %*% rowSums(A)` or `rep(..., each = nrow(A))`.
- `lapply`/`vapply` over a matrix iterate over its underlying vector, not its columns. For pairwise work use `combn(n, 2, simplify = FALSE)`.
- `sweep(X, MARGIN, STATS)`: for a k × n matrix scaled per row, MARGIN is 1. Getting it wrong warns "STATS does not recycle exactly across MARGIN" and silently misaligns.
- `x[idx]` with a named character vector names the result from the SOURCE vector's names at the matched positions, not from `idx`. Indexing a palette by a key vector loses the keys; use `setNames(palette[key], key)`.
- `unique()` drops names. Build lookups from `unique(df[, c(key, value)])`.
- ggplot2 4.0.3 is installed. `facetted_pos_scales()` is gone; for per-panel x ticks, use a breaks function on `scale_x_continuous()`.

## Plots and analysis conventions

- Base pipe `|>`; ggplot2; `ggsave(bg = "white")` with theme_void or theme_minimal.
- Put comments above pipeline lines, not after them. Keep code comments brief.
- Avoid colons excessively in prose. Use American spelling (color, center, behavior), including in figure captions.
- Analysis that feeds a claim needs its counts and a stated basis; the report should cite the current network, not an earlier one.
- Node labels are unique within a plot. Code nodes carry the K&K code, work nodes the work label, sub-element nodes the element name. Do not label a code with the works it holds.
- A definition group is the first letter of the code (A–G). Draw it with the ggstar symbols in `scripts/kk-group-style.R` wherever groups appear, so one symbol means one group across figures.
- Where labels must stay readable together (the definitions CA), put them in one `geom_label_repel` layer; CA labels use a white fill.
- Sankey labels (ggsankeyfier): compute them on the FULL layer data, never on a subset of one stage, because a subset makes ggsankeyfier re-stack the nodes and the labels drift off their rectangles. Use `geom_text(stat = "sankeynode")` with blank labels on the other stage, and a nudged position. `geom_text_repel` with `direction = "y"` also drifts labels off nodes. Check label y against node midpoints after `ggplot_build()`; the label's x carries its nudge, so compare x with a tolerance.
- Sankey construction (ggsankeyfier): it requires one edge per node pair, so build the long format from the aggregated transition tables. `position_sankey()` stacks the first level at the bottom, so reverse the factor levels to put the first level on top. `write.csv` writes `NA` as the literal "NA", so a merged group column must treat both `""` and `NA` as ties.

## Environment

- renv: R 4.5.3, PPM binaries. Do not run `renv::snapshot()` blindly; it records every package the dependency scan finds, which once added many unrelated packages. Record specific packages with `renv::record("pkg@version")`, then check `git diff renv.lock` shows only the intended additions. Restart the R session to activate renv.
- `renv.lock` currently matches HEAD.
- Installed and recorded: `ggstar`, `ggsankeyfier` (with `gridBezier` and `vwline`), `gridExtra`. `gdtools` builds from source and needs the system cairo headers (`libcairo2-dev`, `libfontconfig1-dev`, `libfreetype-dev`).

## Release and publication

- The release is `release/two-mode-network-data/`. The version and history live in its `CHANGELOG.md`, which is the source of truth; this file does not record versions. Contents: three `.rds` files (the four stored networks; the full works file keeps the work table), `kk-index-b-work-citations.csv`, `MANIFEST.md` and `CHANGELOG.md`. The Boroch two-mode networks (`kkcc_two_mode*.rds`) are not in the release unless the user changes that.
- Versioning: a minor bump for added data or changed network contents; a patch for fixes that leave the structure alone. Each change goes in `CHANGELOG.md` with its version and date. Refresh the `.rds` files from `data/` when the data changes, and update the dimensions in `MANIFEST.md`. The citation file keeps core columns only: take the release's header columns from `data/kk-index-b-work-citations.csv`. Copy the three `.rds` files from `data/` unchanged (they are the release's network objects).
- The site is served from the `gh-pages` branch of `origin` (`olizardo/definitions-of-culture-two-mode`). Its source is the `site-source` branch, an orphan branch holding the pages, `_quarto.yml`, `data/` and `.github/workflows/publish.yml`. Edit the site on `site-source`, never on `gh-pages` directly.
- A push to `site-source` runs `.github/workflows/publish.yml`: it renders the site with Quarto, replaces the contents of `gh-pages` with `_site/` and `data/`, and pushes one fast-forward commit as `github-actions[bot]`. Pushing publishes the site, so it needs the user's approval. Never force-push. Do not push `main` as part of a site update. Nothing publishes from `main`.
- Manual fallback, if the workflow is unavailable: clone `gh-pages` into a scratch directory, replace its contents with the rendered site, copy `data/` and `.nojekyll`, commit, and push as a fast-forward.
- Split works files (`data/kk-index-b-works-*-network.rds`) are made by hand from the full works file (graph only) and committed to `data/` on `site-source`. Refresh them when the works data change.
- The site changelog follows the release CHANGELOG but omits references to PROVENANCE and TODO, which readers cannot open. Keep the two in step when the version changes.
- The local project `~/projects/ACADEMICS/kkcc-two-mode-data/` is a stale copy with no git remote. Do not edit it for site changes.
- `main` has uncommitted work (see TODO) and is not part of the publication. Its recent commit messages are placeholders, so refer to commits by hash, not message.
- Publication history lives in the CHANGELOG and PROVENANCE, not here.
