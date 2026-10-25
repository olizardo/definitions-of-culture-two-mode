# Node shapes for a work's publication type (article, book, chapter, other), so one
# shape means one type across figures. CA points use solid shapes; MST nodes use
# the filled shapes 21-24, so the community fill still shows. Sourced by
# scripts/analysis-ca-works-index-b.R and scripts/analysis-mst-works-index-b.R.
pub.shape.ca <- c(article = 16, book = 15, chapter = 17, other = 18)
pub.shape.mst <- c(article = 21, book = 22, chapter = 24, other = 23)
