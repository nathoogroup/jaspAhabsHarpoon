# jaspAhabsHarpoon 0.1

* Initial release. Implements the eJAB analysis: computes the eJAB01
  approximate objective Bayes factor for each NHST result, estimates a
  calibrated threshold C* via integrated squared deviation, and flags
  Bayes/NHST contradictions as candidate Type I errors.
* Outputs: summary table, candidate-error table, calibration curve,
  diagnostic QQ-plot with simultaneous confidence band, and data summary
  plot (ln(eJAB01) vs p).
* Bundled example datasets: Reproducibility Project: Psychology
  (`inst/data/rpp_data.csv`) and Reproducibility Project: Cancer Biology
  (`inst/data/rpcb_data.csv`), with pre-configured analyses in
  `inst/examples/`.
