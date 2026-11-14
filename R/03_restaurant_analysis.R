# Step 4: Restaurant performance analysis

library(tidyverse)
library(here)

# Load New Orleans restaurant data
restaurants <- readRDS(
  here("data", "new_orleans", "new_orleans_restaurants.rds")
)

# Restaurant summary
restaurant_summary <- restaurants |>
  select(
    business_id,
    name,
    city,
    postal_code,
    stars,
    review_count,
    is_open,
    categories
  ) |>
  mutate(
    stars = as.numeric(stars),
    review_count = as.numeric(review_count),
    postal_code = as.character(postal_code)
  )

# Highest-rated restaurants with at least 100 reviews
top_rated_restaurants <- restaurant_summary |>
  filter(review_count >= 100) |>
  arrange(desc(stars), desc(review_count)) |>
  slice_head(n = 20)

# Most-reviewed restaurants
most_reviewed_restaurants <- restaurant_summary |>
  arrange(desc(review_count)) |>
  slice_head(n = 20)

# Summary by ZIP Code
zip_summary <- restaurant_summary |>
  group_by(postal_code) |>
  summarise(
    restaurant_count = n(),
    average_rating = mean(stars, na.rm = TRUE),
    total_reviews = sum(review_count, na.rm = TRUE),
    median_reviews = median(review_count, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(desc(restaurant_count))

# Save tables
write_csv(
  top_rated_restaurants,
  here("figures", "top_rated_restaurants.csv")
)

write_csv(
  most_reviewed_restaurants,
  here("figures", "most_reviewed_restaurants.csv")
)

write_csv(
  zip_summary,
  here("figures", "zip_restaurant_summary.csv")
)

# Plot 1: Most common ZIP Codes by restaurant count
zip_plot_data <- zip_summary |>
  slice_max(order_by = restaurant_count, n = 10)

zip_plot <- ggplot(
  zip_plot_data,
  aes(
    x = reorder(postal_code, restaurant_count),
    y = restaurant_count
  )
) +
  geom_col(fill = "#D95F02") +
  coord_flip() +
  labs(
    title = "New Orleans Restaurants by ZIP Code",
    x = "ZIP Code",
    y = "Number of restaurants"
  ) +
  theme_minimal()

ggsave(
  here("figures", "restaurants_by_zip.png"),
  zip_plot,
  width = 8,
  height = 6,
  dpi = 300
)

# Plot 2: Ratings and review counts
rating_plot <- ggplot(
  restaurant_summary,
  aes(x = stars, y = review_count)
) +
  geom_jitter(
    alpha = 0.35,
    width = 0.08,
    color = "#1B9E77"
  ) +
  scale_y_log10() +
  labs(
    title = "Restaurant Ratings and Review Counts",
    x = "Yelp rating",
    y = "Number of reviews, log scale"
  ) +
  theme_minimal()

ggsave(
  here("figures", "ratings_and_reviews.png"),
  rating_plot,
  width = 8,
  height = 6,
  dpi = 300
)

# Display the most useful results
cat("\nTop-rated restaurants:\n")
print(top_rated_restaurants)

cat("\nZIP Code summary:\n")
print(zip_summary |> slice_head(n = 10))

