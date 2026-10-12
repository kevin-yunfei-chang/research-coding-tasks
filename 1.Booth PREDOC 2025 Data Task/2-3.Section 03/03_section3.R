# ==============================================================================
# 2025 PREDOC DATA TASK | SECTION 3: POLLUTION AND MORTALITY
# Questions 3-1 to 3-4 | Regressions + automatic journal-style LaTeX table
# ==============================================================================
# INSTRUCTIONS
# 1. Open Section03.Rproj (located next to this file).
# 2. Run SETUP, then 3-1, 3-2, 3-3, 3-4, and FINAL TABLE in order.
# 3. The script AUTOMATICALLY reads the original Section 1 county-day RDS.
# 4. R calculates ALL coefficients; no hard-coded regression results exist.
# 5. A real .tex table is ALWAYS exported. If pdflatex is on your Mac,
#    a real .pdf is generated as well. LaTeX sources are zipped when possible.
# ============================================================================== 

# ------------------------------------------------------------------------------
# SETUP | Reproducible paths, exact input, package, data checks, helper functions
# ------------------------------------------------------------------------------

wd <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
if (basename(wd) == "2-3.Section 03") {
  section_dir <- wd
} else if (dir.exists(file.path(wd, "2-3.Section 03"))) {
  section_dir <- normalizePath(file.path(wd, "2-3.Section 03"),
                               winslash = "/", mustWork = TRUE)
} else {
  stop("Open Section03.Rproj or its parent project before running this code.")
}
project_root <- dirname(section_dir)

# ONLY this file is accepted. There is no alternative search path.
input_file <- file.path(project_root, "2-1.Section 01", "Output", "1-5",
                        "1-5_county_day_panel.rds")
if (!file.exists(input_file)) {
  stop("Fixed Section 1 input not found:\n", input_file,
       "\nPlease run Section 1 Question 1-5 first.")
}

output_root <- file.path(section_dir, "Output")
for (folder in c("3-1", "3-2", "3-3", "3-4", "Regression_Tables")) {
  dir.create(file.path(output_root, folder), recursive = TRUE,
             showWarnings = FALSE)
  if (!dir.exists(file.path(output_root, folder))) {
    stop("Failed to create output folder: ", folder)
  }
}
path_out <- function(question, filename) {
  file.path(output_root, question, paste0(question, "_", filename))
}
write_csv <- function(x, question, filename) {
  write.csv(x, path_out(question, filename), row.names = FALSE, na = "")
}

# fixest is the only additional R package. Install only when needed.
if (!requireNamespace("fixest", quietly = TRUE)) {
  message("Installing required CRAN package: fixest")
  install.packages("fixest", repos = "https://cloud.r-project.org")
}
if (!requireNamespace("fixest", quietly = TRUE)) {
  stop("The 'fixest' package could not be loaded. Check Internet/package setup.")
}

panel <- readRDS(input_file)
if (!is.data.frame(panel)) stop("Input RDS must contain a data frame.")
required <- c("county_code", "date", "aqi", "mortality", "cbsacode")
missing_columns <- setdiff(required, names(panel))
if (length(missing_columns) > 0L) {
  stop("Missing required columns: ", paste(missing_columns, collapse = ", "))
}
if (!inherits(panel$date, "Date") || anyNA(panel$date)) {
  stop("Section 1 input must have a nonmissing Date-class date column.")
}
if (!is.numeric(panel$aqi) || !is.numeric(panel$mortality)) {
  stop("AQI and mortality must be numeric, not factors or character strings.")
}
raw_county <- trimws(as.character(panel$county_code))
if (anyNA(raw_county) || any(!grepl("^[0-9]{1,3}$", raw_county))) {
  stop("County codes must be numeric-looking identifiers with 1-3 digits.")
}
panel$county_code <- sprintf("%03d", as.integer(raw_county))

key <- paste(panel$county_code, format(panel$date, "%Y-%m-%d"), sep = "|")
if (anyDuplicated(key)) stop("Duplicate county-day records in Section 1 input.")

# Section 1 Q1-5 provides a county-wide CBSA assignment (or NA).
cbsa_raw <- trimws(as.character(panel$cbsacode))
cbsa_raw[is.na(panel$cbsacode) | cbsa_raw %in% c("", "NA", "N/A", "00000", "0")] <- NA_character_
panel$in_cbsa <- as.integer(!is.na(cbsa_raw))

