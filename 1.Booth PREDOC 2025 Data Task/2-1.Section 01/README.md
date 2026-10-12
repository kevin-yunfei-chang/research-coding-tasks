> **Public repository note:** Original datasets, derived CSV/RDS outputs, and serialized models are intentionally excluded from GitHub; output filenames below describe what the R script generates **locally** after downloading the official datasets.

# 2025 PREDOC Data Task — Section 1

**Data Processing and Summarizing | Questions 1-1 through 1-6**  
**Language:** R (base R only; no additional packages)  
**Period:** California, 2024  
**Input unit:** County × monitor × day  
**Final analysis unit:** County × day

## 1. Objective

Merge the provided ozone and PM2.5 monitor-level data, summarize pollution measurements, compare the AQS and AirNow ozone samples, discuss data-quality differences, construct a county-day panel, and count counties with missing days. This folder addresses **Section 1 only**; it does not estimate the regressions in later sections.

## 2. Setup and execution

Expected directory layout **on your Mac**:

```text
/Users/zhangyunfei/Desktop/1.Booth PREDOC 2025 Data Task/
├── 1.Database/
│   ├── data-set-2025-ozone-R.Rdata
│   └── data-task-2025-pm-r.rdata
└── 2-1.Section 01/
    ├── 01_section1.R
    ├── README.md
    └── Output/                  # Created automatically when the script runs
        ├── 1-1/
        ├── 1-2/
        ├── 1-3/
        ├── 1-4/
        ├── 1-5/
        └── 1-6/
```

1. Place the two official downloads in `1.Database/` and place this `.R` script and README in `2-1.Section 01/`.
2. Open `01_section1.R` in **RStudio**.
3. Confirm the `project_root` setting near the top of the script matches the Mac folder.
4. Run the **SETUP** block, then the `1-1`, `1-2`, ..., `1-6` blocks **in order**, using the dashed comment separators. Alternatively, click **Source** to run the entire script.
5. Open `Output/1-1/`, ..., `Output/1-6/` to inspect the files created for each question. Use `readRDS()` to recover typed data objects or `View()` to inspect them in RStudio.

The script identifies the official input files using case-insensitive filename patterns, so minor capitalization differences in the original filenames are acceptable. It deliberately stops if more than one candidate matches a dataset name.

## 3. Inputs and variables

| File | Main variables | Notes |
| --- | --- | --- |
| Ozone (`*ozone*.Rdata`) | `county_code`, `county_name`, `date`, `siteid`, `cbsacode`, `cbsaname`, `aqi`, `ozone_source`, `ozone_value`, `mortality` | Includes synthetic mortality, AQI, and county/CBSA metadata. |
| PM2.5 (`*pm*.rdata`) | `county_code`, `date`, `siteid`, `pm25_source`, `pm25_value` | Adds fine-particulate readings and their source. |

- `siteid` identifies a pollution monitoring location, not a county.
- `county_code` is the **three-digit county FIPS component** for California in these files (`001`, `037`, etc.), not a full five-digit U.S. county FIPS code. If needed, the California state prefix is `06`.
- `cbsacode` / `cbsaname` describe the county's core-based statistical area; counties without a CBSA may have missing values.
- `aqi` is the Air Quality Index supplied in the ozone file; this script does **not** recompute AQI from ozone and PM2.5.
- `mortality` is **synthetic deaths**, not a mortality rate or actual observed death counts.
- The provided task does not explicitly document units for the concentration columns; do not assign units without checking the source specification.

## 4. Algorithm and outputs

### 1-1. Merge the ozone and PM2.5 data

**Algorithm**

1. Load both files. Although their extension is `.Rdata`, the downloads can be RDS-serialized; try `readRDS()` first and fall back to `load()` for genuine `.RData` files.
2. Standardize `county_code` as a zero-padded 3-character string, `siteid` as a zero-padded 9-character string, and dates as `Date` objects.
3. Confirm that **(`county_code`, `siteid`, `date`) is unique** within each dataset. Duplicate keys trigger an audit file and an explicit error, rather than an accidental many-to-many merge.
4. Apply a **full outer join**, retaining ozone-only, PM2.5-only, and matched monitor-days.
5. Add `merge_status` and save the combined dataset and a merge audit.

**Outputs** (`Output/1-1/`)

- `1-1_merged_monitor_day.csv` — merged monitor-day observations.
- `1-1_merged_monitor_day.rds` — the same dataset with R types preserved.
- `1-1_merge_audit.csv` — matched, ozone-only, and PM2.5-only row counts.
- `1-1_unmatched_monitor_days.csv` — observations without a partner.
- `1-1_duplicate_keys_{dataset}.csv` — **only if duplicate join keys are found**.

**Note:** A full outer join does not imply every ozone monitor measures PM2.5 on the same day; unmatched readings are a meaningful feature, not necessarily a coding error.

### 1-2. Overall summary statistics

Compute mean, median, minimum, maximum, and standard deviation for `ozone_value`, `pm25_value`, and `aqi` on the merged **monitor-day** sample. Missing readings are excluded separately for each variable. Report both total rows and nonmissing counts.

**Output:** `Output/1-2/1-2_pollution_summary.csv`.

### 1-3. Ozone statistics by source

