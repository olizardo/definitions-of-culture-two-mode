# Citation table for the Index B works (data/kk-index-b-works.csv). Each work is
# matched on surname(s), initials and year to two bibliographies:
#   1. K&K's bibliography, from the ABBYY text layer of documents/Kroeber-kluckhohn.pdf
#      (PDF pp. 190-208). Entries are anchored on year lines. The text layer is
#      two-column, so an author header can sit a few lines above its year line; the
#      match looks back up to 8 lines and takes the closest surname. Where a work
#      label carries initials ("Kluckhohn C. 1951a"), the header must show them too.
#   2. Boroch's supplement bibliography, data/kkcc-supplement-bibliography.csv.
# Where K&K has several candidates, the one whose title shares a word with Boroch's
# reference is preferred. Title agreement is a check, not proof. Page-image checks
# (data/kk-index-b-work-citations-page-checks.csv) override the automatic match.
# Writes data/kk-index-b-work-citations.csv. Run from the project root.

works <- read.csv("data/kk-index-b-works.csv", stringsAsFactors = FALSE)
supp <- read.csv("data/kkcc-supplement-bibliography.csv", stringsAsFactors = FALSE)
pdf <- "documents/Kroeber-kluckhohn.pdf"
kk_pages <- 190:208

kk <- do.call(rbind, lapply(kk_pages, function(p) {
  l <- system2("pdftotext", c("-f", p, "-l", p, "-raw", pdf, "-"), stdout = TRUE)
  l <- gsub("\uFB01", "fi", l, fixed = TRUE)
  l <- gsub("\uFB02", "fl", l, fixed = TRUE)
  data.frame(pdf_page = p, line = trimws(l), stringsAsFactors = FALSE)
}))
kk <- kk[nzchar(kk$line), ]
row.names(kk) <- NULL
kk$nospace <- gsub("\\s+", "", kk$line)

# OCR year line: "1948.", "19 41b .", "19J1." etc. Spaces are removed first.
yre <- "^([1lI][0-9OoJjSsI$:lL|]{3})([a-z]?)[.,]"
mm <- regmatches(kk$nospace, regexec(yre, kk$nospace, perl = TRUE))
kk$is_year <- lengths(mm) > 0
kk$year_raw <- vapply(mm, function(x) if (length(x)) x[2] else NA_character_, character(1))
kk$suffix <- vapply(mm, function(x) if (length(x) && nzchar(x[3])) x[3] else NA_character_, character(1))

ocr <- c(O = "0", o = "0", J = "5", j = "5", S = "5", s = "5", I = "1", l = "1",
         L = "1", "|" = "1", "$" = "4", ":" = "4")
norm_year <- function(x) {
  if (is.na(x)) return(NA_character_)
  ch <- strsplit(x, "")[[1]]
  hit <- ch %in% names(ocr)
  ch[hit] <- ocr[ch[hit]]
  y <- paste(ch, collapse = "")
  if (grepl("^1[0-9]{3}$", y)) y else NA_character_
}

yi <- which(kk$is_year)
nxt <- c(yi[-1], nrow(kk) + 1)
idx_range <- function(a, b) if (b >= a) a:b else integer(0)
kk_ent <- do.call(rbind, lapply(seq_along(yi), function(j) {
  i <- yi[j]
  t_idx <- idx_range(i + 1, min(i + 3, nxt[j] - 3, nrow(kk)))
  data.frame(
    pdf_page = kk$pdf_page[i],
    line_idx = i,
    year_line = kk$line[i],
    year_norm = norm_year(kk$year_raw[i]),
    suffix = kk$suffix[i],
    snippet = paste(kk$line[t_idx], collapse = " "),
    stringsAsFactors = FALSE
  )
}))
kk_line_norm <- gsub("[^a-z]", "", tolower(kk$line))

norm_name <- function(x) gsub("[^a-z]", "", tolower(x))

