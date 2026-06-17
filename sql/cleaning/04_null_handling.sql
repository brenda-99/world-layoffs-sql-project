-- ============================================================
-- STEP 4: NULL & BLANK VALUE HANDLING
-- Rule     : Investigate before deleting — missing ≠ wrong
--            Unknown layoffs ≠ zero layoffs
--            Do not replace NULL with 0
-- ============================================================

-- 4a. Convert all blank strings to NULL for consistency
--     Mixing '' and NULL for the same concept causes issues in WHERE clauses
UPDATE layoffs_staging2 SET industry             = NULL WHERE industry             = '';
UPDATE layoffs_staging2 SET country              = NULL WHERE country              = '';
UPDATE layoffs_staging2 SET location             = NULL WHERE location             = '';
UPDATE layoffs_staging2 SET funds_raised         = NULL WHERE funds_raised         = '';
UPDATE layoffs_staging2 SET total_laid_off       = NULL WHERE total_laid_off       = '';
UPDATE layoffs_staging2 SET percentage_laid_off  = NULL WHERE percentage_laid_off  = '';

-- 4b. Populate NULL industry via self-join
--     If a company appears multiple times and one row has an industry value,
--     use it to fill NULL rows for the same company
--     Industry is a company-level attribute — safe for self-join population
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
    ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

-- 4c. Handle the 2 rows with missing country
--     NOTE: Self-join was NOT used for country — unlike industry, country is a
--     row-level attribute. A company can operate in multiple countries so
--     filling from another row for the same company could be inaccurate.
--     Instead: inspect the location to determine the correct country directly.

-- Identify which rows have NULL country
SELECT company, location, country
FROM layoffs_staging2
WHERE country IS NULL;

-- Confirm location context for each company
SELECT company, location, country, industry
FROM layoffs_staging2
WHERE location = 'Berlin, Non-U.S.' OR location = 'Montreal, Non-U.S.'
ORDER BY company;

-- Fix directly using known location — no guessing
-- Fit Analytics: location = Berlin, Non-U.S. → Germany
UPDATE layoffs_staging2
SET country = 'Germany'
WHERE company = 'Fit Analytics'
AND location = 'Berlin, Non-U.S.';

-- Ludia: location = Montreal, Non-U.S. → Canada
UPDATE layoffs_staging2
SET country = 'Canada'
WHERE company = 'Ludia'
AND location = 'Montreal, Non-U.S.';

-- 4d. Data quality flag for rows missing both key layoff columns
--     Rows where both total_laid_off AND percentage_laid_off are NULL
--     have no usable layoff data for EDA — flag them before deletion
--     This preserves the record of what was removed and why
ALTER TABLE layoffs_staging2
ADD COLUMN layoffs_data_missing INT DEFAULT 0;

-- Flag = 1 means both columns are NULL → unanalysable
-- Flag = 0 means at least one column has data → keep
UPDATE layoffs_staging2
SET layoffs_data_missing = CASE
    WHEN total_laid_off IS NULL AND percentage_laid_off IS NULL THEN 1
    ELSE 0
END;

-- Confirm flag distribution before deletion
-- flag 0: ~3726 rows (kept)
-- flag 1: ~724 rows (will be removed in Step 9)
SELECT layoffs_data_missing, COUNT(*) AS row_count
FROM layoffs_staging2
GROUP BY layoffs_data_missing;
