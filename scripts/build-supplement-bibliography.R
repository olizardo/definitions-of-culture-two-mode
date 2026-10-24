# Build the Supplement Bibliography of ROBAFC-5.1.pdf (pp. 94-99: the works
# cited in the appendix definition tables) as a structured dataset, match each
# of the 135 KKCC definition codes to its bibliography entry. Writes
# data/kkcc-supplement-bibliography.csv and data/kkcc-definition-biblio.csv;
# graph attributes are attached by scripts/build-two-mode-networks.R.
#
# The bibliography also canonicalizes author names (appendix strings like
# "A. Davis" / "K. Davis" normalize to the bibliography's surname forms) and
# resolves F4-6: the code is used in Table 2 but absent from appendix Table 13.
# Evidence (see match_status = "inferred" below): K&K Part II group F-IV has
# exactly 5 definitions, all five (F4)-tagged works appear in the supplement
# bibliography, K&K's concept index row "acting, A-8, C-I-3, C-I-17, F-IV-5"
# matches Boroch's ACTING row (A8, C1-3, C1-17, F4-6) cell-for-cell, and
# F4-5 occurs nowhere in Table 2 -- so Table 2's F4-6 is an off-by-one slip
# for Boroch's own F4-5 = Kluckhohn & Kelly, 1945a: 87.
#
# Parsing notes: entries start with a 4-digit year (optionally suffixed
# "1924a", optionally followed by a parenthesized re-edition year with stray
# footnote digits, e.g. "1939 (1940)300") or "(???)" (Tozzer, undated).
# Bibliography convention: bare year = first publication, parenthesized year
# = edition quoted in the appendix -- mirrored relative to the appendix's
# "(1929)13, 1931" style (footnote 13), so matching compares def year or
# year_orig against EITHER bib year. Author block = "Surname Initials" chain
# (separators ", " / " and "); "i in." = Polish "et al.", "(red.)" = editor.
# The TRE engine mis-parses "[?][?][?]"-style classes, so perl = TRUE is used
# for the entry-start pattern.

pdf <- "documents/ROBAFC-5.1.pdf"
txt <- system2("pdftotext", c("-layout", pdf, "-"), stdout = TRUE)
txt <- gsub("ﬁ", "fi", txt); txt <- gsub("ﬂ", "fl", txt); txt <- gsub("ﬀ", "ff", txt)

# ------------------------------------------------------- 1. parse bibliography
i0 <- grep("Supplement Bibliography", txt)
i1 <- grep("ENDNOTES", txt)
stopifnot(length(i0) == 1, length(i1) == 1, i1 > i0)
bib.lines <- txt[(i0 + 1):(i1 - 1)]
noise <- grepl("A Formal Concept of Culture in the Classification", bib.lines) |
  grepl("Robert Boroch", bib.lines) |
  grepl("^[0-9]+[[:space:]]+No bibliographical", bib.lines) |
  grepl("^[0-9]+[[:space:]]*$", bib.lines)
bib.lines <- bib.lines[!noise]

start.pat <- "^([0-9]{4}[a-z]?|\\(\\?\\?\\?\\))[[:space:]]"
is.start <- grepl(start.pat, bib.lines, perl = TRUE)
orphans <- which(!is.start & !grepl("^ ", bib.lines) & trimws(bib.lines) != "")
stopifnot(length(orphans) == 0)   # every non-start line is an indented continuation

starts1 <- which(is.start)
ends <- c(starts1[-1] - 1, length(bib.lines))
entries <- vapply(seq_along(starts1), function(i)
  gsub("[[:space:]]+", " ", trimws(paste(bib.lines[starts1[i]:ends[i]], collapse = " "))), "")

grab <- function(pat) {
  m <- regmatches(entries, gregexpr(pat, entries, perl = TRUE))
  vapply(m, function(x) if (length(x)) x else "", "")
}

scan.authors <- function(s) {
  # leading chain of "Surname Initials" tokens; stops at the title
  pat <- "[A-Z][[:alpha:]\u2013-]+[[:space:]]+[A-Z](\\.[A-Z])*\\.?(?![[:alpha:]])"
  out <- character(0); pos <- 1L
  repeat {
    ss <- substr(s, pos, nchar(s))
    m <- regexpr(pat, ss, perl = TRUE)
    if (m[1] != 1L) break
    out <- c(out, sub("[[:space:]]+.*$", "", regmatches(ss, m)))
    pos <- pos + attr(m, "match.length")
    adv <- regexpr("^[,[:space:]]+(and[[:space:]]+)?", substr(s, pos, nchar(s)), perl = TRUE)
    if (adv[1] == -1) break
    pos <- pos + attr(adv, "match.length")
  }
  rest <- trimws(substr(s, pos, nchar(s)))
  if (length(out) == 0) out <- sub(",.*$", "", rest)  # "(???) Tozzer, ..."
  list(surnames = out, rest = rest)
}

after.year <- sub(paste0("^(", "\\([?][?][?]\\)", "|[0-9]{4}[a-z]?)",
                         "[[:space:]]*(\\([0-9]{4}\\)[0-9]*)?[[:space:]]*,?[[:space:]]*"),
                  "", entries, perl = TRUE)
au <- lapply(after.year, scan.authors)

yr   <- grab("^[0-9]{4}")
suf  <- sub("^[0-9]{4}", "", grab("^[0-9]{4}[a-z]"))
yp   <- gsub("[()]", "", grab("\\([0-9]{4}\\)"))
tag  <- gsub("[()]", "", grab("\\([A-G][0-9]?\\)"))
foot <- vapply(regmatches(entries, gregexpr("\\([A-G][0-9]?\\)[0-9]+", entries, perl = TRUE)),
               function(x) if (length(x)) sub("^\\([A-G][0-9]?\\)", "", x) else "", "")
