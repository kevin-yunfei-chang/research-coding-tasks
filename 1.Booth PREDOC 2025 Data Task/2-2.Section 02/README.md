> **Public repository note:** The source county-day panel and numerical CSV outputs are excluded from this repository; figures and interpretation Markdown are retained. The script recreates the data files locally only after Section 1 is run with official inputs.

# 2025 PREDOC Data Task — Section 2: Visualizing the Data

A self-contained **RStudio Project** for Questions **2-1** and **2-2** of the [2025 PREDOC Data Task](https://www.predoc.org/how-to-prepare). The script uses **Base R only** and can be run question by question.

## 1. Project Structure

```text
1.Booth PREDOC 2025 Data Task/
├── 2-1.Section 01/
│   └── Output/
│       └── 1-5/
│           └── 1-5_county_day_panel.rds     # External input; NOT copied
└── 2-2.Section 02/
    ├── 2-2.Section 02.Rproj                     # Open this first
    ├── 02_section2.R                       # SETUP, 2-1, 2-2
    ├── README.md
    └── Output/
        ├── 2-1/
        └── 2-2/
```

All Section 2 artifacts are saved in `2-2.Section 02/Output/`; the original Section 1 file is **read-only**.

## 2. Fixed Input

**Only** the following file is accepted:

```text
/Users/zhangyunfei/Desktop/1.Booth PREDOC 2025 Data Task/2-1.Section 01/Output/1-5/1-5_county_day_panel.rds
```

The script constructs this path relative to the folder containing `2-2.Section 02.Rproj`. If the file is absent, execution **stops**; it does not search alternative directories, load earlier raw files, or rerun the merge.

- **Unit of observation:** county × calendar day (the Section 1 Question 1-5 output).
- **Key variables:** `county_code`, `date`.
- **Relevant measurements:** `ozone_value`, `pm25_value`.
- **Provenance:** In Section 1, monitor readings were averaged **equally** within county-days; these values are not population-weighted exposures.
- **Date range:** The original task's 2024 data; February 2024 contains **29** calendar days.

## 3. Run in RStudio

1. Place the **entire** `2-2.Section 02` folder inside the existing `1.Booth PREDOC 2025 Data Task` project folder.
2. Double-click **`2-2.Section 02.Rproj`**. Confirm that `getwd()` ends with `/2-2.Section 02`.
3. Open `02_section2.R` in the editor.
4. Highlight and run **SETUP** (up to the first `2-1` separator); press **Command + Return**.
5. Highlight and run **2-1**. Check `Output/2-1/`.
6. Highlight and run **2-2**. Check `Output/2-2/`.

After both blocks have worked individually, reproduce everything with:

```r
source("02_section2.R", echo = TRUE)
```

If you are still in the *parent* RStudio Project, the script also accepts the parent as its working directory and can be sourced via:

```r
source("2-2.Section 02/02_section2.R", echo = TRUE)
```

**No extra packages are required.** Outputs are generated locally when the R script is executed; the public repository includes previously generated PNG figures and written notes but intentionally excludes data-only CSV/RDS outputs.

## 4. Question 2-1 — Compare Pollutant Distributions

**Task.** Plot the distributions of Ozone and PM2.5 as two distinct curves on one set of axes, paying attention to the different measurement scales.

**Method.**

1. Extract nonmissing, finite `ozone_value` and `pm25_value` from the **county-day** panel.
2. Standardize each pollutant separately:
   \[
   z_{it}^{(p)} = \frac{x_{it}^{(p)}-\overline{x}^{(p)}}{s^{(p)}},
   \]
   where \(p\) denotes the pollutant and the mean/SD are computed over its available county-day observations.
3. Use Gaussian kernel-density estimates (KDEs) on the same standardized x-axis, with a **common smoothing bandwidth**.
4. Export two views: a legible main view spanning the **0.5th–99.5th percentiles** of pooled Z-scores, and a full-range comparison. **Both density curves are estimated using all finite observations**; no data are discarded merely to zoom the main chart.

**Interpretation.** Standardization permits a comparison of *distributional shapes*, not pollution levels in physical units or equivalent health effects. The displayed x-axis is in standard deviations, and the y-axis is a density.

**Outputs.**

| File in `Output/2-1/` | Description |
|---|---|
| `2-1_standardized_distributions_main.png` | Publication-ready KDE overlay (central range) |
| `2-1_standardized_distributions_full.png` | KDE overlay showing the full range |
| `2-1_standardization_summary.csv` | Valid count, missing count, mean, SD, min, max in original units |
| `2-1_kde_coordinates.csv` | Curve coordinates for reproducibility |
| `2-1_plot_notes.md` | Method, scales, and caveats |

## 5. Question 2-2 — Los Angeles Ozone, February 2024

**Task.** Plot daily Ozone for Los Angeles County (**FIPS county code `037`**) in February. Discuss suspected autocorrelation and how it could be assessed, **without conducting a test**.

**Method.**

1. Filter to `county_code == "037"` and dates `2024-02-01` through `2024-02-29`.
2. Join the observed values to the **complete 29-day calendar**. Missing days remain `NA`; the line **breaks** rather than interpolating across gaps.
3. Produce a line-plus-point time-series plot and a transparent daily-value CSV.

**Autocorrelation discussion.** Day-to-day persistence is plausible because weather and emissions are persistent. Visible stretches of relatively high or low readings would be suggestive, but a plot alone cannot establish autocorrelation. A lagged scatter plot, ACF, or AR(1) regression could be informative; a Ljung–Box test or residual serial-correlation test may be used in a properly specified analysis. **No test is run**, as requested.

**Outputs.**

| File in `Output/2-2/` | Description |
|---|---|
| `2-2_los_angeles_february_ozone.png` | February 2024 time-series plot |
| `2-2_los_angeles_february_daily_ozone.csv` | 29-row daily calendar with `observed` flag |
| `2-2_time_series_summary.csv` | Observed/missing days and Ozone summary |
| `2-2_autocorrelation_discussion.md` | Concise written interpretation, no formal test |

## 6. Validation and Important Caveats

- Input **must** be the Section 1 county-day RDS, not the raw monitor-day data.
- Duplicate county-date keys, missing required columns, missing input, invalid dates, and non-numeric pollution fields cause informative errors.
- Original Ozone and PM2.5 measurements use **different scales**; standardization is *only for visualization*.
- **Negative PM2.5 measurements**, if present, are retained; the script does not silently drop scientifically unusual but finite readings.
- Ozone measurements in the county-day panel reflect **equal-weighted monitor averages**. The source files did not independently establish physical measurement units here; graph labels therefore avoid asserting unverified units.
- The main 2-1 view trims only the *display window*, not the observations used for density estimation. Always inspect the full-range plot as well.
- Do **not** infer actual autocorrelation from the mere existence of a time-series chart. No formal significance test is performed.
- This is practice-task analysis, **not** causal evidence.

## 7. References

- [PREDOC — How to Prepare (2025 exercise, datasets, solutions)](https://www.predoc.org/how-to-prepare)
- [PREDOC — 2025 Workshop Recordings (R walkthrough)](https://www.predoc.org/pre-workshop/pre-workshop-recordings-2025)
- [Official 2025 Data Task PDF](https://www.predoc.org/-/media/project/chicago-booth/consortium/predoc/pre-workshop/2025/data-task-problem-set/2025_data_task.pdf)
- [R Documentation — `density()`](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/density.html)
- [R Documentation — `acf()`](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/acf.html)
- [RStudio — Working with Projects](https://support.posit.co/hc/en-us/articles/200526207-Using-RStudio-Projects)

---

**Reproducibility status:** The `.R` source and project structure are prepared; actual plots and CSV results require running this script with the specified external RDS on the user's computer.
