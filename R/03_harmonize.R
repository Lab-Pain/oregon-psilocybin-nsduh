# 03_harmonize.R — Align OPS and NSDUH categories for comparison
source(here::here("R", "00_packages.R"))

load(here::here("output", "nsduh_processed.RData"))
load(here::here("output", "ops_processed.RData"))

# ===========================================================
# OPS AGE → NSDUH 5 groups
# ===========================================================
ops_age_harmonized <- ops_age %>%
  filter(!is.na(pct)) %>%
  mutate(age_group = case_when(
    column %in% c("Under21", "Age21_24")                       ~ "18-25",
    column %in% c("Age25_29", "Age30_34")                      ~ "26-34",
    column %in% c("Age35_39", "Age40_44", "Age45_49")          ~ "35-49",
    column %in% c("Age50_54", "Age55_59", "Age60_64")          ~ "50-64",
    column %in% c("Age65_69", "Age70_74", "Age75_79",
                   "Age80_84", "Age85Older")                   ~ "65+",
    TRUE ~ NA_character_
  )) %>%
  filter(!is.na(age_group)) %>%
  group_by(age_group) %>%
  summarise(n = sum(n), .groups = "drop") %>%
  mutate(
    denom = sum(n),
    pct   = n / denom * 100,
    variable = "age",
    source   = "OPS"
  ) %>%
  rename(category = age_group) %>%
  select(source, variable, category, n, pct)

# ===========================================================
# OPS SEX → Male / Female
# ===========================================================
ops_sex_harmonized <- ops_sex %>%
  filter(column %in% c("Female", "Male")) %>%
  mutate(
    denom = sum(n),
    pct   = n / denom * 100,
    variable = "sex",
    source   = "OPS",
    category = column
  ) %>%
  select(source, variable, category, n, pct)

# ===========================================================
# OPS PRIMARY RACIAL IDENTITY → 5 categories
# ===========================================================
ops_race_harmonized <- ops_race_pi %>%
  filter(!is.na(pct)) %>%
  mutate(race_group = case_when(
    column %in% c("PrimaryIdentityWesternEuropean",
                   "PrimaryIdentityEasternEuropean",
                   "PrimaryIdentitySlavic",
                   "PrimaryIdentityOtherWhite")               ~ "White",
    column == "PrimaryIdentityAfricanAmerican"                 ~ "Black",
    column %in% c("PrimaryIdentityCentralAmerican",
                   "PrimaryIdentityMexican",
                   "PrimaryIdentitySouthAmerican",
                   "PrimaryIdentityOtherHispanic")             ~ "Hispanic",
    column %in% c("PrimaryIdentityAsianIndian",
                   "PrimaryIdentityChinese",
                   "PrimaryIdentityJapanese",
                   "PrimaryIdentityKorean",
                   "PrimaryIdentityCambodian",
                   "PrimaryIdentityMyanmar",
                   "PrimaryIdentityFilipinoA",
                   "PrimaryIdentityHmong",
                   "PrimaryIdentityLaotian",
                   "PrimaryIdentitySouthAsian",
                   "PrimaryIdentityVietnamese",
                   "PrimaryIdentityOtherAsian")                ~ "Asian",
    column %in% c("PrimaryIdentityAmericanIndian",
                   "PrimaryIdentityAlaskaNative",
                   "PrimaryIdentityCanadianInnuitMetisFirstNation",
                   "PrimaryIdentityIndigenousMexicanCentralAmericanSouthAmerican",
                   "PrimaryIdentityAfroCaribbean",
                   "PrimaryIdentityEthiopian",
                   "PrimaryIdentitySomali",
                   "PrimaryIdentityOtherAfrican",
                   "PrimaryIdentityOtherBlack",
                   "PrimaryIdentityMiddleEastern",
                   "PrimaryIdentityNorthAfrican",
                   "PrimaryIdentityChamoruChamorro",
                   "PrimaryIdentityMarshallese",
                   "PrimaryIdentityCommunitiesOfTheMicronesianRegion",
                   "PrimaryIdentityNativeHawaiian",
                   "PrimaryIdentitySamoan",
                   "PrimaryIdentityOtherPacificIslander",
                   "PrimaryIdentityRacialIdentitiesOtherNotListed",
                   "PrimaryIdentityMultipleIdentities",
                   "PrimaryIdentityBiracial")                  ~ "Other",
    TRUE ~ NA_character_
  )) %>%
  filter(!is.na(race_group)) %>%
  group_by(race_group) %>%
  summarise(n = sum(n), .groups = "drop") %>%
  mutate(
    denom = sum(n),
    pct   = n / denom * 100,
    variable = "race",
    source   = "OPS"
  ) %>%
  rename(category = race_group) %>%
  select(source, variable, category, n, pct)

# ===========================================================
# OPS INCOME → show full brackets for each source
# Thresholds differ: NSDUH 4 brackets, OPS 7 brackets
# We show both the collapsed 3-tier AND full breakdowns
# ===========================================================

