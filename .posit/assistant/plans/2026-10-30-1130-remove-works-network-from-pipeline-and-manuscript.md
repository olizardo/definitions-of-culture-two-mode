# Plan: remove the works network from the pipeline and manuscript

## Goal

The analysis unit is the definitions network: each K&K code is one author-year-page-quote (171 codes, 171 distinct keys, checked 2026-10-30). Remove the works network, meaning each work's sub-element set as the union over its codes, from the pipeline, the manuscript and the README. This follows from the rule that pooling several quotes into one work is out of scope.

## Dependencies found (read-only check)

- Scripts reading the works network (`two_mode_graph`, `two_mode_heading_graph`): `build-work-concept-network-index-b.R` (writes it), `analysis-ca-works-index-b.R`, `analysis-mst-works-index-b.R`, `analysis-nmf-works-index-b.R`, `analysis-mst-nmf-works-index-b.R`, `analysis-centrality-index-b.R` (works half), `analysis-index-b.R` (works degree panel), `analysis-mst-headings-index-b.R` (works heading tree), `figure-sankey-subgroups.R` (works panel).
- Scripts reading the works table (`data/kk-index-b-works.csv`): `analysis-mst-definitions-index-b.R` (code labels, lines 46–70), `build-index-b-work-citations.R`, `build-work-authors-index-b.R`, `attach-work-pub-type-index-b.R`, `check-definition-text-coverage.R` (text-to-work match).
- Release 0.6.0 ships `kk-index-b-work-concept-network-full.rds`. The site split files on `site-source` carry the works graphs.
- Manuscript (`kk-index-b-two-mode.tex`): abstract, Data and networks section, Table 1 (works column), degree figure (works panels), works MST subsections and figures, works betweenness table, "Taken together" paragraph, structural NMF subsection and its factor table, works-factor tree subsection, Interpretation sentences on works, Limitations (works keying), and the works panel of the subgroup Sankey appendix.

## Proposed changes

### 1. Pipeline (scripts)

- Delete: `analysis-ca-works-index-b.R`, `analysis-mst-works-index-b.R`, `analysis-nmf-works-index-b.R`, `analysis-mst-nmf-works-index-b.R`.
- Edit `analysis-centrality-index-b.R`: definitions half only; drop `kk-index-b-centrality-works.csv`.
- Edit `analysis-index-b.R`: definitions degree panels only; the figure becomes `degree-definitions.png` (rename, since the file name carries "works").
- Edit `analysis-mst-headings-index-b.R`: definitions heading tree only.
- Edit `figure-sankey-subgroups.R`: codes panel only; drop the works panel and the plurality-over-codes logic for works (PROVENANCE 17.10 no longer applies).
- Edit `build-work-concept-network-index-b.R`: stop writing the works network file. Whether it keeps writing the works table depends on decision B.
- Edit `analysis-mst-definitions-index-b.R`: code labels no longer come from the works table, depending on decision A.
- Edit `check-definition-text-coverage.R`: its text-to-work match depends on decision B.

### 2. Data and figures

- Delete: `data/kk-index-b-work-concept-network-full.rds`; `data/kk-index-b-ca-works-lcc2core-{subelements,works}.csv`; `data/kk-index-b-centrality-works.csv`; `data/kk-index-b-mst-works-nodes.csv`; `data/kk-index-b-mst-nmf-works-nodes.csv`; `data/kk-index-b-nmf-works-{factors,loads,stability,agreement}.csv`; `data/kk-index-b-nmf-subgroup-works-crosstab.csv`; the `figures/kk-index-b/works/` folder; `figures/kk-index-b/nmf/nmf-works.png`, `nmf-works-mst.png`, `sankey-works-subgroups.png`.
- Regenerate: `data/kk-index-b-network-stats.csv` (definitions values only), `figures/kk-index-b/degree-definitions.png`, and the definitions tree tables, if the labels change (decision A).
- Keep: the definitions networks, the definitions and texts analyses, and the texts NMF.

### 3. Manuscript (`kk-index-b-two-mode.tex`)

