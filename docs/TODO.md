# Handoff: K&K Index A/B dataset

Last updated 2026-10-24 (latest status update below). Read `AGENTS.md` (project memory) and `docs/PROVENANCE.md` first.

## Current state (2026-10-24, final for this session)

- Index B: 1318 edges. Flags: ok 978, ocr_corrected 207, manual_fix 125, code_not_in_index_a 8 (6 codes). Counts rechecked 2026-10-25 after C-I-18a, D-II-16 and E-17 were added to the verified network. Full networks (all 172 codes, including the 4 excluded): sub-element 472 x 172 (1193 ties); heading 53 x 172 (1084 ties). Verified networks used by the analyses: sub-element 472 x 165 (1193 edges); heading 53 x 170 (1084 edges; codes with no Index B edges drop out; from `data/kk-index-b-network-stats.csv`). Excluded codes: none. Two printed-code errors were remapped on 2026-10-25: F-9 to E-9 (main-text footnote 9, Turney-High 1949: 5) and F-4 to F-I-4 (footnote 4, Winston 1933: 209; Index A lists Winston as F-I-4). D-II-16 (footnote 16, Aberle et al. 1950: 102) and E-17 (footnote 17, Taylor 1950: 559-60; weaker basis, commentary rather than a definition) were added 2026-10-25. Block check: 1293 in printed block, 25 in another block. The two extra flags are the remaps: the printed block lists F-9 and F-4, not E-9 and F-I-4. Not yet reviewed on the page image beyond the citations.
- Unresolved tokens: 2 (`D-I` society, `F-j` organized), excluded as duplicates by decision.
- User-confirmed readings (not image-checked in this session): F-IV-3, A-15 (all edges), B-15, D-II-15, D-I-5 under learned behavior, C-I-13, F-II-5, A-5, F-I-13, B-21 under group. F-I-15 under transmission is correct and unchanged.
- Open items:
  1. Audit the remaining general-rule tokens in the 207 ocr_corrected edges (most common: A-i, D-I-i, B-i, C-I-i, D-IV-i, E-i, D-I-y). Group by printed block and check each block on the page image.
  2. ~~Review the 22 block-check flags~~ Done 2026-10-25. Reviewed on the page image (`data/kk-index-b-block-check-review-current.csv`): 21 OK, and 1 block OK with the code unreadable (F-IV-3 under processes and means). The F-IV-3 reading was checked by the user on 2026-10-25 (their check, not an image reading recorded here), so the second-reader need for F-IV-3 is closed. The PDF text-layer check (column `text_layer_check`) does not confirm any of the 22: it garbles 14 codes and 7 headings (e.g. "F -lV -5", "A -3, A -3"), so it cannot serve as an independent reader. Verdicts still rest on one image reader.
  3. Image-check the OK_TEXT blocks on printed pp. 76-81.
  4. Second reader for the user-confirmed readings and the manual fixes they came from.
  5. Partly resolved: C-I-13, D-I-1 and F-III-3 match your list, and F-IV-j has no edge. The verdict file still has one NEEDS_CHECK row (carriers of culture, "a people, adjustments"; edge code not decided). See item 20.
  6. The verified network now excludes no codes (`data/kk-index-b-excluded-codes.csv` is empty). Codes that are not in Index A are kept on a recorded basis (`data/kk-index-b-verified-extra-codes.csv`: C-I-18a, D-II-16, E-17) or on Part III (D-5, D-7).
- Rights: K&K element labels are cleared by the user (the 1952 monograph is publicly available online). Boroch's article and its verbatim quotations remain restricted.
- Working tree (checked 2026-10-25): `git status` lists 56 changed or untracked entries, including modified scripts, data, figures and docs, and deleted figures and `kkcc-two-mode.qmd`. Review these before committing.

## Status update (2026-10-24, latest)

