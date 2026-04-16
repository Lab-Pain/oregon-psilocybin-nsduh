# 04_table.R — Table 1: Demographic comparison NSDUH vs OPS
source(here::here("R", "00_packages.R"))

load(here::here("output", "harmonized.RData"))
load(here::here("output", "nsduh_processed.RData"))
load(here::here("output", "ops_processed.RData"))

# --- Format for publication ---
# NSDUH: survey-weighted % (unweighted n)
# OPS: % of demographic respondents (n)
fmt_nsduh <- function(n, pct) {
  sprintf("%.1f%% (%s)", pct, format(n, big.mark = ","))
}
fmt_ops <- function(n, pct) {
  sprintf("%.1f%% (%s)", pct, format(n, big.mark = ","))
}

# Main comparison (age, sex, race — same categories both sides)
main_comp <- comparison %>%
  filter(variable != "income") %>%
  mutate(formatted = if_else(
    source == "NSDUH",
    fmt_nsduh(n, pct),
    fmt_ops(n, pct)
  )) %>%
  select(variable, category, source, formatted) %>%
  pivot_wider(names_from = source, values_from = formatted)

# Full income breakdown
nsduh_inc_detail <- income_full %>%
  filter(source == "NSDUH") %>%
  mutate(formatted = fmt_nsduh(n, pct))
ops_inc_detail <- income_full %>%
  filter(source == "OPS") %>%
  mutate(formatted = fmt_ops(n, pct))

# --- Build final table rows ---
rows <- list()

# Age
for (cat in c("18-25", "26-34", "35-49", "50-64", "65+")) {
  r <- main_comp %>% filter(variable == "age", category == cat)
  rows[[length(rows) + 1]] <- tibble(
    Variable = if (cat == "18-25") "Age, y" else "",
    Category = cat,
    `NSDUH Past-Year Psilocybin Users` = r$NSDUH,
    `OPS Clients (2025)` = r$OPS
  )
}

# Sex
for (cat in c("Male", "Female")) {
  r <- main_comp %>% filter(variable == "sex", category == cat)
  rows[[length(rows) + 1]] <- tibble(
    Variable = if (cat == "Male") "Sex" else "",
    Category = cat,
    `NSDUH Past-Year Psilocybin Users` = r$NSDUH,
    `OPS Clients (2025)` = r$OPS
  )
}

# Race
for (cat in c("White", "Black", "Hispanic", "Asian", "Other")) {
  r <- main_comp %>% filter(variable == "race", category == cat)
  rows[[length(rows) + 1]] <- tibble(
    Variable = if (cat == "White") "Race/ethnicity" else "",
    Category = if (cat == "Other") "Other/Multiracial" else cat,
    `NSDUH Past-Year Psilocybin Users` = r$NSDUH,
    `OPS Clients (2025)` = r$OPS
  )
}

# Income — show each source's brackets with full breakdown
# NSDUH brackets
rows[[length(rows) + 1]] <- tibble(
  Variable = "Household income",
  Category = "",
  `NSDUH Past-Year Psilocybin Users` = "",
  `OPS Clients (2025)` = ""
)

for (cat in c("<$20K", "$20-49K", "$50-74K", "$75K+")) {
  r <- nsduh_inc_detail %>% filter(category == cat)
  rows[[length(rows) + 1]] <- tibble(
    Variable = "",
    Category = cat,
    `NSDUH Past-Year Psilocybin Users` = if (nrow(r) > 0) r$formatted else "",
    `OPS Clients (2025)` = "—"
  )
}

# OPS brackets
for (i in seq_len(nrow(ops_inc_detail))) {
  r <- ops_inc_detail[i, ]
  rows[[length(rows) + 1]] <- tibble(
    Variable = "",
    Category = r$category,
    `NSDUH Past-Year Psilocybin Users` = "—",
    `OPS Clients (2025)` = r$formatted
  )
}

# ===========================================================
# OPS-unique: Out-of-state residence
# ===========================================================
geo_data <- ops_geo %>% filter(!grepl("NoAnswer", column))
oregon_n <- geo_data %>%
  filter(!column %in% c("OtherInsideUS", "OutsideUS")) %>%
  summarise(n = sum(n, na.rm = TRUE)) %>% pull(n)
other_us <- geo_data %>% filter(column == "OtherInsideUS") %>% pull(n)
outside  <- geo_data %>% filter(column == "OutsideUS") %>% pull(n)
geo_denom <- oregon_n + other_us + outside

rows[[length(rows) + 1]] <- tibble(
  Variable = "Residence (OPS only)",
  Category = "Oregon",
  `NSDUH Past-Year Psilocybin Users` = "—",
  `OPS Clients (2025)` = fmt_ops(oregon_n, oregon_n / geo_denom * 100)
)
rows[[length(rows) + 1]] <- tibble(
  Variable = "", Category = "Other US state",
  `NSDUH Past-Year Psilocybin Users` = "—",
  `OPS Clients (2025)` = fmt_ops(other_us, other_us / geo_denom * 100)
)
rows[[length(rows) + 1]] <- tibble(
  Variable = "", Category = "International",
  `NSDUH Past-Year Psilocybin Users` = "—",
  `OPS Clients (2025)` = fmt_ops(outside, outside / geo_denom * 100)
)

# ===========================================================
# NSDUH-unique: Past-year clinical profile
# ===========================================================
# Extract from nsduh_mh (already has weighted_pct for "Yes" category)
add_mh_row <- function(varname, label, is_first = FALSE) {
  r <- nsduh_mh %>% filter(variable == varname, category == "Yes")
  if (nrow(r) == 0) return(NULL)
  tibble(
    Variable = if (is_first) "Past-year clinical (NSDUH only)" else "",
    Category = label,
    `NSDUH Past-Year Psilocybin Users` = fmt_nsduh(r$n, r$weighted_pct),
    `OPS Clients (2025)` = "—"
  )
}

rows[[length(rows) + 1]] <- add_mh_row("mde", "Major depressive episode", TRUE)
rows[[length(rows) + 1]] <- add_mh_row("spd", "Serious psychological distress")
rows[[length(rows) + 1]] <- add_mh_row("suicidal_ideation", "Suicidal ideation")
rows[[length(rows) + 1]] <- add_mh_row("any_sud", "Any substance use disorder")
rows[[length(rows) + 1]] <- add_mh_row("mh_treatment", "Received MH treatment")

# Remove NULLs
rows <- rows[!sapply(rows, is.null)]

table1_final <- bind_rows(rows)

cat("\n=== TABLE 1 ===\n")
print(table1_final, n = 40)

# --- Export ---
write_csv(table1_final,
          here::here("output", "tables", "table1_comparison.csv"))
cat("\nSaved to output/tables/table1_comparison.csv\n")

# --- Also save raw comparison numbers for verification ---
write_csv(comparison,
          here::here("output", "tables", "comparison_raw.csv"))
