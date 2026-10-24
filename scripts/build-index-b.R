# Build the K&K Index A / Index B datasets from the scanned monograph
# (Kroeber & Kluckhohn 1952, Kroeber-kluckhohn.pdf, ABBYY OCR).
#
# Outputs (data/):
#   kk-index-a-authors.csv        author x code (Index A: Authors)
#   kk-index-b-edges.csv          element x code edge list (Index B)
#   kk-index-b-definitions.csv    definition registry (K&K codes)
#   kk-index-b-words-excluded.csv "Words not included in Index B"
#   kk-index-b-ocr-corrections.csv  every non-trivial OCR code correction
#   kk_biadjacency_subelement.{rds,csv}, kk_biadjacency_heading.{rds,csv}
#
# Run order: build-index-b.R -> build-index-b-crosswalk.R -> analysis-index-b.R

suppressPackageStartupMessages(library(igraph))

pdf_path <- "documents/Kroeber-kluckhohn.pdf"
data_dir <- "data"
stopifnot(file.exists(pdf_path))

# ---- 1. Word-level layout, split into columns --------------------------------

# pdftotext -bbox-layout emits one <word> per token with coordinates. Assigning
# each word to a column by its xMin (page midline) avoids the column-gap
# heuristics that fail on this OCR.
read_bbox_words <- function(pdf, first, last) {
  xml <- system2("pdftotext",
                 c("-f", first, "-l", last, "-bbox-layout", pdf, "-"),
                 stdout = TRUE)
  xml <- paste(xml, collapse = "\n")
  pages <- strsplit(xml, "<page ", fixed = TRUE)[[1]][-1]
  page_list <- lapply(seq_along(pages), function(i) {
    pg <- pages[[i]]
    width <- as.numeric(sub('.*width="([0-9.]+)".*', "\\1", pg))
    m <- gregexpr('<word xMin="[0-9.]+" yMin="[0-9.]+" xMax="[0-9.]+" yMax="[0-9.]+">[^<]*</word>', pg)
    w <- regmatches(pg, m)[[1]]
    if (length(w) == 0) return(NULL)
    coords <- regmatches(w, regexec('xMin="([0-9.]+)" yMin="([0-9.]+)".*?>([^<]*)</word>', w, perl = TRUE))
    d <- data.frame(
      page = first + i - 1,
      x = as.numeric(vapply(coords, `[`, "", 2)),
      y = as.numeric(vapply(coords, `[`, "", 3)),
      text = vapply(coords, `[`, "", 4),
      width = width
    )
    d$col <- ifelse(d$x < d$width / 2, "L", "R")
    d$text <- gsub("&amp;", "&", d$text, fixed = TRUE)
    d$text <- gsub("&#39;|&apos;", "'", d$text, perl = TRUE)
    d$text <- gsub("&quot;", '"', d$text, fixed = TRUE)
    d$text <- gsub("&lt;", "<", d$text, fixed = TRUE)
    d$text <- gsub("&gt;", ">", d$text, fixed = TRUE)
    d
  })
  do.call(rbind, page_list)
}

# Collapse words into text lines per (page, column); y is the line's yMin.
column_lines <- function(words) {
  words$row <- round(words$y / 4)
  split_key <- interaction(words$page, words$col, words$row, drop = TRUE)
  out <- lapply(split(words, split_key), function(d) {
    d <- d[order(d$x), ]
    data.frame(page = d$page[1], col = d$col[1], y = min(d$y),
               text = paste(d$text, collapse = " "))
  })
  res <- do.call(rbind, out)
  res[order(res$page, res$col, res$y), ]
}

# ---- 2. Locate regions by text markers (not hard-coded pages) ----------------

