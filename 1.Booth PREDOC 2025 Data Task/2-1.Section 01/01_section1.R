# ==============================================================================
# 2025 PREDOC DATA TASK | SECTION 1: DATA PROCESSING AND SUMMARIZING
# Questions 1-1 through 1-6 | Base R only | One script, six output folders
# ==============================================================================

# ------------------------------------------------------------------------------
# SETUP | Input paths, output folders, and reusable functions
# ------------------------------------------------------------------------------

# Portable paths: work from this Section 1 RStudio Project or project root.
current_dir <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
project_root <- if (basename(current_dir) == "2-1.Section 01") {
  dirname(current_dir)
} else {
  current_dir
}
input_dir    <- file.path(project_root, "1.Database")
section_dir  <- file.path(project_root, "2-1.Section 01")
output_root  <- file.path(section_dir, "Output")
if (!dir.exists(input_dir)) stop("Missing input folder: ", input_dir)

for (question in paste0("1-", 1:6)) {
  dir.create(file.path(output_root, question), recursive = TRUE,
             showWarnings = FALSE)
}
#create son-folders to store different complete answers

out_file <- function(question, filename) {
  file.path(output_root, question, filename)
}

write_csv <- function(object, question, filename) {
  write.csv(object, out_file(question, filename), row.names = FALSE, na = "")
}

# Select the two official downloads using their distinctive filenames.
# Stop if zero or multiple files match, rather than silently choosing one.
find_input <- function(pattern) {
  if (!dir.exists(input_dir)) stop("Input directory does not exist: ", input_dir)
  candidates <- list.files(input_dir, pattern = pattern, full.names = TRUE,
                           ignore.case = TRUE)
  if (length(candidates) != 1L) {
    stop("Expected exactly one input matching '", pattern, "' in ", input_dir,
         "; found ", length(candidates), ". Files: ",
         paste(basename(candidates), collapse = ", "))
  }
  candidates[[1L]]
}

# The official downloads have .Rdata extensions but can be RDS files.
# Fall back to load() only for a genuine RData workspace file.
read_official_data <- function(path) {
  result <- tryCatch(readRDS(path), error = function(e) NULL)
  if (is.null(result)) {
    temp_env <- new.env(parent = emptyenv())
    object_names <- load(path, envir = temp_env)
    if (length(object_names) != 1L) {
      stop("Expected one data object in ", basename(path),
           "; found ", length(object_names))
    }
    result <- get(object_names[[1L]], envir = temp_env)
  }
  if (!is.data.frame(result)) {
    stop("Input is not a data frame: ", basename(path))
  }
  as.data.frame(result)
}

# Normalize identifiers as STRINGS to preserve geographic leading zeros.
normalize_id <- function(x, width, variable) {
  raw <- trimws(as.character(x))
  raw[is.na(x) | raw == "" | raw == "NA"] <- NA_character_
  valid <- is.na(raw) | grepl("^[0-9]+(\\.0+)?$", raw)
  if (any(!valid)) stop(variable, ": nonnumeric identifier(s) found")
  digits <- sub("\\.0+$", "", raw)
  if (any(!is.na(digits) & nchar(digits) > width)) {
    stop(variable, ": identifier longer than expected width ", width)
  }
  output <- rep(NA_character_, length(digits))
  keep <- !is.na(digits)
  output[keep] <- sprintf(paste0("%0", width, "d"), as.integer(digits[keep]))
  output
}

# Accept the two date formats observed in the official downloads.
normalize_date <- function(x, variable) {
  if (inherits(x, "Date")) return(as.Date(x))
  if (inherits(x, "POSIXt")) return(as.Date(x))
  raw <- trimws(as.character(x))
  raw[is.na(x) | raw == ""] <- NA_character_
  result <- as.Date(raw, format = "%Y-%m-%d")
  pending <- !is.na(raw) & is.na(result)
  result[pending] <- as.Date(raw[pending], format = "%m/%d/%Y")
  if (any(!is.na(raw) & is.na(result))) {
    stop(variable, ": some dates could not be parsed")
  }
  result
}

ensure_columns <- function(data, expected, dataset_name) {
  absent <- setdiff(expected, names(data))
  if (length(absent)) {
    stop(dataset_name, ": missing variables: ", paste(absent, collapse = ", "))
  }
}

