# Oregon Psilocybin Services vs National Psilocybin Use (NSDUH 2024)

Descriptive comparison of demographic characteristics between adults reporting past-year psilocybin use in a nationally representative survey and clients accessing Oregon's legal psilocybin program.

## Data Sources

- **NSDUH 2024** — National Survey on Drug Use and Health, 2024 Public Use File (n = 47,299 adults; 1,822 reporting past-year psilocybin use). First NSDUH cycle with psilocybin-specific items. Available from [SAMHSA](https://www.samhsa.gov/data/data-we-collect/nsduh-national-survey-drug-use-and-health/datafiles/2024).

- **Oregon Psilocybin Services (OPS) 2025** — Aggregate quarterly demographic, visit reason, and safety data reported by licensed service centers under Senate Bill 303 (ORS 475A.372). January through December 2025; 5,935 client-quarter encounters. Available from the [OHA Data Dashboard](https://www.oregon.gov/oha/ph/preventionwellness/pages/psilocybin-data-dashboard.aspx).

## Analysis Pipeline

Scripts in `R/` are numbered and should be run sequentially:

| Script | Description |
|--------|-------------|
| `00_packages.R` | Load dependencies (survey, tidyverse, srvyr, here, scales) |
| `01_nsduh_setup.R` | Load NSDUH data, define survey design, compute weighted demographics for adults reporting past-year psilocybin use |
| `02_ops_clean.R` | Read and stack four OPS quarterly CSVs, replace suppressed values, compute respondent-denominator percentages, extract service and safety data |
| `03_harmonize.R` | Align age, sex, race/ethnicity, and income categories across sources |
| `04_table.R` | Generate demographic comparison table (Table 1) |
| `05_figure.R` | Generate visit reason bar chart (Figure 1) |
| `06_inline_stats.R` | Compute all supplementary statistics (geography, safety, LGBQ+, clinical profile) |
| `07_statistical_tests.R` | Chi-square goodness-of-fit tests comparing OPS demographic distributions to NSDUH survey-weighted proportions (sex, age, race/ethnicity) |

## Key Methodological Notes

- NSDUH estimates use survey weights (`svydesign` with VEREP, VESTR_C, ANALWT2_C)
- OPS data are aggregate counts; individual records are not available and clients are not deduplicated across quarters
- Approximately 35% of OPS encounters lack demographic data due to client opt-out or service center reporting noncompliance
- OPS percentages use respondent denominators, not total encounters
- Income brackets differ between sources and are presented separately
- OPS race/ethnicity uses Oregon REALD primary racial identity categories, collapsed to five groups for comparison

## Requirements

- R (>= 4.4)
- Packages: survey, tidyverse, srvyr, here, scales, readr
