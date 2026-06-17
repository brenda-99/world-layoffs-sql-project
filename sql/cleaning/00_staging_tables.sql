-- ============================================================
-- STEP 0: STAGING TABLES
-- Dataset  : layoffs.csv (~4,453 rows, 11 columns)
-- Tool     : MySQL 8.x
-- Purpose  : Create working copies of raw data
--            Never modify raw data directly — always work on a copy
-- ============================================================

SELECT * FROM layoffs;

-- First staging copy — exact mirror of raw data
CREATE TABLE layoffs_staging
LIKE layoffs;

INSERT INTO layoffs_staging
SELECT * FROM layoffs;

-- Second staging table adds row_num column for duplicate detection
-- All columns kept as TEXT at this stage — casting happens in Step 8
CREATE TABLE `layoffs_staging2` (
  `company`               TEXT,
  `location`              TEXT,
  `total_laid_off`        TEXT,
  `date`                  TEXT,
  `percentage_laid_off`   TEXT,
  `industry`              TEXT,
  `source`                TEXT,
  `stage`                 TEXT,
  `funds_raised`          TEXT,
  `country`               TEXT,
  `date_added`            TEXT,
  row_num INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO layoffs_staging2
SELECT *,
    ROW_NUMBER() OVER (
        PARTITION BY company, location, total_laid_off,
                     date, percentage_laid_off, industry,
                     stage, funds_raised, country
    ) AS row_num
FROM layoffs_staging;