surnames <- lapply(au, `[[`, "surnames")

bib <- data.frame(
  entry_id = sprintf("B%03d", seq_along(entries)),
  year = as.integer(yr),                      # first-publication year
  year_suffix = ifelse(suf == "", NA_character_, suf),
  year_quoted = ifelse(yp == "", NA_integer_, as.integer(yp)),  # parenthesized re-edition
  authors_raw = vapply(surnames, function(x) paste(x, collapse = ", "), ""),
  n_authors = lengths(surnames),
  tag = vapply(tag, function(x) paste(x, collapse = ";"), ""),
  footnote = foot,                            # e.g. "1" = no bibliographical address in K&K
  title_and_rest = vapply(au, function(x) x$rest, ""),
  reference = entries, stringsAsFactors = FALSE
)
stopifnot(nrow(bib) == 163, all(bib$tag != ""))
cat("bibliography entries:", nrow(bib), "\n")
print(table(bib$tag))
write.csv(bib, "data/kkcc-supplement-bibliography.csv", row.names = FALSE)

# ------------------------------------------------- 2. match definitions to bib
dy <- read.csv("data/kkcc-definition-years.csv")
dy$group <- ifelse(grepl("-", dy$code), sub("-.*$", "", dy$code),
                   sub("[0-9]+[a-z]?$", "", dy$code))
def.sur <- lapply(dy$author, function(a) {
  if (is.na(a)) return(character(0))
  a <- gsub("\\b[A-Z]\\.[- ]?", "", a)   # "K. Davis" -> "Davis"
  a <- gsub(" et al\\.", "", a)
  unique(trimws(strsplit(a, " and |, ")[[1]]))
})
names(def.sur) <- dy$code

match.one <- function(code) {
  i <- match(code, dy$code)
  cand <- which(bib$tag == dy$group[i])
  ok <- vapply(cand, function(j) {
    setequal(def.sur[[i]], strsplit(bib$authors_raw[j], ", ")[[1]]) &&
      !is.na(dy$year[i]) &&
      dy$year[i] %in% c(bib$year[j], bib$year_quoted[j]) &&
      (is.na(dy$year_suffix[i]) || is.na(bib$year_suffix[j]) ||
         dy$year_suffix[i] == bib$year_suffix[j])
  }, TRUE)
  cand[ok]
}
mm <- lapply(dy$code, match.one)
names(mm) <- dy$code
stopifnot(all(lengths(mm) <= 1))
cat("uniquely matched:", sum(lengths(mm) == 1), "of", length(mm), "\n")
print(dy$code[lengths(mm) == 0])

def.bib <- data.frame(code = dy$code, entry_id = NA_character_,
                      match_status = NA_character_, stringsAsFactors = FALSE)
for (cd in names(mm)) if (length(mm[[cd]]) == 1) {
  def.bib$entry_id[def.bib$code == cd] <- bib$entry_id[mm[[cd]]]
  def.bib$match_status[def.bib$code == cd] <- "auto"
}
# D3-1 Tozzer: no year in the appendix ("data"); match on surname + tag only
i.row <- def.bib$code == "D3-1"
def.bib$entry_id[i.row] <- bib$entry_id[bib$authors_raw == "Tozzer" & bib$tag == "D3"]
def.bib$match_status[i.row] <- "manual"
# F4-6: resolved as Boroch's F4-5 slip -- Kluckhohn & Kelly 1945a (see header)
i.row <- def.bib$code == "F4-6"
def.bib$entry_id[i.row] <-
  bib$entry_id[bib$year == 1945 & bib$year_suffix == "a" &
                 bib$authors_raw == "Kluckhohn, Kelly" & bib$tag == "F4"]
def.bib$match_status[i.row] <- "inferred"
cat("unmatched after manual/inferred fixes:",
    sum(is.na(def.bib$entry_id)), "\n")
stopifnot(!any(is.na(def.bib$entry_id)))

ji <- match(def.bib$entry_id, bib$entry_id)
canon <- vapply(seq_len(nrow(def.bib)), function(i) {
  s <- strsplit(bib$authors_raw[ji[i]], ", ")[[1]]
  if (grepl("^i in\\.", bib$title_and_rest[ji[i]])) paste0(s[1], " et al.")
  else if (length(s) == 1) s
  else paste(s, collapse = " and ")
}, "")
def.bib$author_canonical <- canon
def.bib$bib_year <- bib$year[ji]
def.bib$bib_ref <- bib$reference[ji]

cat("\ndefinitions per bibliography entry (duplicated works):")
print(table(table(def.bib$entry_id)))
write.csv(def.bib[, c("code", "entry_id", "match_status", "author_canonical",
                      "bib_year", "bib_ref")],
          "data/kkcc-definition-biblio.csv", row.names = FALSE)

# ------------------------- 3. fold the F4-6 resolution into the years table
idx <- dy$code == "F4-6"
dy$author[idx] <- def.bib$author_canonical[idx]        # "Kluckhohn and Kelly"
dy$year[idx]   <- def.bib$bib_year[idx]                # 1945
dy$decade[idx] <- floor(dy$year[idx] / 10) * 10
write.csv(dy, "data/kkcc-definition-years.csv", row.names = FALSE)
cat("F4-6 resolved:", dy$author[idx], dy$year[idx], "\n")

# Graph attributes are attached by scripts/build-two-mode-networks.R.
