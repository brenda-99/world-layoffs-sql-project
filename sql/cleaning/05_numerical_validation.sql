-- ============================================================
-- STEP 5: NUMERICAL VALIDATION
-- Purpose  : Validate that numerical columns fall within
--            logical boundaries before type conversion
-- ============================================================

-- 5a. total_laid_off cannot be negative
SELECT *
FROM layoffs_staging2
WHERE CAST(total_laid_off AS DECIMAL) < 0;
-- Result: 0 rows — confirmed clean

-- 5b. percentage_laid_off must be between 0 and 1
--     Values are stored as proportions (0.0 to 1.0)
--     where 1.0 = 100% of workforce laid off (full company shutdown)
SELECT *
FROM layoffs_staging2
WHERE CAST(percentage_laid_off AS DECIMAL) < 0
OR CAST(percentage_laid_off AS DECIMAL) > 1;
-- Result: 0 rows — confirmed clean

-- 5c. funds_raised should be positive
SELECT *
FROM layoffs_staging2
WHERE CAST(funds_raised AS DECIMAL) < 0;
-- Result: 0 rows — confirmed clean

-- 5d. Headcount sanity check — flag extremely small values worth investigating
--     A company laying off fewer than 5 people is unusual and worth verifying
SELECT company, total_laid_off, country, date
FROM layoffs_staging2
WHERE CAST(total_laid_off AS DECIMAL) < 5
AND total_laid_off IS NOT NULL
ORDER BY CAST(total_laid_off AS DECIMAL);
