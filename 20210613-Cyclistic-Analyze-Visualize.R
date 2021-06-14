# Author  : Ginanjar Saputra (ginsaputra@outlook.com)
# Version : 2021-06-13

###########################################################################
# 1. SETUP
###########################################################################

# 1.1. Set working directory
setwd("D:/Coursera/Google-Data-Analytics/8-Capstone/Cyclistic")
load("Cyclistic-Trip-Data-2020.RData")
load("Cyclistic-Station-Coord.RData")

# 1.2. Load libraries
library(tidyverse)
library(lubridate)
library(ggplot2)
library(leaflet)
library(mapview)

# 1.3. Set color palette for graphs
pink_purple = c(
  "member" = "#DF6589FF",
  "casual" = "#3C1053FF")

###########################################################################
# 2. ANALYSIS
###########################################################################

# 2.1. Ridership proportion
ridership <- trips_clean %>%
  group_by(member_casual) %>%                      # Group data by ridership
  summarize(count = n(), .groups="drop") %>%       # Counting number of rides
  mutate(pct = 100*count/sum(count))
write.csv(ridership, file = "tbl-1-ridership.csv") # Store results

# 2.2. Number of rides, by date and ridership
rides_2020 <- trips_clean %>%
  group_by(date = date(started_at), member_casual) %>%  
  summarize(count = n(), .groups = "drop")
pivot_rides_2020 <- rides_2020 %>%  # Pivot results of the grouping
  pivot_wider(names_from = member_casual, values_from = count) %>%
  mutate(total = member + casual)
write.csv(pivot_rides_2020, file = "tbl-2-rides-2020.csv")

# 2.3. Number of rides, by month and ridership
rides_monthly <- trips_clean %>%
  group_by(month = month(started_at, label = TRUE), member_casual) %>%
  summarize(count = n(), .groups = "drop")
pivot_rides_monthly <- rides_monthly %>%
  pivot_wider(names_from = member_casual, values_from = count) %>%
  mutate(total = member + casual)
write.csv(pivot_rides_monthly, file = "tbl-3-rides-monthly.csv")

# 2.4. Number of rides, by day-of-week and ridership
rides_dow <- trips_clean %>%
  group_by(day_of_week, member_casual) %>%
  summarize(count = n(), .groups = "drop")
pivot_rides_dow <- rides_dow %>%
  pivot_wider(names_from = member_casual, values_from = count) %>%
  mutate(total = member + casual)
write.csv(pivot_rides_dow, file = "tbl-4-rides-weekly.csv")

# 2.5. Rides duration
duration_stats <- trips_clean %>%
  group_by(member_casual) %>%
  summarize(Min = min(ride_minutes),  # Get descriptive statistics
            Q1 = quantile(ride_minutes, .25),
            Median = quantile(ride_minutes, .50),
            Q3 = quantile(ride_minutes, .75),
            Max = max(ride_minutes),
            Mean = mean(ride_minutes),
            SD = sd(ride_minutes))
write.csv(duration_stats, file = "tbl-5-duration-stats.csv")

# 2.6. Median rides duration, by day-of-week and ridership
duration_dow <- trips_clean %>%
  group_by(day_of_week, member_casual) %>%
  summarize(median_duration = median(ride_minutes), .groups = "drop") %>%
  pivot_wider(names_from = member_casual, values_from = median_duration)
write.csv(duration_dow, file = "tbl-6-duration-dow.csv")

# 2.7. Median rides duration, by season and ridership
season_vec <- c("Spring", "Summer", "Fall", "Winter")
duration_season <- trips_clean %>%
  group_by(season, member_casual) %>%
  summarize(median_duration = median(ride_minutes), .groups = "drop") %>%
  .[order(match(.$season, season_vec)),]  # Sort seasons chronologically
pivot_duration_season <- duration_season %>%
  pivot_wider(names_from = member_casual, values_from = median_duration)
write.csv(pivot_duration_season, file = "tbl-7-duration-season.csv")

# 2.8 Number of rides, by rideable type and ridership
rideables <- trips_clean %>%
  group_by(rideable_type, member_casual) %>%
  filter(rideable_type != "docked_bike") %>%  # Omit type "docked_bike"
  summarize(count = n(), .groups = "drop")
pivot_rideables <- rideables %>%
  pivot_wider(names_from = member_casual, values_from = count)
write.csv(pivot_rideables, file = "tbl-8-rideables.csv")

# 2.9. Median rides duration, by rideable type and day-of-week
rideables_dow <- trips_clean %>%
  group_by(day_of_week, rideable_type, member_casual) %>%
  filter(rideable_type != "docked_bike") %>%
  summarize(median_duration = median(ride_minutes), .groups = "drop")
pivot_rideables_dow <- rideables_dow %>%
  pivot_wider(names_from = member_casual, values_from = median_duration)
write.csv(pivot_rideables_dow, file = "tbl-9-rideables-dow.csv")

###########################################################################
# 3. VISUALIZATION
###########################################################################

ridership %>%  # Plot 1. Ridership proportion
  ggplot(aes(x = "", y = count, fill = member_casual)) +
  geom_bar(position = "fill", stat = "identity") +
  labs(
    title = "Cyclistic Ridership (2020)",
    fill = "Ridership",
    y = NULL) +
  theme(
    axis.title.x = element_blank(),
    axis.text.x = element_blank(),
    axis.ticks.x = element_blank()) +
  scale_fill_manual(values = pink_purple)

