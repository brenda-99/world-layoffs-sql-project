-- ============================================================
-- STEP 1: DATA PROFILING & QUALITY BASELINE
-- Purpose  : Establish what needs fixing before touching anything
--            At 4,453 rows visual inspection is not viable
--            Let SQL count and surface every issue systematically
-- ============================================================

-- 1a. Total row count
SELECT COUNT(*) AS total_rows
FROM layoffs_staging2;

-- 1b. NULL/blank audit across every column in a single query
--     One row of output = instant picture of the entire dataset's completeness
SELECT
    SUM(CASE WHEN company             = '' OR company IS NULL             THEN 1 ELSE 0 END) AS missing_company,
    SUM(CASE WHEN location            = '' OR location IS NULL            THEN 1 ELSE 0 END) AS missing_location,
    SUM(CASE WHEN total_laid_off      = '' OR total_laid_off IS NULL      THEN 1 ELSE 0 END) AS missing_total_laid_off,
    SUM(CASE WHEN percentage_laid_off = '' OR percentage_laid_off IS NULL THEN 1 ELSE 0 END) AS missing_pct_laid_off,
    SUM(CASE WHEN industry            = '' OR industry IS NULL            THEN 1 ELSE 0 END) AS missing_industry,
    SUM(CASE WHEN stage               = '' OR stage IS NULL               THEN 1 ELSE 0 END) AS missing_stage,
    SUM(CASE WHEN funds_raised        = '' OR funds_raised IS NULL        THEN 1 ELSE 0 END) AS missing_funds_raised,
    SUM(CASE WHEN country             = '' OR country IS NULL             THEN 1 ELSE 0 END) AS missing_country
FROM layoffs_staging2;

-- Results from this dataset:
-- missing_total_laid_off : 1534 (34.4%)
-- missing_pct_laid_off   : 1656 (37.2%)
-- missing_funds_raised   :  517 (11.6%)
-- All other columns      : 0-5 rows only

-- 1c. Distinct value counts for categorical columns
--     Reveals the scale of standardization work needed (addressed in Step 3)
SELECT COUNT(DISTINCT industry) AS distinct_industries,
       COUNT(DISTINCT country)  AS distinct_countries,
       COUNT(DISTINCT stage)    AS distinct_stages
FROM layoffs_staging2;

-- 1d. Numerical range check on key columns
SELECT
    MIN(CAST(total_laid_off AS DECIMAL))  AS min_laid_off,
    MAX(CAST(total_laid_off AS DECIMAL))  AS max_laid_off,
    MIN(CAST(funds_raised AS DECIMAL))    AS min_funds,
    MAX(CAST(funds_raised AS DECIMAL))    AS max_funds
FROM layoffs_staging2
WHERE total_laid_off != '' AND funds_raised != '';
