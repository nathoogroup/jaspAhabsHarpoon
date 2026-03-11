import QtQuick
import QtQuick.Layouts
import JASP.Controls
import JASP.Widgets
import JASP

Form
{
  info: qsTr("The eJAB Analysis detects potential Type I errors (false positives) in a collection of hypothesis test results by identifying Bayes-frequentist contradictions. A contradiction occurs when a result is statistically significant (small p-value) yet the approximate objective Bayes factor (eJAB01) indicates the data actually support the null hypothesis. Such results are flagged as candidate Type I errors.")

  VariablesForm
  {
    AvailableVariablesList { name: "allVariables" }
    AssignedVariablesList  {
      name: "p"
      label: qsTr("p-value")
      singleVariable: true
      allowedColumns: ["scale"]
      info: qsTr("The column of observed p-values from each hypothesis test. Values must be strictly between 0 and 1.")
    }

    AssignedVariablesList  {
      name: "n"
      label: qsTr("Sample Size")
      singleVariable: true
      allowedColumns: ["scale"]
      info: qsTr("The column of sample sizes (n) used in each test. Must be greater than 1.")
    }

    AssignedVariablesList  {
      name: "q"
      label: qsTr("Test Dimension")
      singleVariable: true
      allowedColumns: ["scale"]
      info: qsTr("The column of test dimensions (q): the number of parameters tested simultaneously (e.g., q = 1 for a t-test, q = 2 for a 2 df chi-square). Must be at least 1.")
    }

    AssignedVariablesList  {
      name: "study_nums"
      label: qsTr("Study ID")
      singleVariable: true
      allowedColumns: ["scale"]
      info: qsTr("The column of study identifiers used to label flagged results in the output.")
    }
  }

  Group
  {
    title: qsTr("Significance Level & Left Tail Uniformity Cutoff")
    DoubleField { name: "alpha"; label: qsTr("α");  defaultValue: 0.05; max: 1; decimals: 2; info: qsTr("The significance level for declaring a result statistically significant. Results with p < α are considered significant. Default is 0.05.") }
    DoubleField { name: "up";    label: qsTr("up"); defaultValue: 0.1;  max: 1; decimals: 2; info: qsTr("The upper p-value cutoff defining the left-tail region used for calibration. Only results with p ≤ up are used to estimate C\\*(α). This restricts calibration to the region where Type I errors are plausible. Default is 0.1.") }
  }

  Group
  {
    title: qsTr("C∗(α) Grid Search")
    DoubleField { name: "lowerBound"; label: qsTr("Lower Bound"); defaultValue: 0;   max: 1; decimals: 2; info: qsTr("The lower end of the grid over which C\\* is searched. Default is 0.") }
    DoubleField { name: "upperBound"; label: qsTr("Upper Bound"); defaultValue: 3.0; max: 3; decimals: 2; info: qsTr("The upper end of the grid over which C\\* is searched. Default is 3.") }
    Slider
    {
      name: "grid_size"
      label: qsTr("Size of the Grid")
      value: 200
      vertical: false
      min: 2
      max: 10000
      decimals: 0
      info: qsTr("The number of candidate C values evaluated during the grid search. A larger grid gives a more precise estimate of C\\*(α) at the cost of computation time. Default is 200.")
    }
  }

  Group
  {
    title: qsTr("Plots")
    CheckBox {
      name: "showCalibrationPlot"
      label: qsTr("Calibration plot (integral threshold)")
      checked: true
      info: qsTr("Displays two plots: (1) the observed contradiction rate vs. α with the ideal diagonal reference; and (2) a diagnostic QQ-plot of the flagged candidates.")
    }
    CheckBox {
      name: "showDataSummaryPlot"
      label: qsTr("Data summary (ln(eJAB01) vs pValue)")
      checked: true
      info: qsTr("A scatterplot of ln(eJAB01) against p-value for all results with p < α. Colour bands indicate regions of evidence for H0 (green), ambiguity (grey), and evidence against H0 (red). Candidate Type I errors are circled in red.")
    }
  }
}
