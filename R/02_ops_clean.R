# 02_ops_clean.R — Read, clean, and sum 4 OPS quarterly CSVs
source(here::here("R", "00_packages.R"))

# --- Read quarterly CSVs ---
ops_dir <- here::here("OPS")
q_files <- paste0("OPS-Data-File-2025-Q", 1:4, ".csv")

ops_raw <- map(q_files, function(f) {
  df <- read_csv(file.path(ops_dir, f), show_col_types = FALSE)
  # Remove blank trailing rows

  df <- df %>% filter(!if_all(everything(), ~is.na(.) | . == ""))
  df
})
names(ops_raw) <- paste0("Q", 1:4)

cat("Rows per quarter:", map_int(ops_raw, nrow), "\n")
cat("Cols per quarter:", map_int(ops_raw, ncol), "\n")

# --- Identify common columns ---
common_cols <- Reduce(intersect, map(ops_raw, names))
cat("Common columns:", length(common_cols), "\n")

# --- Stack into single row per quarter using common columns ---
ops_all <- bind_rows(
  ops_raw$Q1 %>% select(all_of(common_cols)) %>% mutate(quarter = "Q1"),
  ops_raw$Q2 %>% select(all_of(common_cols)) %>% mutate(quarter = "Q2"),
  ops_raw$Q3 %>% select(all_of(common_cols)) %>% mutate(quarter = "Q3"),
  ops_raw$Q4 %>% select(all_of(common_cols)) %>% mutate(quarter = "Q4")
)

# --- Replace -99 with NA ---
ops_all <- ops_all %>%
  mutate(across(where(is.numeric), ~if_else(. == -99, NA_real_, .)))

# --- Service volume summary ---
service_summary <- ops_all %>%
  summarise(
    total_clients    = sum(ClientsServed, na.rm = TRUE),
    total_individual = sum(IndividualAdministrationSessions, na.rm = TRUE),
    total_group      = sum(GroupAdministrationSessions, na.rm = TRUE),
    total_denials    = sum(DeniedPsilocybinServicesTotal, na.rm = TRUE),
    adverse_behavioral = sum(AdverseBehavioralReactions, na.rm = TRUE),
    severe_behavioral  = sum(SevereBehavioralReactions, na.rm = TRUE),
    adverse_medical    = sum(AdverseMedicalReactions, na.rm = TRUE),
    severe_medical     = sum(SevereMedicalReactions, na.rm = TRUE),
    post_session       = sum(PostSessionReactions, na.rm = TRUE)
  ) %>%
  mutate(
    total_sessions = total_individual + total_group,
    total_adverse  = adverse_behavioral + severe_behavioral +
                     adverse_medical + severe_medical
  )

cat("\nService summary:\n")
print(as.data.frame(service_summary))

# ===========================================================
# DEMOGRAPHICS: sum across quarters, compute respondent %
# ===========================================================

sum_cols <- function(col_names) {
  # Sum a set of columns across all 4 quarters
  ops_all %>%
    summarise(across(all_of(col_names), ~sum(., na.rm = TRUE))) %>%
    pivot_longer(everything(), names_to = "column", values_to = "n")
}

# --- AGE (select one) ---
age_cols <- c("Under21", "Age21_24", "Age25_29", "Age30_34", "Age35_39",
              "Age40_44", "Age45_49", "Age50_54", "Age55_59", "Age60_64",
              "Age65_69", "Age70_74", "Age75_79", "Age80_84", "Age85Older",
              "NoAgeAnswer")
ops_age <- sum_cols(intersect(age_cols, common_cols))

# --- SEX (select one) ---
sex_cols <- c("Female", "Male", "Intersex", "SexDontKnow",
              "SexDontUnderstand", "SexNoAnswer", "SexNotListed")
ops_sex <- sum_cols(intersect(sex_cols, common_cols))