# Keep duplicates in an audit file; never silently drop or average them.
check_unique_keys <- function(data, keys, dataset_name) {
  signature <- do.call(paste, c(data[keys], sep = "|"))
  duplicated_rows <- duplicated(signature) | duplicated(signature, fromLast = TRUE)
  if (any(duplicated_rows)) {
    write_csv(data[duplicated_rows, , drop = FALSE], "1-1",
              paste0("1-1_duplicate_keys_", dataset_name, ".csv"))
    stop(dataset_name, ": duplicate county-monitor-day keys. Review 1-1 audit file.")
  }
}

safe_mean <- function(x) {
  x <- x[!is.na(x)]
  if (length(x) == 0L) NA_real_ else mean(x)
}

safe_stat <- function(x) {
  x <- suppressWarnings(as.numeric(x))
  x <- x[!is.na(x)]
  if (length(x) == 0L) {
    return(data.frame(n = 0L, mean = NA_real_, median = NA_real_,
                      min = NA_real_, max = NA_real_, sd = NA_real_))
  }
  data.frame(n = length(x), mean = mean(x), median = median(x),
             min = min(x), max = max(x),
             sd = if (length(x) > 1L) sd(x) else NA_real_)
}

# Return the single nonmissing value within a group. A conflict is not guessed.
unique_nonmissing <- function(x) {
  if (is.character(x)) {
    x <- trimws(x)
    x[x == ""] <- NA_character_
  }
  unique(x[!is.na(x)])
}

# ------------------------------------------------------------------------------
# 1-1 | Standardize keys, verify uniqueness, merge monitor-day observations
# ------------------------------------------------------------------------------

ozone_path <- find_input("ozone.*\\.(rdata|rda|rds)$")
pm25_path  <- find_input("pm.*\\.(rdata|rda|rds)$")

ozone <- read_official_data(ozone_path)
pm25  <- read_official_data(pm25_path)

ensure_columns(ozone,
  c("county_code", "county_name", "date", "siteid", "cbsacode",
    "cbsaname", "aqi", "ozone_source", "ozone_value", "mortality"), "ozone")
ensure_columns(pm25,
  c("county_code", "date", "siteid", "pm25_source", "pm25_value"), "pm25")

for (source_name in c("ozone", "pm25")) {
  data <- get(source_name)
  data$county_code <- normalize_id(data$county_code, 3, "county_code")
  data$siteid      <- normalize_id(data$siteid, 9, "siteid")
  data$date        <- normalize_date(data$date, "date")
  assign(source_name, data)
}

# Preserve CBSA code as a 5-digit identifier (NA is allowed).
ozone$cbsacode <- normalize_id(ozone$cbsacode, 5, "cbsacode")
ozone$county_name  <- as.character(ozone$county_name)
ozone$cbsaname     <- as.character(ozone$cbsaname)
ozone$ozone_source <- as.character(ozone$ozone_source)
pm25$pm25_source   <- as.character(pm25$pm25_source)

for (variable in c("aqi", "ozone_value", "mortality")) {
  ozone[[variable]] <- as.numeric(ozone[[variable]])
}
pm25$pm25_value <- as.numeric(pm25$pm25_value)

keys <- c("county_code", "siteid", "date")
if (anyNA(ozone[keys]) || anyNA(pm25[keys])) {
  stop("Missing merge key(s) detected; do not merge until investigated.")
}
check_unique_keys(ozone, keys, "ozone")
check_unique_keys(pm25, keys, "pm25")

ozone$.in_ozone <- TRUE
pm25$.in_pm25   <- TRUE

# FULL OUTER JOIN: retain ozone-only and PM2.5-only monitor-days.
merged <- merge(ozone, pm25, by = keys, all = TRUE, sort = TRUE)
merged$merge_status <- ifelse(!is.na(merged$.in_ozone) &
                                !is.na(merged$.in_pm25), "matched",
                              ifelse(!is.na(merged$.in_ozone),
                                     "ozone_only", "pm25_only"))
merged$.in_ozone <- NULL
merged$.in_pm25  <- NULL
merged <- merged[order(merged$county_code, merged$date, merged$siteid), ]
row.names(merged) <- NULL

merge_labels <- c("matched", "ozone_only", "pm25_only")
merge_audit <- data.frame(
  merge_status = merge_labels,
  n_monitor_days = as.integer(table(factor(merged$merge_status,
                                           levels = merge_labels)))
)
write_csv(merge_audit, "1-1", "1-1_merge_audit.csv")
write_csv(merged[merged$merge_status != "matched", , drop = FALSE],
          "1-1", "1-1_unmatched_monitor_days.csv")
