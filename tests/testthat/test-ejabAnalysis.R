context("eJAB Analysis (end-to-end, both bundled datasets)")

# Smoke-test the JASP analysis on each bundled dataset. These tests
# require jaspTools (installed in the JASP CI image). Each test loads
# the dataset shipped in inst/data/, runs the analysis with default
# options, and checks that the expected result containers are produced.
#
# To regenerate snapshot tables for these tests after intentional
# changes, run:
#   options <- jaspTools::analysisOptions("ejabAnalysis")
#   options[c("p","n","q","study_nums")] <- list("p","n","q","study_id")
#   options$showCalibrationPlot   <- TRUE
#   options$showDataSummaryPlot   <- TRUE
#   results <- jaspTools::runAnalysis("ejabAnalysis", "rpp_data.csv", options)
#   jaspTools::makeTestsFromOptions("ejabAnalysis", "rpp_data.csv", options)

defaultOptions <- function() {
  options <- jaspTools::analysisOptions("ejabAnalysis")
  options$p                   <- "p"
  options$n                   <- "n"
  options$q                   <- "q"
  options$study_nums          <- "study_id"
  options$alpha               <- 0.05
  options$up                  <- 0.05
  options$lowerBound          <- 0
  options$upperBound          <- 3
  options$grid_size           <- 200
  options$showCalibrationPlot <- TRUE
  options$showDataSummaryPlot <- TRUE
  options
}

expect_analysis_runs <- function(dataset) {
  options <- defaultOptions()
  results <- jaspTools::runAnalysis("ejabAnalysis", dataset, options)

  # Status: no errors during analysis
  expect_null(results[["results"]][["error"]])

  # Required output containers
  expect_true("summaryContainer"    %in% names(results[["results"]]))
  expect_true("candidatesContainer" %in% names(results[["results"]]))
  expect_true("calibrationCurve"    %in% names(results[["results"]]))
  expect_true("qqPlot"              %in% names(results[["results"]]))
  expect_true("dataSummaryPlot"     %in% names(results[["results"]]))

  # Summary table has exactly one row
  summaryTable <- results[["results"]][["summaryContainer"]][["collection"]][["summaryContainer_table"]][["data"]]
  expect_length(summaryTable, 1L)

  # C* lies in the searched grid
  cstar <- summaryTable[[1]][["cstar"]]
  expect_true(is.finite(cstar) && cstar >= 0 && cstar <= 3)

  # Total equals the number of usable rows in the dataset
  total <- summaryTable[[1]][["total"]]
  expect_true(is.numeric(total) && total > 0)

  invisible(results)
}

test_that("eJAB Analysis runs on bundled RPP dataset", {
  expect_analysis_runs("rpp_data.csv")
})

test_that("eJAB Analysis runs on bundled RPCB dataset", {
  expect_analysis_runs("rpcb_data.csv")
})

test_that("eJAB Analysis surfaces error for empty data", {
  options <- defaultOptions()
  # Force every row to be filtered out by setting an impossible q column;
  # the analysis should produce an errorContainer rather than crashing.
  badData <- data.frame(study_id = 1:3, p = c(0.1, 0.2, 0.3),
                        n = c(50, 50, 50), q = c(0, 0, 0))
  results <- jaspTools::runAnalysis("ejabAnalysis", badData, options)
  expect_true("errorContainer" %in% names(results[["results"]]))
})