# --- INCOME (select one) ---
income_cols <- c("Income0_11000", "Income11001_44725", "Income44726_95375",
                 "Income95376_182100", "Income182101_231250",
                 "Income231251_578125", "Income578126More",
                 "NoAnswerForIncome")
ops_income <- sum_cols(intersect(income_cols, common_cols))

# --- PRIMARY RACIAL IDENTITY (select one) ---
pi_cols <- common_cols[grepl("^PrimaryIdentity", common_cols)]
ops_race_pi <- sum_cols(pi_cols)

# --- GEOGRAPHY (select one) ---
geo_cols <- c(common_cols[common_cols %in% c(
  "Baker", "Benton", "Clackamas", "Clatsop", "Columbia", "Coos", "Crook",
  "Curry", "Deschutes", "Douglas", "Gilliam", "Grant", "Harney", "HoodRiver",
  "Jackson", "Jefferson", "Josephine", "Klamath", "Lake", "Lane", "Lincoln",
  "Linn", "Malheur", "Marion", "Morrow", "Multnomah", "Polk", "Sherman",
  "Tillamook", "Umatilla", "Union", "Wallowa", "Wasco", "Washington",
  "Wheeler", "Yamhill")],
  "OtherInsideUS", "OutsideUS", "NoAnswerForCounty")
ops_geo <- sum_cols(intersect(geo_cols, common_cols))

# --- VISIT REASONS (select all that apply) ---
vr_cols <- common_cols[grepl("^VisitReason", common_cols)]
ops_visit <- sum_cols(vr_cols)

# --- SEXUAL ORIENTATION ---
so_cols <- c("SameGenderLoving", "Lesbian", "Gay", "Bisexual", "Pansexual",
             "Straight", "Asexual", "Queer", "QuestioningSexualOrientation",
             "SexualOrientationNotListed", "SexualOrientationDontKnow",
             "SexualOrientationDontUnderstand", "SexualOrientationNoAnswer")
ops_orientation <- sum_cols(intersect(so_cols, common_cols))

# --- GENDER IDENTITY ---
gi_cols <- c("WomanGirl", "ManBoy", "NonBinary", "Agender", "Bigender",
             "Demiboy", "Demigirl", "Genderfluid", "Genderqueer",
             "QuestioningGender", "GenderNotListed",
             "GenderSpecificToEthnicity", "GenderDontKnow",
             "GenderDontUnderstand", "GenderNoAnswer")
ops_gender <- sum_cols(intersect(gi_cols, common_cols))

# --- ADVERSE EVENTS (already in service_summary) ---

# --- DISABILITY (Yes/No per domain) ---
disability_domains <- c("Deaf", "Blind", "DifficultyWalking",
                        "DifficultyConcentrating", "DifficultyDressingOrBathing",
                        "DifficultyLearning", "DifficultyCommunicating",
                        "DifficultyErrandsAlone", "DifficultyWithMoods")
disability_cols <- paste0(rep(disability_domains, each = 4),
                          c("Yes", "No", "DontKnow", "NoAnswer"))
ops_disability <- sum_cols(intersect(disability_cols, common_cols))

# --- LANGUAGE (select one) ---
spoken_cols <- common_cols[grepl("^Spoken", common_cols)]
ops_language <- sum_cols(spoken_cols)

# ===========================================================
# Compute respondent denominators and percentages
# ===========================================================

add_pct <- function(df, nonresponse_patterns) {
  # Remove non-response rows, compute denominator, add pct
  respondents <- df %>%
    filter(!grepl(nonresponse_patterns, column, ignore.case = TRUE))
  denom <- sum(respondents$n, na.rm = TRUE)

  df %>%
    mutate(
      respondent_denom = denom,
      pct = if_else(n > 0 & !grepl(nonresponse_patterns, column, ignore.case = TRUE),
                    n / denom * 100, NA_real_)
    )
}

