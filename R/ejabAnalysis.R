ejabAnalysis <- function(jaspResults, dataset, options) {

  # Check if required variables are assigned
  if (length(options$p) == 0 || options$p == "" || 
      length(options$n) == 0 || options$n == "" || 
      length(options$q) == 0 || options$q == "" || 
      length(options$study_nums) == 0 || options$study_nums == "")
    return()

  # Read data
  p_vals    <- dataset[[options$p]]
  n_vals    <- dataset[[options$n]]
  q_vals    <- dataset[[options$q]]
  study_num <- dataset[[options$study_nums]]
  complete_cases <- complete.cases(p_vals, n_vals, q_vals, study_num) &
                   p_vals > 0 & p_vals < 1 &
                   n_vals > 1 &
                   q_vals >= 1
  p_vals    <- p_vals[complete_cases]
  n_vals    <- n_vals[complete_cases]
  q_vals    <- q_vals[complete_cases]
  study_num <- study_num[complete_cases]

  if (length(p_vals) == 0) {
    errorContainer <- createJaspContainer(gettext("eJAB Analysis"))
    errorContainer$setError(gettext(
      "No usable rows after filtering. The analysis requires p in (0, 1), n > 1, and q >= 1, with no missing values in any assigned column."
    ))
    jaspResults[["errorContainer"]] <- errorContainer
    return()
  }

  # Extract options, ensuring they are scalars
  alpha      <- as.numeric(options$alpha)[1]
  up         <- as.numeric(options$up)[1]
  grid_range <- c(as.numeric(options$lowerBound)[1], as.numeric(options$upperBound)[1])
  grid_n     <- as.integer(options$grid_size)[1]

  # Compute eJAB values (vendored from ejabT1E; see R/ejabCore.R)
  ejab_vals <- ejab01(p_vals, n_vals, q_vals)

  # Estimate C* using the integral method (minimises integrated squared deviation)
  fit <- estimate_Cstar(p_vals, ejab_vals, up = up,
                        grid_range = grid_range, grid_n = grid_n)
  Cstar_at_alpha     <- fit$Cstar
  objective_at_alpha <- fit$objective

  # Detect candidates using C* at the specified alpha
  candidates_idx <- detect_type1(p_vals, ejab_vals, alpha, Cstar_at_alpha)

  # Summary table
  if (is.null(jaspResults[["summaryContainer"]])) {
    summaryContainer <- createJaspContainer(gettext("eJAB Summary"))
    summaryContainer$dependOn(c("p", "n", "q", "study_nums", "alpha", "up", "lowerBound", "upperBound", "grid_size"))

    tbl <- createJaspTable()
    tbl$addColumnInfo(name = "cstar",      title = gettext("C*(α)"),       type = "number")
    tbl$addColumnInfo(name = "objective",  title = gettext("Objective"),   type = "number")
    tbl$addColumnInfo(name = "candidates", title = gettext("Candidates"),  type = "integer")
    tbl$addColumnInfo(name = "total",      title = gettext("Total"),       type = "integer")

    tbl[["cstar"]]      <- Cstar_at_alpha
    tbl[["objective"]]  <- objective_at_alpha
    tbl[["candidates"]] <- length(candidates_idx)
    tbl[["total"]]      <- length(p_vals)

    tbl$addFootnote(gettextf("C*(α) is the C* value corresponding to the selected α = %s", alpha),
                    colNames = "cstar")

    summaryContainer[["table"]] <- tbl
    jaspResults[["summaryContainer"]] <- summaryContainer
  }

  # Candidates table
  if (is.null(jaspResults[["candidatesContainer"]])) {
    candidatesContainer <- createJaspContainer(gettext("Candidate Type I Errors"))
    candidatesContainer$dependOn(c("p", "n", "q", "study_nums", "alpha", "up", "lowerBound", "upperBound", "grid_size"))

    ctbl <- createJaspTable()

    ctbl$addColumnInfo(name = "study",  title = gettext("Study ID"),  type = "string")
    ctbl$addColumnInfo(name = "pval",   title = gettext("p-value"),   type = "number")
    ctbl$addColumnInfo(name = "nval",   title = gettext("n"),         type = "integer")
    ctbl$addColumnInfo(name = "qval",   title = gettext("q"),         type = "integer")
    ctbl$addColumnInfo(name = "ejab",   title = gettext("eJAB01"),    type = "number")

    if (length(candidates_idx) > 0) {
      ctbl[["study"]] <- as.character(study_num[candidates_idx])
      ctbl[["pval"]]  <- p_vals[candidates_idx]
      ctbl[["nval"]]  <- n_vals[candidates_idx]
      ctbl[["qval"]]  <- q_vals[candidates_idx]
      ctbl[["ejab"]]  <- ejab_vals[candidates_idx]
    } else {
      ctbl$addFootnote(gettext("No candidate Type I errors detected."))
    }

    candidatesContainer[["table"]] <- ctbl
    jaspResults[["candidatesContainer"]] <- candidatesContainer
  }

  allDeps <- c("p", "n", "q", "study_nums", "up", "alpha",
               "lowerBound", "upperBound", "grid_size",
               "showCalibrationPlot", "showDataSummaryPlot")

  # --- Calibration plots (3 separate JASP plots instead of par(mfrow)) ---
  if (isTRUE(options$showCalibrationPlot)) {

    # Plot 1: Calibration curve - observed proportion vs alpha
    if (is.null(jaspResults[["calibrationCurve"]])) {
      alpha_grid <- seq(0, up, length.out = 200)[-1]
      N_cal <- sum(p_vals < up)
      proportions <- vapply(alpha_grid, function(a)
        sum(p_vals < a & ejab_vals > Cstar_at_alpha) / N_cal, numeric(1))
      keep <- alpha_grid <= alpha
      calDf <- data.frame(alpha = alpha_grid[keep], proportion = proportions[keep])
      refDf <- data.frame(alpha = c(0, alpha), proportion = c(0, alpha / up))

      p1 <- ggplot2::ggplot(calDf, ggplot2::aes(x = alpha, y = proportion)) +
        ggplot2::geom_line(linewidth = 1) +
        ggplot2::geom_line(data = refDf, linetype = "dashed", color = "red", linewidth = 1) +
        ggplot2::scale_x_continuous(limits = c(0, alpha)) +
        ggplot2::scale_y_continuous(limits = c(0, max(calDf$proportion, alpha / up) * 1.1)) +
        ggplot2::labs(x = expression(alpha), y = "Observed Proportion",
                      title = bquote("Calibration Curve (" ~ alpha <= .(alpha) ~ ")")) +
        jaspGraphs::geom_rangeframe() +
        jaspGraphs::themeJaspRaw()

      calCurve <- createJaspPlot(plot = p1,
                                  title = gettext("Calibration Curve"),
                                  width = 480, height = 400)
      calCurve$dependOn(allDeps)
      jaspResults[["calibrationCurve"]] <- calCurve
    }

    # Plot 2 (formerly C*(alpha) vs alpha) removed — not meaningful for integral method

    # Plot 3: Diagnostic QQ-plot (logic from ejabT1E::diagnostic_qqplot)
    if (is.null(jaspResults[["qqPlot"]])) {
      if (length(candidates_idx) > 0) {
        U <- diagnostic_U(p_vals[candidates_idx], n_vals[candidates_idx],
                                    q_vals[candidates_idx], alpha, Cstar_at_alpha)
        n_u      <- length(U)
        theoretical <- stats::ppoints(n_u)
        observed    <- sort(U)

        # OLS best-fit line (C* is estimated, so 45-degree line is inappropriate)
        fit_line <- stats::lm(observed ~ theoretical)
        int_ols  <- as.numeric(stats::coef(fit_line)[1])
        slp_ols  <- as.numeric(stats::coef(fit_line)[2])

        qqDf <- data.frame(theoretical = theoretical, observed = observed)

        p3 <- ggplot2::ggplot(qqDf, ggplot2::aes(x = theoretical, y = observed)) +
          ggplot2::geom_point(size = 1.5) +
          ggplot2::geom_abline(intercept = int_ols, slope = slp_ols,
                               color = "red", linewidth = 1) +
          ggplot2::labs(x = "Theoretical Unif(0,1) Quantiles",
                        y = "Observed U_i Quantiles",
                        title = paste0("Diagnostic QQ-Plot (alpha = ", alpha,
                                       ", C* = ", round(Cstar_at_alpha, 4), ")")) +
          jaspGraphs::geom_rangeframe() +
          jaspGraphs::themeJaspRaw()

        # MC-calibrated simultaneous confidence band, transformed through OLS fit
        if (n_u >= 2) {
          set.seed(1)
          B     <- 10000
          i_seq <- seq_len(n_u)
          U_sim <- apply(matrix(stats::runif(n_u * B), nrow = n_u, ncol = B), 2, sort)

          coverage_hat <- function(p) {
            tail <- (1 - p) / 2
            L <- stats::qbeta(tail,     i_seq, n_u + 1 - i_seq)
            U <- stats::qbeta(1 - tail, i_seq, n_u + 1 - i_seq)
            mean(colSums(U_sim >= L & U_sim <= U) == n_u)
          }
          f <- function(p) coverage_hat(p) - 0.95
          p_star <- if (f(0.95) >= 0) 0.95 else
            stats::uniroot(f, lower = 0.95, upper = 0.9999, tol = 1e-4)$root

          tail_star <- (1 - p_star) / 2
          lower_raw <- stats::qbeta(tail_star,     i_seq, n_u + 1 - i_seq)
          upper_raw <- stats::qbeta(1 - tail_star, i_seq, n_u + 1 - i_seq)

          # Transform bands through OLS fit
          lower <- int_ols + slp_ols * lower_raw
          upper <- int_ols + slp_ols * upper_raw

          bandDf <- data.frame(theoretical = theoretical, lower = lower, upper = upper)
          p3 <- p3 +
            ggplot2::geom_line(data = bandDf, ggplot2::aes(x = theoretical, y = lower),
                               linetype = "dashed", color = "grey50") +
            ggplot2::geom_line(data = bandDf, ggplot2::aes(x = theoretical, y = upper),
                               linetype = "dashed", color = "grey50")
        }

        qqPlot <- createJaspPlot(plot = p3,
                                  title = gettext("Diagnostic QQ-Plot"),
                                  width = 480, height = 400)
      } else {
        qqPlot <- createJaspPlot(title = gettext("Diagnostic QQ-Plot"),
                                  width = 480, height = 400)
        qqPlot$setError(gettext("No candidate Type I errors detected; cannot produce QQ-plot."))
      }
      qqPlot$dependOn(allDeps)
      jaspResults[["qqPlot"]] <- qqPlot
    }
  }

  # --- Data summary plot (ggplot2 only, no cowplot) ---
  if (isTRUE(options$showDataSummaryPlot) && is.null(jaspResults[["dataSummaryPlot"]])) {
    if (length(p_vals) > 0) {
      logJAB <- log(ejab_vals)
      is_candidate <- (p_vals < alpha) & (ejab_vals > Cstar_at_alpha)

      plotDf <- data.frame(pValue = p_vals, logJAB = logJAB,
                           candidate = is_candidate)

      sig    <- p_vals < alpha
      yr     <- range(c(logJAB[sig], log(Cstar_at_alpha)), finite = TRUE) + c(-0.5, 0.5)
      ytrans <- scales::pseudo_log_trans(sigma = 1)
      cand_breaks <- c(-1000, -300, -100, -30, -10, -5, -3, -2, -1, 0, 1, 2, 3, 5, 10)
      ybreaks <- cand_breaks[cand_breaks >= yr[1] & cand_breaks <= yr[2]]

      bands <- data.frame(
        ymin = c(yr[1],    log(1/3), log(3)),
        ymax = c(log(1/3), log(3),   yr[2]),
        fill = c("green",  "grey80", "red")
      )
      bands <- bands[bands$ymax > yr[1] & bands$ymin < yr[2], , drop = FALSE]
      bands$ymin <- pmax(bands$ymin, yr[1])
      bands$ymax <- pmin(bands$ymax, yr[2])

      p4 <- ggplot2::ggplot(plotDf, ggplot2::aes(x = pValue, y = logJAB)) +
        ggplot2::geom_rect(data = bands,
                           ggplot2::aes(xmin = 0, xmax = alpha, ymin = ymin, ymax = ymax, fill = fill),
                           alpha = 0.15, inherit.aes = FALSE) +
        ggplot2::scale_fill_identity() +
        ggplot2::geom_point(ggplot2::aes(color = candidate), size = 1.5, show.legend = FALSE) +
        ggplot2::scale_color_manual(values = c(`TRUE` = "red", `FALSE` = "steelblue")) +
        ggplot2::geom_vline(xintercept = alpha, linetype = "dashed") +
        ggplot2::geom_hline(yintercept = log(1/3), linetype = "dashed", color = "grey40") +
        ggplot2::geom_hline(yintercept = log(3),   linetype = "dashed", color = "grey40") +
        ggplot2::geom_hline(ggplot2::aes(yintercept = log(Cstar_at_alpha),
                                         linetype = paste0("C*(alpha) = ",
                                                           signif(Cstar_at_alpha, 4))),
                            color = "red") +
        ggplot2::scale_linetype_manual(name = NULL, values = "dashed") +
        ggplot2::coord_cartesian(xlim = c(0, alpha), ylim = yr) +
        ggplot2::scale_x_continuous(name = "p-value") +
        ggplot2::scale_y_continuous(name = "ln(eJAB01)", trans = ytrans, breaks = ybreaks) +
        ggplot2::labs(title = paste0("ln(eJAB01) vs p-value  (alpha = ", alpha, ")")) +
        jaspGraphs::geom_rangeframe() +
        jaspGraphs::themeJaspRaw() +
        ggplot2::theme(legend.position = c(0.98, 0.02),
                       legend.justification = c(1, 0),
                       legend.background = ggplot2::element_rect(
                         fill = scales::alpha("white", 0.85), color = "grey70"),
                       legend.key = ggplot2::element_rect(fill = NA),
                       legend.margin = ggplot2::margin(2, 4, 2, 4))

      dataPlot <- createJaspPlot(plot = p4,
                                  title = gettext("Data Summary: ln(eJAB01) vs pValue"),
                                  width = 600, height = 400)
    } else {
      dataPlot <- createJaspPlot(title = gettext("Data Summary: ln(eJAB01) vs pValue"),
                                  width = 600, height = 400)
      dataPlot$setError(gettext("No data available for plotting."))
    }
    dataPlot$dependOn(allDeps)
    jaspResults[["dataSummaryPlot"]] <- dataPlot
  }
}
