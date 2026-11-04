# Install packages once if needed
install.packages(c("jsonlite", "tidyverse", "here"))

# Load packages
library(jsonlite)
library(tidyverse)
library(here)

# Import the Yelp business file
business_raw <- stream_in(
  file(
    here(
      "data",
      "raw",
      "yelp_academic_dataset_business.json"
    )
  ),
  pagesize = 10000,
  verbose = TRUE
)

# Inspect the data
glimpse(business_raw)
dim(business_raw)
names(business_raw)

# Keep only the columns needed for the project
business_small <- business_raw |>
  select(
    business_id,
    name,
    address,
    city,
    state,
    postal_code,
    latitude,
    longitude,
    stars,
    review_count,
    is_open,
    categories
  )

# Filter for restaurants in New Orleans, Louisiana
new_orleans_restaurants <- business_small |>
  filter(
    state == "LA",
    city == "New Orleans",
    !is.na(categories),
    str_detect(
      categories,
      regex("(^|,\\s*)Restaurants(,|$)", ignore_case = TRUE)
    )
  )

# Check the filtered data
glimpse(new_orleans_restaurants)
dim(new_orleans_restaurants)

# Save the filtered data as an RDS file
saveRDS(
  new_orleans_restaurants,
  here(
    "data",
    "new_orleans",
    "new_orleans_restaurants.rds"
  )
)
# Remove large objects to free memory
rm(business_raw, business_small)
gc()

# Location of the review file
review_file <- here(
  "data",
  "raw",
  "yelp_academic_dataset_review.json"
)

# IDs of the New Orleans restaurants
new_orleans_ids <- new_orleans_restaurants$business_id

# Empty list for filtered review pages
review_chunks <- list()

# Read the large review file in pages
stream_in(
  file(review_file),
  pagesize = 5000,
  handler = function(page) {
    
    filtered_page <- page |>
      filter(business_id %in% new_orleans_ids) |>
      select(
        review_id,
        user_id,
        business_id,
        stars,
        date,
        useful,
        funny,
        cool,
        text
      )
    
    if (nrow(filtered_page) > 0) {
      review_chunks[[length(review_chunks) + 1]] <<- filtered_page
    }
  },
  verbose = TRUE
)

# Combine the filtered pages
new_orleans_reviews <- bind_rows(review_chunks)

# Check the result
glimpse(new_orleans_reviews)
dim(new_orleans_reviews)

# Save the filtered reviews
saveRDS(
  new_orleans_reviews,
  here(
    "data",
    "new_orleans",
    "new_orleans_reviews.rds"
  )
)
restaurants_check <- readRDS(
  here(
    "data",
    "new_orleans",
    "new_orleans_restaurants.rds"
  )
)

reviews_check <- readRDS(
  here(
    "data",
    "new_orleans",
    "new_orleans_reviews.rds"
  )
)

dim(restaurants_check)
dim(reviews_check)

head(restaurants_check)
head(reviews_check)