write_csv(merged, "1-1", "1-1_merged_monitor_day.csv")
saveRDS(merged, out_file("1-1", "1-1_merged_monitor_day.rds"))
print(merge_audit)
cat("1-1 completed: ", nrow(merged), " monitor-day observations.\n", sep = "")

# ------------------------------------------------------------------------------
# 1-2 | Summary statistics for ozone, PM2.5, and AQI (merged sample)
# ------------------------------------------------------------------------------

pollution_fields <- c("ozone_value", "pm25_value", "aqi")
summary_all <- do.call(rbind, lapply(pollution_fields, function(variable) {
  stats <- safe_stat(merged[[variable]])
  data.frame(variable = variable, n_total_rows = nrow(merged),
             n_nonmissing = stats$n, n_missing = nrow(merged) - stats$n,
             mean = stats$mean, median = stats$median,
             min = stats$min, max = stats$max, sd = stats$sd)
}))
row.names(summary_all) <- NULL
write_csv(summary_all, "1-2", "1-2_pollution_summary.csv")
print(summary_all)

# ------------------------------------------------------------------------------
# 1-3 | Ozone statistics by measurement source (AQS vs. AirNow)
# ------------------------------------------------------------------------------

ozone_sources <- trimws(toupper(merged$ozone_source))
source_levels <- c("AQS", "AIRNOW")
summary_sources <- do.call(rbind, lapply(source_levels, function(source) {
  mask <- !is.na(ozone_sources) & ozone_sources == source
  stats <- safe_stat(merged$ozone_value[mask])
  data.frame(ozone_source = ifelse(source == "AIRNOW", "AirNow", source),
             n_observations = sum(mask), n_nonmissing = stats$n,
             n_missing = sum(mask) - stats$n,
             mean = stats$mean, median = stats$median,
             min = stats$min, max = stats$max, sd = stats$sd)
}))
row.names(summary_sources) <- NULL
write_csv(summary_sources, "1-3", "1-3_ozone_by_source.csv")
print(summary_sources)

unexpected_sources <- sort(unique(ozone_sources[
  !is.na(ozone_sources) & !(ozone_sources %in% source_levels)]))
if (length(unexpected_sources)) {
  writeLines(paste("Unrecognized source(s):", paste(unexpected_sources,
                  collapse = ", ")), out_file("1-3", "1-3_source_warning.txt"))
  warning("Unknown ozone source categories were not included in the Q3 table.")
}

# ------------------------------------------------------------------------------
# 1-4 | Data-quality interpretation (English discussion; descriptive only)
# ------------------------------------------------------------------------------

fmt_number <- function(x, digits = 5) {
  if (length(x) == 0L || is.na(x)) "NA" else format(round(x, digits),
                                                     trim = TRUE, scientific = FALSE)
}

aqs_stats    <- summary_sources[summary_sources$ozone_source == "AQS", ]
airnow_stats <- summary_sources[summary_sources$ozone_source == "AirNow", ]

if (aqs_stats$n_nonmissing > 0L && airnow_stats$n_nonmissing > 0L) {
  comparison <- paste0(
    "The observed mean ozone reading is ", fmt_number(aqs_stats$mean),
    " for AQS (n = ", aqs_stats$n_nonmissing, ") and ",
    fmt_number(airnow_stats$mean), " for AirNow (n = ",
    airnow_stats$n_nonmissing, "). Their standard deviations are ",
    fmt_number(aqs_stats$sd), " and ", fmt_number(airnow_stats$sd),
    ", respectively. These descriptive differences alone do not establish a difference in measurement quality.")
} else {
  comparison <- paste0(
    "The merged data contain ", aqs_stats$n_nonmissing,
    " nonmissing AQS ozone readings and ", airnow_stats$n_nonmissing,
    " nonmissing AirNow readings; a two-source distribution comparison may be uninformative.")
}

