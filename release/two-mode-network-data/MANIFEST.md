# Two-mode network data (preliminary release)

Derived from Kroeber & Kluckhohn (1952), Index A/B. Subject to further verification (see docs/TODO.md; the copy here is a snapshot).

| File | Object(s) | Network |
|---|---|---|
| `kk-index-b-verified-network.rds` | `graph`, `biadjacency` | definitions x sub-elements (472 x 170) |
| `kk-index-b-heading-network.rds` | `graph`, `biadjacency` | definitions x headings (53 x 170) |
| `kk-index-b-work-concept-network-full.rds` | `two_mode_graph` | works x sub-elements (472 x 136) |
| `kk-index-b-work-concept-network-full.rds` | `two_mode_heading_graph` | works x headings (53 x 136) |

Read with `readRDS()`. Objects are igraph graphs (`igraph` package), and the `biadjacency` element is the 0/1 matrix.
Not included: text of definitions and quotations (restricted), the Boroch networks, analysis outputs, and the edge tables.