# Fuzzy surname test: edit distance <= 20% of the surname length, over substrings
# of the line that are close to the surname's length.
has_name <- function(h, s) {
  k <- nchar(s)
  if (k < 2 || nchar(h) < k - 1) return(FALSE)
  maxd <- max(1, floor(0.2 * k))
  for (L in (k - 1):(k + 1)) {
    n <- nchar(h)
    if (L < 2 || L > n) next
    subs <- substring(h, 1:(n - L + 1), L:n)
    if (min(adist(s, subs)) <= maxd) return(TRUE)
  }
  FALSE
}

# Distance from year line i back to the nearest line (within 8) containing surname s.
near <- function(i, s) {
  if (i <= 1) return(NA_real_)
  js <- max(1, i - 8):(i - 1)
  hits <- js[vapply(js, function(j) has_name(kk_line_norm[j], s), logical(1))]
  if (!length(hits)) NA_real_ else i - max(hits)
}

# Does a header line show surname s followed by the initials (e.g. "KLUCKHOHN, C.")?
# Punctuation and spaces are dropped, so "K l u c k h o h n , C ." reads "kluckhohn,c".
init_hit <- function(line, s, letters) {
  h <- tolower(gsub("[^A-Za-z,.]", "", line))
  n <- nchar(h)
  k <- nchar(s)
  maxd <- max(1, floor(0.2 * k))
  pat <- paste0("^[,.]*", paste(strsplit(letters, "")[[1]], collapse = "[.]?"))
  for (L in (k - 1):(k + 1)) {
    if (L < 2 || L > n) next
    st <- 1:(n - L + 1)
    subs <- substring(h, st, st + L - 1)
    tails <- substring(h, st + L, st + L + 15)
    if (any(adist(s, subs)[1, ] <= maxd & grepl(pat, tails))) return(TRUE)
  }
  FALSE
}

stop_words <- c("york", "american", "journal", "press", "chicago", "boston",
                "their", "these", "which", "review", "mimeographed", "committee")
title_words <- function(x) {
  w <- unique(tolower(unlist(regmatches(x, gregexpr("[A-Za-z]{5,}", x)))))
  setdiff(w, stop_words)
}
title_agree <- function(bref, kk_text) {
  if (is.na(bref) || !nzchar(bref)) return(NA)
  length(intersect(title_words(bref), title_words(kk_text))) > 0
}

# Work label -> surnames and initials. Initials are the initial-like tokens
# directly before or after the surname ("F. R. Kluckhohn", "Kluckhohn C.",
# "Radcliffe-Brown, A. R."). Surnames without initials get "".
parse_work <- function(w) {
  yr <- regmatches(w, regexpr("[0-9]{4}[a-z]?$", w))
  stem <- sub("\\s*[0-9]{4}[a-z]?$", "", w)
  parts <- trimws(strsplit(stem, "\\s*&\\s*")[[1]])
  ini_re <- "^([A-Z][.]?)+,?$"
  sn_ini <- lapply(parts, function(p) {
    tk <- strsplit(p, " ")[[1]]
    is_ini <- grepl(ini_re, tk)
    s_idx <- which(!is_ini)[1]
    lead <- if (s_idx > 1) tk[seq_len(s_idx - 1)] else character(0)
    after <- if (s_idx < length(tk)) tk[(s_idx + 1):length(tk)] else character(0)
    after <- after[seq_len(sum(cumprod(grepl(ini_re, after))))]
    list(surname = sub(",$", "", tk[s_idx]),
         letters = tolower(gsub("[^A-Za-z]", "", paste(c(lead, after), collapse = ""))))
  })
  list(year = yr, base = substr(yr, 1, 4), suffix = sub("^[0-9]{4}", "", yr),
       surnames = vapply(sn_ini, `[[`, character(1), "surname"),
       letters = vapply(sn_ini, `[[`, character(1), "letters"))
}

