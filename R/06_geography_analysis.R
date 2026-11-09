# Step 6: Compare and defend geographic areas

# Install packages only if they are missing
packages_needed <- c("sf", "tigris", "tidyverse", "here")

packages_missing <- packages_needed[
  !packages_needed %in% rownames(installed.packages())
]

if (length(packages_missing) > 0) {
  install.packages(packages_missing)
}

# Load packages
suppressPackageStartupMessages({
  library(sf)
  library(tigris)
  library(tidyverse)
  library(here)
})

# Store Census boundary files locally
options(tigris_use_cache = TRUE)

# Create the figures folder
dir.create(
  here("figures"),
  recursive = TRUE,
  showWarnings = FALSE
)

# ---------------------------------------------------------
# 1. Load the filtered New Orleans restaurant data
# ---------------------------------------------------------

new_orleans_restaurants <- readRDS(
  here(
    "data",
    "new_orleans",
    "new_orleans_restaurants.rds"
  )
)

# Make sure latitude and longitude are numeric
new_orleans_restaurants <- new_orleans_restaurants |>
  mutate(
    latitude = as.numeric(latitude),
    longitude = as.numeric(longitude)
  )

# Keep restaurants with valid coordinates
restaurant_points <- new_orleans_restaurants |>
  filter(
    !is.na(latitude),
    !is.na(longitude),
    is.finite(latitude),
    is.finite(longitude)
  ) |>
  st_as_sf(
    coords = c("longitude", "latitude"),
    crs = 4326,
    remove = FALSE
  )

# ---------------------------------------------------------
# 2. Download geographic boundaries
# ---------------------------------------------------------

# ZIP Code Tabulation Areas
zcta_boundaries <- zctas(
  cb = TRUE,
  year = 2020,
  class = "sf"
)

# Census tracts in Orleans Parish, Louisiana
tract_boundaries <- tracts(
  state = "LA",
  county = "Orleans",
  cb = TRUE,
  year = 2020,
  class = "sf"
)

# ---------------------------------------------------------
# 3. Put all geographic data in the same CRS
# ---------------------------------------------------------

zcta_boundaries <- zcta_boundaries |>
  st_transform(4326)

tract_boundaries <- tract_boundaries |>
  st_transform(4326)

restaurant_points <- restaurant_points |>
  st_transform(4326)

# ---------------------------------------------------------
# 4. Assign restaurants to ZIP Code Tabulation Areas
# ---------------------------------------------------------

restaurants_zcta <- st_join(
  restaurant_points,
  zcta_boundaries |>
    select(ZCTA5CE20),
  join = st_within,
  left = TRUE
) |>
  rename(
    zcta = ZCTA5CE20
  )

# ---------------------------------------------------------
# 5. Assign restaurants to Census tracts
# ---------------------------------------------------------

restaurants_tract <- st_join(
  restaurant_points,
  tract_boundaries |>
    select(GEOID, NAME),
  join = st_within,
  left = TRUE
) |>
  rename(
    tract = GEOID,
    tract_name = NAME
  )

# ---------------------------------------------------------
# 6. Summarize ZIP Code areas
# ---------------------------------------------------------

