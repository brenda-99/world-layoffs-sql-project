-- ============================================================
-- STEP 9: REMOVE REDUNDANT ROWS & COLUMNS
-- Purpose  : Remove rows with no analytical value and drop
--            helper columns that served their purpose
-- ============================================================

-- 9a. Delete rows flagged in Step 4d as having no layoff data in either key column
--     These rows cannot contribute to any layoff analysis
--     ~724 rows deleted, ~3730 rows remaining
DELETE FROM layoffs_staging2
WHERE layoffs_data_missing = 1;

-- 9b. Drop the row_num helper column — used for duplicate removal in Step 2
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

-- 9c. Drop the layoffs_data_missing flag column — deletion complete, flag no longer needed
ALTER TABLE layoffs_staging2
DROP COLUMN layoffs_data_missing;

-- 9d. Drop source column — URL strings have no analytical value
ALTER TABLE layoffs_staging2
DROP COLUMN source;

-- 9e. Drop date_added column — redundant alongside the date column
--     date = announcement date (analytically meaningful)
--     date_added = when the row was entered into the dataset (not meaningful for EDA)
ALTER TABLE layoffs_staging2
DROP COLUMN date_added;

-- 9f. Final row count after all cleaning — approximately 3730 rows
SELECT COUNT(*) AS final_row_count
FROM layoffs_staging2;

-- 9g. Final inspection of the cleaned dataset
SELECT *
FROM layoffs_staging2
LIMIT 20;

-- Data is now ready for Exploratory Data Analysis (EDA)
