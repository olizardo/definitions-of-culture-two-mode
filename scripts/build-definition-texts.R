# Extract the full definition text for each KKCC definition code from the
# appendix definition tables of ROBAFC-5.1.pdf (same entry spans as
# build-definition-years.R). Writes data/kkcc-definition-texts.csv and prints
# every extracted text for manual review; entries the rules cannot recover are
# fixed in CORRECTIONS below.
#
# Layout quirks handled:
# - "year: page" citations mark where the definition text starts; the page
#   number itself can wrap to the next line, optionally with a note like
#   "(Glossary)" or a roman-numeral page ("xiii", "xiii–xiv")
# - Boroch's marginal cross-references ("or gr. B", "(1. sentence)", "; or D1")
#   sit left of the text column and are stripped
# - authors can be split from their text by a column gap or run into it
#   ("Kluckhohn, Culture consists..."); on the code line we cut the author at
#   the first 2+ space gap, falling back to the first comma
# - page headers ("Robert Boroch"), footnotes ("missing (before 1930)"), and
#   table banners are skipped; stray page numbers wrapped into the text
#   ("the 77 sum total") are removed; en-dashes split by line wraps are
#   rejoined ("handed– down" -> "handed–down")

txt <- system2("pdftotext", c("-layout", "documents/ROBAFC-5.1.pdf", "-"), stdout = TRUE)
lines <- txt[710:1459]   # appendix definition tables

code.pat <- "^[[:space:]]*([A-G][0-9]{1,2}(?:[-\u2013][0-9]{1,2})?[a-z]?)[[:space:]]+"
starts <- grep(code.pat, lines)
ends <- c(starts[-1] - 1, length(lines))

JUNK <- c("^Table [0-9]+:", "^Group [A-G]$", "^[A-Za-z ]+Definitions$",
          "^Incomplete definitions$", "^missing \\(before 1930\\)$",
          "Robert Boroch", "A Formal Concept of Culture",
          "^tions$", "^[[:space:]]*$")

# strip leading marginal/page tokens from a column-0 continuation line;
# returns "" when nothing but tokens remains
strip.margin <- function(s) {
  repeat {
    s0 <- s
    s <- sub("^[,;]?[[:space:]]*[0-9\u2013-]{1,6}[[:space:]]*(\\([A-Za-z]+\\))?[[:space:]]*", "", s, perl = TRUE)
    s <- sub("^[[:space:]]*\\([0-9]{4}\\)[0-9]*,?[[:space:]]*", "", s, perl = TRUE)
    s <- sub("^[[:space:]]*;?[[:space:]]*or (gr\\. )?[A-G][0-9]?( \\([0-9]\\. sentence\\))?[[:space:]]*", "", s, perl = TRUE)
    s <- sub("^[[:space:]]*\\([0-9]\\. sentence\\)[[:space:]]*", "", s, perl = TRUE)
    # roman-numeral page markers only when followed by a column gap
    m <- regexpr("^[ivxlcdm]+([\u2013-][ivxlcdm]+)*[[:space:]]{2,}", s, perl = TRUE)
    if (m[1] > 0) s <- trimws(substring(s, m[1] + attr(m, "match.length")))
    # author-continuation lines: "Moore,  knowledge..." or a lone "Moore,"
    m <- regexpr("^[A-Z][a-zA-Z]+,[[:space:]]{2,}", s, perl = TRUE)
    if (m[1] > 0) s <- trimws(substring(s, m[1] + attr(m, "match.length")))
    s <- sub("^[A-Z][a-zA-Z]+,$", "", s, perl = TRUE)
    if (s == s0) break
  }
  trimws(s)
}