ops_age     <- add_pct(ops_age,     "NoAge|Answer")
ops_sex     <- add_pct(ops_sex,     "NoAnswer|DontKnow|DontUnderstand|NotListed")
ops_income  <- add_pct(ops_income,  "NoAnswer")
ops_race_pi <- add_pct(ops_race_pi, "DontKnow|DontWant|^PrimaryIdentityNA$")
ops_geo     <- add_pct(ops_geo,     "NoAnswer")
ops_visit   <- add_pct(ops_visit,   "DontKnow|NoAnswer")
ops_orientation <- add_pct(ops_orientation, "NoAnswer|DontKnow|DontUnderstand")
ops_gender  <- add_pct(ops_gender,  "NoAnswer|DontKnow|DontUnderstand")

# Disability: compute % Yes among Yes+No respondents per domain
ops_disability_summary <- tibble(
  domain = disability_domains,
  yes = map_dbl(disability_domains, ~{
    v <- ops_disability %>% filter(column == paste0(.x, "Yes")) %>% pull(n)
    if (length(v) == 0) 0 else v
  }),
  no = map_dbl(disability_domains, ~{
    v <- ops_disability %>% filter(column == paste0(.x, "No")) %>% pull(n)
    if (length(v) == 0) 0 else v
  })
) %>%
  mutate(
    respondents = yes + no,
    pct = if_else(respondents > 0, yes / respondents * 100, NA_real_)
  )

cat("\n--- OPS Disability ---\n")
print(ops_disability_summary)

# --- Average client uses (weighted across quarters) ---
avg_uses_weighted <- ops_all %>%
  summarise(
    weighted_avg = sum(ClientsServed * AverageClientUses, na.rm = TRUE) /
                   sum(ClientsServed, na.rm = TRUE)
  ) %>%
  pull(weighted_avg)
cat("\nWeighted average client uses:", round(avg_uses_weighted, 2), "\n")

cat("\n--- OPS Age ---\n")
print(ops_age)
cat("\n--- OPS Sex ---\n")
print(ops_sex)
cat("\n--- OPS Income ---\n")
print(ops_income)
cat("\n--- OPS Visit Reasons (top 15) ---\n")
print(ops_visit %>% filter(!is.na(pct)) %>% arrange(desc(pct)) %>% head(15))

# ===========================================================
# Service denials by reason
# ===========================================================
denial_cols <- c(
  "DeniedDueToClientRequestedInconsistentBusinessModel",
  "DeniedDueToClientIsIneligible",
  "DeniedDueToClientIsIntoxicated",
  "DeniedDueToClientExhibitedConcerningBehaviors",
  "DeniedDueToOtherReasons"
)
denial_summary <- ops_all %>%
  summarise(across(all_of(denial_cols), ~sum(., na.rm = TRUE))) %>%
  pivot_longer(everything(), names_to = "reason", values_to = "n") %>%
  mutate(
    label = case_when(
      grepl("Inconsistent", reason)  ~ "Inconsistent with business model",
      grepl("Ineligible", reason)    ~ "Client ineligible",
      grepl("Intoxicated", reason)   ~ "Client intoxicated",
      grepl("Concerning", reason)    ~ "Concerning behaviors",
      grepl("Other", reason)         ~ "Other reasons"
    ),
    pct_of_denials = n / sum(n) * 100
  )

# ===========================================================
# Table 2: Service and safety summary (CSV export)
# ===========================================================
total_encounters <- service_summary$total_clients
total_sessions   <- service_summary$total_sessions
total_denials    <- service_summary$total_denials

