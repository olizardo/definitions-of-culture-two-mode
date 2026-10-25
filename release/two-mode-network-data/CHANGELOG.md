# Changelog

Versions follow `MAJOR.MINOR.PATCH`. A minor bump adds data or changes network contents; a patch fixes an
error in existing data without changing its structure.

## 0.2.0 (2026-10-26)

- Added `kk-index-b-work-citations.csv`: 133 works with their codes, surnames, year, K&K and Boroch match status, and the Boroch reference.
- Refreshed the three network files from the current build. The works networks now have 133 works (v0.1.0 had 136). The works-level outputs were compared with the previous build (see docs/PROVENANCE.md section 10 in the project repository): centrality is stable, CA positions are moderately stable, and MST community assignments changed for about a third of the works. Edge-level changes were not compared one by one.
- Changed MANIFEST.md to list each object's dimensions as rows x columns.

Known open items in the citation table (see docs/TODO.md, items 13, 16, 17 and 20):

- Some rows have a K&K line from another author (`year_only_no_author`), or no K&K match.
- Five works are in K&K only (`kk_only`). Roberts 1951 and Young 1944 have year conflicts.
- The Committee mimeograph (Bernard, Blumenthal, Dodd, Hart 1941) is one work with five codes.

## 0.1.0

- Preliminary release: the three Index B network files (definitions x sub-elements, definitions x headings, works x sub-elements and works x headings). 136 works.
