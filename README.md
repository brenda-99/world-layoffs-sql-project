# World Layoffs 2020–2026 — SQL Data Cleaning, EDA & Power BI Dashboard

![MySQL](https://img.shields.io/badge/MySQL-4479A1?style=flat&logo=mysql&logoColor=white)
![Power BI](https://img.shields.io/badge/Power%20BI-F2C811?style=flat&logo=powerbi&logoColor=black)
![Status](https://img.shields.io/badge/Status-Complete-brightgreen?style=flat)

An end-to-end data analytics project covering data cleaning, exploratory
analysis, and dashboard visualization of global company layoffs from
March 2020 through June 2026.

**Project status:** Complete — all three phases finished.

---

## Dataset

**Source:** [Layoffs.fyi](https://layoffs.fyi/) (global layoffs tracker), via [Kaggle](https://www.kaggle.com/datasets/swaptr/layoffs-2022/versions/314)
Expanded to ~4,453 rows covering March 2020 – June 2026.

**Raw file:** [`data/raw/layoffs.csv`](data/raw/layoffs.csv)
**Cleaned file:** [`data/clean/layoffs_clean.csv`](data/clean/layoffs_clean.csv)

**Raw columns:** company, location, total_laid_off, date,
percentage_laid_off, industry, source, stage, funds_raised, country,
date_added

---

## Tools Used

- MySQL 8.x
- MySQL Workbench
- Power BI Desktop

---

## Project Structure

```
world-layoffs-sql-project/
├── README.md
├── data/
│   ├── raw/           # Original unmodified dataset
│   └── clean/          # Final cleaned dataset, ready for EDA and Power BI
├── sql/
│   ├── cleaning/        # Phase 1 — 11 sequential SQL files
│   └── eda/             # Phase 2 — 10 analysis queries + 2 Power BI views
├── docs/
│   └── cleaning_log.md  # Full decision log for every cleaning choice made
├── results/
│   ├── cleaning/         # Before/after snapshots from Phase 1
│   └── eda/               # Output for each of the 10 EDA queries
└── dashboard/
    ├── world_layoffs_dashboard.pbix    # Full interactive Power BI file
    ├── dashboard_screenshot.png         # Executive Overview, shown above
    ├── dashboard_demo.gif                # 15-second interactivity demo
    └── world_layoffs_dashboard.pdf       # All 3 pages, static reference
```

---

## Phase 1 — Data Cleaning

Located in `sql/cleaning/`. Split into 11 sequential files so each
technique can be reviewed independently rather than scrolling through
one large script.

| File | Step | What It Does |
|------|------|---------------|
| `00_staging_tables.sql` | Setup | Creates working copies of raw data |
| `01_data_profiling.sql` | Profiling | Establishes a quality baseline across all columns |
| `02_duplicate_detection.sql` | Duplicates | Identifies and removes exact + soft duplicates |
| `03_standardization.sql` | Standardization | Fixes whitespace, country name variants, mapping tables |
| `04_null_handling.sql` | NULL Handling | Investigates and resolves missing values without guessing |
| `05_numerical_validation.sql` | Validation | Confirms numerical columns fall within logical bounds |
| `06_location_country_validation.sql` | Cross-Column Validation | Resolves 36 location/country mismatches across 6 categories |
| `07_outlier_identification.sql` | Outliers | IQR-based outlier detection — flags, does not remove |
| `08_type_conversion.sql` | Type Conversion | Converts TEXT columns to DATE, INT, DECIMAL |
| `09_column_removal.sql` | Cleanup | Drops redundant rows and helper columns |
| `10_data_quality_report.sql` | Reporting | Single dashboard query confirming the final clean state |

Full reasoning behind every decision — including mistakes caught and
corrected along the way — is documented in
[`docs/cleaning_log.md`](docs/cleaning_log.md).

### Key Cleaning Highlights

- **3 exact duplicates** removed (Cars24, Beyond Meat, Cazoo)
- **36 location/country mismatches** resolved across 6 distinct issue types, including UTF-8 encoding corruption on international city names (Malmö, Düsseldorf, Wrocław, Førde)
- **NULL values preserved, not zero-filled** — unknown layoffs ≠ zero layoffs
- **External verification used** where the dataset alone was ambiguous (e.g. confirming Brisbane, California is a real distinct city from Brisbane, Australia)
- **Final dataset:** ~3,730 rows, 7 analytical columns

### Results — Before/After Evidence

Three snapshots capture the cleaning's before/after impact:

| File | What It Shows |
|------|----------------|
| [`01_null_audit_baseline.csv`](results/cleaning/01_null_audit_baseline.csv) | NULL/blank count per column **before** cleaning began |
| [`06_location_country_final.csv`](results/cleaning/06_location_country_final.csv) | Clean location-country map **after** all 36 mismatches resolved |
| [`10_data_quality_report.csv`](results/cleaning/10_data_quality_report.csv) | Final dashboard query confirming 0 invalid values remain across every check |

---

## Phase 2 — Exploratory Data Analysis

Located in `sql/eda/`. 10 analytical queries plus 2 SQL views built
specifically as the data source layer for the Power BI dashboard in
Phase 3.

| File | Concept | What It Answers |
|------|---------|-------------------|
| `01_overall_scale.sql` | Aggregation | Total scale of the dataset — companies, countries, employees affected |
| `02_industry_impact.sql` | Window `SUM() OVER()` | Which industries account for the largest share of all layoffs |
| `03_country_concentration.sql` | Running cumulative % | How concentrated layoffs are in a small number of countries |
| `04_monthly_trend_lag.sql` | `LAG()` | Month-over-month change — accelerating or slowing? |
| `05_rolling_average.sql` | Moving average (`ROWS BETWEEN`) | Smoothed trend line with single-month noise removed |
| `06_ntile_severity_quartiles.sql` | `NTILE(4)` | Segmenting companies into severity quartiles |
| `07_top5_per_year_rank.sql` | `DENSE_RANK()` partitioned | Top 5 biggest-cutting companies, per year |
| `08_funding_stage_severity.sql` | `CASE WHEN` + `AVG()` | Whether funding stage predicts the % of workforce cut |
| `09_industry_peer_benchmark.sql` | Window `AVG() OVER(PARTITION BY)` | How far a company's worst layoff sits above its own industry average |
| `10_funding_vs_severity.sql` | `NTILE(5)` | Whether more funding actually reduced layoff severity |

### Key Findings

- **921,130 employees** were laid off across **2,541 companies** in **60 countries** between March 2020 and June 2026
- **Retail and Other** account for **24.6%** of all layoffs — more than the next two industries combined
- The **top 5 countries** make up **~87%** of all layoffs — the **US alone is ~72%**
- **January 2023** saw the largest monthly jump in the dataset — nearly **80,000 layoffs in one month**
- A 3-month rolling average shows a **sustained upward trend**, not a single shock — the steepest climb was late 2022 into early 2023
- The **top 25%** of companies by layoff size averaged **1,612 layoffs each**, versus just **23** in the bottom quartile
- **Amazon** appears in the **top 5 biggest-cutting companies in four separate years** (2022, 2023, 2025, 2026) — not a one-off event
- **Seed-stage** companies cut **82.3%** of their workforce on average per event — nearly **5x** the Post-IPO rate, even though Post-IPO companies cut far more people in absolute terms
- **Lower-funded companies cut a larger share of their workforce** — the bottom funding quintile averaged **51%**, about **3x** the rate of the top two funding tiers

Full output for each query is saved in [`results/eda/`](results/eda/).

### Power BI Data Layer

Two SQL views were built specifically to feed the Phase 3 dashboard,
keeping all business logic in version-controlled SQL rather than buried
inside Power BI transformations:

| View | Built In | Purpose |
|------|----------|---------|
| `vw_layoffs_enriched` | `11_create_main_view.sql` | Row-level view with year/month buckets and a `severity_band` classification (Full Shutdown / Severe / Major / Moderate), used for detailed visuals |
| `vw_layoffs_kpi_summary` | `12_create_kpi_summary_view.sql` | Pre-aggregated by year, country, and industry — feeds the dashboard's KPI cards directly with no DAX measures required |

Both views connect to Power BI exactly like a regular MySQL table —
they appear in the table picker under *Get Data → MySQL Database*
alongside `layoffs_staging2` itself.

---

## Phase 3 — Power BI Dashboard

![Dashboard Overview](dashboard/dashboard_screenshot.png)

![Dashboard Demo](dashboard/dashboard_demo.gif)

📄 [Full dashboard PDF](dashboard/world_layoffs_dashboard.pdf) · 📊 [Download interactive .pbix](dashboard/world_layoffs_dashboard.pbix)

A 3-page interactive dashboard built directly on `vw_layoffs_enriched`
and `vw_layoffs_kpi_summary`, the two SQL views created in Phase 2.

| Page | Focus | Key Features |
|------|-------|----------------|
| Executive Overview | High-level KPIs and trends | KPI cards, monthly trend line, Top 10 countries bar chart, industry treemap |
| Company Analysis | Company-level patterns | Year-by-year matrix with gradient formatting, funding-vs-severity scatter chart, severity distribution donut |
| Detailed Records | Full row-level detail | Filterable table with icon sets and data bars, reached via drillthrough from the matrix |

### Key Dashboard Highlights

- **One consistent severity color system** (green → red) used only where color signals severity — every other chart uses a single neutral accent color
- **Three distinct conditional-formatting techniques**: gradient background color, icon sets, and data bars
- **Drillthrough with preserved filter context**, from the Company Analysis matrix into Detailed Records
- The funding-vs-severity scatter chart shows a **weak relationship at the individual-company level** — the real pattern only emerges when companies are grouped by funding quintile (see `10_funding_vs_severity.sql`)

---

## How to Run

1. Import `data/raw/layoffs.csv` into MySQL as the `layoffs` table
2. Run `sql/cleaning/00_staging_tables.sql` through `10_data_quality_report.sql` in order
3. Export the final `layoffs_staging2` table — this is the dataset in `data/clean/`
4. Run EDA queries `01` through `10` from `sql/eda/` against `layoffs_staging2` to reproduce all results
5. Run `11_create_main_view.sql` and `12_create_kpi_summary_view.sql` to create the two views Power BI connects to
6. Open `dashboard/world_layoffs_dashboard.pbix` in Power BI Desktop (free) for full interactivity — or view the screenshot/GIF above for a quick look without installing anything

---

**Brenda Homera** · [LinkedIn](https://www.linkedin.com/in/bhomera) · [Email](mailto:brendahomera12@gmail.com)