grab <- function(ls) {
  pieces <- character(0)
  for (k in seq_along(ls)) {
    l <- ls[k]
    if (k == 1) l <- sub(code.pat, "", l, perl = TRUE)
    if (any(grepl(JUNK, trimws(l), perl = TRUE))) next
    ym <- regexpr("[0-9]{4}[a-z]?:", l, perl = TRUE)
    if (ym[1] > 0) {
      # citation on this line: text follows, after a possibly wrapped page number
      t <- substring(l, ym[1] + attr(ym, "match.length"))
      t <- sub("^[[:space:]]*[0-9\u2013-]{1,5}[[:space:]]*(\\([A-Za-z]+\\))?[[:space:]]*", "", t, perl = TRUE)
      t <- sub("^[[:space:]]*\\([A-Za-z]+\\)[[:space:]]*", "", t, perl = TRUE)
    } else if (k > 1) {
      t <- strip.margin(trimws(l))
    } else if (k == 1) {
      # code line without citation: cut the author at the column gap, else at
      # the first comma
      s <- trimws(l)
      t <- sub("^[^,]*?[[:space:]]{2,}", "", s, perl = TRUE)
      if (t == s) t <- sub("^[^,]*,[[:space:]]*", "", s, perl = TRUE)
    } else {
      t <- trimws(l)   # indented continuation: pure text
    }
    if (nchar(trimws(t)) > 0) pieces <- c(pieces, trimws(t))
  }
  t <- paste(pieces, collapse = " ")
  t <- gsub("\uFB01", "fi", t, perl = TRUE)
  t <- gsub("\uFB02", "fl", t, perl = TRUE)
  t <- gsub("([A-Za-z])\u2013 ", "\\1\u2013", t)   # rejoin en-dashes split by wraps
  t <- gsub(" [0-9]{1,4}\\)? ", " ", paste0(" ", t, " "), perl = TRUE)   # stray page numbers
  # running headers and table banners merged into text lines at the page margin
  t <- trimws(t)
  t <- gsub(" ?(Group [A-G] [A-Za-z]+ Definitions|Robert Boroch|culture as a problem-solving device|A Formal Concept of Culture in the Classification of Alfred L\\. Kroeber\\.+) ?", "", t, perl = TRUE)
  t <- sub("\\.? *or artifact$", ".", t, perl = TRUE)   # marginal note merged into E10's end
  t <- sub(" \\.$", ".", t, perl = TRUE)   # stray period left by a removed header
  # doubled-period collapse disabled: D1-8 ends in ".." in the committed CSV; check the page image before enabling
  gsub("\\s+", " ", t, perl = TRUE)
}

codes_all <- colnames(readRDS("data/kkcc_two_mode.rds")$biadjacency)
codes <- gsub("\u2013", "-", sub(paste0(code.pat, ".*$"), "\\1", lines[starts]), perl = TRUE)
out <- data.frame(code = codes_all, stringsAsFactors = FALSE)
out$text <- vapply(seq_along(starts), function(i) grab(lines[starts[i]:ends[i]]), "")[match(out$code, codes)]
# variants absent from the appendix inherit the base code's text
idx <- is.na(out$text)
for (i in which(idx)) {
  b <- sub("[a-z]$", "", out$code[i], perl = TRUE)
  if (b %in% out$code) out$text[i] <- out$text[match(b, out$code)]
}

# Table 2 columns with no appendix entry of their own carry another entry's
# text; text_note says which. F4-6 is Boroch's off-by-one slip for F4-5
# (PROVENANCE section 5), so it carries F4-5's text, which lives in the
# appendix-only set, not under a Table 2 code.
out$text_note <- ""
COPIED <- c(A10a = "A10", `C1-5a` = "C1-5", `F4-6` = "F4-5")
for (cd in names(COPIED)) {
  out$text_note[out$code == cd] <-
    sprintf("Text copied from %s: no appendix entry of its own (PROVENANCE sections 2 and 5).", COPIED[[cd]])
}
aot <- read.csv("data/kkcc-appendix-only-texts.csv", stringsAsFactors = FALSE)
out$text[out$code == "F4-6"] <- aot$text[aot$code == "F4-5"]
stopifnot(!any(is.na(out$text)), all(nzchar(trimws(out$text))))

# hand corrections for entries the rules cannot recover
CORRECTIONS <- c(
  `A13`  = "It [culture] is the complex whole of the system of concepts and usages, organizations, skills, and instruments by means of which mankind deals with physical, biological, and human nature in satisfaction of its needs.",
  `C1-1` = "The mode of life followed by the community or the tribe is regarded as a culture [...] [It] includes all standardized social procedures [...] a tribal culture is [...] the aggregate of standardized beliefs and procedures followed by the tribe.",
  `D2-2` = "Culture consists in behavior patterns transmitted by imitation or intuition. [...] Culture includes all behavior patterns socially acquired and socially transmitted.",
  `D2-3` = "Culture, as conceived by social scientists, is a statement of the design of the human maze, of the type of reward involved, and of what responses are to be rewarded.",
  `D2-10` = "Culture is the sum total of learned behavior patterns which are characteristic of the members of a society and which are, therefore, not the result of biological inheritance.",
  `D2-16` = "Culture is socially transmitted behavior conceived as an abstraction from concrete social groups.",
  `D3-1` = "Culture is the rationalization of habit.",
  `D3-2` = "Culture: forms of habitual behavior common to a group, community, or society. It is made up of material and non-material traits.",
  `D3-3` = "[...] culture, the traditional patterns of action which constitute a major portion of the established habits with which an individual enters any social situation."
)
for (cd in names(CORRECTIONS)) out$text[out$code == cd] <- CORRECTIONS[[cd]]

# review print
cat(sprintf("--- %s ---\n%s\n", out$code, out$text), sep = "")
write.csv(out[c("code", "text", "text_note")], "data/kkcc-definition-texts.csv", row.names = FALSE)
cat("wrote data/kkcc-definition-texts.csv,", nrow(out), "rows\n")