rides_2020 %>%  # Plot 2. Rides by date (totals)
  ggplot(aes(x = date, y = count, color = member_casual)) +
  geom_line() +
  labs(
    title = "Total Rides by Date",
    color = "Ridership",
    x = NULL,
    y = "Number of rides") +
  theme(legend.position = "bottom") +
  scale_color_manual(values = pink_purple)

rides_monthly %>%  # Plot 3. Rides by month (totals)
  ggplot(aes(x = month, y = count, fill = member_casual)) +
  geom_bar(stat = "identity") +
  labs(
    title = "Total Rides by Month",
    fill = "Ridership",
    x = NULL,
    y = "Number of rides") +
  theme(legend.position = "bottom") +
  scale_fill_manual(values = pink_purple)

rides_monthly %>%  # Plot 4. Rides by month (proportions)
  ggplot(aes(x = month, y = count, fill = member_casual)) +
  geom_bar(position = "fill", stat = "identity") +
  labs(
    title = "Ridership Proportion by Month",
    fill = "Ridership",
    x = NULL,
    y = NULL) +
  theme(legend.position = "bottom") +
  scale_fill_manual(values = pink_purple)

rides_dow %>%  # Plot 5. Rides by day-of-week (totals)
  ggplot(aes(x = day_of_week, y = count, fill = member_casual)) +
  geom_bar(stat="identity") +
  labs(
    title = "Total Rides by Day-of-Week",
    fill = "Ridership",
    x = NULL,
    y = "Number of rides") +
  theme(legend.position = "bottom") +
  scale_fill_manual(values = pink_purple)

rides_dow %>%  # Plot 6. Rides by day-of-week (proportions)
  ggplot(aes(x = day_of_week, y = count, fill = member_casual)) +
  geom_bar(position="fill", stat="identity") +
  labs(
    title = "Ridership Proportion by Day-of-Week",
    fill = "Ridership",
    x = NULL,
    y = NULL) +
  theme(legend.position = "bottom") +
  scale_fill_manual(values = pink_purple)

trips_clean %>%  # Plot 7. Rides duration distribution
  ggplot(aes(x = member_casual, y = ride_minutes, fill = member_casual)) +
  geom_boxplot(alpha = 0.5) +
  labs(
    title = "Rides Duration Between Ridership",
    fill = "Ridership",
    x = NULL,
    y = "Rides duration (minutes)") +
  theme(legend.position = "none") +
  scale_fill_manual(values = pink_purple) +
  # Too many outliers, plot zoomed in to y-max = 90
  coord_cartesian(ylim=c(0,90))

trips_clean %>%  # Plot 8. Rides duration, distribution by day
  ggplot(aes(x = day_of_week, y = ride_minutes, fill = member_casual)) +
  geom_boxplot(alpha = 0.5) +
  labs(
    title = "Rides Duration by Day-of-Week",
    fill = "Ridership",
    x = NULL,
    y = "Rides duration (minutes)") +
  theme(legend.position = "bottom") +
  scale_fill_manual(values = pink_purple) +
  coord_cartesian(ylim=c(0,60))

duration_season %>%  # Plot 9. Median rides duration by season
  ggplot(aes(x = season, y = median_duration, fill = member_casual)) +
  geom_bar(position = "dodge", stat = "identity") +
  labs(
    title = "Rides Duration Between Ridership: Seasonal Median",
    fill = "Ridership",
    x = NULL,
    y = "Rides duration (minutes)") +
  theme(legend.position = "bottom") +
  scale_fill_manual(values = pink_purple) +
  scale_x_discrete(limits = season_vec)

rideables %>%  # Plot 10. Rides by rideable type (proportion)
  ggplot(aes(x = rideable_type, y = count, fill = member_casual)) +
  geom_bar(position = "fill", stat = "identity") +
  labs(
    title = "Preferred Type of Rideable",
    fill = "Ridership",
    x = NULL,
    y = NULL) +
  theme(legend.position = "bottom") +
  scale_fill_manual(values = pink_purple)

rideables_dow %>% # Plot 11. Median rides duration, by rideable, by day
  ggplot(aes(x = day_of_week, y = median_duration, fill = member_casual)) +
  geom_bar(position = "dodge", stat = "identity") +
  facet_wrap(~ rideable_type) +
  labs(
    title = "Median Rides Duration by Rideable Type",
    fill = "Ridership",
    x = NULL,
    y = "Rides duration (minutes)") +
  theme(legend.position = "bottom") +
  scale_fill_manual(values = pink_purple)

# Plot 12. Start station map distribution
pal <- colorFactor(
  palette = c("#DF6589FF", "#3C1053FF"),
  levels = c("member", "casual"))

station_map <- leaflet(station_coord) %>%
  addTiles() %>%
  addCircleMarkers(
    ~start_lng,
    ~start_lat,
    radius = runif(100, 3, 10),
    color = ~pal(member_casual),
    popup = ~as.character(start_station_name)) %>%
  addLegend(
    "bottomright",
    color = c("#DF6589FF", "#3C1053FF"),
    labels = c("member", "casual"),
    title = "Ridership")

mapshot(station_map, url = "20210613-Cyclistic-Station-Map.html")
