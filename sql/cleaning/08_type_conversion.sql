-- ============================================================
-- STEP 8: TYPE CONVERSION
-- Purpose  : Convert all columns from TEXT to correct data types
--            Must run after all string-based cleaning is complete
--            Enables proper numeric operations and date functions
-- ============================================================

-- 8a. Fix total_laid_off — stored as '50.0', should be integer headcount
--     Preview the cast before committing
SELECT total_laid_off,
       CAST(CAST(total_laid_off AS DECIMAL(10,0)) AS SIGNED) AS as_integer
FROM layoffs_staging2
WHERE total_laid_off IS NOT NULL
LIMIT 10;

UPDATE layoffs_staging2
SET total_laid_off = CAST(CAST(total_laid_off AS DECIMAL(10,0)) AS SIGNED)
WHERE total_laid_off IS NOT NULL;

ALTER TABLE layoffs_staging2
MODIFY COLUMN total_laid_off INT;

-- 8b. Convert date from M/D/YYYY text to DATE type
--     Enables YEAR(), MONTH(), DATEDIFF() and time-series analysis
SELECT `date`, STR_TO_DATE(`date`, '%m/%d/%Y') AS converted_date
FROM layoffs_staging2
LIMIT 5;

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- 8c. Convert funds_raised to DECIMAL
--     NOTE: Running this produced a MySQL warning
--     Diagnostics revealed: row 1182 had value 0.9755 which was
--     truncated to 0.98 by DECIMAL(12,2) — only 2 decimal places allowed
--     Confirmed via: SELECT * FROM layoffs_staging2 LIMIT 1182, 1;
--     Company affected: Eatsy
--     Decision: DECIMAL(12,2) accepted — truncation of fractional fund amounts
--     is negligible for analysis purposes
SELECT * FROM layoffs_staging2 LIMIT 1182, 1;
SELECT * FROM layoffs_staging WHERE company = 'Eatsy';

ALTER TABLE layoffs_staging2
MODIFY COLUMN funds_raised DECIMAL(12,2);

-- 8d. Convert percentage_laid_off to DECIMAL
--     NOTE: Similar warning received
--     Diagnostics: row 94 had a value affected by precision limit
--     Company affected: Airy Rooms
--     Decision: DECIMAL(5,4) accepted — proportions stored to 4 decimal places
--     is sufficient precision for all EDA use cases
SELECT company, percentage_laid_off FROM layoffs_staging2 LIMIT 94, 1;
SELECT company, percentage_laid_off FROM layoffs_staging WHERE company = 'Airy Rooms';

ALTER TABLE layoffs_staging2
MODIFY COLUMN percentage_laid_off DECIMAL(5,4);

-- 8e. Validate no future dates exist post-conversion
SELECT *
FROM layoffs_staging2
WHERE `date` > CURRENT_DATE;
-- Result: 0 rows — confirmed clean
