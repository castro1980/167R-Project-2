# Step 5: Analysis of critical Yelp reviewers

library(tidyverse)
library(here)

# Load restaurant and review data
restaurants <- readRDS(
  here("data", "new_orleans", "new_orleans_restaurants.rds")
)

reviews <- readRDS(
  here("data", "new_orleans", "new_orleans_reviews.rds")
)

# Make sure review ratings are numeric
reviews <- reviews |>
  mutate(
    stars = as.numeric(stars)
  )

# Calculate each reviewer's average rating
reviewer_summary <- reviews |>
  group_by(user_id) |>
  summarise(
    reviewer_average_rating = mean(stars, na.rm = TRUE),
    reviewer_review_count = n(),
    .groups = "drop"
  ) |>
  mutate(
    # A critical reviewer has an average rating of 3.5 or lower
    critical_reviewer =
      reviewer_review_count >= 10 &
      reviewer_average_rating <= 3.5
  )

# Add reviewer information to each review
reviews_with_reviewer_info <- reviews |>
  left_join(reviewer_summary, by = "user_id") |>
  mutate(
    positive_review = stars >= 4
  )

# Summarize how restaurants perform with critical reviewers
critical_reviewer_restaurants <- reviews_with_reviewer_info |>
  group_by(business_id) |>
  summarise(
    reviews_analyzed = n(),
    
    critical_reviewer_reviews =
      sum(critical_reviewer, na.rm = TRUE),
    
    critical_positive_reviews =
      sum(critical_reviewer & positive_review, na.rm = TRUE),
    
    critical_reviewer_average_rating =
      mean(
        stars[critical_reviewer],
        na.rm = TRUE
      ),
    
    critical_positive_share =
      if_else(
        critical_reviewer_reviews > 0,
        critical_positive_reviews / critical_reviewer_reviews,
        NA_real_
      ),
    
    .groups = "drop"
  )

# Add restaurant information
restaurant_recommendations <- restaurants |>
  select(
    business_id,
    name,
    postal_code,
    stars,
    review_count,
    categories,
    is_open
  ) |>
  mutate(
    stars = as.numeric(stars),
    review_count = as.numeric(review_count),
    postal_code = as.character(postal_code)
  ) |>
  left_join(
    critical_reviewer_restaurants,
    by = "business_id"
  )

# Select strong restaurants with enough evidence
top_critical_reviewer_restaurants <- restaurant_recommendations |>
  filter(
    is_open == 1,
    stars >= 4,
    review_count >= 100,
    critical_reviewer_reviews >= 5
  ) |>
  arrange(
    desc(critical_positive_share),
    desc(critical_reviewer_reviews),
    desc(stars)
  )

# Save the results
write_csv(
  top_critical_reviewer_restaurants,
  here("figures", "critical_reviewer_restaurant_recommendations.csv")
)

write_csv(
  reviewer_summary,
  here("figures", "reviewer_summary.csv")
)

# Display the strongest results
cat("\nRestaurants that performed well with critical reviewers:\n")

print(
  top_critical_reviewer_restaurants |>
    select(
      name,
      postal_code,
      stars,
      review_count,
      critical_reviewer_reviews,
      critical_positive_reviews,
      critical_positive_share,
      categories
    ) |>
    slice_head(n = 20)
)