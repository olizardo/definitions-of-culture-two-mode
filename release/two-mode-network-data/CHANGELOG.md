# Changelog

Versions follow `MAJOR.MINOR.PATCH`. A minor bump adds data or changes network contents; a patch fixes an
error in existing data without changing its structure.

## 0.6.0 (2026-10-30)

- Split the four K&K codes whose Boroch quotations are lettered a and b into variants: A-3, E-5, F-II-4 and F-II-7 become A-3(a), A-3(b), E-5(a), E-5(b), F-II-4(a), F-II-4(b), F-II-7(a) and F-II-7(b). The definitions networks go from 167 to 171 codes. K&K prints one Index B entry per code, so each variant starts with a copy of its parent's sub-element links. Twenty-nine variant-specific links were then removed where the quotation text indicates the variant does not carry the sub-element (PROVENANCE 17.8). The verified network goes from 1189 to 1201 edges and the heading network from 1080 to 1095. The sub-element and heading counts are unchanged (470 and 53).
- Works are unchanged at 131. Dixon 1928, Blumenthal 1937 and Feibleman 1946 now list two variant codes each. Counted by K&K code, works under two or more codes stay at 19. The citations table changes in four rows' `codes` column.
- Code vertices of the verified network carry `source_author`, `source_year`, `source_page` and `quote_opening` (see MANIFEST.md).
- Rights: the six-word quote openings are released by decision. The definition and quotation texts stay out of the release.

## 0.5.0 (2026-10-30)

- Removed the Part III statement codes C-5, D-5, D-7 and E-17 from the networks. They are K&K's Part III statements and sit outside the Part II typology. The definitions networks go from 171 to 167 codes, the sub-element network from 472 to 470 sub-elements, and the edges from 1193 to 1189. The raw sub-element and heading networks now have the same codes as the verified network.
- The works networks go from 133 to 131 works. Goldenweiser 1933 and 1937 were attached only to Part III codes and leave with them; Roheim 1934 stays, under D-IV-1 only. Work vertices now have 27 articles, 89 books, 8 chapters and 7 other.
- Refreshed the three network files and the citations table from the current build. The citations table has 131 works (127 both agree, 1 both disagree, 3 K&K only).
- Rights unchanged: the definition and quotation texts stay out of the release.

## 0.4.0 (2026-10-26)

- Added the Part III statement code C-5 to the verified network (Goldenweiser 1937: 45-46, printed p. 99). C-5 has no Index A entry and no Index B element, so it enters the definitions networks as an isolate: the definitions networks go from 170 to 171 codes, with the edges unchanged.
- The Part III attribution of Goldenweiser 1937 moves from E-5 to C-5. The printed Part III author index (p. 141) reads "c-5 (1937)"; the source OCR misreads it as e-5, which the earlier mapping had followed. K&K quote Goldenweiser's Anthropology (1937) only in Part III, never in Part II.
- Goldenweiser 1937 therefore holds no sub-element and no heading: it leaves the works largest component and 2-core, so the works-level CA, MST and centrality outputs change. E-5 now holds one work (Linton 1945a). The definitions-level outputs are unchanged.
- Refreshed the three network files and the citations table from the current build.
- Rights unchanged: the definition and quotation texts stay out of the release. The K&K monograph is treated as publicly available online; online availability does not by itself settle redistribution rights.

## 0.3.1 (2026-10-26)

- Attribute and content fixes; the network structure is unchanged (vertices, edges and weights are the same as in 0.3.0).
- The G-1 definition (Sapir 1921) now carries the Boroch appendix label G1, and the works table's "Sapir 1921" row lists both of its codes (B-2; G-1). Printed Index A p. 74 lists Sapir under G-1 (1921); an earlier transcription note had missed the row.
- Bernard's Index A year is now shown as printed, (1941b); the committee mimeograph remains one work of four authors under 1941, as in 0.3.0.
- Refreshed the three network files and the citations table from the current build.

## 0.3.0 (2026-10-25)

- Added `pub_type` to the work vertices of both works networks and to the `works` table in the full works file. Values: `article`, `book`, `chapter`, `other`. Of the 133 works, 27 are articles, 91 books, 8 chapters and 7 other. A chapter is an entry in an edited volume or a reference work; numbered monograph series count as books. Blumenthal 1937 and Steward 1950 are uncertain and coded `other`.
- The network structure is unchanged: vertices, edges and edge weights are the same as in 0.2.0.
- Refreshed the network files from the current build. The works networks keep the same 133 works.

## 0.2.0 (2026-10-25)

- Added `kk-index-b-work-citations.csv`: 133 works with their codes, surnames, year, K&K and Boroch match status, and the Boroch reference.
- Refreshed the three network files from the current build. The works networks now have 133 works (v0.1.0 had 136). The works-level outputs were compared with the previous build (see docs/PROVENANCE.md section 10 in the project repository): centrality is stable, CA positions are moderately stable, and MST community assignments changed for about a third of the works. Edge-level changes were not compared one by one.
- Changed MANIFEST.md to list each object's dimensions as rows x columns.

Known open items in the citation table (see docs/TODO.md, items 13, 16, 17 and 20):

- Some rows have a K&K line from another author (`year_only_no_author`), or no K&K match.
- Five works are in K&K only (`kk_only`). Roberts 1951 and Young 1944 have year conflicts.
- The Committee mimeograph (Bernard, Blumenthal, Dodd, Hart 1941) is one work with five codes.

## 0.1.0

- Preliminary release: the three Index B network files (definitions x sub-elements, definitions x headings, works x sub-elements and works x headings). 136 works.