county_groups <- split(panel$in_cbsa, panel$county_code)
cbsa_inconsistent <- names(county_groups)[vapply(county_groups, function(x) {
  length(unique(x)) != 1L
}, logical(1))]
if (length(cbsa_inconsistent) > 0L) {
  stop("CBSA status is not constant within county: ",
       paste(cbsa_inconsistent, collapse = ", "))
}

# Treat Inf/-Inf as missing instead of sending invalid values to estimation.
panel$aqi[!is.finite(panel$aqi)] <- NA_real_
panel$mortality[!is.finite(panel$mortality)] <- NA_real_
panel$aqi_cbsa <- panel$aqi * panel$in_cbsa

# True CALENDAR lag: for county i on date t, retrieve AQI from date t-1.
# An absent day does not become yesterday merely because it is the previous row.
previous_key <- paste(panel$county_code,
                      format(panel$date - 1L, "%Y-%m-%d"), sep = "|")
prev_index <- match(previous_key, key)
panel$aqi_lag1 <- panel$aqi[prev_index]

# A reproducible sample audit to document the impact of missing outcomes/lags.
panel$sample_31 <- !is.na(panel$mortality) & !is.na(panel$aqi)
panel$sample_32 <- panel$sample_31 & !is.na(panel$aqi_lag1)
panel$sample_33 <- panel$sample_31 & !is.na(panel$aqi_cbsa)

audit <- data.frame(
  sample = c("all_county_days", "3-1_baseline", "3-2_lagged", "3-3_cbsa"),
  n_county_days = c(nrow(panel), sum(panel$sample_31),
                    sum(panel$sample_32), sum(panel$sample_33)),
  n_counties = c(length(unique(panel$county_code)),
                 length(unique(panel$county_code[panel$sample_31])),
                 length(unique(panel$county_code[panel$sample_32])),
                 length(unique(panel$county_code[panel$sample_33])))
)
write.csv(audit, file.path(output_root, "3-1", "3-1_sample_audit.csv"),
          row.names = FALSE)

if (sum(panel$sample_31) < 10L || sum(panel$sample_32) < 10L) {
  stop("Too few complete observations to estimate the TWFE regressions.")
}

# Model output helper. Coefficient table columns: estimate, SE, statistic, p.
export_model <- function(model, question, label) {
  ct <- fixest::coeftable(model)
  tab <- data.frame(
    term = rownames(ct), estimate = as.numeric(ct[, 1]),
    std_error = as.numeric(ct[, 2]), t_stat = as.numeric(ct[, 3]),
    p_value = as.numeric(ct[, 4]), row.names = NULL
  )
  write_csv(tab, question, "coefficients.csv")
  saveRDS(model, path_out(question, "model.rds"))
  writeLines(capture.output(print(summary(model))),
             path_out(question, "regression_summary.txt"))
  model_stats <- data.frame(
    model = label, n = stats::nobs(model),
    n_counties = length(unique(model_data[[question]]$county_code)),
    r2 = unname(fixest::r2(model, type = "r2")),
    within_r2 = unname(fixest::r2(model, type = "wr2")),
    se_type = "Clustered by county"
  )
  write_csv(model_stats, question, "model_statistics.csv")
  print(summary(model))
  invisible(tab)
}

model_data <- list()
cat("SECTION 3 SETUP COMPLETE\n",
    "Project: ", project_root, "\n",
    "Input:   ", input_file, "\n",
    "Output:  ", output_root, "\n",
    "Rows:    ", nrow(panel), "\n", sep = "")

# ------------------------------------------------------------------------------
# 3-1 | Baseline OLS with County and Date fixed effects (TWFE)
# ------------------------------------------------------------------------------

# Mortality_it = beta1 * AQI_it + county_FE + date_FE + error_it
# County-clustered SE allow within-county serial correlation of residuals.
model_data[["3-1"]] <- panel[panel$sample_31, , drop = FALSE]
m1 <- fixest::feols(mortality ~ aqi | county_code + date,
                    data = model_data[["3-1"]], vcov = ~county_code)
export_model(m1, "3-1", "Baseline TWFE")

