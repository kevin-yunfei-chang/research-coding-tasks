# 2025 PREDOC Data Task — Section 4: Discussion on Threats

> **Submission instructions:** The three answers in Part I contain **eight sentences in total**, with no additional empirical results or external citations. **Submit Part I only.** Part II is optional study material and is not part of the submission.

## Part I — Submission Answers (8 Sentences Total)

### Question 4-1 — AR(3), Pollution Lags, and Omitted-Variable Bias (3 sentences)

An AR(3) process does not automatically require exactly three pollution lags in the mortality regression, because autocorrelation in pollution does not itself imply lagged effects on mortality.  
If past pollution affects current mortality and remains correlated with current pollution conditional on the other controls, omitting those relevant lags can bias the contemporaneous AQI coefficient.  
Thus, the appropriate number of lags depends on the outcome's dynamic response to pollution: three may be unnecessary if lagged pollution has no independent effect, or insufficient if more distant exposures matter.

### Question 4-2 — Can the Baseline Estimate Be Interpreted Causally? (2 sentences)

No, ruling out lagged pollution effects does not establish that current AQI is conditionally exogenous after the included county and date fixed effects.  
For example, county-specific daily temperature may affect both pollution and mortality, generating confounding that neither set of fixed effects necessarily removes.

### Question 4-3 — Mortality Harvesting (3 sentences)

Under pure one-day mortality harvesting, an increase in today's pollution raises today's mortality by accelerating deaths that otherwise would have occurred tomorrow.  
With the appropriate controls and no additional mortality effects, the coefficient from regressing tomorrow's mortality on today's pollution would be negative and equal in magnitude to the positive coefficient for today's mortality.  
Consequently, the coefficient from regressing the sum of today's and tomorrow's mortality on today's pollution would be zero.

---

## Part II — Conceptual Notes (Study Only; Do Not Submit)

### A. Why AR(3) Is Not an Outcome-Lag Requirement

**Pollution process:**

$$
AQI_{it}=\rho_1 AQI_{i,t-1}+\rho_2 AQI_{i,t-2}
+\rho_3 AQI_{i,t-3}+v_{it}.
$$

**Potential mortality process:**

$$
Mortality_{it}=\beta AQI_{it}+\sum_{\ell=1}^{L}\gamma_\ell AQI_{i,t-\ell}
+\alpha_i+\delta_t+\varepsilon_{it}.
$$

- The AR order describes dependence **within pollution**, not how many past pollution exposures matter for **mortality**.
- Lag inclusion for omitted-variable bias depends on both a relevant lag's effect on the outcome and its conditional association with current pollution.
- An AR(3) process by itself does **not** establish that the outcome's lag length is three.

**DAG — past pollution as a possible confounder:**

```text
           AQI(t−1)
            /    \
           v      v
        AQI(t) -> Mortality(t)
```

### B. Omitted-Variable Bias After Fixed Effects

Suppose the true linear model includes a relevant omitted variable $Z_{it}$:

$$
Y_{it}=\beta X_{it}+\gamma Z_{it}
+\alpha_i+\delta_t+\varepsilon_{it}.
$$

After residualizing $X$ and $Z$ with respect to the included fixed effects (denoted by tildes), the omitted-variable-bias formula is:

$$
\operatorname{plim}(\widehat\beta_{\mathrm{omit}})-\beta
=
\gamma\frac{\operatorname{Cov}(\widetilde X,\widetilde Z)}
{\operatorname{Var}(\widetilde X)}.
$$

**Two necessary ingredients for this particular OVB mechanism:**

1. $\gamma\neq 0$: omitted $Z$ independently predicts or affects $Y$ in the assumed structural model.
2. $\operatorname{Cov}(\widetilde X,\widetilde Z)\neq0$: omitted $Z$ is associated with treatment $X$ after accounting for existing controls.

*These conditions concern OVB within the stated linear model; the causal validity of any control also depends on its position in the causal graph and the target estimand.*

### C. Good Controls, Bad Controls, and DAGs

**Confounder — usually adjust for it:**

```text
        Z
       / \
      v   v
      X -> Y
```

The backdoor path $X\leftarrow Z\rightarrow Y$ can create confounding.

**Outcome-only predictor — potentially useful for precision:**

```text
X ---> Y <--- Z
```

Assuming $Z$ is independent of $X$ and otherwise a valid pretreatment control, adjustment can improve precision by explaining residual outcome variation; it does not automatically reduce standard errors in every finite sample.

**Mediator — avoid adjusting when targeting the total effect:**

```text
X ---> M ---> Y
 \------------>/
```

In a simple linear mediation model,

$$
M=aX+u_M,\qquad Y=cX+bM+u_Y,
$$

$$
\underbrace{\tau}_{\text{total effect}}
=
\underbrace{c}_{\text{direct effect}}
+
\underbrace{ab}_{\text{indirect effect}},
$$

under the assumptions required to identify these paths; controlling for $M$ changes the estimand from the total effect toward the direct effect and can introduce further bias if mediator–outcome confounding remains.

**Collider — avoid conditioning on a common effect:**

```text
X ---> C <--- U ---> Y
 \------------------> Y
```

The path $X\rightarrow C\leftarrow U\rightarrow Y$ is blocked at collider $C$ unless it (or an appropriate descendant) is conditioned on.

### D. Frisch–Waugh–Lovell (FWL) Interpretation

Residualize $X$ and $Y$ on the already included controls $W$:

$$
\widetilde X = X-\widehat{\operatorname{Proj}}(X\mid W),
\qquad
\widetilde Y = Y-\widehat{\operatorname{Proj}}(Y\mid W).
$$

Then the multiple-regression slope on $X$ equals:

$$
\widehat\beta=\frac{\sum_i\widetilde X_i\widetilde Y_i}
{\sum_i\widetilde X_i^2}.
$$

With homoskedastic disturbances under standard fixed-design assumptions, its conditional variance takes the form:

$$
\operatorname{Var}(\widehat\beta\mid X,W)
=\frac{\sigma^2}{\sum_i\widetilde X_i^2}.
$$

Adding a valid outcome predictor can reduce $\sigma^2$, but controlling for variables correlated with $X$ can also reduce the variation in $\widetilde X$; changes in precision are therefore not automatic.

### E. The Algebra of Pure One-Day Harvesting

Let $\theta_0$ be the effect of today's pollution on today's mortality and $\theta_1$ the effect on tomorrow's mortality, identified under the question's assumptions:

$$
\theta_0>0,\qquad\theta_1=-\theta_0<0.
$$

For two-day cumulative mortality:

$$
\theta_{\mathrm{today+tomorrow}}=\theta_0+\theta_1=0.
$$

A zero two-day cumulative **death-count** effect does not mean that advancing the timing of death has zero welfare cost.

---

**Source basis:** 2025 PREDOC Data Task, Section 4; the substantive answers above contain no external citations, as instructed by the task.
