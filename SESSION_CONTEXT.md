# Session Context — Oregon Psilocybin Paper
**Last updated:** April 8, 2026
**Status:** Plan complete, ready for preliminary analysis before implementation

---

## What This Project Is

A JAMA Psychiatry Research Letter comparing who uses psilocybin nationally (NSDUH 2024) vs. who accesses Oregon's legal psilocybin services (OPS 2025). First study to compare these two novel datasets.

- **NSDUH 2024**: Individual-level nationally representative survey. n=47,299 adults; 1,822 past-year psilocybin users. First year with psilocybin-specific items.
- **OPS 2025**: Aggregate quarterly data from Oregon's legal psilocybin program (Measure 109). N=5,935 client-quarter encounters across Q1-Q4. Mandated by SB 303.

---

## 8 Headline Findings (already established)

1. **Sex reversal**: NSDUH 64% male → OPS 58% female
2. **Age shift**: NSDUH 57% under 35 → OPS 69% aged 35-64, 13% aged 65+
3. **Racial narrowing**: NSDUH 71% NH White → OPS >85% White (most non-White suppressed <11)
4. **Income concentration**: 58.5% of OPS clients earn >$95K/year
5. **Psilocybin tourism**: 48.4% of OPS clients from out of state, 5.1% international
6. **Wellness > clinical**: Top visit reasons are general health (31%), perspective (28%), consciousness (27%) — not depression/PTSD/SUD
7. **LGBQ+ overrepresentation**: 27.2% in OPS vs ~7% US population
8. **Strong safety**: 0.47% adverse event rate, 0.15% severe, zero intoxication denials

---

## Work Completed So Far

### Data Exploration (done)
- Read and summarized all 4 OPS quarterly CSVs (386 columns each)
- Identified OPS data quirks: Q2 "StateDate" typo, Q3 missing date columns (384 vs 386), Q3 trailing blank row, -99 suppression
- Reviewed all existing NSDUH R scripts (01-09) and outputs
- Inventoried all files in the Oregon project folder
- Read JAMA Psychiatry Research Letter format samples (Rhee 2020 = model)

### Documents Created
- `OPS_NSDUH_Data_Summary_v2.docx` — comprehensive data summary with all findings, tables, and proposed framing (edited with tracked changes)
- `OPS_NSDUH_Data_Summary_4-7-26.docx` — date-stamped version
- `v2_current.md` — markdown version of the summary

### Code Repo Setup (done)
- `Code/` folder created with git initialized (1 commit: README.md)
- `Code/CLAUDE.md` written with full project context for future Claude sessions
- Git user configured: Gabriel P. A. Costa <gabriel.costa@yale.edu>

### Reference Materials Converted
- `Ketamine Parallel/md/` — 2 papers on ketamine access disparities (Liu et al. 2025, Aslam et al. 2025)
- `Language Samples/md/` — 3 JAMA Psychiatry papers for format reference (Rhee 2020, Cummings 2017, Marcus & Olfson 2010)

### Email Drafted
- Email to JP (Joel Desmeules) about the project, mentioning Christina meeting and offering to join their meeting

---

## Current Plan (in `C:\Users\Gabriel\.claude\plans\warm-snacking-bubble.md`)

### Folder Structure
```
Code/
├── R/
│   ├── 00_packages.R          # Dependencies
│   ├── 01_nsduh_setup.R       # Raw NSDUH → survey design → recode → weighted stats
│   ├── 02_ops_clean.R         # Read/clean/stack 4 OPS CSVs
│   ├── 03_harmonize.R         # Align categories between sources
│   ├── 04_table.R             # Table 1: demographic comparison (comparable vars only)
│   ├── 04b_table2.R           # Table 2: NSDUH clinical profile (MH, SUDs, polysubstance)
│   ├── 05_figure.R            # Figure 1: OPS visit reasons (horizontal bars)
│   └── 06_inline_stats.R      # All in-text statistics
├── data/
│   ├── ops/                   # OPS CSVs (NOT committed — README with download instructions)
│   └── nsduh/                 # NSDUH_2024.RData (NOT committed — README with download instructions)
└── output/
    ├── tables/
    └── figures/
```

