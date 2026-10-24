# Build author/year attributes for the 135 KKCC definition codes by parsing
# the appendix definition tables of ROBAFC-5.1.pdf, then attach them as node
# attributes (author, year, decade) to the definition vertices of both igraph
# objects (kkcc_two_mode.rds and kkcc_two_mode_main.rds) and as columns of
# def_attrs.
#
# Appendix entries look like "A1 Tylor, 1871: 1 <definition text>", but the
# -layout text wraps unpredictably: the "year: page" citation can land on its
# own line or on the next line with an author continuation ("and Kelly,
# 1945a: 82"), re-editions appear as "(1929)13, 1931: 806" (original year in
# parens with footnote marker, then quoted edition year), and authors can be
# split across lines ("Radcliffe– / Brown"). Strategy: per entry, collect
# author chunks from the code line and unindented continuation lines (cut at
# the column gaps that separate author/text), find the first "year:" citation
# token, and cut the author string at the first 4-digit year. Flagged entries
# are hand-corrected in CORRECTIONS below.

pdf <- "ROBAFC-5.1.pdf"
txt <- system2("pdftotext", c("-layout", pdf, "-"), stdout = TRUE)
lines <- txt[710:1459]   # appendix definition tables

code.pat <- "^[[:space:]]*([A-G][0-9]{1,2}(?:[-\u2013][0-9]{1,2})?[a-z]?)[[:space:]]+"
starts <- grep(code.pat, lines)
ends <- c(starts[-1] - 1, length(lines))

chunk <- function(s) {
  # text up to the first run of 2+ spaces (the author/text column gap)
  m <- regexpr("[^ ]([ ]{2,}|$)", s)
  if (m[1] == -1) trimws(s) else trimws(substr(s, 1, m[1]))
}

rec <- do.call(rbind, lapply(seq_along(starts), function(i) {
  ls <- lines[starts[i]:ends[i]]
  code <- gsub("\u2013", "-", sub(paste0(code.pat, ".*$"), "\\1", ls[1]))
  body <- sub(code.pat, "", ls[1])
  ch1 <- chunk(sub("^[[:space:]]+", "", body))
  parts <- ch1
  # append unindented continuation lines (citation wrapped to next line)
  j <- 2
  while (j <= length(ls) && !grepl("^ ", ls[j]) && nchar(trimws(ls[j])) > 0) {
    parts <- paste(parts, chunk(ls[j]))
    j <- j + 1
  }
  ec <- gsub("\\s+", " ", paste(ls, collapse = " "))
  ym <- regexpr("[0-9]{4}[a-z]?:", ec)
  year <- if (ym[1] > 0) substr(ec, ym[1], ym[1] + 3) else NA_character_
  # year suffix (the "a" in "1945a: 82") disambiguates same-year works,
  # e.g. Linton 1945a/1945b or White 1949a/1949b in the supplement bibliography
  suffix <- if (ym[1] > 0 && nchar(regmatches(ec, ym)) > 5)
    substr(regmatches(ec, ym), 5, 5) else NA_character_
  # author: everything before the first 4-digit year in the assembled chunks
  a <- parts
  ypos <- regexpr("[0-9]{4}|\\(", a)
  if (ypos[1] > 0) a <- substr(a, 1, ypos[1] - 1)
  a <- gsub("\u2013", "-", a)
  a <- gsub("-[[:space:]]+", "-", a)
  a <- sub("[,[:space:]]+$", "", a)
  a <- sub(" and$", "", a)
  op <- regmatches(ec, regexpr("\\(([0-9]{4})\\)", ec))
  data.frame(code = code, author = a, year = year, year_suffix = suffix,
             orig = if (length(op)) op else NA_character_)
}))

rec$orig <- as.integer(gsub("[()]", "", ifelse(is.na(rec$orig), "", rec$orig)))

cat("parsed entries:", nrow(rec), "\n")
cat("no citation year found:\n")
print(rec[is.na(rec$year), c("code", "author")], row.names = FALSE)

def_attrs <- readRDS("data/kkcc_two_mode.rds")$def_attrs
cat("codes missing from appendix:",
    paste(setdiff(def_attrs$code, rec$code), collapse = ", "), "\n")
