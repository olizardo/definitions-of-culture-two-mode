# Definition attributes as a data frame, read from the definition vertices of
# the fine network (data/kkcc_two_mode.rds). Analysis scripts and the report
# source this file and call definition_attrs(). subgroup_code is the full code
# (e.g. C1-6), which the subgroup regex in analysis-centrality-prestige-main.R reads.

definition_attrs <- function(path = "data/kkcc_two_mode.rds") {
  g <- readRDS(path)$graph
  v <- igraph::V(g)[igraph::V(g)$type]
  data.frame(
    code = v$name,
    group = v$def_group,
    type = v$def_type,
    subgroup_code = v$name,
    author = v$author,
    year = v$year,
    year_orig = v$year_orig,
    decade = v$decade,
    year_suffix = v$year_suffix,
    bib_entry = v$bib_entry,
    match_status = v$match_status,
    author_canonical = v$author_canonical,
    bib_year = v$bib_year,
    bib_ref = v$bib_ref,
    stringsAsFactors = FALSE
  )
}