### Key Design Decisions
1. Start from raw NSDUH_2024.RData (not pre-computed table1.csv) — public reproducibility
2. Table 1 = only variables available in BOTH sources (age, sex, race, income, geography)
3. Table 2 = NSDUH clinical profile (MH/SUD comorbidity) — adds clinical depth
4. Figure = OPS visit reasons (NOT redundant with table demographics)
5. Use OPS PrimaryIdentity columns for race (not "all that apply")
6. No statistical tests between sources — descriptive only
7. No original data committed to git
8. Build all 3 elements (Table 1, Table 2, Figure 1), pick best 2 for JAMA submission

### Category Harmonization
- **Age**: OPS 16 bins → NSDUH 5 groups (Under21+21_24→"18-25", 25_29+30_34→"26-34", etc.)
- **Race**: OPS primary identity (41 cats) → NSDUH 7 categories
- **Income**: 3-tier collapse with footnote (thresholds differ: OPS >$95K vs NSDUH >$75K)
- **Geography**: Both shown — NSDUH metro type + OPS resident/out-of-state/international

---

## NEXT STEP: Preliminary Analysis (not yet started)

**Before locking in the plan and writing scripts, run a systematic data audit to ensure we're not missing anything that could improve framing and impact.**

### 1. NSDUH Variable Audit
Variables we haven't checked but should:
- **Treatment-seeking motivations** — does NSDUH capture WHY people use psilocybin? (probably not, but check)
- **Veteran status** — relevant to PTSD/combat trauma visit reasons in OPS
- **State-level identifiers** — could we identify Oregon residents in NSDUH? (unlikely in PUF, but check)
- **CBD use** — CBDHMPFLAG is already coded in 02_variables.R but unused
- **Health status / chronic conditions** — self-rated health, chronic pain variables?
- **Frequency of psilocybin use** — PSILCYMON (past-month), lifetime frequency? Not just binary past-year
- **Other hallucinogen variables** — LSDYR, HALLUCYR already coded. DMT? Ayahuasca? Ketamine?

### 2. OPS Systematic Variable Review
- Cross-quarter trend analysis (are demographics shifting over time?)
- Disability data deeper dive (onset ages, types)
- Language data (near-total English homogeneity)
- Full denial reason breakdown
- Every variable we haven't examined yet

### 3. NSDUH Sensitivity Analyses Already Done
The existing `06_sensitivity.R` has results we should review:
- Age-stratified analysis (18-25 vs. 26+) — does MH comorbidity differ by age?
- Sex-stratified analysis
- MDE-stratified analysis
- Comparator exposures (LSD, any hallucinogen) — is psilocybin unique?
- Recency gradient (4-level: never / lifetime only / past-year not past-month / past-month)
- SUD treatment receipt among SUD+ subgroup

### 4. Recency Gradient Relevance
OPS clients are by definition RECENT users (they just had a session). The NSDUH recency gradient could show whether recent users look different from past-year users in demographics or comorbidity — directly relevant to interpreting OPS vs. NSDUH differences.

### 5. Framing Angles to Consider
- Policy environment analysis (07_policy_environment.R) — medical MJ state as moderator
- The ketamine parallel papers (racial disparities in emerging psychiatric treatments)
- Whether to frame as "equity gap" vs. "different populations, different needs"

---

## Existing Files and Paths

### Data Files
| File | Path | Description |
|------|------|-------------|
| NSDUH raw | `Oregon/NSDUH Data/NSDUH_2024.RData` | 36 MB, raw PUF |
| NSDUH processed | `Oregon/NSDUH Data/nsduh_analysis_ready.RData` | 55.7 MB, adults 18+ with survey design |
| OPS Q1 | `Oregon/OPS-Data-File-2025-Q1.csv` | 1,509 clients |
| OPS Q2 | `Oregon/OPS-Data-File-2025-Q2.csv` | 1,758 clients |
| OPS Q3 | `Oregon/OPS-Data-File-2025-Q3.csv` | 1,310 clients |
| OPS Q4 | `Oregon/OPS-Data-File-2025-Q4.csv` | 1,358 clients |
| NSDUH codebook | `Oregon/NSDUH Data/codebook.md` | 3.3 MB, full variable definitions |

### Existing R Scripts (NSDUH pipeline, in `Oregon/NSDUH Data/R/`)
| Script | Purpose |
|--------|---------|
| `01_setup.R` | Load data, survey design, subset adults |
| `02_variables.R` | All variable recoding (637 lines) |
| `03_table1.R` | Weighted Table 1 |
| `04_bivariate.R` | Unadjusted ORs |
| `05_regression.R` | Models 1-2 (adjusted) |
| `06_sensitivity.R` | 11 sensitivity/subgroup analyses |
| `07_figures.R` | Initial figures |
| `07_policy_environment.R` | MJ policy moderator analysis |
| `08_model4_substance_adjusted.R` | Model 3 (substance-adjusted) |
| `09_figures.R` | Revised figures (13 figure files) |
| `check_vars.R` | Quick diagnostic |

