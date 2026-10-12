# 2025 PREDOC Data Task — R Replication

> **Public code-and-results repository (NO DATA).** This repository contains **R scripts, regression tables (PDF and LaTeX), published figures, written interpretations, and README documentation only**. **Original datasets, cleaned records, county-day/monitor-day panels, row-level CSVs, serialized R objects, and model-object files are NOT included.** Download the practice inputs separately from the [official PREDOC page](https://www.predoc.org/how-to-prepare) if you wish to reproduce the analyses.

A reproducible set of solutions for the **2025 PREDOC Data Task**, covering data processing, visualization, county/date fixed-effects regressions, and causal-identification reasoning. All mortality outcomes are **synthetic**; results are for training and do not measure real-world health effects.

## Repository Structure

```text
.
├── README.md                        # This overview; data exclusion notice
├── .gitignore                       # Prevent future data/model files from being committed
├── 1.Database/
│   └── README.md                     # Input descriptions and official source links; no datasets
├── 2-1.Section 01/
│   ├── 01_section1.R                 # Merge, clean, summarize, aggregate (Q1-1 to Q1-6)
│   ├── README.md
│   └── Output/                       # Written explanations only; no generated data files
├── 2-2.Section 02/
│   ├── 02_section2.R                 # Visualization (Q2-1 to Q2-2)
│   ├── README.md
│   └── Output/                       # Charts (PNG) and plotting notes (MD)
├── 2-3.Section 03/
│   ├── 03_section3.R                 # TWFE, lags, interactions, LaTeX (Q3-1 to Q3-4)
│   ├── README.md
│   └── Output/                       # Regression summaries, LaTeX, published PDF
└── 2-4.Section 04/
    └── Section04_Answers.md          # Identification and mortality harvesting answers
```

Each Section 1–3 folder also contains its RStudio `.Rproj` file. The original PREDOC question paper is **not redistributed**; find it via the [official task page](https://www.predoc.org/how-to-prepare).

## Sections & Key Results

| Section | Code / explanation | Public result |
|---|---|---|
| **1 — Data Processing** | [R code](<2-1.Section 01/01_section1.R>) · [README](<2-1.Section 01/README.md>) | [Data-quality discussion](<2-1.Section 01/Output/1-4/1-4_data_quality_discussion.md>) · [Aggregation method](<2-1.Section 01/Output/1-5/1-5_aggregation_method.md>) |
| **2 — Visualization** | [R code](<2-2.Section 02/02_section2.R>) · [README](<2-2.Section 02/README.md>) | [Pollution distributions](<2-2.Section 02/Output/2-1/2-1_standardized_distributions_main.png>) · [Los Angeles Ozone series](<2-2.Section 02/Output/2-2/2-2_los_angeles_february_ozone.png>) |
| **3 — Mortality Regressions** | [R code](<2-3.Section 03/03_section3.R>) · [README](<2-3.Section 03/README.md>) | **[Regression table (PDF)](<2-3.Section 03/Output/Regression_Tables/3_regression_table_main.pdf>)** · [LaTeX source](<2-3.Section 03/Output/Regression_Tables/3_regression_table.tex>) |
| **4 — Identification** | [Written answers](<2-4.Section 04/Section04_Answers.md>) | AR(3), omitted-variable bias, causality, and mortality harvesting |

## Reproduction (Datasets Must Be Supplied Locally)

1. Download the two 2025 R datasets via [PREDOC — How to Prepare](https://www.predoc.org/how-to-prepare), then place them in `1.Database/` on your **local machine only**. The Section 1 script requires both inputs there.
2. Open the `.Rproj` under `2-1.Section 01/`, then run `01_section1.R`. This generates the local county-day panel at `2-1.Section 01/Output/1-5/1-5_county_day_panel.rds`.
3. Open `2-2.Section 02/` or `2-3.Section 03/` as a project and run the corresponding `.R` script; both read the Section 1 county-day file, **which is intentionally absent from this public repository**.
4. Section 3 requires R package `fixest` and a local LaTeX installation (e.g. MacTeX) to regenerate the PDF. Sections 1 and 2 use Base R.

> **Publishing policy:** This GitHub-ready archive removes all `.Rdata`, `.rda`, `.rds`, `.csv`, source datasets, derived observation-level data, serialized fitted models, and the original question PDF. Keep those materials off the public repository; only curated non-data results are included. The `.gitignore` reduces accidental Git commits but does **not** prevent a manual browser upload of excluded files.
