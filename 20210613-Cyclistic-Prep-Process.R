# Author  : Ginanjar Saputra (ginsaputra@outlook.com)
# Version : 2021-06-13

###########################################################################
# 1. SETUP
###########################################################################

# 1.1. Set working directory
setwd("D:/Coursera/Google-Data-Analytics/8-Capstone/Cyclistic")

# 1.2. Load libraries
library(tidyverse)
library(lubridate)

###########################################################################
# 2. LOAD DATA SETS
###########################################################################

# 2.1. Download the data
# Link: "https://divvy-tripdata.s3.amazonaws.com/index.html"
# Unzip CSV files, store in a folder "Datasets" under working directory

# 2.2. Read CSV files
directory <- "Datasets"
csv_list <- list.files(                   # Make a list of CSV file names
  path = directory, pattern = "*.csv", full.names = TRUE)
read_files <- lapply(csv_list, read.csv)  # Read each CSV in the list

# 2.3. Merge into a single data frame
trips <- bind_rows(
  read_files[10],   # 2020 Jan-Mar
  read_files[1:8],  # 2020 Apr-Nov
  transform(        # Make data types consistent
    read_files[9],  # 2020 Dec
    start_station_id = as.numeric(start_station_id),
    end_station_id = as.numeric(end_station_id)))

###########################################################################
# 3. DATA PROCESSING
###########################################################################

# 3.1. Ensure data types are appropriate
trips_clean <- trips %>% mutate(
  started_at = as_datetime(started_at),  # Timestamp columns as `dttm`
  ended_at = as_datetime(ended_at))

# 3.2. Check for missing values
missing_values <- trips_clean %>%
  sapply(function(x) sum(is.na(x))) %>%
  as.data.frame() %>%
  rename(., nulls = .) %>%
  mutate(col = colnames(trips), .before = nulls)
rownames(missing_values) <- 1:nrow(missing_values)

missing_values %>%  # Plot nulls occurrence across columns
  ggplot(aes(y = col, x = nulls)) +
  geom_bar(stat = "identity", fill = "#DF6589FF") +
  labs(
    title = "Mising Values",
    x = NULL,
    y = "Column")

# 3.3. Create new columns for derived values
trips_clean <- trips_clean %>%
  mutate(
    day_of_week = wday(started_at, label = TRUE, week_start = 1),
    ride_minutes = difftime(ended_at, started_at, units = "mins"),
    season = case_when(
      month(started_at) %in% c(12, 1, 2) ~ "Winter",
      month(started_at) %in% c(3, 4, 5) ~ "Spring",
      month(started_at) %in% c(6, 7, 8) ~ "Summer",
      month(started_at) %in% c(9, 10, 11) ~ "Fall")) %>%
  mutate(ride_minutes = as.numeric(ride_minutes))

# 3.4. Address incorrect or irrelevant values
name_filter <- c(
  "", " ", "HQ QR", "WATSON TESTING - DIVVY",
  "HUBBARD ST BIKE CHECKING (LBS-WH-TEST)")
trips_clean <- trips_clean %>%
  filter(ride_minutes > 0) %>%
  filter(!(start_station_name %in% name_filter) &
           !(end_station_name %in% name_filter))

# 3.5. Create separate data frame for start station map
station_coord <- select(trips_clean, c(
  start_station_name, member_casual, start_lat, start_lng)) %>%
  group_by(start_station_name, member_casual, start_lat, start_lng) %>%
  summarize(num_rides = n(), .groups = "drop") %>%
  arrange(., desc(num_rides)) %>%
  slice(., 1:200)  # Select 200 stations with the highest total rides

# 3.6. Drop irrelevant columns
trips_clean <- select(trips_clean, -c(
  start_station_id, end_station_id,      # Drop columns with too many nulls
  start_station_name, end_station_name,  # also those not used for analysis
  start_lat, start_lng, end_lat, end_lng, ride_id))

###########################################################################
# 4. STORE CLEANED DATA
###########################################################################
save(trips_clean, file = "Cyclistic-Trip-Data-2020.RData")
save(station_coord, file = "Cyclistic-Station-Coord.RData")
write.csv(trips_clean, file = "Cyclistic-Trip-Data-2020.csv")
write.csv(station_coord, file = "Cyclistic-Station-Coord.csv")