locate_pages <- function(pdf) {
  txt <- system2("pdftotext", c("-layout", pdf, "-"), stdout = TRUE)
  pg <- cumsum(grepl("\f", txt)) + 1
  # Headings are letter-spaced in the OCR ("A : A U T H O R S"), so allow
  # optional spaces between letters. Case-sensitive: the headings are capitals.
  sp <- function(s) paste0(strsplit(s, "")[[1]], "\\s*", collapse = "")
  first_after <- function(pattern, after = 0) {
    hit <- which(grepl(pattern, txt, perl = TRUE))
    hit_pages <- pg[hit]
    hit_pages <- hit_pages[hit_pages > after]
    if (length(hit_pages) == 0) stop("marker not found: ", pattern)
    min(hit_pages)
  }
  a <- first_after(sp("A: AUTHORS"))
  b <- first_after(sp("CONCEPTUAL ELEMENTS"), a)
  x <- first_after(sp("WORDS NOT INCLUDED"), b)
  c3 <- first_after(sp("SOME STATEMENTS"), x)
  list(index_a_start = a, index_b_start = b, excluded_start = x, part_iii = c3)
}

# Full-width headings split each column in two. Return the y coordinate of the
# first column line matching a heading pattern on a given page.
heading_y <- function(lines, page, pattern) {
  hits <- lines[lines$page == page & grepl(pattern, lines$text, perl = TRUE), ]
  if (nrow(hits) == 0) stop("heading not found on page ", page, ": ", pattern)
  min(hits$y)
}

# ---- 3. OCR normalization ---------------------------------------------------

# Drop soft hyphens, join words hyphenated across line breaks, and unify dashes.
join_hyphen_wraps <- function(lines) {
  out <- character(0)
  carry <- ""
  for (ln in lines) {
    ln <- gsub("\u00ad", "-", ln)
    if (nzchar(carry)) {
      ln <- paste0(carry, sub("^\\s+", "", ln))
      carry <- ""
    }
    # hyphen at line end: word split ("attitudi-" + "nal") or code split ("D-11-" + "12")
    if (grepl("[A-Za-z0-9]-$", ln, perl = TRUE)) {
      carry <- sub("-$", "", ln)
      next
    }
    out <- c(out, ln)
  }
  if (nzchar(carry)) out <- c(out, carry)
  out
}

# Roman subgroup OCR variants -> canonical I / II / III / IV.
norm_roman <- function(s) {
  # "IH" / "lH" is OCR for III; the H->I step below would otherwise give II.
  if (s %in% c("IH", "lH")) return("III")
  s <- gsub("l", "I", s)
  s <- gsub("1", "I", s)
  s <- gsub("H", "I", s)
  s <- gsub("lV", "IV", s)
  s <- toupper(s)
  if (s %in% c("I", "II", "III", "IV")) return(s)
  s2 <- gsub("[^IV]", "", s)
  if (s2 %in% c("I", "II", "III", "IV")) return(s2)
  NA_character_
}

# Digit OCR variants inside a K&K number. Returns digits, or NA.
norm_number <- function(s) {
  # A lone "n" or "u" in a number slot is OCR for eleven ("A-n" = A-11).
  if (s %in% c("n", "u")) return("11")
  # "j" is deliberately unmapped: on the scan it is read as both 3 and 5, so a
  # guess is wrong about half the time. Such tokens stay unresolved until a
  # page-image check adds them to data/kk-index-b-manual-fixes.csv.
  map <- c(i = "1", l = "1", I = "1", y = "5", "$" = "5", s = "5",
           z = "2", o = "0", O = "0", g = "9", b = "6", t = "1")
  chars <- strsplit(s, "")[[1]]
  out <- vapply(chars, function(ch) {
    if (grepl("[0-9]", ch)) return(ch)
    if (ch %in% names(map)) return(unname(map[ch]))
    NA_character_
  }, "")
  if (anyNA(out)) return(NA_character_)
  paste(out, collapse = "")
}