q4_lines <- c(
  "# 1-4 | AQS vs. AirNow: Data-Quality Discussion",
  "",
  "## What the summary table shows",
  "", comparison, "",
  "## Interpretation",
  "",
  "- Differences in sample means, dispersion, or extremes can signal different composition or reporting practices, but are NOT by themselves proof of lower data quality.",
  "- AQS measurements undergo the validation/certification process used for regulatory purposes; AirNow data are more timely and are not fully validated to the same standard.",
  "- Source selection by county, site, day, and weather may explain apparent differences even when both measurements are accurate.",
  "",
  "## Additional evidence that would help (discussion only)",
  "",
  "1. Pair AQS and AirNow readings for the SAME site, date, and pollutant when overlapping source records are available; examine systematic measurement differences.",
  "2. Compare validation flags, completeness, missingness, corrections, instrument calibration, and outlier rates by source.",
  "3. Compare distributions conditional on county/site, season, and weather to reduce differences in sample composition.",
  "4. Examine later certified AQS records as a benchmark for preliminary AirNow observations, where linkage is defensible.",
  "",
  "Reference: https://www.airnow.gov/about-the-data/"
)
writeLines(q4_lines, out_file("1-4", "1-4_data_quality_discussion.md"),
           useBytes = TRUE)
cat("1-4 completed: English discussion saved.\n")

# ------------------------------------------------------------------------------
# 1-5 | Aggregate monitor-day records to one county-day observation
# ------------------------------------------------------------------------------

# Check county-level attributes: counties may have missing CBSA, but must not
# have two different nonmissing values for the same county.
county_parts <- split(ozone, ozone$county_code)
county_conflicts <- list()
county_metadata <- do.call(rbind, lapply(names(county_parts), function(code) {
  data <- county_parts[[code]]
  fields <- c("county_name", "cbsacode", "cbsaname")
  chosen <- lapply(fields, function(f) unique_nonmissing(data[[f]]))
  names(chosen) <- fields
  inconsistent <- fields[vapply(chosen, length, integer(1)) > 1L]
  if (length(inconsistent)) {
    county_conflicts[[length(county_conflicts) + 1L]] <<- data.frame(
      county_code = code, conflicting_field = paste(inconsistent, collapse = "; "))
  }
  data.frame(county_code = code,
             county_name = if (length(chosen$county_name) == 1L) chosen$county_name else NA_character_,
             cbsacode = if (length(chosen$cbsacode) == 1L) chosen$cbsacode else NA_character_,
             cbsaname = if (length(chosen$cbsaname) == 1L) chosen$cbsaname else NA_character_)
}))
row.names(county_metadata) <- NULL
if (length(county_conflicts)) {
  write_csv(do.call(rbind, county_conflicts), "1-5",
            "1-5_county_metadata_conflicts.csv")
  stop("Conflicting county/CBSA metadata found. Review 1-5 audit output.")
}

# Most mortality values are repeated across monitors or missing. Use the ONE
# county-day value, never the sum of mortality over monitor rows.
record_groups <- split(seq_len(nrow(merged)),
                       paste(merged$county_code, merged$date, sep = "|"))
mortality_conflicts <- list()

county_day_list <- lapply(record_groups, function(idx) {
  data <- merged[idx, , drop = FALSE]
  unique_mortality <- unique_nonmissing(data$mortality)
  if (length(unique_mortality) > 1L) {
    mortality_conflicts[[length(mortality_conflicts) + 1L]] <<- data.frame(
      county_code = data$county_code[1], date = as.character(data$date[1]),
      n_values = length(unique_mortality),
      values = paste(unique_mortality, collapse = "; "))
  }
  data.frame(
    county_code = data$county_code[1],
    date = data$date[1],
    ozone_value = safe_mean(data$ozone_value),
    pm25_value = safe_mean(data$pm25_value),
    aqi = safe_mean(data$aqi),
    mortality = if (length(unique_mortality) == 1L) unique_mortality else NA_real_,
    n_monitor_days = nrow(data),
    n_ozone_readings = sum(!is.na(data$ozone_value)),
    n_pm25_readings = sum(!is.na(data$pm25_value)),
    n_aqi_readings = sum(!is.na(data$aqi)),
    stringsAsFactors = FALSE
  )
})

if (length(mortality_conflicts)) {
  write_csv(do.call(rbind, mortality_conflicts), "1-5",
            "1-5_mortality_conflicts.csv")
  stop("More than one mortality value in some county-days. Review 1-5 audit output.")
}

county_day <- do.call(rbind, county_day_list)
row.names(county_day) <- NULL
metadata_row <- match(county_day$county_code, county_metadata$county_code)
county_day$county_name <- county_metadata$county_name[metadata_row]
county_day$cbsacode   <- county_metadata$cbsacode[metadata_row]
county_day$cbsaname   <- county_metadata$cbsaname[metadata_row]
county_day <- county_day[, c("county_code", "county_name", "date", "cbsacode",
                             "cbsaname", "ozone_value", "pm25_value", "aqi",
                             "mortality", "n_monitor_days", "n_ozone_readings",
                             "n_pm25_readings", "n_aqi_readings")]
