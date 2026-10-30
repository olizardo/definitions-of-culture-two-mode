# Machine cross-check of Index B heading assignments against the printed text.
#
# This is NOT a human second reader. It reads the PDF text layer (a separate
# code path from the build's parser) and tests, for every edge, whether its K&K
# code appears inside the printed region of its assigned block heading. Edges
# that fail are candidates for a page-image check. A pass shows only that the
# code is printed somewhere in that block, not under the element the edge gives.
#
# Inputs:  documents/Kroeber-kluckhohn.pdf, data/kk-index-b-edges.csv,
#          data/kk-index-b-block-map.csv
# Outputs: data/kk-index-b-block-check.csv          (one row per edge)
#          data/kk-index-b-block-check-summary.csv  (one row per block)

pdf_path <- "documents/Kroeber-kluckhohn.pdf"
block_map <- read.csv("data/kk-index-b-block-map.csv", stringsAsFactors = FALSE)
blocks <- block_map[block_map$kind == "block", ]
blocks <- blocks[order(blocks$pdf_page, blocks$printed_page), ]

# ---- 1. Reading-order token stream: left column, then right, per page -------

read_stream <- function(pdf, first, last) {
  xml <- paste(system2("pdftotext", c("-f", first, "-l", last, "-bbox-layout", pdf, "-"),
                       stdout = TRUE), collapse = "\n")
  pages <- strsplit(xml, "<page ", fixed = TRUE)[[1]][-1]
  out <- lapply(seq_along(pages), function(i) {
    pg <- pages[[i]]
    width <- as.numeric(sub('.*width="([0-9.]+)".*', "\\1", pg))
    w <- regmatches(pg, gregexpr('<word xMin="[0-9.]+" yMin="[0-9.]+" [^>]*>[^<]*</word>', pg))[[1]]
    d <- data.frame(
      x = as.numeric(sub('.*xMin="([0-9.]+)".*', "\\1", w)),
      y = as.numeric(sub('.*yMin="([0-9.]+)".*', "\\1", w)),
      text = sub(".*>([^<]*)</word>$", "\\1", w), stringsAsFactors = FALSE)
    d$text <- gsub("&amp;", "&", d$text, fixed = TRUE)
    d$col <- ifelse(d$x < width / 2, 1, 2)
    d$row <- round(d$y / 4)
    d$page <- first + i - 1
    d
  })
  do.call(rbind, out)
}

words <- read_stream(pdf_path, min(blocks$pdf_page), max(blocks$pdf_page))
words <- words[order(words$page, words$col, words$row, words$x), ]
stream <- paste(words$text, collapse = " ")

# ---- 2. Locate each block heading in the stream, in printed order -----------

esc <- function(s) gsub("([][{}()+*^$|\\\\?.])", "\\\\\\1", s, perl = TRUE)
# OCR can insert spaces inside words, so allow optional spaces between characters.
loose <- function(s) {
  chars <- strsplit(s, "")[[1]]
  paste(vapply(chars, function(ch) if (ch == " ") "\\s*" else paste0(esc(ch), "\\s*"), ""),
        collapse = "")
}
# A heading counts only when a dash follows it directly; cross-references such as
# "generations (see carriers of culture)" do not match.
heading_regexes <- function(h) {
  h <- tolower(h)
  c(paste0(loose(h), "[\u2014\u2013-]"),
    paste0(loose(substr(h, 1, 10)), "[^\u2014\u2013\n]{0,40}[\u2014\u2013-]"))
}

start_pos <- rep(NA_integer_, nrow(blocks))
match_kind <- rep(NA_character_, nrow(blocks))
cursor <- 1
for (i in seq_len(nrow(blocks))) {
  for (k in 1:2) {
    m <- regexpr(heading_regexes(blocks$printed_heading[i])[k], substring(stream, cursor),
                 ignore.case = TRUE, perl = TRUE)
    if (m[1] != -1) {
      start_pos[i] <- cursor + m[1] - 1
      match_kind[i] <- c("full", "prefix")[k]
      cursor <- start_pos[i] + attr(m, "match.length")
      break
    }
  }
}
blocks$start <- start_pos
blocks$match_kind <- match_kind

# Each block runs from its heading to the next located heading (or end of text).
located <- blocks[!is.na(blocks$start), ]
located <- located[order(located$start), ]
located$end <- c(located$start[-1] - 1, nchar(stream))
# Remove spaces only around dashes ("C - I - 14" -> "c-i-14"); keep word
# boundaries so adjacent codes such as "C-I-14 C-I-19" stay separate.
norm_text <- function(x) tolower(gsub("\\s*([-\u2013\u2014])\\s*", "\\1", x, perl = TRUE))
region_norm <- setNames(
  lapply(seq_len(nrow(located)), function(i) {
    norm_text(substr(stream, located$start[i], located$end[i]))
  }),
  located$printed_heading)