# Normalize one raw code token, e.g. "F -lV -5" -> "F-IV-5".
# Returns list(code, ok, corrected) so every correction can be audited.
normalize_code <- function(raw) {
  s <- gsub("\\s+", "", raw)
  s <- gsub("[—–]", "-", s)
  m <- regexec("^([A-G])(?:-([IVXLlHi1]{1,4}))?-([0-9A-Za-z$]{1,4})([a-z])?$", s, perl = TRUE)
  p <- regmatches(s, m)[[1]]
  if (length(p) == 0) return(list(code = NA_character_, ok = FALSE, corrected = FALSE))
  group <- p[2]
  sub_raw <- p[3]
  num_raw <- p[4]
  suffix <- p[5]
  # "ioa" / "toa" style: trailing "a" is the suffix letter, not a digit
  if (nzchar(suffix) == FALSE && grepl("a$", num_raw) && nchar(num_raw) > 1) {
    suffix <- "a"
    num_raw <- sub("a$", "", num_raw)
  }
  if (nzchar(sub_raw) && is.na(norm_roman(sub_raw))) {
    return(list(code = NA_character_, ok = FALSE, corrected = FALSE))
  }
  num <- norm_number(num_raw)
  if (is.na(num)) return(list(code = NA_character_, ok = FALSE, corrected = FALSE))
  code <- if (nzchar(sub_raw)) {
    paste0(group, "-", norm_roman(sub_raw), "-", num)
  } else {
    paste0(group, "-", num)
  }
  code <- paste0(code, suffix)
  list(code = code, ok = TRUE, corrected = code != raw)
}

# ---- 4. Tokenization shared by Index A and Index B ---------------------------

is_code_like <- function(tok) grepl("^[A-G]-", tok, perl = TRUE)

# Tokenize one entry body. Parentheticals are replaced by "[[k]]" markers so
# year qualifiers ("(1942)", "(with Kelly, 1945a)") and cross-references
# ("(see learning)") stay attached to their position in the entry.
tokenize_body <- function(body) {
  body <- gsub("[—–]", "-", body)
  body <- gsub("\\s*[~^]\\s*", "-", body, perl = TRUE)
  body <- gsub("\\s*-\\s*", "-", body, perl = TRUE)
  # comma/period glued to a following code: "relationships,-C-I" -> "relationships, C-I"
  body <- gsub("([,;.])-?(?=[A-G]-)", "\\1 ", body, perl = TRUE)
  # OCR sometimes splits a code at the group letter: "F 1-8" -> "F-1-8"
  body <- gsub("(?<=\\b[A-G]) (?=[IVXl1i]{1,4}-[0-9A-Za-z$])", "-", body, perl = TRUE)
  body <- gsub("\\b([A-Z])\\.", "\\1", body, perl = TRUE)  # "Clellan S." initials
  m <- gregexpr("\\([^()]*\\)", body, perl = TRUE)
  parens <- regmatches(body, m)[[1]]
  regmatches(body, m) <- list(paste0(" [[", seq_along(parens), "]] "))
  flags <- character(0)
  if (grepl("[()]", body)) flags <- c(flags, "unbalanced_paren")
  body <- gsub("([,;.])", " \\1 ", body)
  toks <- strsplit(trimws(body), "\\s+")[[1]]
  toks <- toks[nzchar(toks)]
  # "F-I-i 1": a bare 1-2 digit token right after an OCR-damaged code is the
  # rest of the same number.
  merged <- character(0)
  i <- 1
  while (i <= length(toks)) {
    t <- toks[i]
    if (is_code_like(t) && i < length(toks) &&
        grepl("^[0-9]{1,2}$", toks[i + 1]) &&
        grepl("[ilIjyzoOs$]$", t)) {
      t <- paste0(t, toks[i + 1])
      i <- i + 1
    }
    merged <- c(merged, t)
    i <- i + 1
  }
  list(tokens = merged, parens = parens, flags = flags)
}

# ---- 5. Index A: authors ----------------------------------------------------