# 3-tier collapsed (for the main comparison)
ops_inc_harmonized <- ops_income %>%
  filter(!grepl("NoAnswer", column)) %>%
  mutate(income_group = case_when(
    column %in% c("Income0_11000", "Income11001_44725")       ~ "<$45K",
    column == "Income44726_95375"                              ~ "$45-95K",
    column %in% c("Income95376_182100", "Income182101_231250",
                   "Income231251_578125", "Income578126More")  ~ ">$95K",
    TRUE ~ NA_character_
  )) %>%
  filter(!is.na(income_group)) %>%
  group_by(income_group) %>%
  summarise(n = sum(n), .groups = "drop") %>%
  mutate(
    denom = sum(n),
    pct   = n / denom * 100,
    variable = "income",
    source   = "OPS"
  ) %>%
  rename(category = income_group) %>%
  select(source, variable, category, n, pct)

# Full OPS income breakdown
ops_inc_full <- ops_income %>%
  filter(!grepl("NoAnswer", column), n > 0) %>%
  mutate(
    category = case_when(
      column == "Income0_11000"       ~ "$0-11K",
      column == "Income11001_44725"   ~ "$11-45K",
      column == "Income44726_95375"   ~ "$45-95K",
      column == "Income95376_182100"  ~ "$95-182K",
      column == "Income182101_231250" ~ "$182-231K",
      column == "Income231251_578125" ~ "$231-578K",
      column == "Income578126More"    ~ ">$578K"
    ),
    denom = sum(n),
    pct   = n / denom * 100,
    variable = "income_full",
    source   = "OPS"
  ) %>%
  select(source, variable, category, n, pct)

# ===========================================================
# NSDUH: reformat to match OPS structure
# ===========================================================
# Full NSDUH income breakdown (keep original 4 brackets)
nsduh_inc_full <- nsduh_demo %>%
  filter(variable == "income") %>%
  mutate(variable = "income_full") %>%
  rename(pct = weighted_pct) %>%
  select(source, variable, category, n, weighted_N, se_N, pct, se)

# Collapsed NSDUH income for 3-tier comparison
nsduh_harmonized <- nsduh_demo %>%
  mutate(
    variable = case_when(
      variable == "age_cat" ~ "age",
      variable == "sex"     ~ "sex",
      variable == "race_5"  ~ "race",
      variable == "income"  ~ "income",
      TRUE ~ variable
    ),
    category = case_when(
      variable == "income" & category %in% c("<$20K", "$20-49K") ~ "<$50K",
      variable == "income" & category == "$50-74K"               ~ "$50-74K",
      variable == "income" & category == "$75K+"                 ~ "≥$75K",
      TRUE ~ category
    )
  ) %>%
  group_by(source, variable, category) %>%
  summarise(
    n = sum(n),
    weighted_N = sum(weighted_N),
    weighted_pct = if (variable[1] == "income" & n() > 1) {
      sum(weighted_pct)
    } else {
      weighted_pct[1]
    },
    se_N = if (variable[1] == "income" & n() > 1) {
      sqrt(sum(se_N^2))
    } else {
      se_N[1]
    },
    se = if (variable[1] == "income" & n() > 1) {
      sqrt(sum(se^2))
    } else {
      se[1]
    },
    .groups = "drop"
  ) %>%
  rename(pct = weighted_pct) %>%
  select(source, variable, category, n, weighted_N, se_N, pct, se)

# ===========================================================
# Combine into single comparison data frame
# ===========================================================
ops_combined <- bind_rows(
  ops_age_harmonized,
  ops_sex_harmonized,
  ops_race_harmonized,
  ops_inc_harmonized
) %>%
  mutate(se = NA_real_, weighted_N = NA_real_, se_N = NA_real_)

comparison <- bind_rows(nsduh_harmonized, ops_combined) %>%
  mutate(
    variable = factor(variable, levels = c("age", "sex", "race", "income")),
    category = factor(category, levels = c(
      "18-25", "26-34", "35-49", "50-64", "65+",
      "Male", "Female",
      "White", "Black", "Hispanic", "Asian", "Other",
      "<$50K", "$50-74K", "≥$75K",
      "<$45K", "$45-95K", ">$95K"
    ))
  ) %>%
  arrange(variable, category, source)

# Full income breakdown (both sources)
income_full <- bind_rows(
  nsduh_inc_full,
  ops_inc_full %>% mutate(se = NA_real_, weighted_N = NA_real_, se_N = NA_real_)
)

cat("\n=== HARMONIZED COMPARISON ===\n")
comparison %>%
  mutate(pct_fmt = sprintf("%.1f%%", pct)) %>%
  select(source, variable, category, n, pct_fmt) %>%
  print(n = 40)

# --- Save ---
save(comparison, income_full,
     ops_age_harmonized, ops_sex_harmonized,
     ops_race_harmonized, ops_inc_harmonized, ops_inc_full,
     file = here::here("output", "harmonized.RData"))
cat("\nSaved to output/harmonized.RData\n")
