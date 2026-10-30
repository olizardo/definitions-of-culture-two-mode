# Two-mode network data, version 0.6.0 (preliminary)

Derived from Kroeber & Kluckhohn (1952), Index A/B. Subject to further verification (see docs/TODO.md; the copy here is a snapshot).
Version history is in `CHANGELOG.md`.

| File | Object(s) | Network | Dimensions (rows x columns) |
|---|---|---|---|
| `kk-index-b-verified-network.rds` | `graph`, `biadjacency` | sub-elements x definitions (codes) | 470 x 171 |
| `kk-index-b-heading-network.rds` | `graph`, `biadjacency` | headings x definitions (codes) | 53 x 171 |
| `kk-index-b-work-concept-network-full.rds` | `two_mode_graph` | sub-elements x works | 470 x 131 |
| `kk-index-b-work-concept-network-full.rds` | `two_mode_heading_graph` | headings x works | 53 x 131 |
| `kk-index-b-work-citations.csv` | (table) | one row per work | 131 rows |

Read the `.rds` files with `readRDS()`. Objects are igraph graphs (`igraph` package), and the `biadjacency` element is the 0/1 matrix.

Code vertices of `kk-index-b-verified-network.rds` carry `source_author`, `source_year` and `source_page` (the printed pinpoint in Boroch's appendix for the code's quotation) and `quote_opening` (the first six words of the quotation). Each variant code (`A-3(a)` and so on, PROVENANCE 17) has one Boroch quotation, so these values are single. Sub-element vertices carry NA for them. The six-word openings are fragments of verbatim quotations and are released by decision; the full texts are not.

Work vertices in both works networks, and the `works` table in the full works file, carry `pub_type`: `article`, `book`, `chapter` or `other` (added in 0.3.0). The basis for each assignment is in the project repository and is not released.

The citations table has these columns:

- `work`: work label (surnames and year), as used in the works network.
- `n_codes`, `codes`: number of codes holding the work, and which codes.
- `surnames`, `year`: author surnames and year string.
- `kk_status`: whether K&K's bibliography matched the work (`page_checked`, `matched`, `matched_multiple`, `year_only_no_author`, `not_found`, `quoted_in`, `year_conflict`). See PROVENANCE section 9.
- `boroch_status`, `boroch_entry_id`, `boroch_reference`: match to Boroch's supplementary bibliography (`matched` or `not_found`), Boroch's ID, and the reference text.
- `overall_status`: `both_agree` (K&K and Boroch agree on the work), `both_disagree`, or `kk_only` (not matched in Boroch's bibliography).

Not included: text of definitions and quotations (restricted; the six-word openings above are the one exception), the Boroch networks, analysis outputs, the edge tables, and the K&K page text and review notes behind the citations table.
