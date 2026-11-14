# Step 3: Restaurant category analysis

library(tidyverse)
library(here)

# Load New Orleans restaurants
new_orleans_restaurants <- readRDS(
  here(
    "data",
    "new_orleans",
    "new_orleans_restaurants.rds"
  )
)

# Separate each business category into its own row
restaurant_categories <- new_orleans_restaurants |>
  select(
    business_id,
    name,
    postal_code,
    stars,
    review_count,
    categories
  ) |>
  separate_rows(categories, sep = ",\\s*") |>
  mutate(
    category = str_squish(categories),
    category = str_to_title(category)
  ) |>
  filter(
    !is.na(category),
    category != ""
  ) |>
  select(-categories)

# Count categories
category_counts <- restaurant_categories |>
  count(category, sort = TRUE)

print(category_counts, n = 30)

# Remove broad categories when looking for meaningful restaurant themes
specific_category_counts <- category_counts |>
  filter(
    !category %in% c(
      "Restaurants",
      "Food",
      "Nightlife",
      "Bars",
      "Shopping"
    )
  )

print(specific_category_counts, n = 30)

# Create category co-occurrence pairs
business_categories <- restaurant_categories |>
  distinct(business_id, category)

category_pairs <- business_categories |>
  inner_join(
    business_categories,
    by = "business_id",
    suffix = c("_1", "_2")
  ) |>
  filter(category_1 < category_2) |>
  count(category_1, category_2, sort = TRUE)

print(category_pairs, n = 30)

# Save results
write_csv(
  category_counts,
  here(
    "figures",
    "category_counts.csv"
  )
)

write_csv(
  category_pairs,
  here(
    "figures",
    "category_pairs.csv"
  )
)

saveRDS(
  restaurant_categories,
  here(
    "data",
    "new_orleans",
    "restaurant_categories.rds"
  )
)