kk_match <- function(p, bref) {
  cand <- which(!is.na(kk_ent$year_norm) & kk_ent$year_norm == p$base)
  if (nzchar(p$suffix)) {
    cand <- cand[is.na(kk_ent$suffix[cand]) | kk_ent$suffix[cand] == p$suffix]
  }
  none <- list(status = "not_found", n = 0, idx = NA_integer_, agree = NA, cands = "", ini = "")
  if (!length(cand)) return(none)
  d <- vapply(cand, function(k) vapply(p$surnames, function(s)
    near(kk_ent$line_idx[k], norm_name(s)), numeric(1)), numeric(length(p$surnames)))
  d <- matrix(d, nrow = length(p$surnames))
  all_ok <- colSums(is.na(d)) == 0
  first_ok <- !is.na(d[1, ])
  agree <- vapply(cand, function(k)
    isTRUE(title_agree(bref, paste(kk_ent$year_line[k], kk_ent$snippet[k]))), logical(1))
  ini_ok <- vapply(seq_along(cand), function(j) {
    if (!all_ok[j]) return(FALSE)
    i <- kk_ent$line_idx[cand[j]]
    all(vapply(seq_along(p$surnames), function(s_i) {
      if (!nzchar(p$letters[s_i])) return(TRUE)
      if (i <= 1) return(FALSE)
      any(vapply(max(1, i - 8):(i - 1), function(l)
        init_hit(kk$line[l], norm_name(p$surnames[s_i]), p$letters[s_i]), logical(1)))
    }, logical(1)))
  }, logical(1))
  ini_note <- ""
  use_ok <- all_ok & ini_ok
  if (!any(use_ok) && any(all_ok)) {
    use_ok <- all_ok
    ini_note <- "initials not confirmed in header"
  }
  if (any(use_ok)) {
    pool <- which(use_ok)
    score <- colSums(d)[pool]
    best <- pool[order(!agree[pool], score)][1]
    return(list(status = if (sum(use_ok) == 1) "matched" else "matched_multiple",
                n = sum(use_ok), idx = cand[best], agree = agree[best],
                cands = paste(kk_ent$year_line[cand[pool]], collapse = " || "), ini = ini_note))
  }
  if (any(first_ok)) {
    pool <- which(first_ok)
    return(list(status = "partial_authors", n = length(pool), idx = cand[pool[1]],
                agree = agree[pool[1]], cands = "", ini = ""))
  }
  list(status = "year_only_no_author", n = length(cand), idx = cand[1],
       agree = FALSE, cands = "", ini = "")
}

supp$year_base <- as.integer(supp$year)
piece_names <- lapply(supp$authors_raw, function(a) {
  pcs <- trimws(strsplit(a, ",|\\band\\b|&")[[1]])
  norm_name(sub(" .*$", "", pcs))
})
supp$abbrev <- grepl("\u2026", supp$reference, fixed = TRUE)
supp$ref_clean <- sub("\\s*\\([A-Za-z0-9]+\\)\\.?$", "", supp$reference)

bor_match <- function(p) {
  cand <- which(supp$year_base == as.integer(p$base))
  if (nzchar(p$suffix)) {
    cand <- cand[is.na(supp$year_suffix[cand]) | supp$year_suffix[cand] == p$suffix]
  }
  none <- list(status = "not_found", n = 0, idx = NA_integer_, alt = "")
  if (!length(cand)) return(none)
  sn <- norm_name(p$surnames)
  all_ok <- vapply(cand, function(i) all(sn %in% piece_names[[i]]), logical(1))
  first_ok <- vapply(cand, function(i) sn[1] %in% piece_names[[i]], logical(1))
  if (!any(first_ok)) return(none)
  if (!any(all_ok)) {
    pool <- cand[first_ok]
    return(list(status = "partial_authors", n = length(pool), idx = pool[1], alt = ""))
  }
  ok <- cand[all_ok]
  complete <- ok[!supp$abbrev[ok]]
  pool <- if (length(complete)) complete else ok
  distinct <- unique(supp$ref_clean[pool])
  status <- if (!length(complete)) "matched_abbrev_only" else
    if (length(distinct) == 1) "matched" else "matched_multiple"
  alt <- if (length(distinct) > 1) paste(distinct[-1], collapse = " | ") else ""
  list(status = status, n = length(distinct), idx = pool[1], alt = alt)
}

