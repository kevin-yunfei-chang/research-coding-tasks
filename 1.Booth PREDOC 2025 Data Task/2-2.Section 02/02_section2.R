# ==============================================================================
# 2025 PREDOC DATA TASK | SECTION 2: VISUALIZING THE DATA
# Questions 2-1 and 2-2 | Base R only | Independent RStudio Project
# ==============================================================================
#
# HOW TO RUN:
# 1. Open Section02.Rproj in RStudio.
# 2. Run the SETUP block below.
# 3. Run Q2-1, then Q2-2, one block at a time (Cmd + Return on macOS).
# 4. Check Output/2-1 and Output/2-2.
#
# This script reads exactly ONE external file:
# ../2-1.Section 01/Output/1-5/1-5_county_day_panel.rds
# It does not search fallback locations, rerun Section 1, or modify the input.
# ==============================================================================

# ------------------------------------------------------------------------------
# SETUP | Project paths, input validation, output folders, helpers
# ------------------------------------------------------------------------------

# Allow execution either from the Section 2 .Rproj or from the parent .Rproj.
working_dir <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
if (basename(working_dir) == "2-2.Section 02") {
  section_dir <- working_dir
} else if (dir.exists(file.path(working_dir, "2-2.Section 02"))) {
  section_dir <- normalizePath(file.path(working_dir, "2-2.Section 02"),
                               winslash = "/", mustWork = TRUE)
} else {
  stop("Open Section02.Rproj (or the parent project) before running the script.")
}

project_root <- dirname(section_dir)

# FIXED SOURCE: only the user's Section 1 county-day panel is accepted.
input_file <- file.path(project_root, "2-1.Section 01", "Output", "1-5",
                        "1-5_county_day_panel.rds")
if (!file.exists(input_file)) {
  stop("Required Section 1 input file not found:\n", input_file,
       "\nRun Section 1 question 1-5 first. No fallback file will be used.")
}

output_root <- file.path(section_dir, "Output")
for (question in c("2-1", "2-2")) {
  dir.create(file.path(output_root, question),
             recursive = TRUE, showWarnings = FALSE)
  if (!dir.exists(file.path(output_root, question))) {
    stop("Unable to create output directory for ", question)
  }
}

out_file <- function(question, filename) {
  file.path(output_root, question, paste0(question, "_", filename))
}

write_csv <- function(x, question, filename) {
  write.csv(x, out_file(question, filename),
            row.names = FALSE, na = "")
}

# Safe converter: require actual numeric values, not silently coerced factors.
validate_numeric <- function(x, name) {
  if (!is.numeric(x)) {
    stop(name, " must be numeric. Check Section 1 output.")
  }
  invisible(TRUE)
}

panel <- readRDS(input_file)
if (!is.data.frame(panel)) {
  stop("Section 1 input is not a data frame.")
}
required_fields <- c("county_code", "county_name", "date",
                     "ozone_value", "pm25_value")
missing_fields <- setdiff(required_fields, names(panel))
if (length(missing_fields)) {
  stop("Required field(s) missing: ", paste(missing_fields, collapse = ", "))
}
if (!inherits(panel$date, "Date")) {
  stop("The date column must have Date class in the Section 1 RDS file.")
}
if (anyNA(panel$date) || anyNA(panel$county_code)) {
  stop("The county-day panel contains missing county/date keys.")
}
validate_numeric(panel$ozone_value, "ozone_value")
validate_numeric(panel$pm25_value, "pm25_value")
panel$county_code <- sprintf("%03d", as.integer(as.character(panel$county_code)))
if (anyNA(panel$county_code)) {
  stop("Non-numeric county identifiers detected.")
}

county_day_key <- paste(panel$county_code, panel$date, sep = "|")
if (anyDuplicated(county_day_key)) {
  stop("The Section 1 input contains duplicate county-day keys.")
}

cat("SECTION 2 SETUP COMPLETE\n",
    "Working directory: ", working_dir, "\n",
    "Section 2 folder:  ", section_dir, "\n",
    "Fixed input file:  ", input_file, "\n",
    "County-days:       ", nrow(panel), "\n",
    "Output directory:  ", output_root, "\n", sep = "")

# ------------------------------------------------------------------------------
# 2-1 | Overlaid Ozone and PM2.5 distributions after Z-score standardization
# ------------------------------------------------------------------------------

# Use the COUNTY-DAY panel produced in Section 1, Q1-5.
# Z = (X - mean(X)) / sd(X), computed separately for each pollutant.
# The source measurement units and distribution shape are retained in the
# original variables; the plot compares shapes on a common standardized axis.

ozone_raw <- panel$ozone_value[is.finite(panel$ozone_value)]
pm25_raw  <- panel$pm25_value[is.finite(panel$pm25_value)]

