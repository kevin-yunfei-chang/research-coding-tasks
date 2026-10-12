# Question 2-1 | Distribution Plot Notes

- Input: Section 1 county-day panel (Q1-5).
- Each pollutant is standardized independently: z = (x - mean(x)) / sd(x).
- Two KDE lines share a single standardized x-axis and a common density y-axis.
- A common kernel bandwidth is applied to both series.
- The main plot displays the central 99% of pooled standardized values.
- The full-range plot shows the entire KDE x-axis; no finite observation
  is dropped from either KDE calculation to create the main plot.
- The variables represent monitor-averaged county-day pollution readings,
  not monitor-day raw values or population-weighted exposures.
- A Z-score comparison is about relative distributions, NOT pollution
  concentration magnitudes or health equivalence across pollutants.