- Applied the two CODE_WRONG rows (motor reactions A-1 → A-17; "culture is that which is useful" D-I-13 → D-I-15) as `set` rows; both confirmed on the page image in the verdict file.
- Applied two user readings (not image-checked in this session): the "means of adjustment" token `F-I\` → F-IV-3 (printed "means of adjustment, D-I-17; F-IV-3"), and the totality-block "accumulated treasury" token `A-i5` → A-15 (this reverses the earlier duplicate decision; the social-heritage copy A-15, B-13, F-I-15 stays).
- Current build: 1318 edges; sub-element network 472 x 174 (1193 ties); heading network 53 x 174 (1085 ties). Block check: 1296 edges in their printed block, 22 in another block. Unresolved tokens: 2 (`D-I` society, `F-j` organized; both excluded as duplicates by decision).
- The A-20 "adjust" edge was traced: it is correct, and the block-check flag is a checker limitation (the text layer reads the code as `\-2o`).

## Status update (2026-10-24, later session)

- Commits: `f99c209` (parser: entry-start fixes; `is_entry_start` no longer treats a code dash as a
  heading dash, and "(see" only starts an entry when no code precedes it) and `0cd27c8` (occurrence
  key in `apply_index_b_fixes()`, keyed decisions, missing rows, rebuilt outputs, verdict file).
- Counts (superseded by Current state): Index B 1316 edges; sub-element network 472 x 174 (1192 ties); heading network 53 x 174
  (1084 ties). Validators pass. Block check: 21 edges printed in another block (mostly checker
  artifacts; see item 14).
- Applied: the three NEEDS_DECISION items (organized E-5 and totality A-15 unresolved as duplicates;
  B-1, B-6, B-7 relabelled to social heritage; B-11 added under social heritage).
- The 36 MISSING_EDGE rows from the sub-element check were reported resolved (2026-10-24), and the verdict file's 27 leftover MISSING_EDGE rows are now OK (2026-10-25; see item 14): 18 by the parser fixes, the rest
  by keyed manual fixes or missing rows (A-5, A-2, B-14, C-I-3, D-II-5, B-17, B-11, E-7, B-22, D-I-6).
  Remaining open tokens are listed in item 4 and item 20.
- Not yet applied: the two CODE_WRONG rows in the verdict file (see item 20).

## Current state

- Index A: 187 rows, 186 resolved, 165 codes. Every row on printed pp. 73-74 was read against
  the page image (200 dpi; disputed lines at 300 dpi). Sears's `C-I-Addendum` is an addendum linked to a specialty code and is not a network code (user decision 2026-10-25); it is not assigned and stays out of the network.
- Index B: 1318 edges. Flags: ok 978, ocr_corrected 207, manual_fix 125, code_not_in_index_a 8 (6 codes), as rechecked 2026-10-25. 2 unresolved tokens (`D-I` society and `F-j` organized, both excluded as duplicates by decision; see `data/kk-index-b-unresolved.csv`). The CODE_WRONG fixes, F-IV-3 and A-15 are described in the latest status update above and in PROVENANCE 3.9.
- Crosswalk (`data/kk-boroch-crosswalk.csv`, 135 rows): 126 auto, 8 hand decisions (D3-1, D2-16,
  A16, A17, A20, C1-11, B5, D2-7), 0 ambiguous, 0 unmatched, 1 F4-6 slip (resolved in PROVENANCE section 5).
- Committed (2026-10-24): the reorganization (`1c026b5`), Phase 0 notes (`42ab463`), the Index B
  script work and audit files, the B-11→B-21 fix and regenerated outputs (`2997ec2`), the finalized
  block-check verdicts (`347c431`), the ok-sample check and documentation updates (`203a743`). The
  working tree was clean after these commits, but it is not clean as of 2026-10-25 (see Current state).
- The untracked copy of a full book text, `documents/papersofpeabodymvol47no1peab_djvu.txt`, is
  now in `documents/` and gitignored. Do not commit or release it.

## Rebuild

Order: `scripts/build-index-b.R` → `scripts/build-index-b-crosswalk.R` → `scripts/analysis-index-b.R`,
then `scripts/build-index-b-networks.R` and the validators `scripts/check-index-b-networks.R` and
`scripts/check-index-b-blocks.R` (and `scripts/analysis-ca-index-b.R` for the CA).
Run them from the project root in a clean session, with `source(..., local = new.env())`.
The crosswalk must read its inputs from files; a stale session object once produced wrong outputs. After any change, check the
manual-fix keys: the build errors if a key matches no token.

## Tools and sources

- Page images: `pdftoppm -r 300 -f N -l N -x X -y Y -W W -H H -png documents/Kroeber-kluckhohn.pdf out`.
  Get coordinates from `pdftotext -bbox`, which reports points at 72/inch. Multiply by 300/72.
  `bc` is not installed; use Python.
- OCR: `tesseract` 5 (eng) is installed.
- Second scan, public: Internet Archive item `culturecriticalr0000kroe_z3a4` (Peabody Papers vol.
  47 no. 1, 1952). It has a Scribe-OCR text PDF (252 pp.; Index A is PDF pp. 89-90, Index B
  starts on PDF p. 90) and a `_djvu.txt` (882 KB). Download with `curl -L` (the text URL
  redirects). Use `https://archive.org/download/culturecriticalr0000kroe_z3a4/<file>`. The
  scratch copies may be gone, so re-download if needed.