if (length(ozone_raw) < 2L || length(pm25_raw) < 2L ||
    sd(ozone_raw) <= 0 || sd(pm25_raw) <= 0) {
  stop("Q2-1 needs at least two finite, nonconstant observations per pollutant.")
}

summary_q21 <- data.frame(
  variable = c("ozone_value", "pm25_value"),
  n_total_county_days = nrow(panel),
  n_finite = c(length(ozone_raw), length(pm25_raw)),
  n_missing_or_nonfinite = c(nrow(panel) - length(ozone_raw),
                             nrow(panel) - length(pm25_raw)),
  original_mean = c(mean(ozone_raw), mean(pm25_raw)),
  original_sd = c(sd(ozone_raw), sd(pm25_raw)),
  original_min = c(min(ozone_raw), min(pm25_raw)),
  original_max = c(max(ozone_raw), max(pm25_raw))
)

ozone_z <- as.numeric(scale(ozone_raw))
pm25_z  <- as.numeric(scale(pm25_raw))

# Use a COMMON smoothing bandwidth; both KDEs use all finite observations.
common_bw <- bw.nrd0(c(ozone_z, pm25_z))
if (!is.finite(common_bw) || common_bw <= 0) {
  stop("Could not determine positive common bandwidth.")
}
common_from <- min(ozone_z, pm25_z) - 3 * common_bw
common_to <- max(ozone_z, pm25_z) + 3 * common_bw

ozone_density <- density(ozone_z, bw = common_bw, from = common_from,
                         to = common_to, n = 4096)
pm25_density <- density(pm25_z, bw = common_bw, from = common_from,
                        to = common_to, n = 4096)

density_table <- data.frame(
  standardized_value = ozone_density$x,
  ozone_density = ozone_density$y,
  pm25_density = pm25_density$y
)

write_csv(summary_q21, "2-1", "standardization_summary.csv")
write_csv(density_table, "2-1", "kde_coordinates.csv")

# The main view shows the central 99% pooled range for readability.
# The full-range figure below retains the complete standardized x-range.
main_xlim <- as.numeric(quantile(
  c(ozone_z, pm25_z), probs = c(0.005, 0.995), na.rm = TRUE
))
if (!all(is.finite(main_xlim)) || diff(main_xlim) <= 0) {
  stop("Invalid central-range plot limits.")
}

draw_density_figure <- function(filename, x_limits, title, subtitle) {
  png(filename, width = 2400, height = 1500, res = 240)
  on.exit(dev.off(), add = TRUE)
  par(mar = c(5.2, 5.2, 4.2, 1.4),
      family = "sans", cex.axis = 1.05, cex.lab = 1.1)
  ymax <- 1.12 * max(ozone_density$y, pm25_density$y)
  plot(ozone_density$x, ozone_density$y, type = "n",
       xlim = x_limits, ylim = c(0, ymax),
       xlab = "Standardized concentration (Z-score)",
       ylab = "Kernel density",
       main = title, sub = subtitle)
  grid(col = "grey90", lty = 1)
  abline(v = 0, col = "grey55", lty = 3, lwd = 1.4)
  lines(ozone_density$x, ozone_density$y,
        col = "#245A81", lwd = 3.2)
  lines(pm25_density$x, pm25_density$y,
        col = "#C06A31", lwd = 3.2)
  legend("topright",
         legend = c(sprintf("Ozone (n=%s)", format(length(ozone_z), big.mark = ",")),
                    sprintf("PM2.5 (n=%s)", format(length(pm25_z), big.mark = ","))),
         col = c("#245A81", "#C06A31"), lwd = 3.2,
         bty = "n", cex = 0.94)
}

draw_density_figure(
  out_file("2-1", "standardized_distributions_main.png"),
  main_xlim, "Ozone and PM2.5 distributions",
  "County-day observations | Z-scores | central 99% of pooled values shown"
)

draw_density_figure(
  out_file("2-1", "standardized_distributions_full.png"),
  range(common_from, common_to), "Ozone and PM2.5 distributions (full range)",
  "All finite observations used for both density estimates"
)

writeLines(c(
  "# Question 2-1 | Distribution Plot Notes",
  "",
  "- Input: Section 1 county-day panel (Q1-5).",
  "- Each pollutant is standardized independently: z = (x - mean(x)) / sd(x).",
  "- Two KDE lines share a single standardized x-axis and a common density y-axis.",
  "- A common kernel bandwidth is applied to both series.",
  "- The main plot displays the central 99% of pooled standardized values.",
  "- The full-range plot shows the entire KDE x-axis; no finite observation",
  "  is dropped from either KDE calculation to create the main plot.",
  "- The variables represent monitor-averaged county-day pollution readings,",
  "  not monitor-day raw values or population-weighted exposures.",
  "- A Z-score comparison is about relative distributions, NOT pollution",
  "  concentration magnitudes or health equivalence across pollutants."
), out_file("2-1", "plot_notes.md"), useBytes = TRUE)

