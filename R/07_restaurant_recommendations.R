# Step 7: Restaurant recommendations by dining need

library(tidyverse)
library(here)

# Prepare the restaurant data
recommendation_data <- top_critical_reviewer_restaurants |>
  mutate(
    category_text = str_to_lower(
      coalesce(categories, "")
    )
  ) |>
  left_join(
    review_theme_summary |>
      select(
        business_id,
        fresh_food_mentions,
        seafood_mentions,
        fast_service_mentions,
        service_mentions,
        value_mentions,
        atmosphere_mentions
      ),
    by = "business_id"
  )

# Seafood recommendations
seafood_recommendations <- recommendation_data |>
  filter(
    str_detect(
      category_text,
      "seafood|fish|oyster|crawfish|catfish|shrimp"
    ),
    stars >= 4,
    review_count >= 100,
    critical_reviewer_reviews >= 5
  ) |>
  arrange(
    desc(critical_positive_share),
    desc(seafood_mentions),
    desc(stars)
  ) |>
  select(
    name,
    postal_code,
    stars,
    review_count,
    critical_reviewer_reviews,
    critical_positive_share,
    seafood_mentions,
    fresh_food_mentions,
    service_mentions,
    value_mentions,
    categories
  ) |>
  slice_head(n = 10)

# Quick-bite recommendations
quick_bite_recommendations <- recommendation_data |>
  filter(
    str_detect(
      category_text,
      "sandwich|deli|fast food|cafe|coffee|breakfast|food truck|bakery"
    ),
    stars >= 4,
    review_count >= 100,
    critical_reviewer_reviews >= 5
  ) |>
  arrange(
    desc(critical_positive_share),
    desc(fast_service_mentions),
    desc(stars)
  ) |>
  select(
    name,
    postal_code,
    stars,
    review_count,
    critical_reviewer_reviews,
    critical_positive_share,
    fast_service_mentions,
    service_mentions,
    value_mentions,
    categories
  ) |>
  slice_head(n = 10)

# Cajun and Creole recommendations
cajun_creole_recommendations <- recommendation_data |>
  filter(
    str_detect(
      category_text,
      "cajun|creole|southern|new orleans"
    ),
    stars >= 4,
    review_count >= 100,
    critical_reviewer_reviews >= 5
  ) |>
  arrange(
    desc(critical_positive_share),
    desc(fresh_food_mentions),
    desc(stars)
  ) |>
  select(
    name,
    postal_code,
    stars,
    review_count,
    critical_reviewer_reviews,
    critical_positive_share,
    fresh_food_mentions,
    service_mentions,
    atmosphere_mentions,
    categories
  ) |>
  slice_head(n = 10)

# Dessert recommendations
dessert_recommendations <- recommendation_data |>
  filter(
    str_detect(
      category_text,
      "dessert|bakery|gelato|ice cream|chocolate|coffee & tea|patisserie"
    ),
    stars >= 4,
    review_count >= 100,
    critical_reviewer_reviews >= 5
  ) |>
  arrange(
    desc(critical_positive_share),
    desc(fresh_food_mentions),
    desc(stars)
  ) |>
  select(
    name,
    postal_code,
    stars,
    review_count,
    critical_reviewer_reviews,
    critical_positive_share,
    fresh_food_mentions,
    service_mentions,
    value_mentions,
    categories
  ) |>
  slice_head(n = 10)

# Save recommendation tables
write_csv(
  seafood_recommendations,
  here("figures", "seafood_recommendations.csv")
)

write_csv(
  quick_bite_recommendations,
  here("figures", "quick_bite_recommendations.csv")
)

write_csv(
  cajun_creole_recommendations,
  here("figures", "cajun_creole_recommendations.csv")
)

write_csv(
  dessert_recommendations,
  here("figures", "dessert_recommendations.csv")
)

# Display the results
cat("\nSeafood recommendations:\n")
print(seafood_recommendations)

cat("\nQuick-bite recommendations:\n")
print(quick_bite_recommendations)

cat("\nCajun and Creole recommendations:\n")
print(cajun_creole_recommendations)

cat("\nDessert recommendations:\n")
print(dessert_recommendations)