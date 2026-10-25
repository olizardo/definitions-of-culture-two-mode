# Open items: K&K Index A/B dataset

Last updated 2026-10-26. Method and dated decisions: `docs/PROVENANCE.md`. Current counts: `README.md`.
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
6. **E-5 under "v-i".** A group-reference entry printed under society (`OK_HEADING_WRONG`). It is not covered
   by the block rules and has not been rechecked.
7. **Element labels.** Labels other than the garbled ones and the seven text-proposed fixes are unverified
   against the page image.

## Crosswalk and audit

8. **Audit coverage.** 930 `ok` edges have no row in `data/kk-index-b-flagged-audit.csv`, and 120 of 123
    `manual_fix` edges have none. Decide whether to add audit rows or to accept the printed evidence in the
    manual-fix file.

## Networks and figures

9. ~~**Works-network figures after the 2-core change.**~~ **Done 2026-10-26.** All works figures and outputs were
    compared with the previous versions; see PROVENANCE section 10. The MST community assignments changed for
    about a third of the works, so any text that names communities must be checked against the current output.

## Release and rights

10. **Release boundary.** `data/kkcc-definition-texts.csv`, `data/kkcc-appendix-only-texts.csv` and the
    Part II quotations in PROVENANCE stay out of any release. Boroch's article (ROBAFC-5.1) and its
    verbatim quotations remain restricted. The K&K element labels are cleared by the user.

## Housekeeping

11. **Git.** `documents/pdfcoffee.com-…pdf` is tracked again at HEAD (`819ff9b` re-added it after `525ab20`
    removed it). Decide whether to untrack and ignore it. Many uncommitted changes in scripts, data, figures
    and docs need review before committing. `Rplots.pdf` and `data/kk-index-b-missing-rows-DRAFT.csv` are
    tracked; the DRAFT is superseded by `data/kk-index-b-missing-rows.csv`.

## Citation list (2026-10-26)

Source: `data/kk-index-b-work-citations.csv` (built by `scripts/build-index-b-work-citations.R`); page-image checks in `data/kk-index-b-work-citations-page-checks.csv`. Status values are described in PROVENANCE section 9.

12. **Unchecked K&K picks.** Resolved. Every `matched_multiple` work is now page-checked (PROVENANCE 9.10–9.31). The Rouse 1939 series is spelled "Anthropology" in the citation; the page prints "Anthrolopogy" (PROVENANCE 9.31).
13. **Year-only rows.** Works with `kk_status` = `year_only_no_author` show a K&K line from another author. Replace the displayed line with a page-checked entry, or record the work as not in K&K's bibliography and blank the line.
14. **Title check.** It counts shared words of five letters or more, so generic words ("culture", "science") can make a wrong pick agree. The `both_agree` flag is not evidence on its own. Remove generic words, rerun, and review the rows whose flag changes.
15. **Boroch-only works:** none remaining. Each was checked against the K&K bibliography or the K&K text (PROVENANCE 9.10–9.17).
16. **K&K-only works, kept.** Boroch does not cite F. R. Kluckhohn 1950, Goldenweiser 1933 and 1937, Roberts 1951 or Young 1944 (`boroch_status` = `not_found`). They stay in the citation table with their K&K entries, since they are Index B works and K&K is the source. Roberts 1951 keeps its year conflict (item 17). Linton 1945b is not K&K-only: Boroch cites it (B106, C1), so its K&K pick is checked (PROVENANCE 9.19).
17. **Year conflicts kept as recorded.** Roberts 1951: the K&K bibliography prints 1950, the index and main text say 1951, eHRAF says 1951. Young 1944: the printed index and footnote 7 say 1947, the bibliography says 1944, Boroch says 1947. Both conflicts are K&K's own printing; the choices are recorded in PROVENANCE 9.2 and 9.3.
18. **Publisher sources.** Closed. Abingdon Press (Myres 1927) and Houghton Mifflin (Nimkoff & Ogburn 1940) are added from Google Books and the user, and recorded in the notes of their page-check rows (PROVENANCE 9.33).
19. **Young 1942 record.** The CiNii link the user gave is behind an access challenge, so the publisher and edition are unverified. The row rests on the bibliography entry.
20. ~~**Committee mimeograph, figures.**~~ **Decided 2026-10-26:** the code tree keeps five code vertices (D-I-9, F-I-9, F-I-10, F-I-11, F-IV-3), now labeled with their codes; see PROVENANCE 10.6. Still open: Boroch B075 combines Bernard's Social Forces article and the mimeograph in one entry, so it needs a note.