For `ozone_source == "AQS"` and `"AirNow"`, calculate the same five statistics and the number of observations. Each source has its own denominator; `NA` values are not treated as zeros.

**Output:** `Output/1-3/1-3_ozone_by_source.csv` (plus a warning file only if other source categories are discovered).

### 1-4. Discuss possible systematic data-quality differences

Generate a brief English-language discussion using the **actual results** of 1-3. Compare source-specific sample moments while emphasizing that source differences can reflect monitor, place, or time selection rather than instrument quality. Identify additional evidence that would be informative (same-site matching, validation flags, corrections, missingness, and conditional comparisons); these checks are **proposed, not performed**.

**Output:** `Output/1-4/1-4_data_quality_discussion.md`.

### 1-5. Aggregate to the county-day level

For each (`county_code`, `date`):

- `ozone_value`: unweighted mean over available ozone monitor readings.
- `pm25_value`: unweighted mean over available PM2.5 monitor readings.
- `aqi`: unweighted mean over available monitor-level AQI readings.
- `mortality`: the **single unique nonmissing county-day value** supplied in the ozone file. **Never sum deaths over monitor rows.** Conflicting nonmissing values stop execution and create a review file.
- County name / CBSA: unique county-level metadata from ozone. Conflicting nonmissing values stop execution; absent CBSA data remain missing.
- Extra QC columns: number of input monitor-day rows and nonmissing reading counts by pollutant.

This is a simple **equal-monitor-weighted** mean, not an equal-person-weighted exposure measure, not a population-weighted interpolation, and not a replacement for an officially calculated EPA geographic AQI. Its benefit for this exercise is a transparent, reproducible convention.

**Outputs** (`Output/1-5/`):

- `1-5_county_day_panel.csv`
- `1-5_county_day_panel.rds`
- `1-5_aggregation_method.md`
- Conflict CSV files **only if** inconsistent mortality or metadata are detected.

The county-day RDS is the recommended typed input for Sections 2 and 3:

```r
county_day <- readRDS(
  "/Users/zhangyunfei/Desktop/1.Booth PREDOC 2025 Data Task/2.Section 01/Output/1-5/1-5_county_day_panel.rds"
)
View(county_day)
```

### 1-6. Count counties with missing days

Construct a complete calendar from **January 1 through December 31, 2024**, including leap day (**366 days**). The county universe is every county appearing at least once in the merged panel. A county is counted as *missing days* if one or more expected county-day rows are absent.

**A row with a missing pollution reading is not the same as an absent county-day row.** The script does not assume counties never present in either input file exist in the observed sampling frame.

**Outputs** (`Output/1-6/`):

- `1-6_summary.csv` — number of counties, counties missing at least one date, complete counties, and total missing county-days.
- `1-6_missing_days_by_county.csv` — expected, observed, and missing days by county.
- `1-6_missing_dates.csv` — one row per missing county-date.
- `1-6_interpretation.md` — definition and headline count.

## 5. Quality checks and interpretation cautions

- **ID hygiene:** Leading zeros in county/site identifiers matter. The `.rds` outputs preserve these strings; spreadsheet programs may auto-convert identifiers when importing CSV.
- **Dates:** Ozone dates may appear as `01/01/2024`, whereas PM2.5 dates may appear as `2024-01-01`; both are parsed into an R `Date` variable.
- **Join cardinality:** The intended join is **one-to-one at the county-monitor-day level**. Duplicate keys are investigated, not silently removed.
- **Incomplete coverage:** Full joining avoids discarding monitors that report only one pollutant. Means are calculated from available readings, and reading counts are retained.
- **Mortality:** Synthetic deaths are an outcome associated with a county-day, not a quantity that should be added across monitoring sites.
- **Data quality:** Differences between AQS and AirNow summary statistics are descriptive; they do not establish measurement bias or causal differences in data quality.
- **Scope:** Q1-2 and Q1-3 use **monitor-day** observations. Subsequent questions start from the **county-day** panel built in Q1-5.
- **Execution:** The pipeline stops rather than inventing a rule for duplicate keys, conflicting county metadata, or multiple nonmissing mortality values.
- **Calendar:** The missing-day count assumes all 366 calendar days in 2024 are expected. If a different observation window is intended, explicitly change the Q1-6 bounds and document the change.

## 6. References

1. [PREDOC — How to Prepare](https://www.predoc.org/how-to-prepare), with official 2025 problem and dataset links.
2. [PREDOC 2025 Data Task PDF](https://www.predoc.org/-/media/project/chicago-booth/consortium/predoc/pre-workshop/2025/data-task-problem-set/2025_data_task.pdf), Section 1 and Data Dictionary.
3. [EPA — Obtaining AQS Data](https://www.epa.gov/aqs/obtaining-aqs-data).
4. [AirNow — About the Data](https://www.airnow.gov/about-the-data/): AirNow data are preliminary rather than fully AQS-validated for regulatory use.
5. [U.S. Census Bureau — CBSA Glossary](https://www.census.gov/programs-surveys/metro-micro/about/glossary.html).
6. [R base documentation — readRDS / saveRDS](https://stat.ethz.ch/R-manual/R-devel/library/base/html/readRDS.html).

**Reproducibility note:** The scripts and README are supplied ready for local execution. Input datasets are not redistributed here; output counts and statistics must be generated by running the R script on the two official files.
