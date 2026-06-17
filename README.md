# World Layoffs 2020–2026 — SQL Data Cleaning, EDA & Power BI Dashboard

An end-to-end data analytics project covering data cleaning, exploratory
analysis, and dashboard visualization of global company layoffs from
March 2020 through June 2026.

**Project status:** Phase 1 (Data Cleaning) complete. Phase 2 (EDA) and
Phase 3 (Power BI Dashboard) in progress.

---

## Dataset

**Source:** [Layoffs Dataset — Kaggle](https://www.kaggle.com/datasets/swaptr/layoffs-2022?resource=download)
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
- Power BI *(Phase 3)*

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
│   └── eda/             # Phase 2 — analysis queries (in progress)
├── docs/
│   └── cleaning_log.md  # Full decision log for every cleaning choice made
├── results/
│   ├── 01_null_audit_baseline.csv
│   ├── 06_location_country_final.csv
│   └── 10_data_quality_report.csv
└── dashboard/
    ├── world_layoffs_dashboard.pbix   # Power BI file (Phase 3)
    └── dashboard_screenshot.png        # Static preview image for GitHub
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

Full query-by-query output isn't included (most cleaning queries are
diagnostic, not analytical — they don't produce standalone insights).
Instead, three snapshots document the cleaning's actual impact:

| File | What It Shows |
|------|----------------|
| [`01_null_audit_baseline.csv`](results/01_null_audit_baseline.csv) | NULL/blank count per column **before** cleaning began |
| [`06_location_country_final.csv`](results/06_location_country_final.csv) | Clean location-country map **after** all 36 mismatches resolved |
| [`10_data_quality_report.csv`](results/10_data_quality_report.csv) | Final dashboard query confirming 0 invalid values remain across every check |

Together these three tell the complete before → fixed → verified story
without cluttering the repo with 40+ diagnostic exports.

---

## Phase 2 — Exploratory Data Analysis *(In Progress)*

Will cover layoffs by industry, country, funding stage, and time period,
plus company-level rankings using window functions. Files will be added
to `sql/eda/` as completed.

---

## Phase 3 — Power BI Dashboard *(Planned)*

An interactive dashboard built on the cleaned dataset, visualizing
trends identified during EDA. Will be added to `dashboard/` once complete.

---

## How to Run

1. Import `data/raw/layoffs.csv` into MySQL as the `layoffs` table
2. Run `sql/cleaning/00_staging_tables.sql` through `10_data_quality_report.sql` in order
3. Export the final `layoffs_staging2` table — this is the dataset in `data/clean/`
4. *(Phase 2)* Run EDA queries from `sql/eda/` against the cleaned table
5. *(Phase 3)* Open `dashboard/world_layoffs_dashboard.pbix` in Power BI
