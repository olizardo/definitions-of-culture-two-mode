# Text-coverage tally for the verified K&K definitions. Joins the definition
# universe to the Boroch text files (via the crosswalk and the appendix-only
# links) and to the K&K-sourced texts for the codes Boroch does not quote.
# Read-only: prints the tally, writes nothing. Run from the project root.

defs <- read.csv("data/kk-index-b-definitions.csv", stringsAsFactors = FALSE)
defs <- defs[defs$in_verified, ]
cw <- read.csv("data/kk-boroch-crosswalk.csv", stringsAsFactors = FALSE)
links <- read.csv("data/kkcc-appendix-only-links.csv", stringsAsFactors = FALSE)
t2 <- read.csv("data/kkcc-definition-texts.csv", stringsAsFactors = FALSE)
aot <- read.csv("data/kkcc-appendix-only-texts.csv", stringsAsFactors = FALSE)
kk_only <- read.csv("data/kk-definition-texts-kk-only.csv", stringsAsFactors = FALSE)

stopifnot(!anyDuplicated(defs$kk_code), !anyDuplicated(t2$code),
          !anyDuplicated(aot$code), !anyDuplicated(kk_only$kk_code))

# Boroch code -> K&K code: crosswalk matches plus the linked appendix-only codes
b2kk <- cw$kk_code[!is.na(cw$kk_code) & nzchar(cw$kk_code)]
names(b2kk) <- cw$boroch_code[!is.na(cw$kk_code) & nzchar(cw$kk_code)]
lk <- links[grepl("^linked", links$verdict) & links$kk_row %in% defs$kk_code, c("code", "kk_row")]
b2kk <- c(b2kk, setNames(lk$kk_row, lk$code))
dup.kk <- names(which(table(unname(b2kk)) > 1))
b2kk <- b2kk[!duplicated(b2kk)]

# Boroch texts, one lookup per K&K code (Table 2 first, then appendix-only)
txt <- setNames(t2$text, t2$code)
txt <- c(txt, setNames(aot$text[!aot$code %in% names(txt)], aot$code[!aot$code %in% names(txt)]))

cov <- data.frame(kk_code = defs$kk_code)
cov$boroch_codes <- vapply(cov$kk_code,
                           function(k) paste(sort(names(b2kk)[b2kk == k]), collapse = "; "), "")
cov$has_boroch_text <- nzchar(cov$boroch_codes)
cov$boroch_text <- vapply(cov$boroch_codes, function(s) {
  cs <- strsplit(s, "; ")[[1]]
  txt <- txt[cs[nzchar(cs)]]
  txt <- txt[nzchar(trimws(txt))]
  if (length(txt)) paste(txt, collapse = " / ") else NA_character_
}, "")
cov$kk_text <- kk_only$text[match(cov$kk_code, kk_only$kk_code)]
cov$source <- ifelse(cov$has_boroch_text, "boroch",
                     ifelse(!is.na(cov$kk_text), "kk part II", "none"))

cat(sprintf("verified definitions: %d | with Boroch text: %d | with K&K text: %d | no text: %d\n",
            nrow(cov), sum(cov$source == "boroch"), sum(cov$source == "kk part II"),
            sum(cov$source == "none")))
cat(sprintf("K&K codes carrying two Boroch quotations: %s\n",
            paste(dup.kk, collapse = ", ")))

gap <- cov[cov$source != "boroch", c("kk_code", "source", "boroch_codes")]
if (nrow(gap)) print(gap, row.names = FALSE)

# Guard: the K&K-only file must cover exactly the codes Boroch leaves out
stopifnot(setequal(kk_only$kk_code, cov$kk_code[cov$source == "kk part II"]))

# ---- Text-to-work match ------------------------------------------------------
# Each definition's quotation should be attributable to one of the works the
# code holds, by surname set and year. Author-year comes from the Boroch years
# file (Table 2 codes; year_orig kept as a fallback, some entries print a later
# year than the work's own), the appendix-only texts (their codes), and the
# K&K-only file (the four codes Boroch leaves out). Initials are dropped, so
# "A. Davis" matches the work "Davis Allison 1948".

yr2 <- read.csv("data/kkcc-definition-years.csv", stringsAsFactors = FALSE)
works <- read.csv("data/kk-index-b-works.csv", stringsAsFactors = FALSE)

b2kk.all <- c(setNames(cw$kk_code, cw$boroch_code), setNames(lk$kk_row, lk$code))
b2kk.all <- b2kk.all[!is.na(b2kk.all) & nzchar(b2kk.all)]

