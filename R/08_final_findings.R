# Step 8: Final findings graphs

library(tidyverse)
library(here)
library(scales)

dir.create(here("figures"), showWarnings = FALSE)

project_theme <- theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(
      face = "bold",
      size = 18
    ),
    plot.subtitle = element_text(
      size = 12,
      color = "gray30"
    ),
    axis.title = element_text(face = "bold"),
    panel.grid.minor = element_blank(),
    legend.position = "none"
  )

# ---------------------------------------------------------
# 1. Most common restaurant categories
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
    subtitle = "The most frequently represented categories in the Yelp data",
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
# 2. Restaurant recommendations by dining need
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
    card_label = paste(
      name,
      paste0(stars, " stars"),
      paste0(comma(review_count), " Yelp reviews"),
      paste0(
        "Critical reviewers: ",
        percent(
          critical_positive_share,
          accuracy = 1
        ),
        " positive"
      ),
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
# 3. Restaurants that impress critical reviewers
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
  geom_col(width = 0.65) +
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
# 4. Review themes
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
  filter(review_count >= 100) |>
  mutate(
    review_group = case_when(
      review_count < 500 ~ "100–499 reviews",
      review_count < 1000 ~ "500–999 reviews",
      TRUE ~ "1,000+ reviews"
    )
  )

rating_summary <- ratings_reviews |>
  group_by(review_group) |>
  summarise(
    average_rating = mean(stars, na.rm = TRUE),
    restaurant_count = n(),
    .groups = "drop"
  ) |>
  mutate(
    review_group = factor(
      review_group,
      levels = c(
        "100–499 reviews",
        "500–999 reviews",
        "1,000+ reviews"
      )
    ),
    label = paste0(
      round(average_rating, 2),
      " stars\n",
      restaurant_count,
      " restaurants"
    )
  )

ratings_plot <- ggplot(
  rating_summary,
  aes(
    x = review_group,
    y = average_rating,
    group = 1
  )
) +
  geom_line(
    color = "#4D4D4D",
    linewidth = 1.2
  ) +
  geom_point(
    color = "#D95F02",
    size = 7
  ) +
  geom_text(
    aes(label = label),
    vjust = -1,
    size = 4
  ) +
  scale_y_continuous(
    limits = c(3.5, 5),
    breaks = seq(3.5, 5, 0.25)
  ) +
  labs(
    title = "Do Restaurants With More Reviews Have Higher Ratings?",
    subtitle = "Average Yelp rating by review-volume group",
    x = "Number of Yelp reviews",
    y = "Average Yelp star rating"
  ) +
  project_theme +
  theme(
    panel.grid.major.x = element_blank(),
    axis.text.x = element_text(
      size = 11
    )
  )

ggsave(
  here("figures", "ratings_and_reviews.png"),
  ratings_plot,
  width = 10,
  height = 6,
  dpi = 300
)

cat("\nAll final findings graphs were created successfully.\n")