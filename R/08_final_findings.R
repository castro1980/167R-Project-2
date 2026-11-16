# Step 8: Creative and reader-friendly final findings

library(tidyverse)
library(here)
library(scales)

dir.create(here("figures"), showWarnings = FALSE)

# Consistent graph style
project_theme <- theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(
      face = "bold",
      size = 18,
      color = "#222222"
    ),
    plot.subtitle = element_text(
      size = 12,
      color = "gray30"
    ),
    axis.title = element_text(face = "bold"),
    axis.text = element_text(color = "gray20"),
    panel.grid.minor = element_blank(),
    legend.position = "none",
    plot.margin = margin(12, 20, 12, 12)
  )

# ---------------------------------------------------------
# 1. What restaurant categories are most common?
# ---------------------------------------------------------

category_counts <- read_csv(
  here("figures", "category_counts.csv"),
  show_col_types = FALSE
)

top_categories <- category_counts |>
  slice_max(n, n = 8, with_ties = FALSE) |>
  arrange(desc(n)) |>
  mutate(
    category = str_wrap(category, width = 18),
    label = comma(n)
  )

category_plot <- ggplot(
  top_categories,
  aes(
    x = reorder(category, -n),
    y = n,
    fill = n
  )
) +
  geom_col(width = 0.7) +
  geom_text(
    aes(label = label),
    vjust = -0.4,
    size = 4
  ) +
  scale_fill_gradient(
    low = "#9ECAE1",
    high = "#08519C"
  ) +
  scale_y_continuous(
    labels = comma,
    expand = expansion(mult = c(0, 0.15))
  ) +
  labs(
    title = "Which Restaurant Categories Are Most Common?",
    subtitle = "The most frequently represented restaurant categories",
    x = NULL,
    y = "Number of restaurants"
  ) +
  project_theme +
  theme(
    axis.text.x = element_text(
      angle = 25,
      hjust = 1
    )
  )

ggsave(
  here("figures", "top_restaurant_categories.png"),
  category_plot,
  width = 11,
  height = 7,
  dpi = 300
)

# ---------------------------------------------------------
# 2. Which restaurant fits each dining need?
# ---------------------------------------------------------

read_recommendations <- function(file_name, dining_need) {
  read_csv(
    here("figures", file_name),
    show_col_types = FALSE
  ) |>
    mutate(dining_need = dining_need)
}

recommendations <- bind_rows(
  read_recommendations(
    "quick_bite_recommendations.csv",
    "Quick bite"
  ),
  read_recommendations(
    "seafood_recommendations.csv",
    "Seafood"
  ),
  read_recommendations(
    "cajun_creole_recommendations.csv",
    "Cajun/Creole"
  ),
  read_recommendations(
    "dessert_recommendations.csv",
    "Dessert"
  )
) |>
  filter(
    !is.na(name),
    !is.na(critical_positive_share)
  ) |>
  group_by(dining_need) |>
  slice_max(
    critical_positive_share,
    n = 1,
    with_ties = FALSE
  ) |>
  ungroup() |>
  mutate(
    dining_need = factor(
      dining_need,
      levels = c(
        "Quick bite",
        "Seafood",
        "Cajun/Creole",
        "Dessert"
      )
    ),
    name = str_wrap(name, width = 18),
    stars_label = paste0(stars, " stars"),
    reviews_label = paste0(
      comma(review_count),
      " Yelp reviews"
    ),
    critical_label = paste0(
      "Critical reviewers: ",
      percent(
        critical_positive_share,
        accuracy = 1
      ),
      " positive"
    ),
    card_label = paste(
      name,
      stars_label,
      reviews_label,
      str_wrap(critical_label, width = 18),
      sep = "\n"
    )
  )

recommendation_plot <- ggplot(
  recommendations,
  aes(
    x = dining_need,
    y = 1,
    fill = critical_positive_share
  )
) +
  geom_tile(
    width = 0.92,
    height = 1.15,
    color = "white",
    linewidth = 1.5
  ) +
  geom_text(
    aes(label = card_label),
    color = "white",
    fontface = "bold",
    size = 3.8,
    lineheight = 1.1
  ) +
  scale_fill_gradient(
    low = "#74ADD1",
    high = "#7A0177"
  ) +
  scale_y_continuous(
    breaks = NULL,
    limits = c(0.35, 1.65)
  ) +
  labs(
    title = "Which Restaurant Fits Each Dining Need?",
    subtitle = "Each card shows the strongest recommendation in that category",
    x = NULL,
    y = NULL
  ) +
  project_theme +
  theme(
    panel.grid = element_blank(),
    axis.text.x = element_text(
      face = "bold",
      size = 12
    )
  )

ggsave(
  here("figures", "recommendation_scorecards.png"),
  recommendation_plot,
  width = 12,
  height = 5.5,
  dpi = 300
)

# ---------------------------------------------------------
# 3. Which restaurants impress critical reviewers?
# ---------------------------------------------------------

critical_reviewers <- read_csv(
  here(
    "figures",
    "critical_reviewer_restaurant_recommendations.csv"
  ),
  show_col_types = FALSE
) |>
  filter(
    critical_reviewer_reviews >= 5,
    stars >= 4,
    !is.na(critical_positive_share)
  )