parse_index_a <- function(lines) {
  txt <- paste(lines, collapse = " ")
  tk <- tokenize_body(txt)
  rows <- list()
  author <- NA_character_
  author_raw <- character(0)
  expect_new <- TRUE
  last_row <- 0
  for (t in tk$tokens) {
    if (startsWith(t, "[[")) {
      k <- as.integer(gsub("\\D", "", t))
      if (last_row > 0) rows[[last_row]]$qualifier <- tk$parens[k]
      next
    }
    if (t == ".") { expect_new <- TRUE; next }
    if (t %in% c(",", ";")) next
    if (is_code_like(t)) {
      nc <- normalize_code(t)
      rows[[length(rows) + 1]] <- data.frame(
        author_raw = author, kk_code = nc$code, raw_code = t,
        qualifier = NA_character_, ok = nc$ok, stringsAsFactors = FALSE)
      last_row <- length(rows)
      expect_new <- FALSE
      next
    }
    if (expect_new) {
      author <- t
      expect_new <- FALSE
    } else {
      author <- paste(author, t)
    }
  }
  out <- do.call(rbind, rows)
  out$author_raw <- trimws(out$author_raw)
  out
}

# ---- 6. Index B: entries ------------------------------------------------------

# A new entry begins at a line that starts with a lowercase heading followed by
# a dash, or with a bare "(see ...)" cross-reference.
is_entry_start <- function(line) {
  # A heading dash is spaced on both sides or sits between two letters; a dash
  # with a space only before it is an OCR code dash ("F —II—5") and is not a start.
  grepl("^[a-z][^—–]*?(\\s[—–]\\s|\\s-\\s-\\s|[a-z][—–][a-z])", line, perl = TRUE) |
    # "(see" starts an entry only when no code precedes it; a cross-reference
    # at the end of a line of codes ("social class, B-22 (see also ...)") does not.
    grepl("^(?![^(]*[A-G] ?[-–—])[a-z][^(]*\\(see", line, perl = TRUE)
}

group_entries <- function(lines) {
  starts <- vapply(lines, is_entry_start, logical(1), USE.NAMES = FALSE)
  starts[1] <- TRUE
  id <- cumsum(starts)
  unname(tapply(lines, id, paste, collapse = " "))
}

# Split an entry into heading and body at its first heading dash.
split_heading <- function(entry) {
  m <- regexpr("\\s[—–]\\s|\\s-\\s-\\s|[a-z][—–](?=[a-z])", entry, perl = TRUE)
  if (m[1] == -1) {
    m2 <- regexpr("\\(see", entry, perl = TRUE)
    if (m2[1] == -1) return(list(heading = NA_character_, body = entry))
    return(list(heading = trimws(substr(entry, 1, m2[1] - 1)),
                body = substr(entry, m2[1], nchar(entry))))
  }
  sep_len <- attr(m, "match.length")
  list(heading = trimws(substr(entry, 1, m[1] - 1)),
       body = substr(entry, m[1] + sep_len, nchar(entry)))
}

clean_name <- function(x) {
  x <- tolower(trimws(gsub("\\s+", " ", x)))
  gsub("[.,;:'’‘]+$", "", x)
}

# Walk the token stream of one entry. Words accumulate into an element name;
# codes attach to the current name; a comma/period/semicolon after a code run
# starts a new name.
parse_entry_codes <- function(body, heading) {
  tk <- tokenize_body(body)
  rows <- list()
  name <- character(0)
  after_code <- FALSE
  flags <- tk$flags
  for (t in tk$tokens) {
    if (startsWith(t, "[[")) next
    if (t %in% c(",", ";", ".")) next
    if (is_code_like(t)) {
      nc <- normalize_code(t)
      nm <- if (length(name)) paste(name, collapse = " ") else clean_name(heading)
      # Unparseable tokens keep a row with kk_code NA so they can be fixed or reported.
      if (!nc$ok) flags <- c(flags, paste0("unparsed_code:", t))
      rows[[length(rows) + 1]] <- data.frame(
        sub_element = clean_name(nm),
        kk_code = if (nc$ok) nc$code else NA_character_,
        ocr_raw = t, corrected = nc$ok && nc$corrected, stringsAsFactors = FALSE)
      after_code <- TRUE
      next
    }
    if (after_code) {
      name <- t
      after_code <- FALSE
    } else {
      name <- c(name, t)
    }
  }
  edges <- if (length(rows)) do.call(rbind, rows) else
    data.frame(sub_element = character(0), kk_code = character(0),
               ocr_raw = character(0), corrected = logical(0))
  list(edges = edges, flags = unique(flags))
}

