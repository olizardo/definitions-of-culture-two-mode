# Initials for work labels, from the page checks in
# data/kk-index-b-work-authors-page-checks.csv (printed bibliography pp. 193-203).
# Keys are surnames as they appear in the work keys; "Surname|year" overrides where
# one surname has two initial forms. Names that already carry initials or a full
# given name are left as they are.

initials.lookup <- c(
  "Angyal" = "A.", "Bain" = "R.", "Becker" = "H.", "Benedict" = "R.",
  "Bennett" = "J. W.", "Bernard" = "L. L.", "Bidney" = "D.", "Blumenthal" = "A.",
  "Boas" = "F.", "Bogardus" = "E. S.", "Bose" = "N. K.", "Bryson" = "L.",
  "Burgess" = "E. W.", "Burkitt" = "M. C.", "Carr" = "L. J.", "Coutu" = "W.",
  "Davis Allison" = "A.", "Davis Kingsley" = "K.", "Dawson" = "C.", "Dietschy" = "H.",
  "Dixon" = "R. B.", "Dodd" = "S. C.", "Dollard" = "J.", "Feibleman" = "J.",
  "Firth" = "R.", "Folsom" = "J.", "Ford Clellan S" = "C. S.", "Ford James A" = "J. A.",
  "Frank" = "L. K.", "Groves" = "E. R.", "Haring" = "D. G.",
  "Katz" = "D.", "Schanck" = "R. L.", "Klineberg" = "O.", "Lynd" = "R. S.",
  "Titiev" = "M.", "Wissler" = "C.", "Young" = "K.", "Gorer" = "G.", "Henry" = "J.",
  "Huntington" = "E.",
  "Hart" = "H.", "Pantzer" = "A.", "Herskovits" = "M. J.", "Hiller" = "E. T.",
  "Hockett" = "C. F.", "Hoebel" = "E. A.", "Jacobs" = "M.", "Stern" = "B. J.",
  "Kelly" = "W. H.", "Keller" = "A. G.", "Kluckhohn" = "C.", "Kolb" = "W. L.",
  "Kroeber" = "A. L.", "LaPiere" = "R. T.", "Lasswell" = "H. D.", "Leighton" = "D.",
  "Linton" = "R.", "Lowie" = "R. H.", "Lundberg" = "G.", "Malinowski" = "B.",
  "Marett" = "R. R.", "Mead" = "M.", "Moore" = "H. E.", "Morris" = "C. W.",
  "Murdock" = "G. P.", "Murray" = "R. W.", "Nimkoff" = "M. F.", "Ogburn" = "W. F.",
  "Opler" = "M. E.", "Osgood" = "C.", "Panunzio" = "C.", "Park" = "R. E.",
  "Parsons" = "T.", "Piddington" = "R.", "Redfield" = "R.", "Reuter" = "E. B.",
  "Roheim" = "G.", "Rouse" = "I.", "Sapir" = "E.", "Slotkin" = "J. S.",
  "Small" = "A. W.", "Sorokin" = "P. A.", "Steward" = "J. H.", "Sumner" = "W. G.",
  "Sutherland" = "R. L.", "Taylor" = "W. W.", "Thomas" = "W. I.", "Thurnwald" = "R.",
  "Tozzer" = "A.", "Tumin" = "M. M.", "Turney-High" = "H. H.", "Tylor" = "E. B.",
  "Warden" = "C. J.", "Ward" = "L. F.", "White" = "L. A.", "Willey" = "M.",
  "Wilson" = "L.", "Winston" = "S.",
  "Woodward|1940" = "J. L.", "Woodward|1938" = "J. W.",
  "Gillin|1942" = "J. L.", "Radcliffe-Brown" = "A. R.",
  "Young|1947" = NA
)

# Full given names already in the index name, written with initials
full.name.lookup <- c(
  "Gillin John P" = "Gillin J. P.", "Gillin J.L." = "Gillin J. L.",
  "Ford Clellan S" = "Ford C. S.",
  "Ford James A" = "Ford J. A."
)

# Label for one work key, e.g. "Davis Allison & Dollard 1940" ->
# "Davis Allison A. & Dollard J. 1940". Authors with no lookup entry stay as they are.
label.authors <- function(key) {
  # D-II-7 is Kimball Young's Handbook of Social Psychology (Boroch quotes it as
  # 1947; the book's record gives 1946). Labelled 1946; the work key is unchanged.
  key <- sub("^Young 1947$", "Young 1946", key)
  yr <- sub(".* ([0-9]{3,4}[a-z]?)$", "\\1", key)
  auth <- trimws(strsplit(sub(" [0-9]{3,4}[a-z]?$", "", key), " & ")[[1]])
  lab <- vapply(auth, function(a) {
    if (a %in% names(full.name.lookup)) return(full.name.lookup[[a]])
    if (grepl(" [A-Z][.]( ?[A-Z][.])*$", a) || grepl("^([A-Z][.] ?)+", a)) return(a)
    year.key <- paste0(a, "|", yr)
    if (year.key %in% names(initials.lookup)) {
      ini <- initials.lookup[[year.key]]
    } else {
      ini <- if (a %in% names(initials.lookup)) initials.lookup[[a]] else NA
    }
    if (is.na(ini)) return(a)
    paste(a, ini)
  }, character(1), USE.NAMES = FALSE)
  paste(paste(lab, collapse = " & "), yr)
}