res <- do.call(rbind, lapply(seq_len(nrow(works)), function(r) {
  w <- works$work[r]
  p <- parse_work(w)
  b <- bor_match(p)
  bref <- if (is.na(b$idx)) NA_character_ else supp$ref_clean[b$idx]
  k <- kk_match(p, bref)
  has_kk <- k$status %in% c("matched", "matched_multiple")
  has_b <- b$status %in% c("matched", "matched_multiple", "matched_abbrev_only")
  check <- if (has_kk && has_b) {
    if (isTRUE(k$agree)) "agree" else "disagree"
  } else NA_character_
  overall <- if (has_kk && has_b) paste0("both_", check) else if (has_kk) "kk_only" else
    if (has_b) "boroch_only" else "neither"
  notes <- character(0)
  if (k$status == "partial_authors") notes <- c(notes, "K&K: first surname found, co-author not found")
  if (k$status == "year_only_no_author") notes <- c(notes, "K&K: year found, no author match")
  if (k$status == "matched_multiple") notes <- c(notes, "K&K: several entries with all surnames; closest title match taken")
  if (nzchar(k$ini)) notes <- c(notes, paste("K&K:", k$ini))
  if (b$status == "matched_abbrev_only") notes <- c(notes, "Boroch: only abbreviated references")
  if (b$status == "matched_multiple") notes <- c(notes, "Boroch: several distinct references for this surname and year")
  if (has_kk && has_b && check == "disagree") notes <- c(notes, "K&K and Boroch titles share no content word; check")
  i <- k$idx
  data.frame(
    work = w,
    n_codes = works$n_codes[r],
    codes = works$codes[r],
    surnames = paste(p$surnames, collapse = " & "),
    year = p$year,
    kk_status = k$status,
    kk_n = k$n,
    kk_pdf_page = if (is.na(i)) NA_integer_ else kk_ent$pdf_page[i],
    kk_year_line = if (is.na(i)) NA_character_ else kk_ent$year_line[i],
    kk_snippet = if (is.na(i)) NA_character_ else kk_ent$snippet[i],
    kk_other_candidates = k$cands,
    boroch_status = b$status,
    boroch_n = b$n,
    boroch_entry_id = if (is.na(b$idx)) NA_character_ else supp$entry_id[b$idx],
    boroch_reference = if (is.na(b$idx)) NA_character_ else supp$reference[b$idx],
    boroch_alt_refs = b$alt,
    title_check = check,
    overall_status = overall,
    notes = paste(notes, collapse = "; "),
    stringsAsFactors = FALSE
  )
}))

# Page-image checks override the text-layer match for the works they list.
checks <- read.csv("data/kk-index-b-work-citations-page-checks.csv", stringsAsFactors = FALSE)
hit <- match(checks$work, res$work)
stopifnot(!anyNA(hit))
res$kk_status[hit] <- ifelse(checks$image_status %in% c("year_conflict", "quoted_in"), checks$image_status, "page_checked")
res$kk_n[hit] <- 1
res$kk_pdf_page[hit] <- checks$pdf_page
res$kk_year_line[hit] <- checks$kk_entry
res$kk_snippet[hit] <- NA_character_
res$kk_other_candidates[hit] <- ""
res$notes[hit] <- checks$note
bid <- as.character(checks$boroch_entry_id)
set_b <- !is.na(bid) & nzchar(bid)
res$boroch_status[hit[set_b]] <- "matched"
res$boroch_entry_id[hit[set_b]] <- bid[set_b]
res$boroch_reference[hit[set_b]] <- supp$reference[match(bid[set_b], supp$entry_id)]
boroch_same <- c(yes = "agree", no = "disagree")[checks$boroch_same]
res$title_check[hit] <- ifelse(res$boroch_status[hit] %in% c("matched", "matched_multiple", "matched_abbrev_only"),
                               unname(boroch_same), NA_character_)
has_kk <- res$kk_status %in% c("matched", "matched_multiple", "page_checked", "year_conflict", "quoted_in")
has_b <- res$boroch_status %in% c("matched", "matched_multiple", "matched_abbrev_only")
res$overall_status <- ifelse(has_kk & has_b, paste0("both_", ifelse(res$title_check %in% "agree", "agree", "disagree")),
                      ifelse(has_kk, "kk_only", ifelse(has_b, "boroch_only", "neither")))

write.csv(res, "data/kk-index-b-work-citations.csv", row.names = FALSE)
