-- ============================================================
-- STEP 10: DATA QUALITY REPORT
-- Purpose  : Single dashboard query showing the state of the
--            cleaned dataset — documents what remains and confirms
--            all validation checks pass
--            Run this after all previous steps are complete
-- ============================================================

SELECT 'Total rows remaining'                        AS quality_check,
        COUNT(*)                                     AS result
FROM layoffs_staging2

UNION ALL

SELECT 'Missing total_laid_off',
        SUM(CASE WHEN total_laid_off IS NULL THEN 1 ELSE 0 END)
FROM layoffs_staging2

UNION ALL

SELECT 'Missing percentage_laid_off',
        SUM(CASE WHEN percentage_laid_off IS NULL THEN 1 ELSE 0 END)
FROM layoffs_staging2

UNION ALL

SELECT 'Missing industry',
        SUM(CASE WHEN industry IS NULL THEN 1 ELSE 0 END)
FROM layoffs_staging2

UNION ALL

SELECT 'Missing country',
        SUM(CASE WHEN country IS NULL THEN 1 ELSE 0 END)
FROM layoffs_staging2

UNION ALL

SELECT 'Missing location',
        SUM(CASE WHEN location IS NULL THEN 1 ELSE 0 END)
FROM layoffs_staging2

UNION ALL

SELECT 'Missing funds_raised',
        SUM(CASE WHEN funds_raised IS NULL THEN 1 ELSE 0 END)
FROM layoffs_staging2

UNION ALL

SELECT 'Missing stage',
        SUM(CASE WHEN stage IS NULL THEN 1 ELSE 0 END)
FROM layoffs_staging2

UNION ALL

SELECT 'Invalid percentages (outside 0-1)',
        SUM(CASE WHEN percentage_laid_off < 0
                  OR percentage_laid_off > 1 THEN 1 ELSE 0 END)
FROM layoffs_staging2

UNION ALL

SELECT 'Future dates',
        SUM(CASE WHEN `date` > CURRENT_DATE THEN 1 ELSE 0 END)
FROM layoffs_staging2

UNION ALL

SELECT 'Negative layoff values',
        SUM(CASE WHEN total_laid_off < 0 THEN 1 ELSE 0 END)
FROM layoffs_staging2

UNION ALL

SELECT 'Non-U.S. suffix with US country (contradictions)',
        SUM(CASE WHEN location LIKE '%, Non-U.S.'
                  AND country = 'United States' THEN 1 ELSE 0 END)
FROM layoffs_staging2

UNION ALL

SELECT 'Garbled location names (merged city names)',
        SUM(CASE WHEN location LIKE '%,%'
                  AND location NOT LIKE '%, Non-U.S.' THEN 1 ELSE 0 END)
FROM layoffs_staging2

UNION ALL

SELECT 'UAE variant remaining (should be 0)',
        SUM(CASE WHEN country = 'UAE' THEN 1 ELSE 0 END)
FROM layoffs_staging2

UNION ALL

SELECT 'Distinct countries in clean dataset',
        COUNT(DISTINCT country)
FROM layoffs_staging2

UNION ALL

SELECT 'Distinct industries in clean dataset',
        COUNT(DISTINCT industry)
FROM layoffs_staging2;