- Restricted: `culture0000unse` (1952 Vintage edition). Its text returns HTTP 401. Do not use.
- Rights: the Archive copies are the same 1952 monograph. Do not commit them or release their text.
  Cite printed page numbers.

## Next steps, in priority order

1. **Second-scan cross-check (code tokens done).** The 10 code_not_in_index_a edges and 33 junk_name
   edges were checked against the second scan's text layer and our scan's page images. Results are
   in `data/kk-index-b-second-scan-check.csv`: all 10 code-not edges and all 33 junk codes are printed
   where the edges say. The second scan's left column is clipped at the scan edge, so use it only as
   a lead. The junk sub-element names remain open (item 5). Index A cross-check: tesseract agreed with every corrected row checked, so it's a useful
   lead, not proof. The Index A comparison from the other copy (`papersofpeabodymvol47no1peab`)
   was noisy; it misattributed continuation lines and misread digits.
2. **Check the 50-row sample: done 2026-10-24.** All 50 rows in `data/kk-index-b-ok-sample.csv`
   were read against the page images (PDF pp. 77-81, quadrant crops at 300 dpi). Verdict: 50 OK,
   0 errors. Clopper-Pearson 95% upper bound on the error rate is 7.1% (rule of three: 6%), so a
   larger sample is not forced by this result. Caveats: single reader; the sample's `heading` and
   two `sub_element` values are pre-correction (stale); verdicts were checked against the CURRENT
   edges, where the heading corrections (capabilities, history, civilization → common or shared
   patterns) apply — the printed block always matched the current edge. Notes recorded per row in
   the sample file.
3. **Heading attribution: done 2026-10-24** (items 13 and 16). `E-5` under "v-i" is a `group reference`
   entry printed under "society" (`data/kk-index-b-ocr-audit.csv`, `OK_HEADING_WRONG`); this is
   not covered by the block rules and has not been re-checked.
