# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Companion analysis code for a JAMA Psychiatry Research Letter comparing demographics of national psilocybin users (NSDUH 2024, n=1,822) with Oregon's legal psilocybin service clients (OPS 2025, N=5,935). First study to compare these two novel datasets.

## Data Sources

### NSDUH 2024
- National Survey on Drug Use and Health, 2024 Public Use File
- Individual-level, nationally representative (n=47,299 adults 18+; 1,822 past-year psilocybin users)
- Raw file: `data/nsduh/NSDUH_2024.RData` (~55 MB, NOT committed — download from SAMHSA)
- Survey design: `svydesign(~VEREP, strata=~VESTR_C, weights=~ANALWT2_C, nest=TRUE, data=nsduh_adults)`
- Key exposure variable: `PSILCYYR` (past-year psilocybin use)

### OPS 2025
- Oregon Psilocybin Services quarterly data (Q1-Q4 2025), mandated by SB 303
- Aggregate counts (1 row per quarter, ~386 columns), NOT individual-level
- Raw files: `data/ops/OPS-Data-File-2025-Q*.csv` (NOT committed — download from OHA)
- **Known quirks:**
  - Q2: column `StateDate` is a typo for `StartDate`
  - Q3: missing `StartDate`/`EndDate` columns entirely (384 vs 386 cols)
  - Q3: trailing blank row
  - `-99` = suppressed cell (count < 11, OHA confidentiality policy)

## R Pipeline

Run scripts in numbered order. All scripts use `here::here()` for paths.

```
R/00_packages.R          # Load/check all dependencies
R/01_nsduh_setup.R       # Raw NSDUH → survey design → recode demographics + psilocybin exposure
R/02_ops_clean.R         # Read/clean/stack 4 OPS CSVs → annual summaries
R/03_harmonize.R         # Align OPS and NSDUH categories for comparison
R/04_table.R             # Table 1: demographic comparison
R/04b_table2.R           # Table 2: NSDUH clinical profile (MH, SUDs, polysubstance)
R/05_figure.R            # Figure 1: OPS visit reason distribution
R/06_inline_stats.R      # All in-text statistics for manuscript
```

Output goes to `output/tables/` and `output/figures/`.

## Category Harmonization (critical logic in 03_harmonize.R)

### Age: OPS 16 bins → NSDUH 5 groups
- Under21 + Age21_24 → "18-25"
- Age25_29 + Age30_34 → "26-34" (note: OPS includes age 25; NSDUH starts "26-34" at 26)
- Age35_39 + Age40_44 + Age45_49 → "35-49"
- Age50_54 + Age55_59 + Age60_64 → "50-64"
- Age65_69 through Age85Older → "65+"

### Race: OPS primary identity (41 cats) → NSDUH 7 categories
Use `PrimaryIdentity*` columns (one per person), NOT the "select all that apply" columns which sum > total.

### Income: 3-tier collapse (thresholds differ — footnote required)
- OPS Low: <$45K | NSDUH Low: <$50K
- OPS Mid: $45-95K | NSDUH Mid: $50-74K
- OPS High: >$95K | NSDUH High: >$75K

## Conventions

- R is the primary language; all analysis in R
- `survey` package for all NSDUH statistics (weighted estimates + SEs)
- No statistical tests between NSDUH and OPS (different populations/data structures — comparison is descriptive only)
- OPS percentages are simple proportions excluding non-response from denominators
- Suppressed OPS cells shown as "S" in tables, treated as NA in code
- JAMA Psychiatry Research Letter format: ~600 words, max 2 visual elements, 5-6 references

## Terminology

- "cannabis use" (never "marijuana use")
- "substance use" (never "substance abuse")
- "participants" (never "subjects")
- "psilocybin services" (not "psilocybin therapy" — OPS is not therapy)

## Git Policy

- No original datasets committed (neither NSDUH nor OPS)
- `data/*/README.md` files provide download instructions
- Output files (tables, figures, .rds) excluded via .gitignore
- Only commit code, READMEs, and documentation