parse_index_b <- function(lines) {
  entries <- group_entries(lines)
  out <- lapply(entries, function(e) {
    sp <- split_heading(e)
    if (is.na(sp$heading)) {
      return(list(edges = data.frame(), heading = NA, flags = "no_heading"))
    }
    pe <- parse_entry_codes(sp$body, sp$heading)
    if (nrow(pe$edges)) pe$edges$heading <- clean_name(sp$heading)
    list(edges = pe$edges, heading = clean_name(sp$heading), flags = pe$flags,
         entry = e)
  })
  edges <- do.call(rbind, lapply(out, `[[`, "edges"))
  entry_log <- data.frame(
    heading = vapply(out, function(o) o$heading %||% NA_character_, ""),
    flags = vapply(out, function(o) paste(o$flags, collapse = ";"), ""),
    stringsAsFactors = FALSE)
  list(edges = edges, entries = entry_log)
}

`%||%` <- function(a, b) if (is.null(a) || is.na(a[1])) b else a

# ---- 7. Region assembly -----------------------------------------------------

stream <- function(lines, page, col, lo = -Inf, hi = Inf) {
  sel <- lines$page == page & lines$y > lo & lines$y < hi
  if (!is.null(col)) sel <- sel & lines$col == col
  lines$text[sel]
}

assemble_regions <- function(lines, pages) {
  hA <- heading_y(lines, pages$index_a_start, "A\\s*:\\s*A\\s*U\\s*T\\s*H")
  hB <- heading_y(lines, pages$index_b_start, "CEPTU|ELEM")
  hX <- heading_y(lines, pages$excluded_start, "W\\s*O\\s*R\\s*D\\s*S|D\\s*E\\s*D\\s*I\\s*N")
  pA <- pages$index_a_start
  pB <- pages$index_b_start
  pX <- pages$excluded_start
  pEnd <- pages$part_iii - 1
  index_a <- c(stream(lines, pA, "L", lo = hA), stream(lines, pA, "R", lo = hA))
  for (p in seq(pA + 1, pB)) {
    hi <- if (p == pB) hB else Inf
    index_a <- c(index_a, stream(lines, p, "L", hi = hi), stream(lines, p, "R", hi = hi))
  }
  index_b <- c(stream(lines, pB, "L", lo = hB), stream(lines, pB, "R", lo = hB))
  for (p in seq(pB + 1, pX)) {
    if (p == pX) {
      index_b <- c(index_b, stream(lines, p, "L", hi = hX), stream(lines, p, "R", hi = hX))
    } else {
      index_b <- c(index_b, stream(lines, p, "L"), stream(lines, p, "R"))
    }
  }
  excluded <- c(stream(lines, pX, "L", lo = hX), stream(lines, pX, "R", lo = hX))
  for (p in seq(pX + 1, pEnd)) {
    excluded <- c(excluded, stream(lines, p, "L"), stream(lines, p, "R"))
  }
  list(index_a = index_a, index_b = index_b, excluded = excluded)
}

# ---- 8. Driver ----------------------------------------------------------------

# Manual fixes, each verified against the printed page image (see
# docs/PROVENANCE.md). Keys must match exactly; a key with no hit is an error.
apply_index_a_fixes <- function(a, fixes) {
  # Blank fields mean "leave unchanged". Each fix can set the code, the author
  # name, and the year qualifier of the matched row.
  set <- function(x) !is.na(x) & nzchar(x)
  for (i in seq_len(nrow(fixes))) {
    hit <- which(a$author_raw == fixes$author_raw[i] & a$raw_code == fixes$raw_code[i])
    stopifnot(length(hit) >= 1)
    if (set(fixes$kk_code[i])) {
      a$kk_code[hit] <- fixes$kk_code[i]
      a$ok[hit] <- TRUE
    }
    if (set(fixes$author_new[i])) a$author_raw[hit] <- fixes$author_new[i]
    if (set(fixes$qualifier_new[i])) a$qualifier[hit] <- fixes$qualifier_new[i]
  }
  a
}