beta_31 <- unname(stats::coef(m1)["aqi"])
if (!is.finite(beta_31)) stop("AQI was not identified in the baseline model.")
writeLines(c(
  "# 3-1 | Baseline Two-Way Fixed Effects",
  "",
  sprintf("Estimated AQI coefficient: %.6f.", beta_31),
  "Conditional on county and date fixed effects, a one-unit higher AQI",
  sprintf("is associated with %.6f units higher synthetic mortality.", beta_31),
  "County FE absorb time-invariant county factors; Date FE absorb common",
  "daily shocks across counties. Neither solves all time-varying confounding.",
  "The outcome is SYNTHETIC; the coefficient is not a real health effect.",
  "Standard errors are clustered by county."
), path_out("3-1", "interpretation.md"), useBytes = TRUE)
cat("3-1 COMPLETE.\n")

# ------------------------------------------------------------------------------
# 3-2 | Add yesterday's AQI (calendar-day lag, not previous available row)
# ------------------------------------------------------------------------------

# Mortality_it = beta1 * AQI_it + beta2 * AQI_i,t-1 + FE_i + FE_t + e_it
model_data[["3-2"]] <- panel[panel$sample_32, , drop = FALSE]
m2 <- fixest::feols(mortality ~ aqi + aqi_lag1 | county_code + date,
                    data = model_data[["3-2"]], vcov = ~county_code)
export_model(m2, "3-2", "Current and previous-day AQI")

co2 <- stats::coef(m2)
if (!all(c("aqi", "aqi_lag1") %in% names(co2))) {
  stop("AQI or lagged AQI is not identified in Model (2).")
}
lag_audit <- data.frame(
  property = c("county_day_rows", "has_real_previous_calendar_day",
               "has_valid_lagged_aqi", "3_2_estimation_rows"),
  count = c(nrow(panel), sum(!is.na(prev_index)),
            sum(!is.na(panel$aqi_lag1)), sum(panel$sample_32))
)
write_csv(lag_audit, "3-2", "lag_audit.csv")
writeLines(c(
  "# 3-2 | Current and Lagged AQI",
  "",
  sprintf("Current AQI coefficient: %.6f.", unname(co2["aqi"])),
  sprintf("Yesterday's AQI coefficient: %.6f.", unname(co2["aqi_lag1"])),
  "The current coefficient is conditional on yesterday's AQI, and",
  "the lag coefficient is conditional on current AQI, with both FE included.",
  "The lag uses EXACTLY date t-1 for the same county; calendar gaps stay NA.",
  "The Model (2) sample may be smaller than Model (1) because lag data are",
  "missing. These are associations, not causal effects. Mortality is synthetic."
), path_out("3-2", "interpretation.md"), useBytes = TRUE)
cat("3-2 COMPLETE.\n")

# ------------------------------------------------------------------------------
# 3-3 | Heterogeneity: AQI x whether county belongs to a CBSA
# ------------------------------------------------------------------------------

# Mortality_it = beta1 * AQI_it + beta3 * (AQI_it * in_cbsa_i) + FE_i + FE_t + e_it
# The main CBSA indicator is ABSORBED by county FE and correctly omitted.
model_data[["3-3"]] <- panel[panel$sample_33, , drop = FALSE]
n_cbsa_counties <- tapply(model_data[["3-3"]]$in_cbsa,
                          model_data[["3-3"]]$county_code, function(x) x[1])
if (length(unique(as.integer(n_cbsa_counties))) < 2L) {
  stop("Only one CBSA group present in estimation sample; cannot estimate heterogeneity.")
}
m3 <- fixest::feols(mortality ~ aqi + aqi_cbsa | county_code + date,
                    data = model_data[["3-3"]], vcov = ~county_code)
export_model(m3, "3-3", "CBSA interaction")

co3 <- stats::coef(m3)
if (!all(c("aqi", "aqi_cbsa") %in% names(co3))) {
  stop("AQI/CBSA interaction not identified: review data variation and FE.")
}

# CBSA slope is beta_AQI + beta_interaction. Delta-method clustered SE.
vc3 <- stats::vcov(m3)
cbsa_slope <- unname(co3["aqi"] + co3["aqi_cbsa"])
cbsa_slope_var <- vc3["aqi", "aqi"] + vc3["aqi_cbsa", "aqi_cbsa"] +
                  2 * vc3["aqi", "aqi_cbsa"]
