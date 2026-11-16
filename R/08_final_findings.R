# Step 8: Final findings graphs

library(tidyverse)
library(here)

# -----------------------------
# 1. Most common categories
# -----------------------------

category_counts <- read_csv(
  here("figures", "category_counts.csv"),
  show_col_types = FALSE
)

top_categories <- category_counts |>
  slice_max(order_by = n, n = 15) |>
  arrange(n)

category_plot <- ggplot(
  top_categories,
  aes(x = n, y = reorder(category, n))
) +
  geom_col(fill = "#D95F02") +
  labs(
    title = "Most Common Restaurant Categories",
    x = "Number of restaurants",
    y = "Restaurant category"
  ) +
  theme_minimal()

ggsave(
  here("figures", "top_restaurant_categories.png"),
  category_plot,
  width = 9,
  height = 7,
  dpi = 300
)

# -----------------------------
# 2. Recommendation comparison
# -----------------------------

seafood <- read_csv(
  here("figures", "seafood_recommendations.csv"),
  show_col_types = FALSE
) |>
  mutate(recommendation_type = "Seafood")

quick_bite <- read_csv(
  here("figures", "quick_bite_recommendations.csv"),
  show_col_types = FALSE
) |>
  mutate(recommendation_type = "Quick bite")

cajun_creole <- read_csv(
  here("figures", "cajun_creole_recommendations.csv"),
  show_col_types = FALSE
) |>
  mutate(recommendation_type = "Cajun/Creole")

dessert <- read_csv(
  here("figures", "dessert_recommendations.csv"),
  show_col_types = FALSE
) |>
  mutate(recommendation_type = "Dessert")

recommendations <- bind_rows(
  seafood,
  quick_bite,
  cajun_creole,
  dessert
) |>
  select(
    name,
    stars,
    critical_positive_share,
    recommendation_type
  ) |>
  filter(!is.na(critical_positive_share)) |>
  group_by(recommendation_type) |>
  slice_max(
    order_by = critical_positive_share,
    n = 5
  ) |>
  ungroup()

recommendation_plot <- ggplot(
  recommendations,
  aes(
    x = critical_positive_share,
    y = reorder(name, critical_positive_share),
    color = recommendation_type
  )
) +
  geom_point(size = 3) +
  facet_wrap(~ recommendation_type, scales = "free_y") +
  scale_x_continuous(labels = scales::percent) +
  labs(
    title = "Recommended Restaurants and Critical-Reviewer Support",
    x = "Positive share among critical reviewers",
    y = "Restaurant"
  ) +
  theme_minimal() +
  theme(
    legend.position = "none"
  )

ggsave(
  here("figures", "recommendation_comparison.png"),
  recommendation_plot,
  width = 11,
  height = 8,
  dpi = 300
)

# -----------------------------
# 3. Review themes
# -----------------------------

review_themes <- read_csv(
  here("figures", "review_theme_summary.csv"),
  show_col_types = FALSE
) |>
  select(
    name,
    fresh_food_mentions,
    seafood_mentions,
    fast_service_mentions,
    service_mentions,
    value_mentions,
    atmosphere_mentions
  ) |>
  pivot_longer(
    cols = ends_with("_mentions"),
    names_to = "theme",
    values_to = "mentions"
  ) |>
  mutate(
    theme = str_remove(theme, "_mentions"),
    theme = str_replace_all(theme, "_", " "),
    theme = str_to_title(theme)
  ) |>
  group_by(theme) |>
  summarise(
    total_mentions = sum(mentions, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(total_mentions)

theme_plot <- ggplot(
  review_themes,
  aes(x = total_mentions, y = reorder(theme, total_mentions))
) +
  geom_col(fill = "#1B9E77") +
  labs(
    title = "Themes Mentioned in Positive Restaurant Reviews",
    x = "Number of mentions",
    y = "Review theme"
  ) +
  theme_minimal()

ggsave(
  here("figures", "review_themes_plot.png"),
  theme_plot,
  width = 9,
  height = 6,
  dpi = 300
)

cat("\nFinal findings graphs created successfully.\n")