4. **Unresolved tokens: 2 left (2026-10-24, latest)** (`data/kk-index-b-unresolved.csv`: "society D-I" and "organized F-j"). Both are excluded as duplicates by decision. `F-I\` (means of adjustment) is now F-IV-3, and `A-i5` (accumulated treasury) is now A-15, both from the user's readings; they are not image-checked in this session. Earlier six page-image resolutions (`A-q`, `F-i`, `F-U`, `F-I-i}`, `F-H-j`, `A-j`) are unchanged; `F-U`, `F-I-i}`, `F-H-j` and `A-j` rest on printed sequence plus the candidate's absence. A second reader should check all of these.
5. **Junk sub-element names: done 2026-10-24** (decisions in `data/kk-index-b-junk-decisions.csv`; PROVENANCE 3.6;
   the six single-letter `manual_fix` names were also mapped). Original note: 33 edges, `parse_flag = junk_name`. Every code is confirmed in its
   printed block: customs (9 codes, printed p. 75), capabilities / "a people" (6, p. 75), the social
   entry under group reference (11, p. 77), patterns (1, p. 77), social heritage (2, p. 77), and
   ways and life-ways (4, p. 78). Decide each case: map to the printed sub-element, or drop from the
   sub-element matrix and keep the edge in the heading matrix. Record the decision in
   `docs/PROVENANCE.md`. The printed blocks should settle most of them.
6. **Open crosswalk rows: done (2026-10-24).** A16 → A-14, A17 → A-15, A20 → A-18, C1-11 → C-I-10,
   B5 → B-4a (PROVENANCE 3.2). Appendix-only: A21 → A-19, C1-12 → C-I-11, C1-13 → C-I-12
   (`data/kkcc-appendix-only-links.csv`). Index A prints Myres as "(1929)" for B-4a, while the Part II
   entry reads 1927. The original book is dated 1927 (Google Books record), so 1927 is the year used; the Index A discrepancy is recorded in PROVENANCE 3.2.
7. **Eight code_not_in_index_a edges (six codes).** All of them are printed where the edges say (page image, our
   scan, 200 dpi). `C-7`, `D-8`, `F-9` were verified at 300 dpi earlier. `D-7`, `D-5`, `F-4`, `E-17`
   were verified at 200 dpi on 2026-10-24, not at 300 dpi. Heading errors are noted in item 3.
   `D-II-16` (`socially transmitted behavior`) has no Index A row. It is in the verified network on K&K footnote 16 (Aberle et al. 1950: 102; 2026-10-25), and a crosswalk decision maps Boroch's D2-16 to it. Do not remap any code without a page-image basis.
   Correction (2026-10-25): `C-7` and `D-8` are not network codes. Manual `set` rows remap them to `C-I-7` and `E-8` (main-text footnotes; PROVENANCE). `D-5` and `D-7` are in the verified network because they are Part III codes (`in_part_iii`), not Index A codes. The user lists `D-5` and `D-7` as verified (2026-10-25, user confirmation, not a new page check). The 2026-10-25 Index A check (Current state) found no Index A row for them.
   Also: the `socially transmined` sub-element is corrected to `socially transmitted` for D-II-14,
   D-II-16, F-I-19 and F-II-10 (manual-fix `rename_sub` rows, applied by `build-index-b.R`).
8. **Rights (partly decided 2026-10-24).** The user regards the 1952 K&K monograph as publicly available online and does not see the K&K element labels as a rights barrier (README, Rights). Boroch's article and its verbatim quotations are still restricted.
   `data/kkcc-definition-texts.csv` holds verbatim Boroch quotations and must stay out of any
   release.
9. **Git: done 2026-10-24.** The pending work is committed in logical units: the earlier script and
   audit-file commits; the B-11→B-21 fix with regenerated outputs (`2997ec2`); the finalized
   block-check review sheet (`347c431`); the ok-sample verdicts and README/PROVENANCE/TODO/AGENTS
   updates (`203a743`). The Archive text in `documents/` is gitignored and stays out. Earlier commits:
   `1c026b5` (reorganization), `42ab463` (Phase 0 notes), `e007b5a`, `7533002`, `e866111`, `f78bece`.
12. **Downstream rerun: done 2026-10-24.** `scripts/analysis-index-b.R` was rerun after the heading correction
    (network stats and the degree-comparison figure regenerated).
    Rerun 2026-10-25 after the "passed down (or on)" label change: `analysis-index-b.R`, `build-work-concept-network-index-b.R`, `analysis-ca-index-b.R`, `analysis-ca-works-index-b.R`, `analysis-centrality-index-b.R`, `analysis-mst-definitions-index-b.R`, `analysis-mst-works-index-b.R`. Every changed CSV differs from HEAD only in the label, so the numbers, CA signs and centrality values are unchanged. The Boroch main-network scripts were not rerun (no Index B input). The PNG figures were regenerated but were not compared pixel by pixel.
    The crosswalk was rerun and is unchanged. Current counts (2026-10-25, after the Young year change): 126 auto, 8 manual decisions, 1 F4-6 slip, 0 ambiguous, 0 unmatched.
10. **Documentation** to keep current: `README.md` (data dictionary, limitations),
    `docs/PROVENANCE.md` (sections 3.1, 3.2, 8), and the "K&K Index A/B dataset" section of
    `AGENTS.md`. Update only current-state text; leave the historical notes alone.
11. **Verification after any change.** The build runs without errors. Every manual-fix key matches a
    token. Edge counts and parse-flag counts change only as expected. Spot-check each new manual
    fix against the page image at 300 dpi and record it in `data/kk-index-b-zoom-check.csv` or
    `data/kk-index-b-ocr-audit.csv`.

13. **Heading corrections: done 2026-10-24** (rules in `apply_heading_corrections()`; PROVENANCE 3.5).
    Original notes: `data/kk-index-b-block-map.csv` lists the 53 printed
    blocks on PDF pp. 77–81 (printed pp. 74–78). Edges under the wrong heading, checked on the page
    images: `capabilities` (73) → carriers of culture; `history` (50) → ideas and cognitive processes;
    `civilization` (36 of 41) → common or shared patterns (includes "attitudinal relationship", which
    is also printed under attitudes and feelings, so the count is approximate); `symbols` (12 of 26) →
    systems (systems-systems, systems of thought, systems of knowledge); `feelings` (1) → forbidden, the;
    `people, a` (1) → permitted, the. Apply as a rule in `build-index-b.R`, not in the output CSVs.
14. **Sub-element check for the remaining edges (in progress, 2026-10-24 later).** Verdict file: `data/kk-index-b-subelement-check.csv` (1327 rows against the 1318-edge build; the row-to-edge mapping is not reconciled). Current verdict tally (2026-10-25): OK 572, OK_IMAGE 297, OK_TEXT 440, FIXED_REBUILD 10, APPLIED 6, NEEDS_CHECK 2; no MISSING_EDGE, CODE_WRONG or NEEDS_DECISION rows remain. The 27 former MISSING_EDGE rows (23 unique edges) were checked against the build on 2026-10-25: each printed heading and sub-element has a build edge under the same code. The build wrote "passed down" for the printed "passed down (or on)", so six rows matched only after that label was normalized. Six `rename_sub` rows (`data/kk-index-b-manual-fixes.csv`, 2026-10-25) now set the build label to "passed down (or on)"; the rebuild changed only those six sub-element labels, and the validators pass. They are now OK, with the verdict and note recorded in the file (the original note is kept). The verdicts changed are only the 27 MISSING_EDGE rows; no other column changed. Blocks on printed pp. 74-78 are covered: pp. 74-75 and most of 76-78 are text-layer diffs; the large blocks (ideas, processes, learning, products, manners, symbols, the transmission and social blocks) were checked on the page image. Still OK_TEXT (not image-checked): most of habits, material culture, modes, the rest of symbols, and blocks on pp. 79-81 beyond those listed. Original note: About 1100 edges are not yet checked against the
    printed sub-element lists. Record verdicts in a file keyed to printed page and block.
15. **Second reader (partly done; human reader still open).** A machine cross-check (`scripts/check-index-b-blocks.R`,
    PROVENANCE 3.7) was run on the earlier 1285-edge build (1268 in block). On the current 1318-edge build it puts 1296 in their block and 22 elsewhere. The earlier 17 flagged edges are in
    `data/kk-index-b-block-check-review.csv` with verdicts (2026-10-24): 17 OK, 1 CODE_WRONG (18 rows). None of its keys match the 22 current flags; those 22 were reviewed on the page image on 2026-10-25 (see `data/kk-index-b-block-check-review-current.csv`).
    (B-11 under process, fixed; see item 18). It is not a human reader.
    Original note: The block map and the heading corrections have one reader. A second reader
    should check the civilization and symbols cases and a sample of the other blocks.
16. **Rebuild and recount: done 2026-10-24.** 174 parsed rows re-headed (173 distinct edges; G-3 is printed twice
    in one block). (Superseded: the build is now 1318 edges.) The 1285-edge total was unchanged at that point. Heading matrix 53 × 174, 1059 ties then; sub-element matrix
    465 × 174, 1171 ties after the label fixes (`systems` is shared by two blocks with identical codes).
18. **Regenerate the CHECK crops: done 2026-10-24.** The old locator was not repaired; instead the
    affected entries were read from full-page quadrant crops (300 dpi) plus targeted 400–600 dpi
    zooms. Verdicts in `data/kk-index-b-block-check-review.csv` are final: 17 OK, 1 CODE_WRONG (18 rows).
    The CODE_WRONG row is `B-11 / processes and means / process`: the print reads
    "process, B-21, B-22, D-I-6, F-I-16" and B-11 prints nowhere in the block. Fixed by a `set`
    row (B-11 → B-21, key on the parsed heading "process ts and means") in
    `data/kk-index-b-manual-fixes.csv`; the pipeline was rebuilt (edge total unchanged at 1285).
    Also amended: the D-I-15 `material culture / artificial` evidence overstated the read —
    the numeral sits under an ink blot (600 dpi, unreadable); the edge is kept with the stated
    basis (blot spans one character width; D-I-15 is the single-numeral candidate in Index A).
19. **Text-proposed labels.** Seven garbled labels were fixed from the text layer and the Archive OCR, not the scan:
    distorted satisfaction, integrated and unintegrated groups, non-physiological products, not created,
    reaction-formations, constitutional changes, categories of actions. Check each on the scan crop.
17. **Memory correction: done 2026-10-24.** AGENTS.md lists "social" and "society" under group reference as heading
    errors. The page image shows both are printed in the group reference block, so drop that note.
    The "social group", "social groupings" and "socially" entries are printed in both group reference
    and social, so they are duplicates in print, not parser errors.

## Known gaps and cautions

- Index A's verification is a single-reader check. There's no double-keying. Do not describe the
  dataset as fully verified.
- 930 ok edges have no row in `kk-index-b-flagged-audit.csv` (978 ok edges minus 48 matched by kk_code, sub_element and ocr_raw; the match is approximate). `kk-index-b-audit.csv` is a Boroch/K&K cell audit, not an edge audit, so it does not cover these edges.
  The earlier figure of 932 could not be reproduced. The 50-row sample was checked on 2026-10-24
  (50 OK, 0 errors). Of the 123
  manual_fix edges, 120 have no row in `kk-index-b-flagged-audit.csv`, the only audit file keyed to edges (2026-10-25 count; PROVENANCE 3.3 still has the older figure). The six 2026-10-24
  resolutions and the other 56 manual fixes are justified by printed evidence in the manual-fix
  file, not by an audit verdict.
- Angyal's row (B-14) is from the page image. It is absent from the project's OCR text, and the
  second scan's tesseract output for PDF p. 89 doesn't include it (page 88 probably has it, not
  checked).
- Element labels: the garbled ones are fixed (PROVENANCE 3.6); the seven text-proposed label fixes were
  checked on the scan on 2026-10-24 — six confirmed, one wrong ("constitutional changes" → the print
  reads "constitutional charters", corrected and rebuilt). Other labels are unverified against the page image.
- The 39 appendix-only Boroch codes (PROVENANCE section 4) are not in `kkcc-definition-years.csv`,
  which covers only the 135 Table 2 codes, so the crosswalk does not link them. Several have
  matching K&K Index A rows (for example D-I-10 Ford 1942, F-I-1a Willey 1927b, E-4 Redfield,
  A-20 Thurnwald 1950) that were not linked. Linking them would be a new decision, not a fix.

20. **Open after the 2026-10-24 latest session.**
    - DONE: the two CODE_WRONG rows (A-1 → A-17; D-I-13 → D-I-15).
    - DONE: the A-20 "adjust" edge was traced. It is correct; the block-check flag is a checker artifact (OCR form `\-2o`).
    - DONE (user reading): accumulated treasury A-15 and means of adjustment F-IV-3. Need a second reader.
    - Open: the NEEDS_CHECK "a people" tokens (C-I-1 j, D-I-i, F-III-j, F-IV-j) are not in the edge list and are not image-checked.
    - Open: image-check the OK_TEXT blocks on printed pp. 76-78 and the blocks on pp. 79-81 that are still text-layer only.
    - Positional fixes need the occurrence column; use it for any further duplicate-token fix.
    - Housekeeping: `git status` lists 56 changed or untracked entries (2026-10-25; see Current state). `Rplots.pdf` and `data/kk-index-b-missing-rows-DRAFT.csv` are tracked and unchanged, not untracked as this line said. The DRAFT is superseded by `kk-index-b-missing-rows.csv`.
