# Works table, K&K Index B: one row per work, with the codes that hold it.
#
# Codes are categories and can hold several works, and one work can sit under
# several codes (see PROVENANCE). A work is keyed by its author set and year
# string, built from the Index A entries under each code. The table feeds the
# citation list, the author labels and the text-coverage check. No network or
# analysis is built from it (PROVENANCE 20).
#
# Output: data/kk-index-b-works.csv

# Codes of the verified network, in the network's column order.
codes <- colnames(readRDS("data/kk-index-b-verified-network.rds")$biadjacency)

defs <- read.csv("data/kk-index-b-definitions.csv", stringsAsFactors = FALSE)
ia <- setNames(defs$index_a_authors, defs$kk_code)

# Authors named in one Index A entry: the main name plus any co-author in
# "(with X, year)" or "(all in collaboration with X, year)"
entry.names <- function(e) {
  main <- trimws(sub("\\s*\\(.*$", "", e))
  co <- if (grepl("\\(.*with ", e)) trimws(sub(".*with ([^,]+),.*", "\\1", e)) else character()
  unique(c(main, co))
}

# A co-author written as a prefix of a full name in the same year group ("Gillin"
# for "Gillin John P", "Davis" for "Davis Allison") takes the full name. Only a
# unique match is used, so "Davis" stays put when two full names share it.
# Reviewed exceptions (data/kk-index-b-name-decisions.csv) override the rule: a
# name with a decision takes that work name and is not prefix-merged.
decisions <- read.csv("data/kk-index-b-name-decisions.csv", stringsAsFactors = FALSE)
decisions$group_year[is.na(decisions$group_year)] <- ""
canon.names <- function(nm, year) {
  dec <- decisions[decisions$year == year | decisions$group_year == year, ]
  for (i in seq_len(nrow(dec))) nm[nm == dec$index_name[i]] <- dec$work_name[i]
  decided <- dec$work_name
  for (x in setdiff(nm, decided)) {
    full <- setdiff(nm[startsWith(nm, paste0(x, " "))], decided)
    if (length(full) == 1) nm[nm == x] <- full
  }
  unique(nm)
}

# Works of one code: entries grouped by year; names are unioned within a year
code.works <- function(s) {
  if (is.na(s) || !nzchar(s)) return(character())
  ents <- trimws(strsplit(s, ";")[[1]])
  # Per-entry year, "" when absent. regmatches() would drop unmatched entries and
  # misalign the years with the entries that follow them.
  has.yr <- grepl("[0-9]{3,4}[a-z]?", ents)
  yr <- ifelse(has.yr, sub("^.*?([0-9]{3,4}[a-z]?).*$", "\\1", ents, perl = TRUE), "")
  ok <- nzchar(yr)
  if (!all(ok)) warning("entry without a year: ", paste(ents[!ok], collapse = " | "))
  ents <- ents[ok]; yr <- yr[ok]
  # A decision with a group_year moves the entry into that year's work (Bernard 1941b joins 1941)
  gdec <- decisions[nzchar(decisions$group_year), ]
  yr <- vapply(seq_along(yr), function(i) {
    for (j in seq_len(nrow(gdec)))
      if (yr[i] == gdec$year[j] && gdec$index_name[j] %in% entry.names(ents[i]))
        return(gdec$group_year[j])
    yr[i]
  }, character(1))
  keys <- vapply(unique(yr), function(y) {
    nm <- canon.names(unique(unlist(lapply(ents[yr == y], entry.names))), y)
    paste(paste(sort(nm), collapse = " & "), y)
  }, character(1))
  unname(keys)
}

code.w <- setNames(lapply(codes, function(k) code.works(ia[[k]])), codes)
works <- sort(unique(unlist(code.w)))
cat("codes:", length(codes), "| codes with no work:", sum(lengths(code.w) == 0),
    "| works:", length(works), "\n")

# code x work incidence
A.cw <- matrix(0, nrow = length(codes), ncol = length(works),
               dimnames = list(codes, works))
for (k in codes) A.cw[k, code.w[[k]]] <- 1

work.tab <- data.frame(
  work = works,
  n_codes = colSums(A.cw),
  codes = vapply(works, function(w) paste(names(which(A.cw[, w] == 1)), collapse = "; "),
                 character(1)),
  stringsAsFactors = FALSE)
work.tab <- work.tab[order(-work.tab$n_codes, work.tab$work), ]
write.csv(work.tab, "data/kk-index-b-works.csv", row.names = FALSE)
cat("works table written:", nrow(work.tab), "works\n")