# Index A rows the OCR text layer omits entirely (checked against the page image).
add_index_a_missing <- function(a, missing) {
  rows <- data.frame(author_raw = missing$author_raw, kk_code = missing$kk_code,
                     raw_code = missing$raw_code, qualifier = missing$qualifier,
                     ok = TRUE, stringsAsFactors = FALSE)
  rbind(a, rows)
}

apply_index_b_fixes <- function(edges, fixes) {
  edges$manual <- FALSE
  for (i in seq_len(nrow(fixes))) {
    hit <- which(edges$heading == fixes$heading[i] &
                 edges$sub_element == fixes$sub_element[i] &
                 edges$ocr_raw == fixes$ocr_raw[i])
    stopifnot(length(hit) >= 1)
    # Sub-element renames correct a name only; they leave the code and flags alone.
    if (identical(fixes$action[i], "rename_sub")) {
      edges$sub_element[hit] <- fixes$new_sub_element[i]
      next
    }
    edges$kk_code[hit] <- fixes$kk_code[i]
    edges$manual[hit] <- TRUE
  }
  edges
}

# Index B edges the OCR text layer loses entirely: a mangled code is glued
# into the following element name, so the printed edge never parses. Each row
# was checked against the page image (see the evidence column).
add_index_b_missing <- function(edges, missing) {
  for (i in seq_len(nrow(missing))) {
    hit <- which(edges$heading == missing$heading[i] &
                 edges$sub_element == missing$sub_element[i] &
                 edges$kk_code == missing$kk_code[i])
    stopifnot(length(hit) == 0)  # an add must not duplicate an existing edge
    edges <- rbind(edges, data.frame(
      heading = missing$heading[i], sub_element = missing$sub_element[i],
      kk_code = missing$kk_code[i], ocr_raw = missing$ocr_glued[i],
      corrected = FALSE, manual = TRUE, stringsAsFactors = FALSE))
  }
  edges
}

# Heading corrections. The text layer puts some entries under the wrong block
# heading (checked against printed pp. 74-78, PDF pp. 77-81; see
# data/kk-index-b-block-map.csv). Applied after the manual fixes, which key on
# the parsed heading. The first element under some blocks also carries the block
# heading text in its name ("carriers of culture-individuals", "systems-systems");
# those are renamed to the printed element name.
apply_heading_corrections <- function(edges) {
  rules <- list(
    # Whole block: every entry printed under "carriers of culture".
    list(from = "capabilities", to = "carriers of culture", where = NULL,
         rename = c("carriers of culture-individuals" = "individuals")),
    # Whole block: printed under "ideas and cognitive processes".
    list(from = "history", to = "ideas and cognitive processes", where = NULL,
         rename = c("ideas and cogni ve processes-ideas" = "ideas")),
    # Printed civilization block lists only the "civilization" element under that
    # heading; the other 36 of 41 print under "common or shared patterns".
    list(from = "civilization", to = "common or shared patterns",
         where = function(s) s != "civilization",
         rename = c("or shared patterns-common" = "common")),
    # Printed systems block: systems-systems, systems of thought, systems of knowledge.
    list(from = "symbols", to = "systems", where = function(s) grepl("^systems", s),
         rename = c("systems-systems" = "systems")),
    # Single entries; the element label is the heading text itself.
    list(from = "feelings", to = "forbidden, the", where = NULL,
         rename = c("forbidden the-" = "forbidden, the")),
    list(from = "people, a", to = "permitted, the", where = NULL,
         rename = c("permitted the-" = "permitted, the"))
  )
  edges$heading_rule <- NA_character_
  for (r in rules) {
    hit <- edges$heading == r$from
    if (!is.null(r$where)) hit <- hit & r$where(edges$sub_element)
    if (!is.null(r$rename)) {
      for (old in names(r$rename)) {
        edges$sub_element[hit & edges$sub_element == old] <- r$rename[[old]]
      }
    }
    edges$heading[hit] <- r$to
    edges$heading_rule[hit] <- paste0(r$from, "->", r$to)
  }
  # Heading names misread by OCR (printed names confirmed on the scan; block map 2026-10-24).
  heading_renames <- c("adjustive-ajjptive function of culture" = "adjustive-adaptive function of culture",
                       "process ts and means" = "processes and means")
  for (old in names(heading_renames)) {
    edges$heading[edges$heading == old] <- heading_renames[[old]]
  }
  message("Heading corrections: ", sum(!is.na(edges$heading_rule)), " edges re-headed")
  edges
}