# Select the ten strongest results.
# If restaurants have the same percentage,
# the restaurant with more critical-reviewer ratings comes first.
critical_top <- critical_reviewers |>
  arrange(
    desc(critical_positive_share),
    desc(critical_reviewer_reviews)
  ) |>
  slice_head(n = 10) |>
  mutate(
    name = str_wrap(name, width = 18),
    percent_label = percent(
      critical_positive_share,
      accuracy = 1
    ),
    review_label = paste0(
      critical_positive_reviews,
      " of ",
      critical_reviewer_reviews,
      " positive"
    )
  ) |>
  arrange(critical_positive_share) |>
  mutate(
    name = factor(
      name,
      levels = name
    )
  )

critical_plot <- ggplot(
  critical_top,
  aes(
    x = name,
    y = critical_positive_share,
    fill = critical_positive_share
  )
) +
  geom_col(
    width = 0.65
  ) +
  geom_text(
    aes(
      label = paste(
        percent_label,
        review_label,
        sep = "\n"
      )
    ),
    vjust = -0.25,
    size = 3.5,
    lineheight = 1.05
  ) +
  scale_fill_gradient(
    low = "#9ECAE1",
    high = "#006D2C"
  ) +
  scale_y_continuous(
    labels = percent,
    limits = c(0, 1.18),
    breaks = seq(0, 1, 0.25),
    expand = expansion(mult = c(0, 0.02))
  ) +
  labs(
    title = "Which Restaurants Receive the Strongest Ratings?",
    subtitle = "Top restaurants among reviewers who usually give lower ratings",
    x = NULL,
    y = "Positive ratings from critical reviewers"
  ) +
  project_theme +
  theme(
    axis.text.x = element_text(
      angle = 35,
      hjust = 1,
      size = 10
    ),
    panel.grid.major.x = element_blank()
  )

ggsave(
  here("figures", "critical_reviewer_graph.png"),
  critical_plot,
  width = 12,
  height = 8,
  dpi = 300
)

# ---------------------------------------------------------
# 4. What do reviewers mention most often?
# ---------------------------------------------------------

review_themes <- read_csv(
  here("figures", "review_theme_summary.csv"),
  show_col_types = FALSE
) |>
  select(
    fresh_food_mentions,
    seafood_mentions,
    fast_service_mentions,
    service_mentions,
    value_mentions,
    atmosphere_mentions
  ) |>
  pivot_longer(
    cols = everything(),
    names_to = "theme",
    values_to = "mentions"
  ) |>
  group_by(theme) |>
  summarise(
    total_mentions = sum(mentions, na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(
    theme = recode(
      theme,
      fresh_food_mentions = "Fresh food",
      seafood_mentions = "Seafood",
      fast_service_mentions = "Fast service",
      service_mentions = "Friendly service",
      value_mentions = "Value and portions",
      atmosphere_mentions = "Atmosphere"
    ),
    label = comma(total_mentions)
  ) |>
  arrange(desc(total_mentions))

theme_plot <- ggplot(
  review_themes,
  aes(
    x = reorder(theme, -total_mentions),
    y = total_mentions,
    color = total_mentions
  )
) +
  geom_segment(
    aes(
      xend = theme,
      y = 0,
      yend = total_mentions
    ),
    linewidth = 1.5,
    color = "#9ECAE1"
  ) +
  geom_point(size = 7) +
  geom_text(
    aes(label = label),
    vjust = -1,
    size = 4
  ) +
  scale_color_gradient(
    low = "#FDAE6B",
    high = "#A50F15"
  ) +
  scale_y_continuous(
    labels = comma,
    expand = expansion(mult = c(0, 0.15))
  ) +
  labs(
    title = "What Do Reviewers Mention Most Often?",
    subtitle = "Food quality and service are major themes in positive reviews",
    x = NULL,
    y = "Number of mentions"
  ) +
  project_theme +
  theme(
    axis.text.x = element_text(
      angle = 25,
      hjust = 1
    )
  )

ggsave(
  here("figures", "review_themes_plot.png"),
  theme_plot,
  width = 10,
  height = 6.5,
  dpi = 300
)

# ---------------------------------------------------------
# 5. Do more reviews mean higher ratings?
# ---------------------------------------------------------

ratings_reviews <- critical_reviewers |>
  filter(
    review_count >= 100,
    stars >= 3
  )

restaurants_to_label <- ratings_reviews |>
  arrange(desc(review_count)) |>
  slice_head(n = 8)

ratings_plot <- ggplot(
  ratings_reviews,
  aes(
    x = review_count,
    y = stars,
    size = critical_reviewer_reviews,
    color = critical_positive_share
  )
) +
  geom_point(alpha = 0.65) +
  geom_text(
    data = restaurants_to_label,
    aes(label = name),
    color = "#222222",
    size = 3.2,
    nudge_y = 0.04,
    check_overlap = TRUE
  ) +
  scale_x_log10(
    labels = comma
  ) +
  scale_y_continuous(
    breaks = seq(3, 5, 0.5),
    limits = c(3, 5.2)
  ) +
  scale_color_gradient(
    low = "#FEE0D2",
    high = "#99000D",
    labels = percent
  ) +
  labs(
    title = "Do More Reviews Mean Higher Ratings?",
    subtitle = "Each point represents a New Orleans restaurant",
    x = "Number of Yelp reviews",
    y = "Yelp star rating",
    color = "Positive ratings from critical reviewers",
    size = "Critical-reviewer reviews"
  ) +
  project_theme +
  theme(
    legend.position = "right"
  )

ggsave(
  here("figures", "ratings_and_reviews.png"),
  ratings_plot,
  width = 11,
  height = 7,
  dpi = 300
)

cat("\nAll redesigned graphs were created successfully.\n")