cat("2-1 complete: plots and summary saved to ", file.path(output_root, "2-1"), "\n", sep = "")

# ------------------------------------------------------------------------------
# 2-2 | Los Angeles County (037) Ozone time series | February 2024
# ------------------------------------------------------------------------------

feb_dates <- seq(as.Date("2024-02-01"), as.Date("2024-02-29"), by = "day")
la <- panel[panel$county_code == "037" &
              panel$date >= min(feb_dates) &
              panel$date <= max(feb_dates),
            c("date", "ozone_value"), drop = FALSE]

if (nrow(la) == 0L) {
  stop("No Los Angeles (county code 037) observations during February 2024.")
}
if (anyDuplicated(la$date)) {
  stop("Unexpected duplicate Los Angeles county-days in February 2024.")
}

# Explicitly show missing calendar days as NA; lines will break at those gaps.
la_feb <- data.frame(date = feb_dates, stringsAsFactors = FALSE)
la_feb$ozone_value <- la$ozone_value[match(la_feb$date, la$date)]
la_feb$observed <- !is.na(la_feb$ozone_value)
if (sum(la_feb$observed) == 0L) {
  stop("No nonmissing LA County ozone observations in February 2024.")
}
write_csv(la_feb, "2-2", "los_angeles_february_daily_ozone.csv")

fig_path <- out_file("2-2", "los_angeles_february_ozone.png")
png(fig_path, width = 2400, height = 1450, res = 240)
par(mar = c(5.5, 5.2, 4.5, 1.5), family = "sans",
    cex.axis = 1.05, cex.lab = 1.05)

vals <- la_feb$ozone_value[la_feb$observed]
range_vals <- range(vals)
padding <- if (diff(range_vals) > 0) 0.12 * diff(range_vals) else max(abs(vals[1]) * 0.1, 0.001)
ylim <- range_vals + c(-padding, padding)

plot(la_feb$date, la_feb$ozone_value,
     type = "n", xlim = range(feb_dates), ylim = ylim,
     xaxt = "n", xlab = "February 2024",
     ylab = "County-average ozone (source units)",
     main = "Los Angeles County (037): daily ozone",
     sub = "County-day mean across available monitors")
grid(col = "grey90", lty = 1)
axis.Date(1, at = feb_dates[seq(1, length(feb_dates), by = 4)],
          format = "%b %d")
lines(la_feb$date, la_feb$ozone_value,
      col = "#245A81", lwd = 2.8)
points(la_feb$date[la_feb$observed],
       la_feb$ozone_value[la_feb$observed],
       pch = 16, cex = 0.83, col = "#245A81")
mtext(sprintf("Observed: %d/29 days | Missing: %d | Gaps are not interpolated",
              sum(la_feb$observed), sum(!la_feb$observed)),
      side = 1, line = 4.3, cex = 0.76, col = "grey35")
dev.off()

la_metadata <- data.frame(
  county_code = "037",
  county_name = "Los Angeles",
  period = "2024-02",
  days_in_month = length(feb_dates),
  observed_days = sum(la_feb$observed),
  missing_days = sum(!la_feb$observed),
  ozone_mean = mean(vals),
  ozone_min = min(vals),
  ozone_max = max(vals)
)
write_csv(la_metadata, "2-2", "time_series_summary.csv")

writeLines(c(
  "# Question 2-2 | Serial Correlation Discussion",
  "",
  "Daily ozone concentrations may be serially correlated because weather",
  "conditions, emissions, and atmospheric processes can persist across days.",
  "Runs of consecutive high or low values in the time-series plot would be",
  "consistent with positive autocorrelation, but visual patterns alone do",
  "not establish its presence.",
  "",
  "One could inspect a lag-1 scatter plot or the autocorrelation function (ACF),",
  "or estimate a simple AR(1) regression of today's ozone on yesterday's ozone.",
  "For a formal test, a Ljung-Box test on an appropriately specified series",
  "or a serial-correlation test on model residuals could be considered.",
  "Any missing days should be handled as calendar gaps, not treated as",
  "consecutive observed dates.",
  "",
  "**No autocorrelation test was performed, as requested.**"
), out_file("2-2", "autocorrelation_discussion.md"), useBytes = TRUE)

cat("2-2 complete: figure, daily series, summary, and discussion saved to ",
    file.path(output_root, "2-2"), "\n", sep = "")
cat("SECTION 2 FINISHED. Output root: ", output_root, "\n", sep = "")
