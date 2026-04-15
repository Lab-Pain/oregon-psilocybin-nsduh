# 01_nsduh_setup.R — Load NSDUH data and compute weighted demographics
# for past-year psilocybin users
source(here::here("R", "00_packages.R"))

# --- Load preprocessed NSDUH data ---
nsduh_path <- here::here("NSDUH", "nsduh_analysis_ready.RData")
load(nsduh_path)

# --- Survey design ---
nsduh_svy <- svydesign(
  ids     = ~VEREP,
  strata  = ~VESTR_C,
  weights = ~ANALWT2_C,
  data    = nsduh_adults,
  nest    = TRUE
)

# --- Subset to past-year psilocybin users ---
psil_svy <- subset(nsduh_svy, psilocybin_yr == "Yes")

cat("NSDUH past-year psilocybin users (unweighted n):",
    nrow(psil_svy$variables), "\n")

# --- Helper: compute weighted % + SE for one variable ---
compute_weighted_pct <- function(svy_obj, varname) {
  formula <- as.formula(paste0("~", varname))
  tbl <- svymean(formula, svy_obj, na.rm = TRUE)

  data.frame(
    variable = varname,
    category = gsub(varname, "", names(coef(tbl))),
    weighted_pct = as.numeric(coef(tbl)) * 100,
    se = as.numeric(SE(tbl)) * 100,
    stringsAsFactors = FALSE
  )
}

# --- Helper: compute weighted N (population estimate) + SE ---
compute_weighted_N <- function(svy_obj, varname) {
  formula <- as.formula(paste0("~", varname))
  tbl <- svytotal(formula, svy_obj, na.rm = TRUE)

  data.frame(
    variable = varname,
    category = gsub(varname, "", names(coef(tbl))),
    weighted_N = as.numeric(coef(tbl)),
    se_N = as.numeric(SE(tbl)),
    stringsAsFactors = FALSE
  )
}

# --- Helper: unweighted counts ---
compute_counts <- function(df, varname) {
  tbl <- table(df[[varname]], useNA = "no")
  data.frame(
    variable = varname,
    category = names(tbl),
    n = as.integer(tbl),
    stringsAsFactors = FALSE
  )
}

# --- Total weighted N (estimated US past-year psilocybin users) ---
total_weighted_N <- sum(weights(psil_svy))
cat("Estimated US past-year psilocybin users (weighted N):",
    format(round(total_weighted_N), big.mark = ","), "\n")

# --- Harmonized age (5 groups, already coded as age_cat) ---
nsduh_age_pct <- compute_weighted_pct(psil_svy, "age_cat")
nsduh_age_N   <- compute_weighted_N(psil_svy, "age_cat")
nsduh_age_n   <- compute_counts(psil_svy$variables, "age_cat")

# --- Sex (already binary) ---
nsduh_sex_pct <- compute_weighted_pct(psil_svy, "sex")
nsduh_sex_N   <- compute_weighted_N(psil_svy, "sex")
nsduh_sex_n   <- compute_counts(psil_svy$variables, "sex")

# --- Race/ethnicity: collapse to 5 categories ---
psil_svy$variables <- psil_svy$variables %>%
  mutate(race_5 = fct_collapse(race_eth,
    "White"    = "NH White",
    "Black"    = "NH Black",
    "Hispanic" = "Hispanic",
    "Asian"    = "NH Asian",
    "Other"    = c("NH Native American", "NH Pacific Islander", "NH Multiracial")
  ))

nsduh_race_pct <- compute_weighted_pct(psil_svy, "race_5")
nsduh_race_N   <- compute_weighted_N(psil_svy, "race_5")
nsduh_race_n   <- compute_counts(psil_svy$variables, "race_5")

# --- Income (already 4 categories) ---
nsduh_inc_pct <- compute_weighted_pct(psil_svy, "income")
nsduh_inc_N   <- compute_weighted_N(psil_svy, "income")
nsduh_inc_n   <- compute_counts(psil_svy$variables, "income")

# --- Combine all NSDUH demographics ---
nsduh_demo <- bind_rows(
  left_join(nsduh_age_n, nsduh_age_pct, by = c("variable", "category")) %>%
    left_join(nsduh_age_N, by = c("variable", "category")),
  left_join(nsduh_sex_n, nsduh_sex_pct, by = c("variable", "category")) %>%
    left_join(nsduh_sex_N, by = c("variable", "category")),
  left_join(nsduh_race_n, nsduh_race_pct, by = c("variable", "category")) %>%
    left_join(nsduh_race_N, by = c("variable", "category")),
  left_join(nsduh_inc_n, nsduh_inc_pct, by = c("variable", "category")) %>%
    left_join(nsduh_inc_N, by = c("variable", "category"))
) %>%
  mutate(source = "NSDUH")

cat("\nNSDUH demographics computed:\n")
print(as_tibble(nsduh_demo), n = 30)

# --- Also extract MH/SUD prevalences for in-text stats ---
# Convert integer 0/1 variables to factors for svymean
int_to_factor <- c("any_sud")
for (v in int_to_factor) {
  if (v %in% names(psil_svy$variables) && is.numeric(psil_svy$variables[[v]])) {
    psil_svy$variables[[v]] <- factor(psil_svy$variables[[v]],
                                       levels = c(0, 1),
                                       labels = c("No", "Yes"))
  }
}

mh_vars <- c("mde", "spd", "suicidal_ideation", "any_sud", "mh_treatment")
nsduh_mh <- map_dfr(mh_vars, function(v) {
  if (v %in% names(psil_svy$variables)) {
    pct <- compute_weighted_pct(psil_svy, v)
    N   <- compute_weighted_N(psil_svy, v)
    n   <- compute_counts(psil_svy$variables, v)
    left_join(n, pct, by = c("variable", "category")) %>%
      left_join(N, by = c("variable", "category"))
  }
})

# --- Save ---
save(nsduh_demo, nsduh_mh, total_weighted_N, psil_svy, nsduh_svy,
     file = here::here("output", "nsduh_processed.RData"))
cat("\nSaved to output/nsduh_processed.RData\n")
