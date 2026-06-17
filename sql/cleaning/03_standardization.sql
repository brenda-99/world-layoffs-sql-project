-- ============================================================
-- STEP 3: STANDARDIZATION
-- Purpose  : Fix inconsistent values in categorical columns
--            so GROUP BY and aggregations produce accurate results
-- ============================================================

-- 3a. Trim whitespace from company names
--     15 companies have trailing spaces (e.g. 'Wayfair ')
--     These create false distinct values in GROUP BY
SELECT company, TRIM(company) AS trimmed,
       LENGTH(company) - LENGTH(TRIM(company)) AS extra_chars
FROM layoffs_staging2
WHERE LENGTH(company) != LENGTH(TRIM(company));

UPDATE layoffs_staging2
SET company = TRIM(company);

-- 3b. Unify country name variants
--     'UAE' and 'United Arab Emirates' are the same country
--     Two names inflate country counts and break aggregations
SELECT DISTINCT country
FROM layoffs_staging2
WHERE country LIKE '%UAE%' OR country LIKE '%Arab%';

UPDATE layoffs_staging2
SET country = 'United Arab Emirates'
WHERE country = 'UAE';

-- 3c. Trim country names for any hidden whitespace
UPDATE layoffs_staging2
SET country = TRIM(country);

-- 3d. Industry check for variants that need consolidating
--     In the original 2020-2023 dataset: Crypto / Crypto Currency / CryptoCurrency
--     In this expanded 2020-2026 dataset: no variants found — confirmed clean
SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY industry;

-- 3e. Mapping table for country corrections at scale
--     More robust than chained UPDATE statements for multi-variant corrections
--     Closer to production ETL practice
CREATE TABLE IF NOT EXISTS country_mapping (
    raw_country   VARCHAR(100),
    clean_country VARCHAR(100)
);

INSERT INTO country_mapping VALUES
    ('UAE',   'United Arab Emirates'),
    ('U.S.',  'United States'),
    ('US',    'United States');

SELECT * FROM country_mapping;

-- Apply mapping table corrections
UPDATE layoffs_staging2 l
JOIN country_mapping m
    ON TRIM(l.country) = m.raw_country
SET l.country = m.clean_country;

-- 3f. Normalize stage blanks and unknowns to NULL for consistency
--     'Unknown' is not a valid stage value — NULL is more honest
UPDATE layoffs_staging2
SET stage = NULL
WHERE stage = '' OR stage = 'Unknown';
