-- ============================================================
-- STEP 2: DUPLICATE DETECTION & REMOVAL
-- Purpose  : Identify and remove duplicate records
--            Both exact duplicates and soft duplicates investigated
-- ============================================================

-- 2a. Exact duplicates — 3 found: Cars24, Beyond Meat, Cazoo
--     Each appears twice with identical values across all analytical columns
--     source URL or date_added may differ slightly but the layoff event is the same
--     NOTE: Initial profiling ran a full-row hash including source and date_added
--           which made these appear unique — only caught when grouping by the
--           9 analytical columns, confirming the importance of defining
--           what "duplicate" means before running detection
SELECT company, location, total_laid_off, date,
       percentage_laid_off, industry, stage,
       funds_raised, country, COUNT(*) AS occurrences
FROM layoffs_staging2
GROUP BY company, location, total_laid_off, date,
         percentage_laid_off, industry, stage,
         funds_raised, country
HAVING COUNT(*) > 1;

-- 2b. Soft duplicates — same company + same date, different values
--     21 found in this dataset
--     Could be: different departments, data corrections, or genuine separate events
--     Must be investigated individually before any deletion
SELECT company, date, COUNT(*) AS occurrences
FROM layoffs_staging2
GROUP BY company, date
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;

-- 2c. Inspect a specific soft duplicate case before deciding action
SELECT *
FROM layoffs_staging2
WHERE company = 'Salesforce'
AND date = '9/3/2025';

-- 2d. Remove exact duplicates — row_num > 1 from the PARTITION in Step 0
--     This correctly targets Cars24, Beyond Meat, and Cazoo second occurrences
DELETE FROM layoffs_staging2
WHERE row_num > 1;

-- Confirm removal
SELECT COUNT(*) AS remaining_rows
FROM layoffs_staging2;
