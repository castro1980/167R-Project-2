# Step 6: Review themes for recommended restaurants

library(tidyverse)
library(here)

# Select the strongest restaurant recommendations
recommendation_list <- top_critical_reviewer_restaurants |>
  select(
    business_id,
    name,
    stars,
    review_count,
    critical_reviewer_reviews,
    critical_positive_reviews,
    critical_positive_share
  ) |>
  rename(
    restaurant_stars = stars
  ) |>
  slice_head(n = 20)

# Prepare review data
reviews_clean <- reviews |>
  select(
    business_id,
    user_id,
    stars,
    date,
    text
  )

# Convert review ratings to numeric
if (is.list(reviews_clean$stars)) {
  reviews_clean$review_stars <- purrr::map_dbl(
    reviews_clean$stars,
    function(x) {
      if (length(x) == 0 || is.na(x[1])) {
        return(NA_real_)
      }
      
      as.numeric(x[1])
    }
  )
} else {
  reviews_clean$review_stars <- as.numeric(reviews_clean$stars)
}

# Select positive reviews
positive_reviews <- reviews_clean |>
  inner_join(
    recommendation_list,
    by = "business_id"
  ) |>
  filter(review_stars >= 4) |>
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

# Summarize themes
review_theme_summary <- positive_reviews |>
  group_by(
    business_id,
    name,
    restaurant_stars,
    review_count,
    critical_reviewer_reviews,
    critical_positive_reviews,
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

# Save results
write_csv(
  review_theme_summary,
  here("figures", "review_theme_summary.csv")
)

# Save review examples
review_examples <- positive_reviews |>
  select(
    name,
    review_stars,
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
print(
  review_theme_summary |>
    select(
      name,
      restaurant_stars,
      review_count,
      critical_reviewer_reviews,
      critical_positive_share,
      fresh_food_mentions,
      seafood_mentions,
      fast_service_mentions,
      service_mentions,
      value_mentions,
      atmosphere_mentions
    ) |>
    slice_head(n = 20),
  width = Inf
)

print(
  review_examples |>
    slice_head(n = 10),
  width = 120
)