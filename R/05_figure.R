# 05_figure.R — Figure 1: OPS Visit Reasons
source(here::here("R", "00_packages.R"))

load(here::here("output", "ops_processed.RData"))

# --- Recompute visit reason % using respondent denominator ---
# Visit reasons are "select all that apply" so denominator = number of
# respondents (approximated by sex-reported total, excluding non-response)
respondent_n <- ops_sex %>%
  filter(column %in% c("Female", "Male")) %>%
  summarise(n = sum(n)) %>% pull(n)

cat("Visit reason denominator (sex-reported respondents):", respondent_n, "\n")

visit_data <- ops_visit %>%
  filter(!grepl("DontKnow|NoAnswer", column), n > 0) %>%
  mutate(
    reason = gsub("^VisitReason", "", column),
    # Clean labels
    label = case_when(
      reason == "GeneralHealth"                        ~ "General health/wellness",
      reason == "ChangeOfPerspective"                  ~ "Change of perspective",
      reason == "ExpandedConsciousness"                ~ "Expanded consciousness",
      reason == "Anxiety"                              ~ "Anxiety",
      reason == "Depression"                           ~ "Depression",
      reason == "EnhancedCreativity"                   ~ "Enhanced creativity",
      reason == "SpiritualityReasons"                  ~ "Spirituality",
      reason == "PTSD"                                 ~ "PTSD",
      reason == "MentalOrPhysicalExhaustion"           ~ "Mental/physical exhaustion",
      reason == "OtherTrauma"                          ~ "Other trauma",
      reason == "SubstanceUse"                         ~ "Substance use",
      reason == "ChronicPain"                          ~ "Chronic pain",
      reason == "MentalHealthDiagnosis"                ~ "Mental health diagnosis",
      reason == "UndiagnosedMentalHealthIssue"         ~ "Undiagnosed mental health",
      reason == "EatingDisorder"                       ~ "Eating disorder",
      reason == "DomesticViolenceTrauma"               ~ "Domestic violence trauma",
      reason == "EndOfLife"                             ~ "End of life",
      reason == "GenderIdentityDevelopment"            ~ "Gender identity",
      reason == "BrainInjury"                          ~ "Brain injury",
      reason == "CombatTrauma"                         ~ "Combat trauma",
      reason == "RacialTrauma"                         ~ "Racial trauma",
      reason == "ColonizationTrauma"                   ~ "Colonization trauma",
      reason == "EconomicDriver"                       ~ "Economic driver",
      reason == "CulturallyOrLinguisticallyResponsiveHealth" ~ "Culturally responsive health",
      reason == "OtherReasons"                         ~ "Other reasons",
      TRUE ~ reason
    ),
    # Categorize
    category = case_when(
      label %in% c("General health/wellness", "Change of perspective",
                    "Expanded consciousness", "Enhanced creativity",
                    "Spirituality")                            ~ "Wellness/Personal Growth",
      label %in% c("Anxiety", "Depression", "PTSD",
                    "Mental health diagnosis",
                    "Undiagnosed mental health",
                    "Substance use", "Chronic pain",
                    "Eating disorder", "End of life",
                    "Brain injury")                            ~ "Clinical",
      label %in% c("Other trauma", "Combat trauma",
                    "Racial trauma", "Colonization trauma",
                    "Domestic violence trauma")                 ~ "Trauma",
      TRUE                                                     ~ "Other"
    )
  ) %>%
  mutate(pct = n / respondent_n * 100) %>%
  filter(label != "Other reasons") %>%
  arrange(desc(pct))

# --- Top 15 for the figure ---
visit_top <- visit_data %>%
  head(15) %>%
  mutate(label = fct_reorder(label, pct))

cat("=== VISIT REASONS (top 15) ===\n")
visit_top %>% select(label, n, pct, category) %>% print(n = 15)

# --- Color palette ---
cat_colors <- c(
  "Wellness/Personal Growth" = "#2e5763",
  "Clinical"                 = "#87aab9",
  "Trauma"                   = "#f8b05d",
  "Other"                    = "#fde9d0"
)

# --- Figure ---
fig1 <- ggplot(visit_top, aes(x = pct, y = label, fill = category)) +
  geom_col(width = 0.7) +
  geom_text(aes(label = sprintf("%.1f%%", pct)),
            hjust = -0.1, size = 3, color = "gray30") +
  scale_x_continuous(
    expand = expansion(mult = c(0, 0.15)),
    labels = label_percent(scale = 1)
  ) +
  scale_fill_manual(values = cat_colors, name = NULL) +
  labs(
    x = "Percentage of respondents",
    y = NULL,
    title = NULL
  ) +
  theme_minimal(base_size = 11) +
  theme(
    legend.position = "bottom",
    panel.grid.major.y = element_blank(),
    panel.grid.minor = element_blank(),
    axis.text.y = element_text(size = 9)
  )

# --- Save ---
ggsave(here::here("output", "figures", "figure1_visit_reasons.pdf"),
       fig1, width = 7, height = 5.5)
ggsave(here::here("output", "figures", "figure1_visit_reasons.png"),
       fig1, width = 7, height = 5.5, dpi = 300)

cat("\nSaved figure1_visit_reasons.pdf and .png\n")

# --- Also save visit reason data ---
write_csv(visit_data %>% select(label, n, pct, category),
          here::here("output", "tables", "visit_reasons.csv"))