### Existing Output (in `Oregon/NSDUH Data/R/`)
- `table1.csv` — weighted demographics by psilocybin use (confirmed format: `"1,022 (64.0%)"`)
- `table2_bivariate.csv` — bivariate ORs
- `table3_regression.csv` — Models 1-2 regression
- `table4_model_comparison.csv` — Models 1-3 comparison
- `forest_plot_data.csv` — forest plot source data
- `recency_gradient_data.csv` — 4-level recency gradient
- `table_sud_treatment_subgroup.csv` — SUD treatment subgroup
- 13 figure pairs (PDF + PNG) in `figures/`

### Key NSDUH Variable Map (raw → analytic)
| Raw | Analytic | Meaning |
|-----|----------|---------|
| PSILCYYR | psilocybin_yr | Past-year psilocybin (primary exposure) |
| PSILCYFLAG | psilocybin_ever | Lifetime psilocybin |
| PSILCYMON | psilocybin_mon | Past-month psilocybin |
| AGE3 | age_cat | Age (5 groups) |
| IRSEX | sex | Sex (binary) |
| NEWRACE2 | race_eth | Race/ethnicity (7 levels) |
| INCOME | income | Family income (4 brackets) |
| COUTYP4 | metro | County type (3 levels) |
| IRAMDEYR | mde | Major depressive episode |
| SPDPSTYR | spd | Serious psychological distress |
| IRSUICTHNK | suicidal_ideation | Suicidal ideation |
| IRPYUD5ALC | aud | Alcohol use disorder |
| IRPYUD5MRJ | mud | Marijuana use disorder |
| UD5OPIANY2 | oud | Opioid use disorder |
| UD5ILALANY | any_sud | Any SUD |
| ANALWT2_C | (weight) | Survey analysis weight |
| VESTR_C | (stratum) | Survey stratum |
| VEREP | (PSU) | Primary sampling unit |

### OPS Column Domains (386 total per quarter)
- Service metrics (18): ClientsServed, sessions, denials, adverse events, dose
- Race/ethnicity — all that apply (41): AfricanAmerican through OtherWhite
- Race/ethnicity — primary identity (42): PrimaryIdentity* parallel set
- Language spoken (26) + written (26)
- Disability (9 types × ~11 cols each = ~99)
- Gender identity (15) + transgender (5) + biological sex (7) + sexual orientation (12)
- Income (8) + Age (16) + County (38) + Visit reasons (28)

---

## Documents in the Project Folder
- `OPS_NSDUH_Data_Summary_v2.docx` — main data summary document (edited, tracked changes)
- `OPS_NSDUH_Data_Summary_4-7-26.docx` — date-stamped copy
- `OPS_NSDUH_Data_Summary.docx` — earlier version
- `NSDUH_Psilocybin.docx` — separate NSDUH-only manuscript draft
- `v2_current.md` — markdown of v2 summary
- `Psychedelic Policy by State .pdf` — state policy landscape reference
- `create_data_summary.js` — Node.js script that generated the summary docx
- `edit_v2.py`, `edit_v2b.py` — Python scripts that edited v2 docx via OOXML
- `pdf-to-markdown.skill` — skill file for PDF conversion

---

## Instructions for Next Session

1. Read this file (`Code/SESSION_CONTEXT.md`) first
2. Read `Code/CLAUDE.md` for repo conventions
3. Read the plan at `C:\Users\Gabriel\.claude\plans\warm-snacking-bubble.md`
4. **Start with the preliminary analysis** described in the "NEXT STEP" section above
5. The goal is to audit both datasets thoroughly, then refine the plan and build the scripts

### Preliminary Analysis Checklist
- [ ] Audit NSDUH codebook for unchecked variables (veteran status, health status, psilocybin frequency, state identifiers)
- [ ] Review existing sensitivity analysis outputs (06_sensitivity.R results)
- [ ] Review recency gradient data (recency_gradient_data.csv)
- [ ] Systematic OPS cross-quarter trend analysis
- [ ] Check if any OPS variables were missed in our summary
- [ ] Identify strongest framing angle for maximum publication impact
- [ ] Refine plan based on findings
- [ ] Begin writing R scripts
