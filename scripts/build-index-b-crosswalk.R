# Crosswalk Boroch's definition codes to K&K numbering, and audit Boroch's
# Table 2 (56 notions x 135 definitions) against K&K Index B.
#
# Run after build-index-b.R (needs data/kk-index-a-authors.csv,
# data/kk-index-b-edges.csv, data/kk-index-b-definitions.csv).
#
# Outputs:
#   data/kk-boroch-crosswalk.csv      one row per Boroch appendix code (171)
#   data/kk-index-b-audit.csv         one row per Table 2 cell x definition
#                                     (56 x 135), with Index B status
#   data/kk-index-b-audit-summary.csv counts by status
#   data/build-index-b-crosswalk-sessioninfo.txt

data_dir <- "data"

# Boroch's codes are K&K numbering with the subgroup as a digit:
# "C1-5a" = C-I-5a, "F4-5" = F-IV-5, "E1" = E-1, "A10a" = A-10a.
boroch_to_kk <- function(code) {
  m <- regmatches(code, regexec("^([A-G])([1-4])-(.+)$", code))[[1]]
  if (length(m)) {
    roman <- c("I", "II", "III", "IV")[as.integer(m[3])]
    return(paste0(m[2], "-", roman, "-", m[4]))
  }
  m <- regmatches(code, regexec("^([A-G])(.+)$", code))[[1]]
  if (length(m)) return(paste0(m[2], "-", m[3]))
  NA_character_
}

# Boroch's numbering is NOT K&K's numbering (e.g. Boroch A10 = Winston 1933,
# K&K A-10 = Linton 1936), so the crosswalk is author + year, never position.
# The positional mapping is kept only as an agreement check.
first_surname <- function(x) sub("[ ,].*$", "", trimws(x))

index_a <- read.csv(file.path(data_dir, "kk-index-a-authors.csv"), stringsAsFactors = FALSE)
index_a_ok <- index_a[index_a$ok, ]
index_a_ok$year <- suppressWarnings(as.integer(sub(".*?((?:18|19|20)[0-9]{2}).*", "\\1",
                                                 index_a_ok$qualifier, perl = TRUE)))
index_a_ok$year[!grepl("(?:18|19|20)[0-9]{2}", index_a_ok$qualifier, perl = TRUE)] <- NA_integer_
index_a_ok$surname <- first_surname(index_a_ok$author_raw)
index_a_ok$suffix <- sub(".*(?:18|19|20)[0-9]{2}([a-z]?).*", "\\1", index_a_ok$qualifier, perl = TRUE)
index_a_ok$suffix[!grepl("(?:18|19|20)[0-9]{2}[a-z]", index_a_ok$qualifier, perl = TRUE)] <- ""

# First four-digit year in a string, or NA.
first_year <- function(x) {
  y <- suppressWarnings(as.integer(sub(".*?((?:18|19|20)[0-9]{2}).*", "\\1", x, perl = TRUE)))
  y[!grepl("(?:18|19|20)[0-9]{2}", x, perl = TRUE)] <- NA_integer_
  y
}

# Candidates must share Boroch's group and subgroup (group letter, plus the
# roman subgroup for C, D, F). Boroch's quoted year is the edition year; his
# year_orig (first publication) is also accepted. A Boroch year suffix (a, b)
# must match the K&K suffix when Boroch gives one.
match_author_year <- function(boroch_code, boroch_author, boroch_years, boroch_suffix) {
  if (is.na(boroch_author) || all(is.na(boroch_years))) return(character(0))
  # Boroch writes initials ("A. Davis"); K&K indexes the surname alone.
  surnames <- sub("^[A-Z][.] ", "", trimws(strsplit(boroch_author, " and ", fixed = TRUE)[[1]]))
  hit <- index_a_ok$surname %in% surnames & index_a_ok$year %in% boroch_years
  if (!is.na(boroch_suffix) && nzchar(boroch_suffix)) {
    hit <- hit & index_a_ok$suffix == boroch_suffix
  }
  prefix <- sub("-[^-]*$", "", boroch_to_kk(boroch_code))
  cand <- index_a_ok$kk_code[hit]
  unique(cand[sub("-[^-]*$", "", cand) == prefix])
}

# ---- Crosswalk --------------------------------------------------------------

appendix <- read.csv(file.path(data_dir, "kkcc-definition-texts.csv"),
                     stringsAsFactors = FALSE)
years <- read.csv(file.path(data_dir, "kkcc-definition-years.csv"),
                  stringsAsFactors = FALSE)
index_b <- read.csv(file.path(data_dir, "kk-index-b-edges.csv"),
                    stringsAsFactors = FALSE)
defs <- read.csv(file.path(data_dir, "kk-index-b-definitions.csv"),
                 stringsAsFactors = FALSE)
biadj <- readRDS(file.path(data_dir, "kkcc_two_mode.rds"))$biadjacency

crosswalk <- data.frame(boroch_code = appendix$code, stringsAsFactors = FALSE)
crosswalk$in_table2 <- crosswalk$boroch_code %in% colnames(biadj)
crosswalk$boroch_author <- years$author[match(crosswalk$boroch_code, years$code)]
crosswalk$boroch_year <- years$year[match(crosswalk$boroch_code, years$code)]
crosswalk$boroch_year_orig <- years$year_orig[match(crosswalk$boroch_code, years$code)]
crosswalk$boroch_suffix <- years$year_suffix[match(crosswalk$boroch_code, years$code)]
crosswalk$positional_kk <- vapply(crosswalk$boroch_code, boroch_to_kk, "")