if (cbsa_slope_var < -1e-10) stop("Invalid CBSA slope variance.")
cbsa_slope_se <- sqrt(max(0, cbsa_slope_var))

cbsa_slopes <- data.frame(
  group = c("Outside CBSA", "Inside CBSA", "Inside minus outside"),
  estimate = c(unname(co3["aqi"]), cbsa_slope,
               unname(co3["aqi_cbsa"])),
  clustered_std_error = c(sqrt(vc3["aqi", "aqi"]), cbsa_slope_se,
                           sqrt(vc3["aqi_cbsa", "aqi_cbsa"]))
)
write_csv(cbsa_slopes, "3-3", "cbsa_marginal_slopes.csv")
write_csv(data.frame(in_cbsa = c(0L, 1L),
                     n_counties = c(sum(n_cbsa_counties == 0),
                                    sum(n_cbsa_counties == 1))),
          "3-3", "cbsa_coverage.csv")
writeLines(c(
  "# 3-3 | CBSA Interaction",
  "",
  sprintf("Outside CBSA: AQI slope = %.6f (beta_AQI).", unname(co3["aqi"])),
  sprintf("Inside CBSA: AQI slope = %.6f (beta_AQI + beta_interaction).", cbsa_slope),
  sprintf("Inside-minus-outside slope difference = %.6f (beta_interaction).",
          unname(co3["aqi_cbsa"])),
  "The inside-CBSA slope SE is obtained using the clustered covariance matrix",
  "and the delta method for the linear combination of coefficients.",
  "The CBSA indicator itself is constant within counties and is absorbed by",
  "county fixed effects. Interpretation remains associational, not causal."
), path_out("3-3", "interpretation.md"), useBytes = TRUE)
cat("3-3 COMPLETE.\n")

# ------------------------------------------------------------------------------
# 3-4 | Explain why the standalone CBSA indicator is collinear with county FE
# ------------------------------------------------------------------------------

# Every county belongs either to a CBSA or not. In this dataset the binary
# indicator is time-invariant. Therefore it is a linear combination of the
# county fixed-effects indicator columns (perfect multicollinearity).
# Fitting an extended model demonstrates that fixest automatically drops it.
m4_check <- fixest::feols(
  mortality ~ aqi + in_cbsa + aqi_cbsa | county_code + date,
  data = model_data[["3-3"]], vcov = ~county_code, notes = FALSE
)
removed_terms <- m4_check$collin.var
if (is.null(removed_terms)) removed_terms <- character(0)

# The substantive fact is analytical. Record the software diagnostic too.
write_csv(data.frame(term = c("in_cbsa"),
                     dropped_by_fixest = c("in_cbsa" %in% removed_terms),
                     time_invariant_within_county = TRUE),
          "3-4", "collinearity_audit.csv")
saveRDS(m4_check, path_out("3-4", "collinearity_check_model.rds"))
writeLines(c(
  "# 3-4 | Why Is the CBSA Main Effect Collinear?",
  "",
  "The CBSA indicator is time-invariant for every county in this dataset.",
  "County fixed effects include a separate intercept for each county;",
  "thus the CBSA indicator is an exact linear combination of these indicators.",
  "It is perfectly collinear with county FE and cannot be separately estimated.",
  "In contrast, AQI x CBSA can vary over time within counties, so its",
  "differential AQI slope may be identified.",
  "",
  paste0("fixest dropped the following terms in the diagnostic fit: ",
         if (length(removed_terms)) paste(removed_terms, collapse = ", ")
         else "none (review model specification/data)")
), path_out("3-4", "collinearity_explanation.md"), useBytes = TRUE)
cat("3-4 COMPLETE.\n")

# ------------------------------------------------------------------------------
# FINAL TABLE | Generate REAL journal-style regression table .tex + optional PDF
# ------------------------------------------------------------------------------

# The main table compares 3-1, 3-2, and 3-3 in THREE COLUMNS.
# No LaTeX coefficients are typed manually. All values come from fixest.
table_dir <- file.path(output_root, "Regression_Tables")

