# Open items: K&K Index A/B dataset

Last updated 2026-10-25. Method and dated decisions: `docs/PROVENANCE.md`. Current counts: `README.md`.
Completed items have been removed from this list; PROVENANCE keeps the history.

## Token and edge verification

1. **Second reader for the unverified readings.** The user-confirmed readings (A-15, B-15, D-II-15, D-I-5
   under learned behavior, C-I-13, F-II-5, A-5, F-I-13, B-21 under group, F-I-15 under transmission is
   correct) and the manual fixes they came from have one reader. F-IV-3 was checked by the user on 2026-10-25,
   but not on the page image.
2. **Sequence-based resolutions.** `F-U`, `F-I-i}`, `F-H-j` and `A-j` rest on printed sequence and the
   candidate's absence (PROVENANCE 3.4). They need a second reader. `D-I` (society) and `F-j` (organized)
   remain unresolved and are excluded as duplicates by decision.
3. **General OCR rule tokens.** Audit the remaining general-rule tokens in the 207 `ocr_corrected` edges
   (most common: A-i, D-I-i, B-i, C-I-i, D-IV-i, E-i, D-I-y). Group them by printed block and check each
   block on the page image.
4. **Sub-element check, text-layer blocks.** About 440 rows in `data/kk-index-b-subelement-check.csv` are
   OK_TEXT and not image-checked. These include most of habits, material culture, modes, the rest of symbols,
   and the blocks on printed pp. 79–81.
5. **Block-check verdicts.** The 22 flagged edges have one image reader
   (`data/kk-index-b-block-check-review-current.csv`). The PDF text layer does not confirm them, so a second
   reader is needed.
6. **Unresolved NEEDS_CHECK rows.**
   - Carriers of culture, "a people, adjustments": the edge code is not decided (one row in the verdict file).
   - The "a people" tokens C-I-1 j, D-I-i, F-III-j and F-IV-j are not in the edge list and are not
     image-checked.
7. **E-5 under "v-i".** A group-reference entry printed under society (`OK_HEADING_WRONG`). It is not covered
   by the block rules and has not been rechecked.
8. **Angyal (B-14).** Taken from the page image and absent from the OCR text. Page 88 of the second scan
   was not checked.
9. **Element labels.** Labels other than the garbled ones and the seven text-proposed fixes are unverified
   against the page image.

## Crosswalk and audit

10. **Appendix-only Boroch codes (39).** Several have matching K&K Index A rows that are not linked, for
    example D-I-10 (Ford 1942), F-I-1a (Willey 1927b), E-4 (Redfield) and A-20 (Thurnwald 1950). Linking
    them is a new decision, not a fix.
11. **Audit coverage.** 930 `ok` edges have no row in `data/kk-index-b-flagged-audit.csv`, and 120 of 123
    `manual_fix` edges have none. Decide whether to add audit rows or to accept the printed evidence in the
    manual-fix file.

## Networks and figures

12. **Works-network figures after the 2-core change.** The concept MST now builds its projection from the
    2-core matrix, so its weights changed. The works CA, works MST, centrality and degree figures were
    regenerated and not compared with the previous versions. Review them.

## Release and rights

13. **Release boundary.** `data/kkcc-definition-texts.csv`, `data/kkcc-appendix-only-texts.csv` and the
    Part II quotations in PROVENANCE stay out of any release. Boroch's article (ROBAFC-5.1) and its
    verbatim quotations remain restricted. The K&K element labels are cleared by the user.

## Housekeeping

14. **Git.** `documents/pdfcoffee.com-…pdf` is tracked again at HEAD (`819ff9b` re-added it after `525ab20`
    removed it). Decide whether to untrack and ignore it. Many uncommitted changes in scripts, data, figures
    and docs need review before committing. `Rplots.pdf` and `data/kk-index-b-missing-rows-DRAFT.csv` are
    tracked; the DRAFT is superseded by `data/kk-index-b-missing-rows.csv`.