# ---- 3. Test each edge's code inside its block's printed region -------------

edges <- read.csv("data/kk-index-b-edges.csv", stringsAsFactors = FALSE)
# Edge headings that are OCR variants of a printed block name map to that name.
variant <- block_map[block_map$kind == "block" & !is.na(block_map$edges_heading) &
                     block_map$edges_heading != block_map$printed_heading, ]
edges$block_key <- edges$heading
for (i in seq_len(nrow(variant))) {
  edges$block_key[edges$heading == variant$edges_heading[i]] <- variant$printed_heading[i]
}

# Digits as the scan prints them: each digit accepts its common look-alikes.
digit_class <- c("0" = "[0o]", "1" = "[1ilt]", "2" = "[2z]", "3" = "[3j]", "4" = "[4]",
                 "5" = "[5ys$]", "6" = "[6b]", "7" = "[7]", "8" = "[8]", "9" = "[9g]")
# OCR-tolerant regex for one K&K code: group letter, optional roman part, number,
# optional suffix letter. Dashes may be missing or printed as dashes or em dashes.
code_regex <- function(code) {
  parts <- strsplit(tolower(code), "-", fixed = TRUE)[[1]]
  piece <- vapply(parts[-1], function(p) {
    if (grepl("^[iv]+$", p)) return("[ivxl1i]{1,3}")
    # The scan prints eleven as a lone "n" or "u" (see norm_number() in build-index-b.R).
    if (p == "11") return("(?:[1ilt]\\s?[1ilt]|[nu])")
    chars <- strsplit(p, "")[[1]]
    paste(vapply(chars, function(ch) {
      if (ch %in% names(digit_class)) return(paste0(digit_class[[ch]], "\\s?"))
      if (ch == "a") return("[a3]")
      esc(ch)
    }, ""), collapse = "")
  }, "")
  # OCR also prints a tilde for a dash ("B~4a") and sometimes a space inside a code.
  sep <- "\\s?[-\u2013\u2014~]?\\s?"
  paste0("(?<![a-z0-9])", esc(parts[1]), sep, paste(piece, collapse = sep), "(?![0-9a-z])")
}

code_in_region <- function(code, region) {
  if (is.null(region) || is.na(region)) return(NA)
  # Split variants such as A-3(a) print as their K&K code (PROVENANCE 17).
  code <- sub("\\([ab]\\)$", "", code)
  grepl(code_regex(code), region, perl = TRUE)
}

edges$code_in_block <- vapply(seq_len(nrow(edges)), function(i) {
  r <- region_norm[[edges$block_key[i]]]
  if (is.null(r)) return(NA)
  code_in_region(edges$kk_code[i], r)
}, logical(1))

# A code that fails its own block but prints elsewhere in the stream is a
# candidate heading error; one that prints nowhere is an unresolved OCR form.
stream_norm <- norm_text(stream)
edges$printed_anywhere <- vapply(edges$kk_code, function(cd) code_in_region(cd, stream_norm), logical(1))

edges$check <- ifelse(is.na(edges$code_in_block), "no_printed_block",
               ifelse(edges$code_in_block, "code_in_block",
               ifelse(edges$printed_anywhere, "code_in_other_block", "code_not_printed")))

check <- edges[, c("kk_code", "heading", "sub_element", "parse_flag", "check")]
write.csv(check, "data/kk-index-b-block-check.csv", row.names = FALSE)

by_block <- as.data.frame.matrix(table(check$heading, check$check))
by_block$heading <- rownames(by_block)
rownames(by_block) <- NULL
write.csv(by_block, "data/kk-index-b-block-check-summary.csv", row.names = FALSE)

message("Blocks located: ", sum(!is.na(blocks$start)), " of ", nrow(blocks),
        if (any(is.na(blocks$start)))
          paste0("; not located: ", paste(blocks$printed_heading[is.na(blocks$start)], collapse = ", ")) else "")
message("Edges: ", nrow(check), "; code in printed block: ", sum(check$check == "code_in_block"),
        "; in another block: ", sum(check$check == "code_in_other_block"),
        "; not printed (OCR form unresolved): ", sum(check$check == "code_not_printed"),
        "; no printed block: ", sum(check$check == "no_printed_block"))
