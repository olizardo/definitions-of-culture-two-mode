# Handoff: K&K Index A/B dataset

Last updated 2026-10-24. Read `AGENTS.md` (project memory) and `docs/PROVENANCE.md` first.

## Current state

- Index A: 187 rows, 186 resolved, 165 codes. Every row on printed pp. 73-74 was read against
  the page image (200 dpi; disputed lines at 300 dpi). Sears's `C-I-Addendum` stays unresolved.
- Index B: 1285 edges. Flags: ok 966, ocr_corrected 210, manual_fix 66, junk_name 33,
  code_not_in_index_a 10. 2 unresolved tokens (`D-I` excluded as a duplicate; `F-I\` smudged;
  see `data/kk-index-b-unresolved.csv`). Six tokens resolved 2026-10-24 (manual-fix file).
- Crosswalk (`data/kk-boroch-crosswalk.csv`, 135 rows): 127 auto, 2 hand decisions (D3-1, D2-16),
  4 ambiguous and 1 unmatched (open), 1 F4-6 slip (resolved in PROVENANCE section 5).
- Committed: the 2026-10-24 reorganization (`1c026b5`: scripts in `scripts/`, PDFs and Archive text
  in `documents/`, stale files deleted, `build-definition-texts.R` parse fix) and the Phase 0 notes
  (`42ab463`).
- 2026-10-24 (later): heading corrections applied in `build-index-b.R` (`apply_heading_corrections()`,
  PROVENANCE 3.5). Crosswalk, networks, `analysis-index-b.R` and the audit files were rerun, so the data/
  outputs changed (see the git diff). Nothing is committed.
- Uncommitted (check `git status`): `scripts/build-index-b.R` (sub-element rename support),
  `data/kk-index-b-manual-fixes.csv` (six new resolutions, four renames, `new_sub_element` column),
  the regenerated Index B outputs in `data/`, this file, and the new untracked
  `data/kk-index-b-second-scan-check.csv`.
- The untracked copy of a full book text, `documents/papersofpeabodymvol47no1peab_djvu.txt`, is
  now in `documents/` and gitignored. Do not commit or release it.

## Rebuild

Order: `scripts/build-index-b.R` → `scripts/build-index-b-crosswalk.R` → `scripts/analysis-index-b.R`.
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
2. **Check the 50-row sample.** Fill `verdict` and `printed_page` in
   `data/kk-index-b-ok-sample.csv` (seed 4817, drawn from the 966 ok edges). Report the error rate
   with its uncertainty. A larger sample is needed if the rate is above about 5%.
3. **Heading attribution: done 2026-10-24** (items 13 and 16). `E-5` under "v-i" is a `group reference`
   entry printed under "society" (`data/kk-index-b-ocr-audit.csv`, `OK_HEADING_WRONG`); this is
   not covered by the block rules and has not been re-checked.
4. **Unresolved tokens: 2 left** (`data/kk-index-b-unresolved.csv`). Six were resolved on page
   images and recorded in the manual-fix file: `A-q` → A-9, `F-i` → F-I-6, `F-U` → B-21,
   `F-I-i}` → F-I-13, `F-H-j` → F-II-5, `A-j` → A-5. Of these, `F-U`, `F-I-i}`, `F-H-j` and `A-j`
   rest on the printed sequence and on the candidate's absence from the edges, not a clean read of
   the OCR glyph. `F-U` was assigned by elimination. A second reader should check those four.
   `D-I` (society) is excluded as a duplicate: D-I-12 and D-I-13 are both printed and both already
   edges. `F-I\` (means of adjustment) is unreadable behind a smudge after "F-I-" (PDF p. 80, printed
   p. 77). Leave it unresolved unless a better scan appears.
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
7. **Ten code_not_in_index_a edges.** All ten are printed where the edges say (page image, our
   scan, 200 dpi). `C-7`, `D-8`, `F-9` were verified at 300 dpi earlier. `D-7`, `D-5`, `F-4`, `E-17`
   were verified at 200 dpi on 2026-10-24, not at 300 dpi. Heading errors are noted in item 3.
   `D-II-16` (`socially transmitted behavior`) has no Index A row, but a crosswalk decision maps
   Boroch's D2-16 to it. Do not remap any code without a page-image basis.
   Also: the `socially transmined` sub-element is corrected to `socially transmitted` for D-II-14,
   D-II-16, F-I-19 and F-II-10 (manual-fix `rename_sub` rows, applied by `build-index-b.R`).
8. **Rights (user decision).** Whether K&K Index B element labels can ship is undecided.
   `data/kkcc-definition-texts.csv` holds verbatim Boroch quotations and must stay out of any
   release.
9. **Git.** Commit the pending work in logical units: (a) `scripts/build-index-b.R` (rename support);
   (b) the manual-fix file and the regenerated Index B outputs; (c) the second-scan check file;
   (d) this TODO. The Archive text in `documents/` is gitignored and stays out. Earlier commits:
   `1c026b5` (reorganization), `42ab463` (Phase 0 notes), `e007b5a`, `7533002`, `e866111`, `f78bece`.
12. **Downstream rerun: done 2026-10-24.** `scripts/analysis-index-b.R` was rerun after the heading correction
    (network stats and the degree-comparison figure regenerated).
    The crosswalk was rerun and is unchanged (127 auto, 2 manual, 1 F4-6, 1 no match, 4 ambiguous).
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
14. **Sub-element check for the remaining edges.** About 1100 edges are not yet checked against the
    printed sub-element lists. Record verdicts in a file keyed to printed page and block.
15. **Second reader (partly done; human reader still open).** A machine cross-check (`scripts/check-index-b-blocks.R`,
    PROVENANCE 3.7) puts 1268 of 1285 edges in their assigned block. The 17 others are in
    `data/kk-index-b-block-check-review.csv` and need a page-image check. Crops are in the scratch directory `crops/`, not the repo. It is not a human reader.
    Original note: The block map and the heading corrections have one reader. A second reader
    should check the civilization and symbols cases and a sample of the other blocks.
16. **Rebuild and recount: done 2026-10-24.** 174 parsed rows re-headed (173 distinct edges; G-3 is printed twice
    in one block). The 1285-edge total is unchanged. Heading matrix 53 × 174, 1059 ties; sub-element matrix
    471 × 174, 1183 ties (`systems` now shared by two blocks with identical codes).
17. **Memory correction: done 2026-10-24.** AGENTS.md lists "social" and "society" under group reference as heading
    errors. The page image shows both are printed in the group reference block, so drop that note.
    The "social group", "social groupings" and "socially" entries are printed in both group reference
    and social, so they are duplicates in print, not parser errors.

## Known gaps and cautions

- Index A's verification is a single-reader check. There's no double-keying. Do not describe the
  dataset as fully verified.
- 915 ok edges have no audit verdict (966 ok minus 51 with a row in `kk-index-b-flagged-audit.csv`).
  The earlier figure of 932 could not be reproduced. Only the 50-row sample is pending. Of the 66
  manual_fix edges, 62 have no row in either audit file (PROVENANCE 3.3). The six 2026-10-24
  resolutions and the other 56 manual fixes are justified by printed evidence in the manual-fix
  file, not by an audit verdict.
- Angyal's row (B-14) is from the page image. It is absent from the project's OCR text, and the
  second scan's tesseract output for PDF p. 89 doesn't include it (page 88 probably has it, not
  checked).
- Element labels are unverified against the page image and may contain residual OCR damage.
- The 39 appendix-only Boroch codes (PROVENANCE section 4) are not in `kkcc-definition-years.csv`,
  which covers only the 135 Table 2 codes, so the crosswalk does not link them. Several have
  matching K&K Index A rows (for example D-I-10 Ford 1942, F-I-1a Willey 1927b, E-4 Redfield,
  A-20 Thurnwald 1950) that were not linked. Linking them would be a new decision, not a fix.
