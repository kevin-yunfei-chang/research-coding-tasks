# Question 2-2 | Serial Correlation Discussion

Daily ozone concentrations may be serially correlated because weather
conditions, emissions, and atmospheric processes can persist across days.
Runs of consecutive high or low values in the time-series plot would be
consistent with positive autocorrelation, but visual patterns alone do
not establish its presence.

One could inspect a lag-1 scatter plot or the autocorrelation function (ACF),
or estimate a simple AR(1) regression of today's ozone on yesterday's ozone.
For a formal test, a Ljung-Box test on an appropriately specified series
or a serial-correlation test on model residuals could be considered.
Any missing days should be handled as calendar gaps, not treated as
consecutive observed dates.

**No autocorrelation test was performed, as requested.**