zcta_area_summary <- restaurants_zcta |>
  st_drop_geometry() |>
  filter(!is.na(zcta)) |>
  group_by(zcta) |>
  summarise(
    restaurant_count = n(),
    average_rating = mean(stars, na.rm = TRUE),
    total_reviews = sum(review_count, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(desc(restaurant_count))

# ---------------------------------------------------------
# 7. Summarize Census tracts
# ---------------------------------------------------------

tract_area_summary <- restaurants_tract |>
  st_drop_geometry() |>
  filter(!is.na(tract)) |>
  group_by(tract, tract_name) |>
  summarise(
    restaurant_count = n(),
    average_rating = mean(stars, na.rm = TRUE),
    total_reviews = sum(review_count, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(desc(restaurant_count))

# ---------------------------------------------------------
# 8. Create the comparison table
# ---------------------------------------------------------

geography_comparison <- tibble(
  geographic_system = c(
    "ZIP Code Tabulation Area",
    "Census tract"
  ),
  
  number_of_areas = c(
    nrow(zcta_area_summary),
    nrow(tract_area_summary)
  ),
  
  restaurants_assigned = c(
    sum(!is.na(restaurants_zcta$zcta)),
    sum(!is.na(restaurants_tract$tract))
  ),
  
  unmatched_restaurants = c(
    sum(is.na(restaurants_zcta$zcta)),
    sum(is.na(restaurants_tract$tract))
  ),
  
  smallest_area_count = c(
    min(zcta_area_summary$restaurant_count),
    min(tract_area_summary$restaurant_count)
  ),
  
  largest_area_count = c(
    max(zcta_area_summary$restaurant_count),
    max(tract_area_summary$restaurant_count)
  ),
  
  average_area_rating = c(
    mean(zcta_area_summary$average_rating, na.rm = TRUE),
    mean(tract_area_summary$average_rating, na.rm = TRUE)
  )
)

print(geography_comparison)

# Save the comparison table
write_csv(
  geography_comparison,
  here(
    "figures",
    "geography_comparison.csv"
  )
)

# ---------------------------------------------------------
# 9. Create map limits
# ---------------------------------------------------------

restaurant_bbox <- st_bbox(restaurant_points)

map_xlim <- c(
  as.numeric(restaurant_bbox["xmin"]) - 0.03,
  as.numeric(restaurant_bbox["xmax"]) + 0.03
)

map_ylim <- c(
  as.numeric(restaurant_bbox["ymin"]) - 0.03,
  as.numeric(restaurant_bbox["ymax"]) + 0.03
)

# ---------------------------------------------------------
# 10. Create the ZIP Code map
# ---------------------------------------------------------

zcta_map <- ggplot() +
  geom_sf(
    data = zcta_boundaries,
    fill = "gray95",
    color = "gray55",
    linewidth = 0.3
  ) +
  geom_sf(
    data = restaurants_zcta,
    aes(color = stars),
    size = 1.3,
    alpha = 0.7
  ) +
  scale_color_viridis_c(
    option = "C",
    limits = c(1, 5),
    name = "Yelp rating"
  ) +
  coord_sf(
    xlim = map_xlim,
    ylim = map_ylim,
    expand = FALSE
  ) +
  labs(
    title = "New Orleans Restaurants by ZIP Code Area",
    subtitle = "Restaurant locations colored by Yelp rating",
    caption = "Sources: Yelp Open Dataset and U.S. Census TIGER/Line data"
  ) +
  theme_minimal()

print(zcta_map)

ggsave(
  filename = here(
    "figures",
    "restaurants_zcta_map.png"
  ),
  plot = zcta_map,
  width = 10,
  height = 7,
  dpi = 300
)

# ---------------------------------------------------------
# 11. Create the Census tract map
# ---------------------------------------------------------

tract_map <- ggplot() +
  geom_sf(
    data = tract_boundaries,
    fill = "gray95",
    color = "gray55",
    linewidth = 0.4
  ) +
  geom_sf(
    data = restaurants_tract,
    aes(color = stars),
    size = 1.3,
    alpha = 0.7
  ) +
  scale_color_viridis_c(
    option = "C",
    limits = c(1, 5),
    name = "Yelp rating"
  ) +
  coord_sf(
    xlim = map_xlim,
    ylim = map_ylim,
    expand = FALSE
  ) +
  labs(
    title = "New Orleans Restaurants by Census Tract",
    subtitle = "Restaurant locations colored by Yelp rating",
    caption = "Sources: Yelp Open Dataset and U.S. Census TIGER/Line data"
  ) +
  theme_minimal()

print(tract_map)

ggsave(
  filename = here(
    "figures",
    "restaurants_tract_map.png"
  ),
  plot = tract_map,
  width = 10,
  height = 7,
  dpi = 300
)

# ---------------------------------------------------------
# 12. Create a comparison plot
# ---------------------------------------------------------

zcta_plot_data <- zcta_area_summary |>
  mutate(
    geographic_system = "ZIP Code Tabulation Area"
  ) |>
  transmute(
    geographic_system,
    area = zcta,
    restaurant_count,
    average_rating
  )

tract_plot_data <- tract_area_summary |>
  mutate(
    geographic_system = "Census tract"
  ) |>
  transmute(
    geographic_system,
    area = tract,
    restaurant_count,
    average_rating
  )

area_plot_data <- bind_rows(
  zcta_plot_data,
  tract_plot_data
)

geography_plot <- ggplot(
  area_plot_data,
  aes(
    x = restaurant_count,
    y = average_rating,
    color = geographic_system
  )
) +
  geom_point(
    size = 2,
    alpha = 0.7
  ) +
  labs(
    title = "Restaurant Counts and Ratings by Geographic Area",
    x = "Number of restaurants in the area",
    y = "Average Yelp rating",
    color = "Geographic system"
  ) +
  theme_minimal()

print(geography_plot)

ggsave(
  filename = here(
    "figures",
    "geography_comparison_plot.png"
  ),
  plot = geography_plot,
  width = 10,
  height = 7,
  dpi = 300
)

# ---------------------------------------------------------
# 13. Display the busiest areas
# ---------------------------------------------------------

cat("\nTop ZIP Code areas by restaurant count:\n")

print(
  zcta_area_summary |>
    arrange(desc(restaurant_count)) |>
    slice_head(n = 10)
)

cat("\nTop Census tracts by restaurant count:\n")

print(
  tract_area_summary |>
    arrange(desc(restaurant_count)) |>
    slice_head(n = 10)
)