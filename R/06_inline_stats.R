# 06_inline_stats.R — All in-text statistics for the manuscript
source(here::here("R", "00_packages.R"))

load(here::here("output", "nsduh_processed.RData"))
load(here::here("output", "ops_processed.RData"))
load(here::here("output", "harmonized.RData"))

cat("============================================================\n")
cat("  IN-TEXT STATISTICS FOR JAMA PSYCHIATRY BRIEF REPORT\n")
cat("============================================================\n\n")

# --- Sample sizes ---
cat("--- SAMPLE SIZES ---\n")
cat(sprintf("NSDUH total adults (unweighted): %s\n",
            format(nrow(nsduh_svy$variables), big.mark = ",")))
cat(sprintf("NSDUH past-year psilocybin users (unweighted n): %s\n",
            format(nrow(psil_svy$variables), big.mark = ",")))
cat(sprintf("NSDUH past-year psilocybin users (weighted N): %s\n",
            format(round(total_weighted_N), big.mark = ",")))
cat(sprintf("OPS client-quarter encounters: %s\n",
            format(service_summary$total_clients, big.mark = ",")))
cat(sprintf("OPS total sessions: %s (individual: %s, group: %s)\n",
            format(service_summary$total_sessions, big.mark = ","),
            format(service_summary$total_individual, big.mark = ","),
            format(service_summary$total_group, big.mark = ",")))

# --- OPS opt-out rate ---
# Use sex as proxy for demographic reporting
ops_sex_total <- ops_sex %>% summarise(total = sum(n)) %>% pull(total)
cat(sprintf("\nOPS demographic respondents (sex proxy): %s of %s (%.1f%% opt-out/missing)\n",
            format(ops_sex_total, big.mark = ","),
            format(service_summary$total_clients, big.mark = ","),
            (1 - ops_sex_total / service_summary$total_clients) * 100))

# --- Safety ---
cat("\n--- SAFETY ---\n")
cat(sprintf("Total adverse events: %d (of %s encounters = %.2f%%)\n",
            service_summary$total_adverse,
            format(service_summary$total_clients, big.mark = ","),
            service_summary$total_adverse / service_summary$total_clients * 100))
cat(sprintf("  Adverse behavioral: %d\n", service_summary$adverse_behavioral))
cat(sprintf("  Severe behavioral: %d\n", service_summary$severe_behavioral))
cat(sprintf("  Adverse medical: %d\n", service_summary$adverse_medical))
cat(sprintf("  Severe medical: %d\n", service_summary$severe_medical))
cat(sprintf("  Post-session reactions: %d\n", service_summary$post_session))
cat(sprintf("Denials: %d (zero for intoxication)\n",
            service_summary$total_denials))

# --- Geography ---
cat("\n--- OPS GEOGRAPHY ---\n")
geo_data <- ops_geo %>% filter(!grepl("NoAnswer", column))
oregon_n <- geo_data %>%
  filter(!column %in% c("OtherInsideUS", "OutsideUS")) %>%
  summarise(n = sum(n, na.rm = TRUE)) %>% pull(n)
other_us <- geo_data %>% filter(column == "OtherInsideUS") %>% pull(n)
outside  <- geo_data %>% filter(column == "OutsideUS") %>% pull(n)
geo_denom <- oregon_n + other_us + outside

cat(sprintf("Oregon residents: %s (%.1f%%)\n",
            format(oregon_n, big.mark = ","), oregon_n / geo_denom * 100))
cat(sprintf("Other US states: %s (%.1f%%)\n",
            format(other_us, big.mark = ","), other_us / geo_denom * 100))
cat(sprintf("International: %s (%.1f%%)\n",
            format(outside, big.mark = ","), outside / geo_denom * 100))
cat(sprintf("Geography denominator: %s\n", format(geo_denom, big.mark = ",")))

# --- Language ---
cat("\n--- OPS LANGUAGE ---\n")
english_spoken <- ops_language %>% filter(column == "SpokenEnglish") %>% pull(n)
lang_total <- ops_language %>% summarise(total = sum(n, na.rm = TRUE)) %>% pull(total)
cat(sprintf("Spoken English: %s of %s (%.1f%%)\n",
            format(english_spoken, big.mark = ","),
            format(lang_total, big.mark = ","),
            english_spoken / lang_total * 100))

# --- Sexual orientation ---
cat("\n--- OPS SEXUAL ORIENTATION ---\n")
non_hetero <- ops_orientation %>%
  filter(!grepl("Straight|NoAnswer|DontKnow|DontUnderstand", column)) %>%
  summarise(n = sum(n, na.rm = TRUE)) %>% pull(n)
so_denom <- ops_orientation %>%
  filter(!grepl("NoAnswer|DontKnow|DontUnderstand", column)) %>%
  summarise(n = sum(n, na.rm = TRUE)) %>% pull(n)
cat(sprintf("Non-heterosexual: %s of %s (%.1f%%)\n",
            format(non_hetero, big.mark = ","),
            format(so_denom, big.mark = ","),
            non_hetero / so_denom * 100))

# --- NSDUH MH/SUD burden ---
cat("\n--- NSDUH MH/SUD BURDEN (psilocybin users) ---\n")
if (nrow(nsduh_mh) > 0) {
  mh_yes <- nsduh_mh %>%
    filter(category == "Yes") %>%
    mutate(label = sprintf("%s: %.1f%% (SE %.1f)", variable, weighted_pct, se))
  cat(paste(mh_yes$label, collapse = "\n"), "\n")
}

# --- Key comparison highlights ---
cat("\n--- KEY COMPARISONS ---\n")
comp_wide <- comparison %>%
  select(source, variable, category, pct) %>%
  pivot_wider(names_from = source, values_from = pct,
              names_prefix = "pct_")

comp_wide %>%
  filter(!is.na(pct_NSDUH) & !is.na(pct_OPS)) %>%
  mutate(
    diff = pct_OPS - pct_NSDUH,
    label = sprintf("%-6s %-8s: NSDUH %.1f%% vs OPS %.1f%% (diff %+.1f pp)",
                    variable, category, pct_NSDUH, pct_OPS, diff)
  ) %>%
  pull(label) %>%
  cat(sep = "\n")

cat("\n\n=== DONE ===\n")