fmt <- function(x, digits = 4L) {
  if (length(x) != 1L || !is.finite(x)) return("--")
  formatC(x, digits = digits, format = "f")
}
get_result <- function(model, term) {
  ct <- fixest::coeftable(model)
  if (!(term %in% rownames(ct))) {
    return(list(cell = "", se = ""))
  }
  b <- as.numeric(ct[term, 1])
  s <- as.numeric(ct[term, 2])
  p <- as.numeric(ct[term, 4])
  stars <- if (is.na(p)) "" else if (p < 0.01) "***" else if (p < 0.05) "**" else if (p < 0.1) "*" else ""
  cell <- paste0(fmt(b), if (nzchar(stars)) paste0("$^{", stars, "}$") else "")
  list(cell = cell, se = paste0("(", fmt(s), ")"))
}

m1_aqi <- get_result(m1, "aqi")
m2_aqi <- get_result(m2, "aqi")
m2_lag <- get_result(m2, "aqi_lag1")
m3_aqi <- get_result(m3, "aqi")
m3_int <- get_result(m3, "aqi_cbsa")

# Helper: produce proper LaTeX table row terminators (\\).
tex_row <- function(label, entries) {
  paste0(label, " & ", paste(entries, collapse = " & "), " \\\\")
}

nfmt <- function(x) format(x, big.mark = ",", scientific = FALSE, trim = TRUE)
models <- list(m1, m2, m3)
model_n <- vapply(models, stats::nobs, numeric(1))
model_r2 <- vapply(models, function(m) unname(fixest::r2(m, "r2")), numeric(1))
model_wr2 <- vapply(models, function(m) unname(fixest::r2(m, "wr2")), numeric(1))
model_clusters <- c(length(unique(model_data[["3-1"]]$county_code)),
                    length(unique(model_data[["3-2"]]$county_code)),
                    length(unique(model_data[["3-3"]]$county_code)))

body <- c(
  "\\begin{table}[!htbp]",
  "\\centering",
  "\\caption{Air Quality and Synthetic Mortality: County--Day Panel}",
  "\\label{tab:pollution_mortality}",
  "\\small",
  "\\setlength{\\tabcolsep}{8pt}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  tex_row("Dependent variable: Synthetic mortality", c("(1)", "(2)", "(3)")),
  tex_row("Specification", c("Baseline TWFE", "Lagged AQI", "CBSA interaction")),
  "\\midrule",
  tex_row("AQI$_{it}$", c(m1_aqi$cell, m2_aqi$cell, m3_aqi$cell)),
  tex_row("", c(m1_aqi$se, m2_aqi$se, m3_aqi$se)),
  "\\addlinespace[3pt]",
  tex_row("AQI$_{i,t-1}$", c("", m2_lag$cell, "")),
  tex_row("", c("", m2_lag$se, "")),
  "\\addlinespace[3pt]",
  tex_row("AQI$_{it}$ $\\times$ CBSA$_i$", c("", "", m3_int$cell)),
  tex_row("", c("", "", m3_int$se)),
  "\\addlinespace[6pt]",
  tex_row("County fixed effects", rep("Yes", 3)),
  tex_row("Date fixed effects", rep("Yes", 3)),
  tex_row("Observations", vapply(model_n, nfmt, character(1))),
  tex_row("County clusters", vapply(model_clusters, nfmt, character(1))),
  tex_row("$R^2$", vapply(model_r2, fmt, character(1))),
  tex_row("Within $R^2$", vapply(model_wr2, fmt, character(1))),
  "\\bottomrule",
  "\\end{tabular}",
  "\\vspace{5pt}",
  "\\begin{minipage}{0.96\\textwidth}",
  "\\footnotesize\\emph{Notes:} Ordinary least squares with county and",
  "calendar-date fixed effects throughout. Standard errors clustered by county",
  "are reported in parentheses. $^{***}p<0.01$, $^{**}p<0.05$,",
  "$^{*}p<0.10$. Model (2) uses the previous calendar day's AQI and may have",
  "fewer observations. CBSA indicates whether the county belongs to a",
  "Core-Based Statistical Area; the indicator's main effect is absorbed by",
  "county fixed effects. The dependent variable is SYNTHETIC, not actual",
  "mortality. Estimates describe associations, not causal effects.",
  "\\end{minipage}",
  "\\end{table}"
)

tex_table <- file.path(table_dir, "3_regression_table.tex")
writeLines(body, tex_table, useBytes = TRUE)

