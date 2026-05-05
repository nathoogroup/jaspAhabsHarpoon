context("eJAB core functions (vendored from ejabT1E)")

# These tests exercise the numerical engine in R/ejabCore.R directly.
# They do not depend on jaspTools and must keep producing identical
# results to the upstream ejabT1E package; if a future refactor changes
# any output here, the JASP module is silently no longer equivalent to
# the published method.

test_that("ejab01 enforces input ranges", {
  expect_error(ejab01(0,    50, 1), "p-values must be in")
  expect_error(ejab01(1,    50, 1), "p-values must be in")
  expect_error(ejab01(0.05,  1, 1), "sample sizes")
  expect_error(ejab01(0.05, 50, 0), "dimensions")
})

test_that("ejab01 matches the closed-form expression", {
  p <- 0.05; n <- 100; q <- 1
  expected <- sqrt(n) * exp(-0.5 * (n^(1/q) - 1) / n^(1/q) *
                            stats::qchisq(1 - p, df = q))
  expect_equal(ejab01(p, n, q), expected, tolerance = 1e-12)
})

test_that("ejab01 is vectorised and monotone in p", {
  p <- c(0.001, 0.01, 0.05, 0.1)
  vals <- ejab01(p, n = rep(100, 4), q = rep(1, 4))
  expect_length(vals, 4)
  expect_true(all(diff(vals) > 0))      # increasing in p
  expect_true(all(vals > 0))
})

test_that("estimate_Cstar respects a fixed grid_range", {
  set.seed(1)
  p    <- runif(200, 0, 0.05)
  ejab <- ejab01(p, rep(50, 200), rep(1, 200))
  fit  <- estimate_Cstar(p, ejab, up = 0.05,
                         grid_range = c(1, 1), grid_n = 1)
  expect_equal(fit$Cstar, 1)
  expect_length(fit$grid, 1)
})

test_that("estimate_Cstar grid search returns minimiser", {
  set.seed(1)
  p    <- runif(200, 0, 0.05)
  ejab <- ejab01(p, rep(50, 200), rep(1, 200))
  fit  <- estimate_Cstar(p, ejab, up = 0.05,
                         grid_range = c(0, 3), grid_n = 50)
  expect_equal(fit$objective, min(fit$all_objectives))
  expect_true(fit$Cstar >= 0 && fit$Cstar <= 3)
})

test_that("detect_type1 returns indices satisfying both conditions", {
  p     <- c(0.001, 0.04, 0.06, 0.02)
  ejab  <- c(0.1,   1.5,  2.0,  0.5)
  alpha <- 0.05
  Cstar <- 1.0
  idx   <- detect_type1(p, ejab, alpha, Cstar)
  expect_equal(idx, 2L)                  # only entry 2 has p<0.05 AND ejab>1
})

test_that("diagnostic_U returns finite values for valid candidates", {
  p     <- c(0.01, 0.02, 0.03)
  n     <- c(50, 80, 120)
  q     <- c(1, 1, 2)
  U     <- diagnostic_U(p, n, q, alpha = 0.05, Cstar = 1)
  expect_length(U, 3)
  expect_true(all(is.finite(U)))
})

test_that("diagnostic_U rejects n <= 1", {
  expect_error(diagnostic_U(0.01, 1, 1, 0.05, 1),
               "Sample sizes n must be > 1")
})