table2 <- tribble(
  ~category,        ~characteristic,                        ~n,      ~denominator,  ~pct,
  "Service volume", "Client-quarter encounters",            total_encounters, NA,    NA,
  "Service volume", "Individual administration sessions",   service_summary$total_individual, total_sessions, service_summary$total_individual / total_sessions * 100,
  "Service volume", "Group administration sessions",        service_summary$total_group, total_sessions, service_summary$total_group / total_sessions * 100,
  "Service volume", "Total sessions",                       total_sessions, NA, NA,
  "Service volume", "Mean psilocybin dose (mg)",            24.5, NA, NA,
  "Service volume", "Mean encounters per client",            round(avg_uses_weighted, 2), NA, NA,
  "Adverse events", "Adverse behavioral reactions",         service_summary$adverse_behavioral, total_encounters, service_summary$adverse_behavioral / total_encounters * 100,
  "Adverse events", "Severe adverse behavioral reactions",  service_summary$severe_behavioral, total_encounters, service_summary$severe_behavioral / total_encounters * 100,
  "Adverse events", "Adverse medical reactions",            service_summary$adverse_medical, total_encounters, service_summary$adverse_medical / total_encounters * 100,
  "Adverse events", "Severe adverse medical reactions",     service_summary$severe_medical, total_encounters, service_summary$severe_medical / total_encounters * 100,
  "Adverse events", "Post-session reactions",               service_summary$post_session, total_encounters, service_summary$post_session / total_encounters * 100,
  "Adverse events", "Total adverse events",                 service_summary$total_adverse, total_encounters, service_summary$total_adverse / total_encounters * 100,
  "Service denials","Inconsistent with business model",     denial_summary$n[denial_summary$label == "Inconsistent with business model"], total_denials, denial_summary$pct_of_denials[denial_summary$label == "Inconsistent with business model"],
  "Service denials","Client ineligible",                    denial_summary$n[denial_summary$label == "Client ineligible"], total_denials, denial_summary$pct_of_denials[denial_summary$label == "Client ineligible"],
  "Service denials","Client intoxicated",                   denial_summary$n[denial_summary$label == "Client intoxicated"], total_denials, denial_summary$pct_of_denials[denial_summary$label == "Client intoxicated"],
  "Service denials","Concerning behaviors",                 denial_summary$n[denial_summary$label == "Concerning behaviors"], total_denials, denial_summary$pct_of_denials[denial_summary$label == "Concerning behaviors"],
  "Service denials","Other reasons",                        denial_summary$n[denial_summary$label == "Other reasons"], total_denials, denial_summary$pct_of_denials[denial_summary$label == "Other reasons"],
  "Service denials","Total denials",                        total_denials, total_encounters, total_denials / total_encounters * 100,
) %>%
  bind_rows(
    ops_disability_summary %>%
      mutate(
        category = "Disability",
        characteristic = case_when(
          domain == "DifficultyWithMoods"          ~ "Difficulty with moods",
          domain == "DifficultyConcentrating"      ~ "Difficulty concentrating",
          domain == "DifficultyErrandsAlone"       ~ "Difficulty doing errands alone",
          domain == "DifficultyWalking"            ~ "Difficulty walking",
          domain == "DifficultyLearning"           ~ "Difficulty learning",
          domain == "DifficultyCommunicating"      ~ "Difficulty communicating",
          domain == "DifficultyDressingOrBathing"  ~ "Difficulty dressing or bathing",
          domain == "Deaf"                         ~ "Deaf or hard of hearing",
          domain == "Blind"                        ~ "Blind or difficulty seeing"
        ),
        n = yes,
        denominator = respondents
      ) %>%
      select(category, characteristic, n, denominator, pct)
  )

cat("\n--- Table 2: Service and Safety ---\n")
print(table2, n = 20)

write_csv(table2, here::here("output", "tables", "table2_service_safety.csv"))
cat("\nSaved to output/tables/table2_service_safety.csv\n")

# --- Save ---
save(ops_age, ops_sex, ops_income, ops_race_pi, ops_geo,
     ops_visit, ops_orientation, ops_gender, ops_language,
     ops_disability, ops_disability_summary, avg_uses_weighted,
     service_summary, denial_summary, ops_all,
     file = here::here("output", "ops_processed.RData"))
cat("\nSaved to output/ops_processed.RData\n")
