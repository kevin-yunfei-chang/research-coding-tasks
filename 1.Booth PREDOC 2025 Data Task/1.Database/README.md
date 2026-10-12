> **GitHub version:** This directory contains **documentation only**. The two original data files are **not distributed** here; obtain them independently through the official PREDOC links below.

# PREDOC 2025 Data Task — California Air Pollution Data

## 1. Overview

These two R datasets accompany the **PREDOC Data Task (July 2025)**, a research-assistant practice exercise hosted by Pathways to Research and Doctoral Careers (PREDOC) at the University of Chicago Booth School of Business. They contain **daily air-pollution monitor readings in California during 2024**. The exercise covers data preparation, descriptive statistics, visualization, and the relationship between air quality and a **synthetic** mortality outcome.

**Unit of observation (both files):** county × monitoring site × day. A county may have multiple monitors on the same date; these files are **not yet county-day panels**.

## 2. Input Files

| Local filename | Main content | Variables |
|---|---|---:|
| `data-set-2025-ozone-R.Rdata` | Ozone readings, air quality index, geographic identifiers, and synthetic mortality | 10 |
| `data-task-2025-pm-r.rdata` | PM2.5 readings and geographic identifiers | 5 |

The official task describes these inputs as `ca-ozone-2024.Rdata` and `ca-pm25-2024.Rdata`; the names above are those of the downloadable R files used here. Despite their `.Rdata` extensions, these downloaded files have been successfully read using **`readRDS()`**, not `load()`.

```r
# Adjust the folder path as needed.
ozone <- readRDS("1.Database/data-set-2025-ozone-R.Rdata")
pm25  <- readRDS("1.Database/data-task-2025-pm-r.rdata")

View(ozone)
View(pm25)
str(ozone)
str(pm25)
```

## 3. Variable Dictionary

| Variable | Dataset | Description |
|---|---|---|
| `county_code` | Both | California county FIPS code (county component; retain leading zeros). |
| `county_name` | Ozone | County name. |
| `date` | Both | Calendar date of the reading. |
| `siteid` | Both | Unique air-pollution monitoring-site identifier. |
| `cbsacode` | Ozone | Core-Based Statistical Area (CBSA) code. |
| `cbsaname` | Ozone | CBSA name; CBSAs cover metropolitan and micropolitan areas. |
| `aqi` | Ozone | Air Quality Index, an EPA index of air-quality conditions; **not** a pollutant concentration. |
| `ozone_source` | Ozone | Source of the ozone reading (e.g., AQS or AirNow). |
| `ozone_value` | Ozone | Measured ozone concentration. |
| `mortality` | Ozone | **Synthetic number of deaths** for the exercise; not observed deaths or a mortality rate. |
| `pm25_source` | PM2.5 | Source of the PM2.5 reading. |
| `pm25_value` | PM2.5 | Measured concentration of fine particulate matter (diameter ≤ 2.5 μm). |

**Units:** The task's data dictionary does **not** specify the measurement units for `ozone_value` or `pm25_value`; verify units against the underlying monitoring metadata before interpreting concentration magnitudes.

## 4. Data-Handling Notes

- **Identifiers and dates:** The sample ozone file displays `county_code` as `1` and dates as `01/01/2024`, while PM2.5 displays `001` and `2024-01-01`. Harmonize codes and parse dates before merging. Treat identifiers as identifiers, not continuous quantities.
- **Merge grain:** The natural candidate keys are **`county_code`, `siteid`, and `date`**. Check missing keys, duplicates, match rates, and unmatched observations before choosing a join strategy.
- **Aggregation:** Subsequent task sections require a **county-day** dataset. Document how multiple monitor readings are combined; do not indiscriminately sum monitor-level pollutant readings.
- **Mortality:** `NA` means missing, not zero. The exercise's outcome is synthetic; avoid treating it as a real-world health estimate or summing repeated county-level outcomes across monitor rows without validation.
- **Source quality:** **AQS** is EPA's regulatory air-quality database, subject to formal data-quality procedures. **AirNow** provides more timely, preliminary air-quality reporting and does not undergo the same full validation before public display. This is a **data-provenance distinction**, not proof that either source has systematically higher or lower measured pollution.

## 5. Official Documentation and References

1. [PREDOC — How to Prepare (task and downloads)](https://www.predoc.org/how-to-prepare)
2. [PREDOC — 2025 Data Task, instructions and data dictionary (PDF)](https://www.predoc.org/-/media/project/chicago-booth/consortium/predoc/pre-workshop/2025/data-task-problem-set/2025_data_task.pdf)
3. [U.S. EPA — Air Quality System (AQS)](https://www.epa.gov/aqs)
4. [U.S. EPA — About AQS Data](https://aqs.epa.gov/aqsweb/documents/about_aqs_data.html)
5. [AirNow — About the Data (validation and timeliness)](https://www.airnow.gov/about-the-data/)
6. [U.S. EPA — AirData / Air Quality Index basics](https://www.epa.gov/outdoor-air-quality-data/airdata-basic-information)
7. [U.S. Census Bureau — CBSA definitions](https://www.census.gov/programs-surveys/metro-micro/about/glossary.html)

*Scope: documentation of the supplied practice datasets, not a claim that they reproduce the full underlying EPA data or contain real mortality observations.*
