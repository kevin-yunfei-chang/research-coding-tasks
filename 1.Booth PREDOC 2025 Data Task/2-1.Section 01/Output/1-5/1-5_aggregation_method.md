# 1-5 | Aggregation Method

- Unit: one row per (county_code, date).
- Ozone, PM2.5, and AQI: arithmetic mean of all available monitor readings in the county on that date (missing values ignored).
- Mortality: the unique nonmissing county-day synthetic death count; never summed or averaged over monitors. Conflicting counts stop the script.
- County name and CBSA fields: unique nonmissing county-level values from the ozone dataset; missing CBSA assignments remain missing.
- The *_readings columns report the number of nonmissing monitors contributing to each mean.
- This is an equally weighted MONITOR average, not a population-weighted exposure estimate or an official county-level EPA AQI.
- Days with only one observed pollutant remain in the panel; the other pollutant may be NA.