# Junk sub-element decisions (data/kk-index-b-junk-decisions.csv). Each of the 33
# junk_name edges is mapped to the element printed in its block (basis column;
# PROVENANCE 3.6). Keys use the heading after apply_heading_corrections().
apply_junk_decisions <- function(edges, decisions) {
  for (i in seq_len(nrow(decisions))) {
    hit <- edges$heading == decisions$heading[i] &
           edges$sub_element == decisions$sub_element[i] &
           edges$ocr_raw == decisions$ocr_raw[i]
    stopifnot(length(hit) >= 1)
    edges$heading[hit] <- decisions$new_heading[i]
    edges$sub_element[hit] <- decisions$new_sub_element[i]
    edges$manual[hit] <- TRUE
  }
  edges
}

pages <- locate_pages(pdf_path)
last_page <- pages$part_iii - 1
words <- read_bbox_words(pdf_path, min(unlist(pages)), last_page)
lines <- column_lines(words)
regions <- assemble_regions(lines, pages)

lines_a <- join_hyphen_wraps(regions$index_a)
lines_b <- join_hyphen_wraps(regions$index_b)
lines_x <- join_hyphen_wraps(regions$excluded)

index_a <- apply_index_a_fixes(parse_index_a(lines_a),
                               read.csv("data/kk-index-a-manual-fixes.csv", stringsAsFactors = FALSE))
index_a <- add_index_a_missing(index_a,
                               read.csv("data/kk-index-a-missing-rows.csv", stringsAsFactors = FALSE))
index_b <- parse_index_b(lines_b)
index_b$edges <- apply_index_b_fixes(index_b$edges,
                                     read.csv("data/kk-index-b-manual-fixes.csv", stringsAsFactors = FALSE))
index_b$edges <- add_index_b_missing(index_b$edges,
                                     read.csv("data/kk-index-b-missing-rows.csv", stringsAsFactors = FALSE))
index_b$edges <- apply_heading_corrections(index_b$edges)
index_b$edges <- apply_junk_decisions(index_b$edges,
                                       read.csv("data/kk-index-b-junk-decisions.csv", stringsAsFactors = FALSE))
excluded <- parse_index_b(lines_x)

# ---- 9. Outputs ---------------------------------------------------------------

dir.create(data_dir, showWarnings = FALSE)

index_a_codes <- unique(index_a$kk_code[index_a$ok])
edges <- index_b$edges
edges$in_index_a <- edges$kk_code %in% index_a_codes
edges$parse_flag <- ifelse(!edges$in_index_a, "code_not_in_index_a",
                    ifelse(edges$corrected, "ocr_corrected", "ok"))
edges$parse_flag[edges$manual] <- "manual_fix"
junk <- !edges$manual & !is.na(edges$kk_code) &
  (nchar(edges$sub_element) < 2 | grepl("^[0-9 ]+$", edges$sub_element))
edges$parse_flag[junk] <- "junk_name"
edges$parse_flag[is.na(edges$kk_code)] <- "unresolved"

# Tokens that still have no code are reported, not silently dropped.
unresolved <- unique(edges[is.na(edges$kk_code), c("heading", "sub_element", "ocr_raw", "parse_flag")])
edges <- edges[!is.na(edges$kk_code), ]
edges <- edges[!duplicated(paste(edges$kk_code, edges$heading, edges$sub_element)),
               c("kk_code", "heading", "sub_element", "ocr_raw", "parse_flag")]
