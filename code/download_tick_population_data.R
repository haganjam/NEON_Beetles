
# NEON forecasts Bookdown
# https://projects.ecoforecast.org/neon4cast-docs/

# load relevant libraries
library(dplyr)
library(lubridate)

# get the site data
site_dat <- readr::read_csv("https://raw.githubusercontent.com/eco4cast/neon4cast-targets/main/NEON_Field_Site_Metadata_20220412.csv") |> 
  dplyr::filter(ticks == 1)
head(site_dat)

# load the tick population data
dat <- readr::read_csv("https://data.ecoforecast.org/neon4cast-targets/ticks/ticks-targets.csv.gz", guess_max = 1e6)
head(dat)
dim(dat)

# convert the date variable to a datetime variable
dat <- 
  dat |>
  dplyr::mutate(datetime = lubridate::as_datetime(dat$datetime, tz = "UTC"))

# get a vector of site names
site_names <- unique(dat$site_id)

# load the processed weather data
weather_stage3 <- neon4cast::noaa_stage3()

weather <- vector("list", length = length(site_names))
for(i in 1:length(site_names)) {

  date_vec <- 
    dat |>
    dplyr::filter(site_id == site_names[i]) |>
    dplyr::pull(datetime) |>
    unique()
  
  x <- 
    weather_stage2 |> 
    dplyr::filter(site_id == site_names[i], datetime %in% date_vec) |>
    dplyr::collect()
  
  y <- 
    x |>
    dplyr::group_by(site_id, datetime, variable) |>
    dplyr::summarise(prediction_m = mean(prediction, na.rm = TRUE),
                     prediction_min = min(prediction, na.rm = TRUE),
                     prediction_max = max(prediction, na.rm = TRUE),
                     prediction_cv = sd(prediction, na.rm = TRUE)/mean(prediction, na.rm = TRUE)) |>
    dplyr::ungroup()
  
  weather[[i]] <- y
  
  rm(x, y)
  
}

# remove the weather_stage3 object
rm(weather_stage3)

# bind into a data.frame
weather_df <- dplyr::bind_rows(weather)

# write this into a rds file
saveRDS(object = weather_df, file = "data/weather_data_raw.rds")

# pull into a data.frame with all variables as columns

# make a vector of relevant variables
weath_vars <- unique(weather_df$variable)

# set-up an output list
weath_list <- vector("list", length = length(weath_vars))

# loop over all the different weather variables
for(i in 1:length(weath_vars)) {
  
  temp_df <- 
    weather_df |>
    dplyr::filter(variable == weath_vars[i]) |>
    dplyr::select(-site_id, -datetime, -variable)
  
  names(temp_df) <- paste0(weath_vars[i], "_", c("m", "min", "max", "cv"))
  
  weath_list[[i]] <- temp_df
  
}

# bind the columns together
weath_sum <- dplyr::bind_cols(weath_list)

# add the identifier columns
weath_sum <- dplyr::bind_cols(weather_df |>
                                dplyr::select(site_id, datetime) |>
                                distinct(),
                              weath_sum
                              )

# save the tick abundance data
saveRDS(dat, file = "data/tick_population_data.rds")

# save the summarised meteorology outputs
saveRDS(weath_sum, file = "data/weather_data_summary.rds")

### END