matches <- lapply(seq_len(nrow(crosswalk)), function(i) {
  match_author_year(crosswalk$boroch_code[i], crosswalk$boroch_author[i],
                    c(as.integer(crosswalk$boroch_year[i]),
                      first_year(crosswalk$boroch_year_orig[i])),
                    crosswalk$boroch_suffix[i])
})
crosswalk$n_candidates <- lengths(matches)
crosswalk$kk_code <- vapply(matches, function(m) if (length(m) == 1) m else NA_character_, "")
crosswalk$candidates <- vapply(matches, function(m) paste(m, collapse = ";"), "")
crosswalk$match_status <- ifelse(is.na(crosswalk$boroch_author), "no_boroch_metadata",
                          ifelse(crosswalk$n_candidates == 1, "auto",
                          ifelse(crosswalk$n_candidates > 1, "ambiguous", "no_kk_match")))
crosswalk$positional_agrees <- !is.na(crosswalk$kk_code) & crosswalk$kk_code == crosswalk$positional_kk
# Boroch's F4-6 has no K&K counterpart (K&K's F-IV has 5 definitions); it is
# resolved by hand in docs/PROVENANCE.md, not by the rule above.
crosswalk$match_status[crosswalk$boroch_code == "F4-6"] <- "manual_F4-6_slip"

# Hand decisions for codes the rule cannot settle (data/kk-boroch-crosswalk-decisions.csv).
# "match" sets the K&K code; "exclude" clears it for a Table 2 column that is a
# verbatim copy of another quotation; "open" keeps the candidates and records why.
decisions <- read.csv(file.path(data_dir, "kk-boroch-crosswalk-decisions.csv"),
                      stringsAsFactors = FALSE)
crosswalk$decision <- NA_character_
crosswalk$decision_note <- NA_character_
for (i in seq_len(nrow(decisions))) {
  j <- match(decisions$boroch_code[i], crosswalk$boroch_code)
  stopifnot(!is.na(j))
  crosswalk$decision[j] <- decisions$decision[i]
  crosswalk$decision_note[j] <- decisions$note[i]
  if (decisions$decision[i] == "match") {
    crosswalk$kk_code[j] <- decisions$kk_code[i]
    crosswalk$match_status[j] <- "manual_decision"
  } else if (decisions$decision[i] == "exclude") {
    crosswalk$kk_code[j] <- NA_character_
    crosswalk$match_status[j] <- "excluded_verbatim_copy"
  }
}
crosswalk$positional_agrees <- !is.na(crosswalk$kk_code) & crosswalk$kk_code == crosswalk$positional_kk

write.csv(crosswalk, file.path(data_dir, "kk-boroch-crosswalk.csv"), row.names = FALSE)

# ---- Audit: Table 2 cells vs Index B -----------------------------------------

# Boroch's notion labels differ from K&K's element wording. A row is linked to
# a K&K element when the normalized labels are equal (case, hyphens, and a
# trailing plural "s" ignored). Linkage is conservative: unlinked rows are
# reported, not guessed.
norm_label <- function(x) {
  x <- tolower(gsub("[-/]", " ", x))
  x <- gsub("\\s+", " ", trimws(x))
  sub("s$", "", x)
}

kk_labels <- unique(rbind(
  data.frame(label = index_b$sub_element, kk_code = index_b$kk_code),
  data.frame(label = index_b$heading, kk_code = index_b$kk_code)
))
kk_labels$norm <- norm_label(kk_labels$label)

row_labels <- rownames(biadj)
row_norm <- norm_label(row_labels)
row_linked <- row_norm %in% kk_labels$norm

boroch_cols <- colnames(biadj)
boroch_kk <- crosswalk$kk_code[match(boroch_cols, crosswalk$boroch_code)]

audit <- expand.grid(notion_row = seq_along(row_labels),
                     def_col = seq_along(boroch_cols))
audit$notion <- row_labels[audit$notion_row]
audit$boroch_code <- boroch_cols[audit$def_col]
audit$kk_code <- boroch_kk[audit$def_col]
audit$kk_code[is.na(audit$kk_code)] <- "unlinked"
audit$boroch_cell <- biadj[cbind(audit$notion_row, audit$def_col)]
audit$row_linked <- row_linked[audit$notion_row]

pair_keys <- unique(paste(kk_labels$norm, kk_labels$kk_code, sep = "\u001f"))
audit$index_b_pair <- paste(row_norm[audit$notion_row], audit$kk_code, sep = "\u001f") %in% pair_keys
audit$index_b_pair[audit$kk_code == "unlinked"] <- FALSE

audit$status <- ifelse(audit$kk_code == "unlinked" & audit$boroch_cell == 1, "boroch_only_def_unlinked",
                ifelse(audit$kk_code == "unlinked", "def_unlinked",
                ifelse(audit$boroch_cell == 1 & audit$index_b_pair, "confirmed",
                ifelse(audit$boroch_cell == 1 & !audit$row_linked, "boroch_only_row_unlinked",
                ifelse(audit$boroch_cell == 1, "boroch_only",
                ifelse(audit$index_b_pair, "index_b_only", "neither"))))))
audit <- audit[, c("notion", "boroch_code", "kk_code", "boroch_cell", "index_b_pair",
                   "row_linked", "status")]
write.csv(audit, file.path(data_dir, "kk-index-b-audit.csv"), row.names = FALSE)

summary_tab <- as.data.frame(table(status = audit$status), stringsAsFactors = FALSE)
names(summary_tab)[2] <- "cells"
write.csv(summary_tab, file.path(data_dir, "kk-index-b-audit-summary.csv"), row.names = FALSE)

writeLines(capture.output(sessionInfo()),
           file.path(data_dir, "build-index-b-crosswalk-sessioninfo.txt"))
