eJAB Analysis
===

The eJAB Analysis detects potential Type I errors (false positives) in a collection of hypothesis test results by identifying Bayes-frequentist contradictions. A contradiction occurs when frequentist and Bayesian evidence point in opposite directions: the p-value leads you to reject $H_0$, but the Bayes factor indicates the data actually support $H_0$. Such contradictions are candidate Type I errors — results that are statistically significant but where the underlying evidence does not warrant that conclusion.

The method works as follows. For each result, an approximate objective Bayes factor ($\text{eJAB01}$) is computed from the p-value, sample size, and test dimension. $\text{eJAB01}$ values less than 1 indicate evidence in favour of $H_1$ (consistent with rejecting $H_0$), while values greater than 1 indicate evidence in favour of $H_0$. Values above 3 are considered moderate evidence for $H_0$, and above 10 strong evidence. An optimal threshold $C^*(\alpha)$ is then estimated by calibration, and any result with $p < \alpha$ and $\text{eJAB01} > C^*(\alpha)$ is flagged as a candidate Type I error.

### Input
-------

#### Assignment Box
- **p-value**: The column of observed p-values from each hypothesis test. Values must be strictly between 0 and 1.
- **Sample Size**: The column of sample sizes ($n$) used in each test. Must be greater than 1.
- **Test Dimension**: The column of test dimensions ($q$), i.e., the number of parameters tested simultaneously (e.g., $q = 1$ for a t-test, $q = 2$ for a 2 df chi-square). Must be at least 1.
- **Study ID**: The column of study identifiers used to label flagged results in the output.

#### Significance Level & Left Tail Uniformity Cutoff
- **$\alpha$**: The significance level for declaring a result statistically significant. Default is 0.05.
- **up**: The upper p-value cutoff defining the left-tail region used for calibration. Only results with $p \leq u_p$ are used to estimate $C^*(\alpha)$. This restricts calibration to the region where Type I errors are plausible. Default is 0.1.

#### $C^*(\alpha)$ Grid Search
- **Lower Bound**: The lower end of the grid over which $C^*$ is searched. Default is 0.
- **Upper Bound**: The upper end of the grid over which $C^*$ is searched. Default is 3.
- **Size of the Grid**: The number of candidate $C$ values evaluated during the grid search. A larger grid gives a more precise estimate of $C^*(\alpha)$ at the cost of computation time. Default is 200.

#### Plots
- **Calibration plot (integral $C^*$)**: Displays two plots showing the calibration results: (1) the observed contradiction rate vs. $\alpha$, with the ideal diagonal reference line; and (2) a diagnostic QQ-plot of the flagged candidates.
- **Data summary ($\ln(\text{eJAB01})$ vs p-value)**: A scatterplot of $\ln(\text{eJAB01})$ against p-value for all results with $p < \alpha$, with colour bands indicating regions of evidence for $H_0$ (green), ambiguity (grey), and evidence against $H_0$ (red). Candidate Type I errors are circled in red.

### Output
-------

#### eJAB Summary
- **$C^*(\alpha)$**: The estimated optimal threshold at the selected $\alpha$ level. Results with $p < \alpha$ and $\text{eJAB01} > C^*(\alpha)$ are flagged as candidate Type I errors.
- **Objective**: The value of the calibration objective function evaluated at $C^*(\alpha)$. Smaller values indicate a better-calibrated threshold.
- **Candidates**: The number of results flagged as candidate Type I errors.
- **Total**: The total number of valid results analysed.

#### Candidate Type I Errors
A table listing each result flagged as a potential Type I error, with columns:
- **Study ID**: The identifier of the flagged study.
- **p-value**: The observed p-value.
- **n**: The sample size.
- **q**: The test dimension.
- **eJAB01**: The approximate objective Bayes factor. Values greater than 1 indicate the data favour $H_0$; values greater than 3 are considered moderate evidence for $H_0$.

#### Calibration Curve
Shows the observed proportion of contradictions as a function of $\alpha$ alongside the ideal diagonal reference (dashed red). A well-calibrated $C^*(\alpha)$ produces a curve close to the diagonal.

#### Diagnostic QQ-Plot
A uniform QQ-plot of the candidate results under the null hypothesis of uniformity. Simultaneous 95% confidence bands (dashed grey) are shown when there are at least 2 candidates. Points falling outside the bands indicate potential departures from expected Type I error behaviour.

#### Data Summary: $\ln(\text{eJAB01})$ vs p-value
A scatterplot of $\ln(\text{eJAB01})$ against p-value for results with $p < \alpha$. Candidate Type I errors are highlighted with a red circle. The horizontal dashed lines at $\ln(1/3)$ and $\ln(3)$ mark the conventional thresholds for moderate evidence.

### References
-------
- Nathoo, F. S., Velidi, P., Wei, Z., & Strasdin, E. (2026). *Detecting Type I errors through Bayes/NHST conflict using eJAB*.
- Open Science Collaboration (2015). Estimating the reproducibility of psychological science. *Science*, 349(6251), aac4716.

### R-packages
---
- ejabT1E
- ggplot2
- jaspGraphs

### Example
---
- For the Reproducibility Project: Psychology dataset, go to `Open` --> `Recent Files` --> `rpp_analysis.jasp`.
