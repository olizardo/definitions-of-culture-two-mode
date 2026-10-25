# Author initials for each work in data/kk-index-b-works.csv, matched by surname
# and year against K&K's bibliography (PDF pp. 190-205). The bibliography is read
# in reading order (pdftotext without -layout), so each year line is attached to
# the author heading above it. Output is candidates, not verified names: a work
# author with more than one initial form, or none, needs a page-image check.

works <- read.csv("data/kk-index-b-works.csv", stringsAsFactors = FALSE)

# split "Kelly & Kluckhohn 1945a" into authors and year
work.rows <- do.call(rbind, lapply(works$work, function(w) {
  yr <- sub(".* ([0-9]{3,4}[a-z]?)$", "\\1", w)
  auth <- trimws(strsplit(sub(" [0-9]{3,4}[a-z]?$", "", w), " & ")[[1]])
  data.frame(work = w, author = auth, year = yr, stringsAsFactors = FALSE)
}))

bib.raw <- system2("pdftotext",
                   c("-f", "190", "-l", "205",
                     "documents/Kroeber-kluckhohn.pdf", "-"),
                   stdout = TRUE)

# collapse OCR letter-spacing ("D o l l a r d" -> "Dollard"), applied repeatedly
unspace <- function(l) {
  for (i in 1:3) l <- gsub("\\b([A-Za-z]) (?=[A-Za-z]\\b)", "\\1", l, perl = TRUE)
  l <- gsub(" ,", ",", l, fixed = TRUE)
  gsub("([A-Z]) \\.", "\\1.", l)
}
bib <- trimws(unspace(bib.raw))
bib <- bib[nzchar(bib)]

# "Surname, I. J." pairs on a heading line that starts with the surname
heading.pairs <- function(l) {
  m <- gregexpr("([A-Z][A-Za-z'-]+(?: [A-Z][A-Za-z'-]+)?), ((?:[A-Z][.] ?)+)", l,
                perl = TRUE)
  hits <- regmatches(l, m)[[1]]
  if (!length(hits)) return(NULL)
  do.call(rbind, lapply(hits, function(h) {
    sur <- sub(",.*$", "", h)
    ini <- gsub("[ ]", "", sub("^[^,]*, ", "", h))
    data.frame(surname = sur, initials = ini, stringsAsFactors = FALSE)
  }))
}

# Columns merge in the text layer, so a line can hold several years. The line is
# split at each year token: headings before a year update the current authors,
# and the year takes the authors in effect at that point.
rows <- list()
cur <- NULL
# A heading is a short whole line. Headings inside titles and editor lists
# ("Spier, A. I. Hallowell") would otherwise replace the current author, so
# only short lines that open with "Surname, initials" are used.
update.cur <- function(cur, l) {
  if (nchar(l) > 35) return(cur)
  hp <- heading.pairs(l)
  if (is.null(hp)) cur else hp
}
for (l in bib) {
  starts <- gregexpr("(?<![0-9A-Za-z])[0-9]{4}[a-z]?[.,]", l, perl = TRUE)[[1]]
  if (starts[1] == -1) {
    cur <- update.cur(cur, l)
    next
  }
  lens <- attr(starts, "match.length")
  for (k in seq_along(starts)) {
    yr <- sub("[.,]$", "", substring(l, starts[k], starts[k] + lens[k] - 1))
    if (!is.null(cur))
      rows[[length(rows) + 1]] <- data.frame(cur, year = yr, stringsAsFactors = FALSE)
  }
}
bib.tab <- do.call(rbind, rows)
bib.tab <- unique(bib.tab)

# match a work author to bibliography rows by surname and year; an author written
# with a prefix of initials ("F. R. Kluckhohn") keeps the surname and the initials
# are read from the bibliography
match.author <- function(a, y) {
  a.clean <- trimws(sub("^([A-Z][.] ?)+", "", a))
  hit <- bib.tab$year == y & (bib.tab$surname == a.clean |
           startsWith(a.clean, paste0(bib.tab$surname, " ")))
  ini <- unique(bib.tab$initials[hit])
  ini
}

res <- do.call(rbind, lapply(seq_len(nrow(work.rows)), function(i) {
  ini <- match.author(work.rows$author[i], work.rows$year[i])
  data.frame(work = work.rows$work[i], author = work.rows$author[i],
             year = work.rows$year[i],
             initials = if (length(ini)) paste(ini, collapse = " | ") else NA_character_,
             n_forms = length(ini),
             stringsAsFactors = FALSE)
}))
res$status <- ifelse(res$n_forms == 0, "none",
               ifelse(res$n_forms == 1, "one form", "ambiguous"))

write.csv(res, "data/kk-index-b-work-authors.csv", row.names = FALSE)
cat("work-author pairs:", nrow(res), "| status:\n")
print(table(res$status))