# Wrapper: compiling this creates a one-page standalone PDF when feasible.
wrapper <- c(
  "\\documentclass[11pt]{article}",
  "\\usepackage[letterpaper,margin=0.75in]{geometry}",
  "\\usepackage{booktabs}",
  "\\usepackage[T1]{fontenc}",
  "\\usepackage{lmodern}",
  "\\begin{document}",
  "\\pagestyle{empty}",
  "\\input{3_regression_table.tex}",
  "\\end{document}"
)
tex_main <- file.path(table_dir, "3_regression_table_main.tex")
writeLines(wrapper, tex_main, useBytes = TRUE)

# Mirror all estimates and standard errors in machine-readable form.
all_coef <- do.call(rbind, lapply(seq_along(models), function(k) {
  ct <- fixest::coeftable(models[[k]])
  data.frame(model = k, term = rownames(ct), estimate = ct[, 1],
             clustered_se = ct[, 2], t_stat = ct[, 3], p_value = ct[, 4],
             row.names = NULL)
}))
write.csv(all_coef, file.path(table_dir, "3_regression_table_coefficients.csv"),
          row.names = FALSE)

# Automatic PDF compilation: works with installed MacTeX/TeX Live (pdflatex).
compile_table <- function() {
  latex <- Sys.which("pdflatex")
  if (!nzchar(latex) && file.exists("/Library/TeX/texbin/pdflatex")) {
    latex <- "/Library/TeX/texbin/pdflatex"
  }
  if (!nzchar(latex)) {
    writeLines("No pdflatex executable found. .tex sources were generated. Install MacTeX or a TeX distribution to enable automatic PDF compilation.",
               file.path(table_dir, "3_pdf_compile_status.txt"))
    message("PDF not compiled: pdflatex is not installed or not on PATH.")
    return(invisible(FALSE))
  }
  old <- getwd()
  on.exit(setwd(old), add = TRUE)
  setwd(table_dir)
  if (file.exists("3_regression_table_main.pdf")) {
    file.remove("3_regression_table_main.pdf")
  }
  cmd_output <- tryCatch(
    suppressWarnings(system2(latex, args = c("-interaction=nonstopmode",
                                           "-halt-on-error",
                                           "-file-line-error",
                                           "3_regression_table_main.tex"),
                              stdout = TRUE, stderr = TRUE)),
    error = function(e) paste("pdflatex invocation failed:", conditionMessage(e))
  )
  writeLines(as.character(cmd_output), "3_pdf_compile_log.txt", useBytes = TRUE)
  success <- file.exists("3_regression_table_main.pdf") &&
             is.null(attr(cmd_output, "status")) &&
             !any(grepl("pdflatex invocation failed", cmd_output, fixed = TRUE))
  writeLines(if (success) "SUCCESS: compiled 3_regression_table_main.pdf"
             else "PDF compilation failed. Inspect 3_pdf_compile_log.txt",
             "3_pdf_compile_status.txt")
  if (success) message("Compiled PDF: ", file.path(table_dir,
                                                 "3_regression_table_main.pdf"))
  else warning("LaTeX PDF not compiled. Inspect 3_pdf_compile_log.txt")
  invisible(success)
}
compile_table()

# Optional zipped LaTeX sources produced BY R after coefficients are estimated.
zip_sources <- function() {
  zip_command <- Sys.which("zip")
  if (!nzchar(zip_command)) {
    message("zip not available; .tex source files remain in Regression_Tables.")
    return(invisible(FALSE))
  }
  old <- getwd()
  on.exit(setwd(old), add = TRUE)
  setwd(table_dir)
  zip_name <- "3_regression_latex_sources.zip"
  if (file.exists(zip_name)) file.remove(zip_name)
  utils::zip(zip_name,
             files = c("3_regression_table.tex",
                       "3_regression_table_main.tex",
                       "3_regression_table_coefficients.csv"),
             flags = "-q")
  invisible(file.exists(zip_name))
}
zip_sources()

cat("\nSECTION 3 COMPLETE.\n",
    "Results: ", output_root, "\n",
    "LaTeX:   ", tex_table, "\n",
    "PDF:     ", file.path(table_dir, "3_regression_table_main.pdf"),
    " (if pdflatex is available)\n", sep = "")
