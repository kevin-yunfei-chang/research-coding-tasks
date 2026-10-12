# 3-4 | Why Is the CBSA Main Effect Collinear?

The CBSA indicator is time-invariant for every county in this dataset.
County fixed effects include a separate intercept for each county;
thus the CBSA indicator is an exact linear combination of these indicators.
It is perfectly collinear with county FE and cannot be separately estimated.
In contrast, AQI x CBSA can vary over time within counties, so its
differential AQI slope may be identified.

fixest dropped the following terms in the diagnostic fit: in_cbsa
