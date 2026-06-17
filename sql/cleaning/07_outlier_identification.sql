-- ============================================================
-- STEP 7: OUTLIER IDENTIFICATION
-- Purpose  : Flag statistical outliers in numerical columns
--            Rule: identify outliers — do NOT blindly remove them
--            Large layoff numbers are real events, not errors
-- ============================================================

-- 7a. IQR method to flag statistical outliers in total_laid_off
--     Formula: outlier threshold = Q3 + 1.5 * IQR
--     This dataset: Q1=40, Q3=200, IQR=160, upper fence=440
--     344 rows exceed the upper fence — all confirmed as legitimate large-company events
--
--     NOTE: MySQL does not support PERCENTILE_CONT()
--     Quartiles are estimated using PERCENT_RANK() instead
WITH ranked_data AS (
    -- Step 1: Calculate dataset-wide percentile rank per row
    SELECT
        company,
        total_laid_off,
        country,
        date,
        PERCENT_RANK() OVER (ORDER BY CAST(total_laid_off AS DECIMAL(10,2))) AS pct_rank
    FROM layoffs_staging2
    WHERE total_laid_off IS NOT NULL
),
quartiles AS (
    -- Step 2: Extract Q1 and Q3 markers
    SELECT
        MAX(CASE WHEN pct_rank <= 0.25 THEN CAST(total_laid_off AS DECIMAL(10,2)) END) AS q1,
        MAX(CASE WHEN pct_rank <= 0.75 THEN CAST(total_laid_off AS DECIMAL(10,2)) END) AS q3
    FROM ranked_data
),
iqr_calc AS (
    -- Step 3: Compute IQR and upper/lower fences
    SELECT q1, q3,
           (q3 - q1)               AS iqr,
           q3 + 1.5 * (q3 - q1)   AS upper_fence,
           q1 - 1.5 * (q3 - q1)   AS lower_fence
    FROM quartiles
)
-- Step 4: Output flagged outlier rows using CROSS JOIN (required in MySQL)
SELECT r.company, r.total_laid_off, r.country, r.date, r.pct_rank,
       i.upper_fence, i.lower_fence
FROM ranked_data r
CROSS JOIN iqr_calc i
WHERE CAST(r.total_laid_off AS DECIMAL(10,2)) > i.upper_fence
ORDER BY CAST(r.total_laid_off AS DECIMAL(10,2)) DESC
LIMIT 20;

-- 7b. Top 10 layoff events for context — these are NOT errors
--     Oracle 30,000 | Intel 22,000 | Google 12,000 — all legitimate tech events
SELECT company, country, date,
       CAST(total_laid_off AS DECIMAL) AS total_laid_off
FROM layoffs_staging2
WHERE total_laid_off IS NOT NULL
ORDER BY CAST(total_laid_off AS DECIMAL) DESC
LIMIT 10;
