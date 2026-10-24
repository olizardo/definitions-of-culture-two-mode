# Handoff: K&K Index A/B dataset

Last updated 2026-10-24. Read `AGENTS.md` (project memory) and `docs/PROVENANCE.md` first.

## Current state

- Index A: 187 rows, 186 resolved, 165 codes. Every row on printed pp. 73-74 was read against
  the page image (200 dpi; disputed lines at 300 dpi). Sears's `C-I-Addendum` stays unresolved.
- Index B: 1279 edges. Flags: ok 966, ocr_corrected 210, manual_fix 60, junk_name 33,
  code_not_in_index_a 10. 8 unresolved tokens (`data/kk-index-b-unresolved.csv`).
- Crosswalk (`data/kk-boroch-crosswalk.csv`, 135 rows): 127 auto, 2 hand decisions (D3-1, D2-16),
  4 ambiguous and 1 unmatched (open), 1 F4-6 slip (resolved in PROVENANCE section 5).
- Uncommitted (check `git status` first): `AGENTS.md`, `README.md`, `.gitignore`, this file,
  `kkcc-two-mode.qmd`, and the 2026-10-24 reorganization. Scripts moved to `scripts/`; PDFs and the
  Archive text moved to `documents/`; stale files deleted (see the project layout in `AGENTS.md`).
  `build-definition-texts.R` has a parse-error fix, with the doubled-period rule disabled.
  `docs/PROVENANCE.md` sections 3.1 and 3.2 are already committed.
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

1. **Cross-check Index B against the second OCR.** Run tesseract (or use the PDF text layer) on
   PDF pp. 90-94 of `culturecriticalr0000kroe_z3a4`. Compare the code tokens by heading and
   sub-element with `data/kk-index-b-edges.csv`. Focus on the 10 code_not_in_index_a edges, the
   33 junk_name edges, and the 8 unresolved tokens. Record each disagreement and its page-image
   verdict. Index A cross-check: tesseract agreed with every corrected row checked, so it's a useful
   lead, not proof. The Index A comparison from the other copy (`papersofpeabodymvol47no1peab`)
   was noisy; it misattributed continuation lines and misread digits.
2. **Check the 50-row sample.** Fill `verdict` and `printed_page` in
   `data/kk-index-b-ok-sample.csv` (seed 4817, drawn from the 966 ok edges). Report the error rate
   with its uncertainty. A larger sample is needed if the rate is above about 5%.
3. **Heading attribution (high priority).** Build a block-to-heading map from the page images, then
   apply it in `build-index-b.R`, not in the output CSVs. Known errors: "carriers of culture"
   sits under `capabilities`; "common or shared patterns" under `civilization`; "systems" under
   `symbols`; "social" and "society" under `group reference`; "ideas and cognitive processes"
   under `history`. Example: `E-5` under "v-i" (group reference) is printed under "society"
   (`data/kk-index-b-ocr-audit.csv`, verdict `OK_HEADING_WRONG`). Rebuild the heading matrix
   after.
4. **Eight unresolved tokens** (`data/kk-index-b-unresolved.csv`). Five have two printed
   candidates under the same sub-element: group `F-i` (F-I-6 or F-I-19), society `A-q` (A-4 or
   A-9), society `D-I` (D-I-12 or D-I-13), ideas `F-H-j` (F-II-3 or F-II-5), sum `A-j` (A-3 or
   A-5). Three are unreadable: group `F-U`, sub `i` `F-I-i}`, and means of adjustment `F-I\`.
   The second scan may resolve some. If not, record an accept-exclusion decision. Do not guess.
5. **Junk sub-element names (33 edges, `parse_flag = junk_name`).** Decide each case: map to the
   printed sub-element, or drop from the sub-element matrix and keep the edge in the heading matrix.
   Record the decision in `docs/PROVENANCE.md`.
6. **Open crosswalk rows** (`data/kk-boroch-crosswalk-decisions.csv`): A16, A17 (K&K A-14, A-15),
   A20 (A-18, A-19), C1-11 (C-I-10/11/12), B5 (probable B-4a, year conflict). Check each against
   the appendix text in `data/kkcc-definition-texts.csv` and the K&K Part II text. Record the
   decision in the same file with its basis. Do not match by position.
7. **Ten code_not_in_index_a edges.** `C-7`, `D-8`, `F-9` are printed without the roman numeral
   (verified at 300 dpi). `D-7`, `D-5`, `F-4`, `E-17` are kept as printed and not yet verified
   at 300 dpi. `D-II-16` (`socially transmitted behavior`) has no Index A row, but a crosswalk
   decision maps Boroch's D2-16 to it. Verify the four unverified codes, and do not remap any
   without a page-image basis.
8. **Rights (user decision).** Whether K&K Index B element labels can ship is undecided.
   `data/kkcc-definition-texts.csv` holds verbatim Boroch quotations and must stay out of any
   release.
9. **Git.** Commit the pending files in logical units: (a) memory, README, `.gitignore` and TODO;
   (b) the reorganization (moves, deletions, path updates in the scripts and the report); (c) the
   `build-definition-texts.R` parse fix, leaving the D1-8 doubled-period rule disabled. The Archive
   text in `documents/` is gitignored and stays out. Earlier commits: `e007b5a`, `7533002`,
   `e866111`, `f78bece`.
10. **Documentation** to keep current: `README.md` (data dictionary, limitations),
    `docs/PROVENANCE.md` (sections 3.1, 3.2, 8), and the "K&K Index A/B dataset" section of
    `AGENTS.md`. Update only current-state text; leave the historical notes alone.
11. **Verification after any change.** The build runs without errors. Every manual-fix key matches a
    token. Edge counts and parse-flag counts change only as expected. Spot-check each new manual
    fix against the page image at 300 dpi and record it in `data/kk-index-b-zoom-check.csv` or
    `data/kk-index-b-ocr-audit.csv`.

## Known gaps and cautions

- Index A's verification is a single-reader check. There's no double-keying. Do not describe the
  dataset as fully verified.
- The 932 unflagged ok rows have not been audited (only the 50-row sample, pending).
- Angyal's row (B-14) is from the page image. It is absent from the project's OCR text, and the
  second scan's tesseract output for PDF p. 89 doesn't include it (page 88 probably has it, not
  checked).
- Element labels are unverified against the page image and may contain residual OCR damage.
- The 39 appendix-only Boroch codes have no author or year in `kkcc-definition-years.csv`, so the
  crosswalk does not link them. Several have matching K&K Index A rows (for example D-I-10 Ford
  1942, F-I-1a Willey 1927b, E-4 Redfield, A-20 Thurnwald 1950) that were not linked.
