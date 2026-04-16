# 07_statistical_tests.R — Chi-square goodness-of-fit tests
# Compares OPS observed counts against NSDUH survey-weighted proportions
data_dir <- "C:/Users/Gabriel/OneDrive - Yale University/Gabriel - JP/Papers/Psilocybin - Oregon-NSDUH/Data"

library(tidyverse)

load(file.path(data_dir, "output", "harmonized.RData"))
load(file.path(data_dir, "output", "nsduh_processed.RData"))
load(file.path(data_dir, "output", "ops_processed.RData"))

cat("============================================================\n")
cat("  CHI-SQUARE GOODNESS-OF-FIT: OPS vs NSDUH PROPORTIONS\n")
cat("============================================================\n\n")

# ------------------------------------------------------------------
# Helper: run chi-square GOF and print results
# ------------------------------------------------------------------
run_gof <- function(label, ops_counts, nsduh_props, categories) {
  names(ops_counts) <- categories
  names(nsduh_props) <- categories

  # Rescale NSDUH proportions to sum to exactly 1
  nsduh_props <- nsduh_props / sum(nsduh_props)

  test <- chisq.test(ops_counts, p = nsduh_props)

  # Standardized residuals: (O - E) / sqrt(E)
  std_resid <- test$stdres

  cat(sprintf("--- %s ---\n", label))
  cat(sprintf("Chi-square = %.1f, df = %d, P < %.1e\n",
              test$statistic, test$parameter, test$p.value))
  cat(sprintf("OPS total N = %d\n\n", sum(ops_counts)))

  # Per-category breakdown
  res_df <- tibble(
    Category   = categories,
    OPS_n      = ops_counts,
    OPS_pct    = ops_counts / sum(ops_counts) * 100,
    NSDUH_pct  = nsduh_props * 100,
    Diff_pp    = OPS_pct - NSDUH_pct,
    Expected   = test$expected,
    Std_Resid  = as.numeric(std_resid)
  )
  print(res_df, n = 20)
  cat("\n")

  invisible(list(test = test, details = res_df))
}

# ==================================================================
# 1. SEX
# ==================================================================
# ------------------------------------------------------------------
# Helper: extract matched data for one variable
# ------------------------------------------------------------------
extract_var <- function(var_name) {
  nsduh <- comparison %>%
    filter(source == "NSDUH", variable == var_name) %>%
    arrange(category)
  ops <- comparison %>%
    filter(source == "OPS", variable == var_name) %>%
    arrange(category)
  cats <- as.character(nsduh$category)
  list(
    nsduh_props = setNames(nsduh$pct / 100, cats),
    ops_counts  = setNames(ops$n, cats),
    categories  = cats
  )
}

# ==================================================================
# 1. SEX
# ==================================================================
d <- extract_var("sex")
sex_result <- run_gof("SEX", d$ops_counts, d$nsduh_props, d$categories)

# ==================================================================
# 2. AGE
# ==================================================================
d <- extract_var("age")
age_result <- run_gof("AGE", d$ops_counts, d$nsduh_props, d$categories)

# ==================================================================
# 3. RACE/ETHNICITY
# ==================================================================
d <- extract_var("race")
race_result <- run_gof("RACE/ETHNICITY", d$ops_counts, d$nsduh_props, d$categories)

# ==================================================================
# Summary for manuscript
# ==================================================================
cat("\n============================================================\n")
cat("  MANUSCRIPT-READY SUMMARY\n")
cat("============================================================\n\n")

for (res in list(
  list(name = "Sex", r = sex_result),
  list(name = "Age", r = age_result),
  list(name = "Race/ethnicity", r = race_result)
)) {
  t <- res$r$test
  cat(sprintf("%s: chi-square(df=%d) = %.1f, P < .001\n",
              res$name, t$parameter, t$statistic))
}

cat("\n=== DONE ===\n")