yr.str <- function(y, o) {
  v <- na.omit(unique(c(y, o)))
  if (length(v)) paste(v, collapse = ",") else NA_character_
}
auth.yr <- rbind(
  data.frame(boroch_code = yr2$code, author = yr2$author,
             years = mapply(yr.str, yr2$year, yr2$year_orig), kk_code = NA_character_),
  data.frame(boroch_code = aot$code, author = aot$author,
             years = as.character(aot$year), kk_code = NA_character_),
  # K&K-only rows carry their kk_code directly; an author may hold several
  # (Goldenweiser has C-5 1937 and D-5 1933), so never key these by author.
  data.frame(boroch_code = NA_character_, author = kk_only$author,
             years = as.character(kk_only$year), kk_code = kk_only$kk_code))
auth.yr <- auth.yr[auth.yr$boroch_code %in% names(b2kk.all) |
                     (!is.na(auth.yr$kk_code) & nzchar(auth.yr$kk_code)), ]
auth.yr$kk_code <- ifelse(is.na(auth.yr$boroch_code),
                          auth.yr$kk_code,
                          b2kk.all[auth.yr$boroch_code])
auth.yr <- auth.yr[!is.na(auth.yr$kk_code) & nzchar(auth.yr$kk_code) &
                     nzchar(auth.yr$author), ]

# Documented author-year conflicts, kept as printed (PROVENANCE): D-II-7 is the
# Young 1947/1944 printing conflict, F-I-20 the F1-21 Kluckhohn 1951a link that
# rests on the main-text citation against Index A's F. R. Kluckhohn 1950.
DOCUMENTED <- c("D-II-7", "F-I-20")

w_list <- strsplit(works$codes, "; ")
work.info <- lapply(seq_len(nrow(works)), function(i) {
  lab <- works$work[i]
  yr <- regmatches(lab, regexpr("[0-9]{4}", lab))
  prefix <- trimws(sub("[0-9]{4}[a-z]?$", "", lab))
  list(year = if (length(yr)) as.integer(yr) else NA_integer_,
       prefix = tolower(prefix))
})

surnames.of <- function(auth) {
  toks <- tolower(strsplit(auth, "[[:space:]]+")[[1]])
  toks <- toks[!toks %in% c("and", "&", "with", "of", "the")]
  toks <- toks[!grepl("^[a-z]\\.?$|^\\(", toks)]   # drop initials and open parens
  unique(sub("[[:punct:]]+$", "", toks))
}

hit.work <- function(wi, surnames, yrs) {
  yrs <- suppressWarnings(as.integer(strsplit(yrs, ",")[[1]]))
  yrs <- yrs[!is.na(yrs)]
  yr.ok <- length(yrs) == 0 || is.na(wi$year) || wi$year %in% yrs
  yr.ok && all(vapply(surnames, function(s) grepl(s, wi$prefix, fixed = TRUE), logical(1)))
}

match.one <- function(auth, yrs, code) {
  surnames <- surnames.of(auth)
  yrs <- if (is.na(yrs)) "" else yrs
  widx <- which(vapply(w_list, function(cs) code %in% cs, logical(1)))
  if (length(widx) == 0) return("no_work_under_code")
  if (any(vapply(widx, function(i) hit.work(work.info[[i]], surnames, yrs), logical(1))))
    return("matched")
  widx2 <- which(vapply(work.info, function(wi) hit.work(wi, surnames, yrs), logical(1)))
  if (length(widx2)) return("text_matches_another_work")
  "conflict"
}

res <- vapply(seq_len(nrow(auth.yr)), function(i)
  match.one(auth.yr$author[i], auth.yr$years[[i]], auth.yr$kk_code[i]), "")
auth.yr$result <- res
# best result per code: matched beats a stray mismatch among several quotations
rank <- c(matched = 1, text_matches_another_work = 2, no_work_under_code = 3, conflict = 4)
best <- tapply(auth.yr$result, auth.yr$kk_code, function(r) names(sort(rank[r]))[1])
r0 <- unname(best[cov$kk_code])
r0 <- ifelse(is.na(r0), "no_text", r0)
r0[r0 %in% c("conflict", "text_matches_another_work") & cov$kk_code %in% DOCUMENTED] <-
  paste0(r0[r0 %in% c("conflict", "text_matches_another_work") & cov$kk_code %in% DOCUMENTED],
         " (documented)")
cov2 <- data.frame(kk_code = cov$kk_code, result = r0)
cat("\ntext-to-work match, per definition:\n")
print(table(cov2$result))
bad <- cov2[cov2$result != "matched" & cov2$result != "no_text", c("kk_code", "result")]
if (nrow(bad)) {
  cat("---- not matched cleanly ----\n")
  print(bad, row.names = FALSE)
}