- Abstract and Data and networks: one network, the definitions network, in which each code is one author-year-page-quote. Remove the works network and its counts (131 works, 10 components). Keep the work-citation point only if decision B keeps the citations.
- Table 1: one column (definitions). Degree figure: definitions panels only.
- MSTs: keep the concept tree and the code tree. Remove the works subsections, their figures, and the works betweenness table.
- "Taken together": rewrite for the definitions tree alone, or drop it.
- NMF: keep the texts analysis as the only NMF. Remove the structural subsection, its factor table and figure, the works factor-tree subsection and its figure, and the works sentences in Interpretation. Rewrite the NMF intro, which currently says both analyses run on the works network. The texts analysis runs on the codes.
- Limitations: remove the works keying sentence.
- Appendix: keep the codes Sankey only, and update its paragraphs.
- Compile in a scratch copy: no overfull boxes, no undefined references, and no stale `\ref`.

### 4. Docs

- README: the pipeline table (rows for the removed scripts), the data dictionary (works rows, the network list), the NMF Methods paragraph, the counts. Each count checked against current outputs.
- `docs/TODO.md`: add or update items for any open decisions.
- `docs/PROVENANCE.md`: new dated section 19 recording the decision and each removed file. Sections 9–17 stay as history.
- `AGENTS.md` (user memory, project scope) still describes the works network. Tell the user to run `/savememory` after the change. I will not edit it unasked.

### 5. Verification

- Run the remaining chain in a scratch copy, following the recheck procedure in AGENTS.md (fresh environments, empty global environment). Compare the definitions outputs with the stored files: CSVs with `cmp`, RDS with `identical()` on the loaded objects.
- Confirm the verified network and the heading network are unchanged. The removal should change no definitions number.
- Grep the repo for `works` network references (`two_mode_graph`, `works-`, `nmf-works`) and confirm the remaining mentions are intentional.
- View the new degree figure and the definitions trees.

## Decisions needed

**A. Code labels in the definitions trees.** `analysis-mst-definitions-index-b.R` labels nodes from the works table. Options: (1) derive the labels from each code's `source_author` and `source_year` vertex attributes, which are the author-year-page-quote key; (2) keep the works table as a label source. I recommend (1), which removes the last works dependency from the definitions trees. The label format will change, so the figures will need regenerating. I have not yet confirmed which tree nodes carry author labels, so this should be checked before the change.

**B. Work-level bibliography.** The works table, `kk-index-b-work-citations.csv` (the release citation table), the work-author and page-check files, and `kk-index-b-work-pub-type.csv`. Options: (1) keep them as a bibliography of code sources, without any work-level analysis (recommended); (2) remove them as well. Under (1), the pub-type file has no consumer once the works trees go, so it can be dropped separately. Under (2), the release loses its citation table.

**C. Release and site.** Release 0.6.0 contains the works network file, and the site split files on `site-source` contain the works graphs. Options: (1) leave the release and the site alone until a publication step, which needs your approval (recommended); (2) cut a new release now without the works file. Removing a network object is a structural change, so this would be a new major version under the CHANGELOG rules. Either way, I will not publish or push.

**D. Degree figure.** Replace `degree-works-definitions.png` with a definitions-only figure, the concept and code degree distributions. The caption and Table 1 change to match. Confirm.

## Answers to decisions A–D (2026-10-30)

These answers supersede the open options above.

**A. Code labels.** Checked: `scripts/analysis-mst-definitions-index-b.R` sets each tree node's label to its K&K code (`V(st.def)$label <- V(st.def)$name`), so the figures do not use the works table. The author labels built from the works table (`works.lab`) go only to the node table's works column. Answer: replace that column with the code's own author and year from the verified network's `source_author` and `source_year` attributes (the citation key). Drop the works-table read from that script. No figure changes.

**B. Work-level bibliography.** Keep `data/kk-index-b-work-citations.csv` (the release citation table), its page-check file, and the works table as the input to the citation build. They serve as a bibliography of code sources and feed no network or analysis. Drop `data/kk-index-b-work-pub-type.csv` and `scripts/attach-work-pub-type-index-b.R`, because their only consumer was the works trees. `check-definition-text-coverage.R` keeps its text-to-author-year check, which reads the works table.

**C. Release and site.** No new release and no change to `release/` or the `site-source` branch in this pass. The release is refreshed at publication, with your approval. The 0.6.0 release still ships the works file, so the publication step will need a new CHANGELOG entry.

**D. Degree figure.** Yes. Replace `degree-works-definitions.png` with a definitions-only figure of sub-element and code degree distributions. Table 1 becomes a single column, and the degree caption changes to match.

## Not in this plan

- Any change to `main` commits or the release folder, unless decision C is approved.
- The PROVENANCE history, which records the works network as it was.
- The Boroch two-mode networks (`kkcc_two_mode*.rds`), which do not involve the works network.