county_day <- county_day[order(county_day$county_code, county_day$date), ]
row.names(county_day) <- NULL

# Integrity check: precisely one row for each county-day.
county_day_key <- paste(county_day$county_code, county_day$date, sep = "|")
stopifnot(!anyDuplicated(county_day_key))

write_csv(county_day, "1-5", "1-5_county_day_panel.csv")
saveRDS(county_day, out_file("1-5", "1-5_county_day_panel.rds"))
writeLines(c(
  "# 1-5 | Aggregation Method",
  "",
  "- Unit: one row per (county_code, date).",
  "- Ozone, PM2.5, and AQI: arithmetic mean of all available monitor readings in the county on that date (missing values ignored).",
  "- Mortality: the unique nonmissing county-day synthetic death count; never summed or averaged over monitors. Conflicting counts stop the script.",
  "- County name and CBSA fields: unique nonmissing county-level values from the ozone dataset; missing CBSA assignments remain missing.",
  "- The *_readings columns report the number of nonmissing monitors contributing to each mean.",
  "- This is an equally weighted MONITOR average, not a population-weighted exposure estimate or an official county-level EPA AQI.",
  "- Days with only one observed pollutant remain in the panel; the other pollutant may be NA."
), out_file("1-5", "1-5_aggregation_method.md"), useBytes = TRUE)
cat("1-5 completed: ", nrow(county_day), " county-days.\n", sep = "")

# ------------------------------------------------------------------------------
# 1-6 | Count counties missing any calendar days during 2024 (leap year)
# ------------------------------------------------------------------------------

calendar_days <- seq(as.Date("2024-01-01"), as.Date("2024-12-31"), by = "day")
if (any(county_day$date < min(calendar_days) |
        county_day$date > max(calendar_days))) {
  stop("Observed dates outside 2024; review the calendar definition for 1-6.")
}

counties <- sort(unique(county_day$county_code))
expected <- data.frame(
  county_code = rep(counties, each = length(calendar_days)),
  date = rep(calendar_days, times = length(counties)),
  stringsAsFactors = FALSE
)
expected_key <- paste(expected$county_code, expected$date, sep = "|")
expected$present <- expected_key %in% county_day_key
missing_dates <- expected[!expected$present, c("county_code", "date"), drop = FALSE]
meta_idx <- match(missing_dates$county_code, county_metadata$county_code)
missing_dates$county_name <- county_metadata$county_name[meta_idx]
missing_dates <- missing_dates[, c("county_code", "county_name", "date")]

missing_n <- vapply(counties, function(code) {
  sum(missing_dates$county_code == code)
}, integer(1))
county_counts <- data.frame(
  county_code = counties,
  county_name = county_metadata$county_name[
    match(counties, county_metadata$county_code)],
  expected_days = length(calendar_days),
  observed_days = length(calendar_days) - missing_n,
  missing_days = missing_n,
  missing_any_day = missing_n > 0L
)
summary_missing <- data.frame(
  year = 2024L,
  days_in_year = length(calendar_days),
  n_counties = length(counties),
  n_counties_missing_days = sum(county_counts$missing_any_day),
  n_counties_complete = sum(!county_counts$missing_any_day),
  total_missing_county_days = nrow(missing_dates)
)

write_csv(summary_missing, "1-6", "1-6_summary.csv")
write_csv(county_counts, "1-6", "1-6_missing_days_by_county.csv")
write_csv(missing_dates, "1-6", "1-6_missing_dates.csv")
writeLines(c(
  "# 1-6 | Missing County-Days",
  "",
  paste0("**Counties missing at least one day:** ",
         summary_missing$n_counties_missing_days, " of ", summary_missing$n_counties, "."),
  paste0("**Total missing county-days:** ",
         summary_missing$total_missing_county_days, "."),
  "",
  "Definition: every county appearing in the merged data is expected to have one row",
  "for each calendar day from 2024-01-01 through 2024-12-31 (366 days).",
  "A missing day means NO county-day row, not merely a missing value of a pollutant",
  "or a missing mortality observation on a present row."
), out_file("1-6", "1-6_interpretation.md"), useBytes = TRUE)
print(summary_missing)
cat("Completed Section 1. Outputs saved under:\n", output_root, "\n")
