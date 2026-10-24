# Concept-to-category mapping for the 56 fine-grained notions.
# Source: Boroch, section 3.2.2, items a)-q) (ROBAFC-5.1.pdf, printed p. 66),
# which lists each main category with its auxiliary notions. DOING (item q) has
# no row in the fine matrix and is not mapped.
# Output: data/kkcc-concept-categories.csv. Run from the project root.

library(igraph)

item_map <- list(
  SOCIAL       = list(letter = "a", aux = c("Socially")),
  BEHAVIOR     = list(letter = "b", aux = c("Behaviors", "Behavior-families", "Behavior-patterns")),
  PATTERNS     = list(letter = "c", aux = c("Pattern", "Pattern-creating order", "Patterning",
                     "Patterned customs", "Patterned totality of group",
                     "Patterned ways of behavior", "Patterned ways of thinking and acting")),
  HABITS       = list(letter = "d", aux = c("Habit", "Habiting", "Habitual attitudes",
                     "Habitual behaviour", "Habitual patterns", "Habitual ways of life",
                     "Social habituation")),
  ACTING       = list(letter = "e", aux = c("Interacting", "Reacting", "Activity", "Activities")),
  HERITAGE     = list(letter = "f", aux = c("Heredity", "Inherit/inherited", "Inherits", "Inherit-ance")),
  BELIEFS      = list(letter = "g", aux = c("Belief")),
  CUSTOMS      = list(letter = "h", aux = c("Custom")),
  SYMBOL       = list(letter = "i", aux = c("Symbolic action", "Symbolic behavior", "Symbolic systems",
                     "Non-symbolic counterparts", "Symbolic transmission",
                     "Symbolically communicable", "Symbol-ling")),
  SYSTEM       = list(letter = "j", aux = c("Systems")),
  ATTITUDES    = list(letter = "k", aux = c("Attitudinal relationship", "Non-attitudional relationships")),
  ADJUSTMENTS  = list(letter = "l", aux = c("Adjustment")),
  KNOWLEDGE    = list(letter = "m", aux = character(0)),
  LANGUAGE     = list(letter = "n", aux = character(0)),
  TRANSMISSION = list(letter = "o", aux = c("Transmissible results")),
  INDUSTRIES   = list(letter = "p", aux = character(0))
)

# Printed "TOTAL USES IN ... CATEGORY" values (Table 2), with multiplicity.
printed_uses <- c(SOCIAL = 68, BEHAVIOR = 59, PATTERNS = 32, HABITS = 29, ACTING = 25,
                  HERITAGE = 21, BELIEFS = 20, CUSTOMS = 20, SYMBOL = 18, SYSTEM = 15,
                  ATTITUDES = 12, ADJUSTMENTS = 10, KNOWLEDGE = 8, LANGUAGE = 7,
                  TRANSMISSION = 4, INDUSTRIES = 3)

fine <- readRDS("data/kkcc_two_mode.rds")$biadjacency
labels <- rownames(fine)

mains <- names(item_map)
map <- rbind(
  data.frame(concept = mains, is_main = TRUE, parent_category = mains,
             list_item = vapply(item_map, `[[`, "", "letter"), stringsAsFactors = FALSE),
  do.call(rbind, lapply(mains, function(m)
    if (length(item_map[[m]]$aux))
      data.frame(concept = item_map[[m]]$aux, is_main = FALSE, parent_category = m,
                 list_item = item_map[[m]]$letter, stringsAsFactors = FALSE))))

stopifnot(
  !anyDuplicated(map$concept),
  setequal(map$concept, labels),
  nrow(map) == length(labels)
)

map$printed_uses <- NA_integer_
map$printed_uses[map$is_main] <- printed_uses[map$concept[map$is_main]]
map <- map[match(labels, map$concept), ]
rownames(map) <- NULL

binary_uses <- tapply(rowSums(fine), map$parent_category, sum)
check <- data.frame(category = names(printed_uses), printed = printed_uses,
                    binary_ties = as.integer(binary_uses[names(printed_uses)]))
stopifnot(all(check$binary_ties <= check$printed))

dir.create("data", showWarnings = FALSE)
write.csv(map, "data/kkcc-concept-categories.csv", row.names = FALSE)
cat("wrote data/kkcc-concept-categories.csv:", nrow(map), "concepts,",
    sum(map$is_main), "main categories\n")
check
