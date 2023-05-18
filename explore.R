
# NEON forecasts Bookdown
# https://projects.ecoforecast.org/neon4cast-docs/

# install the NEON forecasts R-package
remotes::install_github("eco4cast/neon4cast")

# get the site data
site_dat <- readr::read_csv("https://raw.githubusercontent.com/eco4cast/neon4cast-targets/main/NEON_Field_Site_Metadata_20220412.csv") |> 
  dplyr::filter(beetles == 1)
head(site_dat)

# load the beetle data
dat <- readr::read_csv("https://data.ecoforecast.org/neon4cast-targets/beetles/beetles-targets.csv.gz", guess_max = 1e6)
head(dat)

# load the processed weather data
weather_stage3 <- neon4cast::noaa_stage3()
weather_stage3 |> 
  dplyr::filter(site_id == "BART") |>
  dplyr::collect()