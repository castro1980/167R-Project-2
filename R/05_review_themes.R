# Step 6: Review themes for recommended restaurants

library(tidyverse)
library(here)

# Select the strongest 20 restaurant recommendations
recommendation_list <- top_critical_reviewer_restaurants |>
  select(
    business_id,
    name,
    stars,
    review_count,
    critical_positive_share
  ) |>
  slice_head(n = 20)

# Select positive reviews for these restaurants
positive_reviews <- reviews |>
  inner_join(
    recommendation_list,
    by = "business_id"
  ) |>
  filter(stars >= 4) |>
  mutate(
    review_text = str_to_lower(text),
    
    mentions_fresh_food = str_detect(
      review_text,
      "fresh|delicious|flavorful|tasty|well seasoned"
    ),
    
    mentions_seafood = str_detect(
      review_text,
      "seafood|shrimp|oyster|fish|crab|crawfish"
    ),
    
    mentions_fast_service = str_detect(
      review_text,
      "quick|fast|speedy|takeout|counter service"
    ),
    
    mentions_service = str_detect(
      review_text,
      "friendly|service|staff|server|waiter"
    ),
    
    mentions_value = str_detect(
      review_text,
      "affordable|price|reasonable|worth|portion"
    ),
    
    mentions_atmosphere = str_detect(
      review_text,
      "atmosphere|ambiance|beautiful|decor|vibe"
    )
  )

# Count common themes for each restaurant
review_theme_summary <- positive_reviews |>
  group_by(
    business_id,
    name,
    stars,
    review_count,
    critical_positive_share
  ) |>
  summarise(
    positive_reviews_analyzed = n(),
    fresh_food_mentions = sum(mentions_fresh_food, na.rm = TRUE),
    seafood_mentions = sum(mentions_seafood, na.rm = TRUE),
    fast_service_mentions = sum(mentions_fast_service, na.rm = TRUE),
    service_mentions = sum(mentions_service, na.rm = TRUE),
    value_mentions = sum(mentions_value, na.rm = TRUE),
    atmosphere_mentions = sum(mentions_atmosphere, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(desc(critical_positive_share))

# Save theme summary
write_csv(
  review_theme_summary,
  here("figures", "review_theme_summary.csv")
)

# Save example positive reviews
review_examples <- positive_reviews |>
  select(
    name,
    stars,
    date,
    text
  ) |>
  filter(!is.na(text), text != "") |>
  group_by(name) |>
  slice_head(n = 3) |>
  ungroup()

write_csv(
  review_examples,
  here("figures", "review_examples.csv")
)

# Display results
print(review_theme_summary)
print(review_examples)