write.csv(unresolved, file.path(data_dir, "kk-index-b-unresolved.csv"), row.names = FALSE)

excl <- excluded$edges
excl <- unique(excl[, c("kk_code", "heading", "sub_element", "ocr_raw")])

authors <- index_a[, c("author_raw", "kk_code", "raw_code", "qualifier", "ok")]
authors$qualifier[is.na(authors$qualifier)] <- ""

# Every OCR token whose normalized form differs from the printed text, from
# both indexes. Lets readers audit each correction.
corrections <- unique(rbind(
  data.frame(source = "index_a", raw = index_a$raw_code, normalized = index_a$kk_code,
             stringsAsFactors = FALSE),
  data.frame(source = "index_b", raw = index_b$edges$ocr_raw, normalized = index_b$edges$kk_code,
             stringsAsFactors = FALSE)))
corrections <- corrections[corrections$raw != corrections$normalized |
                             is.na(corrections$normalized), ]
corrections <- corrections[order(corrections$source, corrections$raw), ]

universe <- sort(unique(c(index_a_codes, edges$kk_code)), method = "radix")
group_of <- function(code) sub("-.*", "", code)
subgroup_of <- function(code) {
  parts <- strsplit(code, "-")
  vapply(parts, function(p) if (length(p) == 3) p[2] else NA_character_, "")
}
definitions <- data.frame(
  kk_code = universe,
  group = group_of(universe),
  subgroup = subgroup_of(universe),
  in_index_a = universe %in% index_a_codes,
  in_index_b = universe %in% edges$kk_code,
  n_index_b_elements = as.integer(table(factor(edges$kk_code, levels = universe))),
  index_a_authors = vapply(universe, function(cd) {
    a <- authors[authors$kk_code == cd & authors$ok, ]
    paste(paste0(a$author_raw, ifelse(nzchar(a$qualifier), paste0(" ", a$qualifier), "")),
          collapse = "; ")
  }, ""),
  stringsAsFactors = FALSE
)

write.csv(authors, file.path(data_dir, "kk-index-a-authors.csv"), row.names = FALSE)
write.csv(edges, file.path(data_dir, "kk-index-b-edges.csv"), row.names = FALSE)
write.csv(definitions, file.path(data_dir, "kk-index-b-definitions.csv"), row.names = FALSE)
write.csv(excl, file.path(data_dir, "kk-index-b-words-excluded.csv"), row.names = FALSE)
write.csv(corrections, file.path(data_dir, "kk-index-b-ocr-corrections.csv"), row.names = FALSE)

biadj <- function(rows, cols_col = "kk_code", row_col) {
  rl <- sort(unique(rows[[row_col]]), method = "radix")
  m <- matrix(0L, nrow = length(rl), ncol = length(universe),
              dimnames = list(rl, universe))
  m[cbind(match(rows[[row_col]], rl), match(rows[[cols_col]], universe))] <- 1L
  m
}
m_sub <- biadj(edges, row_col = "sub_element")
m_head <- biadj(edges, row_col = "heading")
saveRDS(m_sub, file.path(data_dir, "kk_biadjacency_subelement.rds"))
saveRDS(m_head, file.path(data_dir, "kk_biadjacency_heading.rds"))
write.csv(data.frame(sub_element = rownames(m_sub), m_sub, check.names = FALSE),
          file.path(data_dir, "kk_biadjacency_subelement.csv"), row.names = FALSE)
write.csv(data.frame(heading = rownames(m_head), m_head, check.names = FALSE),
          file.path(data_dir, "kk_biadjacency_heading.csv"), row.names = FALSE)

writeLines(capture.output(sessionInfo()), file.path(data_dir, "build-index-b-sessioninfo.txt"))
message("Index B: ", nrow(edges), " edges; ", nrow(m_sub), " sub-elements; ",
        nrow(m_head), " headings; ", length(universe), " codes in universe.")