cat("appendix codes not in def_attrs:",
    paste(setdiff(rec$code, def_attrs$code), collapse = ", "), "\n")

# variants (A10a, C1-5a) are absent from the appendix: add rows inheriting
# the base code's citation
miss <- setdiff(def_attrs$code, rec$code)
for (cd in miss) {
  b <- sub("[a-z]$", "", cd)
  if (b %in% rec$code) {
    r <- rec[rec$code == b, ]
    r$code <- cd
    rec <- rbind(rec, r)
  }
}

out <- def_attrs[, "code", drop = FALSE]
out$author <- rec$author[match(out$code, rec$code)]
out$year   <- as.integer(rec$year[match(out$code, rec$code)])
out$year_suffix <- rec$year_suffix[match(out$code, rec$code)]
out$year_orig <- rec$orig[match(out$code, rec$code)]
out$decade <- floor(out$year / 10) * 10

# hand corrections for entries the parser could not recover (authors polluted
# by wrapped definition text); D3-1 has no year in the PDF ("Tozzer, data",
# footnote: "missing (before 1930)"); F4-6 has no appendix entry at all
CORRECTIONS <- list(
  `D1-15` = list(author = "Turney-High"),
  `D2-12` = list(author = "Wilson and Kolb"),
  `D2-16` = list(author = "Aberle et al."),
  `D2-2`  = list(author = "Hart and Pantzer"),
  `D2-3`  = list(author = "Miller and Dollard"),
  `D2-4`  = list(author = "Kluckhohn"),
  `D3-1`  = list(author = "Tozzer"),
  `D4-2`  = list(author = "Katz and Schanck"),
  `E10`   = list(author = "Turney-High"),
  `F4-3`  = list(author = "Blumenthal")
)
for (cd in names(CORRECTIONS)) {
  idx <- out$code == cd
  if (!is.null(CORRECTIONS[[cd]]$author)) out$author[idx] <- CORRECTIONS[[cd]]$author
  if (!is.null(CORRECTIONS[[cd]]$year))   out$year[idx]   <- CORRECTIONS[[cd]]$year
  out$decade <- floor(out$year / 10) * 10
}

cat("\nentries with suspicious author fields (manual review):\n")
susp <- out[is.na(out$author) | out$author == "" |
              grepl("[Cc]ulture|The |The$|[a-z] [a-z] [a-z] ", out$author) |
              length(strsplit(out$author, " ")[[1]]) > 3, ]
print(unique(susp[, c("code", "author", "year")]), row.names = FALSE)

cat("\nentries still missing author or year:\n")
print(out[is.na(out$author) | is.na(out$year), ], row.names = FALSE)
print(out, row.names = FALSE)
write.csv(out, "data/kkcc-definition-years.csv", row.names = FALSE)

# ------------------------------------------------------------ attach to graphs
# add author/year/decade as node attributes on the definition vertices of both
# igraph objects, and as columns of def_attrs (concept vertices stay NA)
for (f in c("data/kkcc_two_mode.rds", "data/kkcc_two_mode_main.rds")) {
  dd <- readRDS(f)
  vi <- match(V(dd$graph)$name, out$code)
  V(dd$graph)$author <- out$author[vi]
  V(dd$graph)$year   <- out$year[vi]
  V(dd$graph)$decade <- out$decade[vi]
  dd$def_attrs$author    <- out$author[match(dd$def_attrs$code, out$code)]
  dd$def_attrs$year      <- out$year[match(dd$def_attrs$code, out$code)]
  dd$def_attrs$year_suffix <- out$year_suffix[match(dd$def_attrs$code, out$code)]
  dd$def_attrs$year_orig <- out$year_orig[match(dd$def_attrs$code, out$code)]
  dd$def_attrs$decade    <- out$decade[match(dd$def_attrs$code, out$code)]
  stopifnot(sum(!is.na(V(dd$graph)$year)) == sum(!is.na(out$year)))
  saveRDS(dd, f)
  cat("attached attributes in", f, "- definition vertices with year:",
      sum(V(dd$graph)$type & !is.na(V(dd$graph)$year)), "of", sum(V(dd$graph)$type), "\n")
}
rm(dd)
