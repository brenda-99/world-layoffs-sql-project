-- ============================================================
-- STEP 6: CROSS-COLUMN RELATIONSHIP VALIDATION
-- Purpose  : Check logical consistency between location and country
--            Issues fall into 6 distinct categories
--            Total issues found: 36 rows across 283 location-country combinations
-- ============================================================


-- ============================================================
-- STEP 6A: AUDIT — Run all checks before making any changes
-- ============================================================

-- 6a. Full location-country map — used to spot all issues visually
SELECT location, country, COUNT(*) AS occurrences
FROM layoffs_staging2
WHERE location IS NOT NULL AND country IS NOT NULL
GROUP BY location, country
ORDER BY location, occurrences DESC;

-- 6b. Non-U.S. suffix present but country = United States (direct contradiction)
SELECT company, location, country, date
FROM layoffs_staging2
WHERE location LIKE '%, Non-U.S.'
AND country = 'United States';

-- 6c. No Non-U.S. suffix but country is not United States
--     International city entered without the dataset's own naming convention
SELECT company, location, country, date
FROM layoffs_staging2
WHERE location NOT LIKE '%, Non-U.S.'
AND country NOT IN ('United States', '');

-- 6d. Garbled/impossible location names — comma-separated but not Non-U.S.
SELECT company, location, country, date
FROM layoffs_staging2
WHERE location LIKE '%,%'
AND location NOT LIKE '%, Non-U.S.';

-- 6e. Location literally = 'Non-U.S.' with no actual city name
SELECT company, location, country, date
FROM layoffs_staging2
WHERE location = 'Non-U.S.';


-- ============================================================
-- STEP 6B: FIX — CATEGORY 1: MISSING Non-U.S. SUFFIX
-- International cities that exist predominantly with the suffix
-- but a handful of rows are missing it — entry inconsistency, not a different place
-- Found: 13 cities, ~18 rows total
-- ============================================================

-- Confirm before fixing
SELECT company, location, country
FROM layoffs_staging2
WHERE location IN (
    'Auckland', 'Bengaluru', 'Brisbane', 'Buenos Aires',
    'Cayman Islands', 'Gurugram', 'Kuala Lumpur', 'London',
    'Montreal', 'Mumbai', 'Singapore', 'Tel Aviv', 'Vancouver'
);

-- Bulk fix: append ', Non-U.S.' to match the rest of the dataset
-- Brisbane deliberately excluded — externally verified as Brisbane, California USA
-- (Arch Oncology Inc. is headquartered there — original data is correct)
UPDATE layoffs_staging2
SET location = CONCAT(location, ', Non-U.S.')
WHERE location IN (
    'Auckland', 'Bengaluru', 'Cayman Islands', 'Gurugram',
    'Kuala Lumpur', 'London', 'Mumbai', 'Tel Aviv'
);

-- Check Canadian city convention before fixing Montreal and Vancouver
SELECT DISTINCT location, country
FROM layoffs_staging2
WHERE country = 'Canada'
ORDER BY location;
-- Canada uses Non-U.S. suffix — fix both

UPDATE layoffs_staging2
SET location = 'Montreal, Non-U.S.'
WHERE location = 'Montreal'
AND country = 'Canada';

UPDATE layoffs_staging2
SET location = 'Vancouver, Non-U.S.'
WHERE location = 'Vancouver'
AND country = 'Canada';

-- Buenos Aires (Argentina, 1 row)
UPDATE layoffs_staging2
SET location = 'Buenos Aires, Non-U.S.'
WHERE location = 'Buenos Aires'
AND country = 'Argentina';

-- Singapore (2 rows)
UPDATE layoffs_staging2
SET location = 'Singapore, Non-U.S.'
WHERE location = 'Singapore'
AND country = 'Singapore';

-- Verify — should return 0 rows
SELECT location, country, COUNT(*) AS occurrences
FROM layoffs_staging2
WHERE location IN (
    'Auckland', 'Bengaluru', 'Buenos Aires', 'Cayman Islands',
    'Gurugram', 'Kuala Lumpur', 'London', 'Montreal',
    'Mumbai', 'Singapore', 'Tel Aviv', 'Vancouver'
)
GROUP BY location, country;


-- ============================================================
-- CATEGORY 2: Non-U.S. SUFFIX BUT COUNTRY = UNITED STATES
-- Direct logical contradiction — suffix explicitly means not US
-- All cases double-checked before updating
-- Found: 8 rows across 5 locations
-- ============================================================

-- Preview all affected rows first
SELECT company, location, country, date
FROM layoffs_staging2
WHERE location LIKE '%, Non-U.S.'
AND country = 'United States';

-- Dublin, Non-U.S. -> Ireland (1 row: Salesforce 9/3/2025)
-- Dublin Non-U.S. = Dublin Ireland, not Dublin Ohio
UPDATE layoffs_staging2
SET country = 'Ireland'
WHERE location = 'Dublin, Non-U.S.'
AND country = 'United States';

-- Haifa, Non-U.S. -> Israel (1 row)
UPDATE layoffs_staging2
SET country = 'Israel'
WHERE location = 'Haifa, Non-U.S.'
AND country = 'United States';

-- Jerusalem, Non-U.S. -> Israel (1 row)
UPDATE layoffs_staging2
SET country = 'Israel'
WHERE location = 'Jerusalem, Non-U.S.'
AND country = 'United States';

-- Tel Aviv, Non-U.S. -> Israel (4 rows)
UPDATE layoffs_staging2
SET country = 'Israel'
WHERE location = 'Tel Aviv, Non-U.S.'
AND country = 'United States';

-- Vancouver, Non-U.S. -> Canada (1 row)
UPDATE layoffs_staging2
SET country = 'Canada'
WHERE location = 'Vancouver, Non-U.S.'
AND country = 'United States';

-- Verify — should return 0 rows
SELECT company, location, country
FROM layoffs_staging2
WHERE location LIKE '%, Non-U.S.'
AND country = 'United States';


-- ============================================================
-- CATEGORY 3: WRONG COUNTRY FOR A CLEARLY CORRECT LOCATION
-- Location is valid, country is wrong — isolated data entry errors
-- Found: 8 rows — each investigated individually with external verification
-- ============================================================

-- Boston → Germany (1 row: Wayfair 3/7/2025)
-- Verified online: Wayfair did shut down its Berlin Germany office in 2025 (720 jobs, ~3% global workforce)
-- The layoffs were Berlin-based but entered with Boston (HQ) as location
-- Decision: Country corrected to United States to match the Boston location entry
-- The Berlin office layoffs are captured separately in other Wayfair rows
UPDATE layoffs_staging2
SET country = 'United States'
WHERE company  = 'Wayfair'
AND location = 'Boston'
AND country  = 'Germany'
AND date     = '3/7/2025';

-- SF Bay Area -> India (3 rows: GupShup)
-- GupShup HQ is SF Bay Area. Reports show layoffs hit remote teams in India
-- but exact cities are unspecified in sources.
-- Decision: Standardized to HQ country (United States) to avoid vague geographic entries
UPDATE layoffs_staging2
SET country = 'United States'
WHERE location = 'SF Bay Area'
AND country = 'India';

-- SF Bay Area -> Israel (2 rows: eBay, Bright Machines)
-- Bright Machines: Israel branch affected but exact city unspecified.
-- eBay: 800 figure reflects a global workforce reduction.
-- Decision: Both defaulted to HQ location (SF Bay Area / United States)
UPDATE layoffs_staging2
SET country = 'United States'
WHERE company = 'Bright Machines'
AND location = 'SF Bay Area'
AND country = 'Israel';

UPDATE layoffs_staging2
SET country = 'United States'
WHERE company = 'eBay'
AND total_laid_off = 800
AND country = 'Israel';

-- New York City -> Israel (1 row: Retrain.ai 7/2/2025)
-- Retrain.ai is Israeli-founded with NY operations
-- Location = New York City contradicts Country = Israel
UPDATE layoffs_staging2
SET country = 'United States'
WHERE location = 'New York City'
AND country = 'Israel';

-- New York City -> France (1 row: Jellysmack 10/21/2024)
-- Jellysmack is French with a New York office
-- 22 layoffs were a global total affecting both US and France teams
-- Decision: Updated to United States to align with New York City location entry
UPDATE layoffs_staging2
SET country = 'United States'
WHERE location = 'New York City'
AND country = 'France';

-- Oslo, Non-U.S. -> Norway (1 row: Oda 11/1/2022)
-- Oslo is in Norway — Sweden was a clear data entry error
UPDATE layoffs_staging2
SET country = 'Norway'
WHERE location = 'Oslo, Non-U.S.'
AND country = 'Sweden';

-- Jakarta, Non-U.S. -> Indonesia (1 row: Halodoc 11/14/2023)
-- Jakarta is in Indonesia — India was a clear data entry error
UPDATE layoffs_staging2
SET country = 'Indonesia'
WHERE location = 'Jakarta, Non-U.S.'
AND country = 'India';

-- Buenos Aires, Non-U.S. -> Argentina (1 row: MercadoLibre)
-- Buenos Aires is in Argentina — Brazil was a clear data entry error
UPDATE layoffs_staging2
SET country = 'Argentina'
WHERE location  = 'Buenos Aires, Non-U.S.'
AND country = 'Brazil';


-- ============================================================
-- CATEGORY 4: GARBLED LOCATION NAMES
-- Two city names or city + state merged into one field
-- Found: 3 rows
-- ============================================================

-- 'New Delhi, New York City' -> New York City (1 row: The Org)
-- The Org is a US company — New York City is the correct location
-- New Delhi was incorrectly prepended
UPDATE layoffs_staging2
SET location = 'New York City'
WHERE country  = 'United States'
AND location = 'New Delhi, New York City';

-- 'Luxembourg, Raleigh' -> Luxembourg, Non-U.S. (1 row: Kleos Space)
-- Kleos Space is Luxembourg-registered with a Raleigh office
-- Country = Luxembourg confirms the intended location
UPDATE layoffs_staging2
SET location = 'Luxembourg, Non-U.S.'
WHERE location = 'Luxembourg, Raleigh'
AND company = 'Kleos Space';

-- 'Melbourne, Victoria' -> Melbourne, Non-U.S. (1 row: Deliveroo Australia)
-- Victoria is the state, not a second city — formatting error
-- All other Melbourne rows correctly use 'Melbourne, Non-U.S.'
UPDATE layoffs_staging2
SET location = 'Melbourne, Non-U.S.'
WHERE location = 'Melbourne, Victoria';


-- ============================================================
-- CATEGORY 5: LOCATION = 'Non-U.S.' WITH NO CITY NAME
-- Placeholder entered instead of an actual city
-- Found: 3 rows (BitMEX x2, WeDoctor)
-- ============================================================

SELECT company, location, country, date
FROM layoffs_staging2
WHERE location = 'Non-U.S.';

-- BitMEX (Seychelles, 2 rows)
-- BitMEX layoffs were global with no specific city reported in source
-- Updated to 'Unknown' as a clean, standardized placeholder
UPDATE layoffs_staging2
SET location = 'Unknown'
WHERE company = 'BitMEX'
AND location = 'Non-U.S.';

-- WeDoctor (China, 1 row)
-- Confirmed from online source: WeDoctor is based in Hangzhou, China
UPDATE layoffs_staging2
SET location = 'Hangzhou, Non-U.S.'
WHERE company  = 'WeDoctor'
AND location = 'Non-U.S.';


-- ============================================================
-- CATEGORY 6: INTERNATIONAL CITIES WITHOUT Non-U.S. SUFFIX
-- Single-occurrence clearly international cities entered
-- without following the dataset's own naming convention
-- Found: Nicosia (Cyprus), Trondheim (Norway)
-- ============================================================

-- Nicosia (Cyprus, 1 row: ABBYY)
UPDATE layoffs_staging2
SET location = 'Nicosia, Non-U.S.'
WHERE location = 'Nicosia'
AND country = 'Cyprus';

-- Trondheim (Norway, 1 row: Signicat)
UPDATE layoffs_staging2
SET location = 'Trondheim, Non-U.S.'
WHERE location = 'Trondheim'
AND country = 'Norway';


-- ============================================================
-- TEXT ENCODING & STRING NORMALIZATION
-- Several international cities have broken special characters
-- due to UTF-8 encoding issues from the CSV import
-- ============================================================

-- Check encoding issues
SELECT * FROM layoffs_staging2 WHERE location LIKE 'Malm%'
UNION ALL
SELECT * FROM layoffs_staging2 WHERE location LIKE '%dorf%';

-- a. Sweden: Malmö (encoded as 'MalmÃ¶' or 'Malmo')
UPDATE layoffs_staging2
SET location = 'Malmö'
WHERE location IN ('Malmo, Non-U.S.', 'MalmÃ¶, Non-U.S.');

-- b. Germany: Düsseldorf (encoded as 'DÃ¼sseldorf' or 'Dusseldorf')
UPDATE layoffs_staging2
SET location = 'Düsseldorf'
WHERE location IN ('Dusseldorf, Non-U.S.', 'DÃ¼sseldorf, Non-U.S.');

-- c. Poland: Wrocław (encoded as 'WrocÅ‚aw')
UPDATE layoffs_staging2
SET location = 'Wrocław'
WHERE location = 'WrocÅ‚aw, Non-U.S.';

-- d. Norway: Førde (encoded as 'FÃ¸rde')
UPDATE layoffs_staging2
SET location = 'Førde'
WHERE location = 'FÃ¸rde, Non-U.S.';

-- e. Remove ', Non-U.S.' suffix from all international locations
--    The suffix was the dataset's original convention to flag non-US cities
--    It is now redundant since we have a clean country column
--    Removing it produces cleaner, more readable city names for EDA
UPDATE layoffs_staging2
SET location = REPLACE(location, ', Non-U.S.', '')
WHERE location LIKE '%, Non-U.S.%';


-- ============================================================
-- FINAL VERIFICATION
-- ============================================================

-- Should return 0 rows (no more Non-U.S. + United States contradictions)
SELECT company, location, country
FROM layoffs_staging2
WHERE location LIKE '%, Non-U.S.'
AND country = 'United States';

-- Should return 0 rows (no more garbled names)
SELECT location, country
FROM layoffs_staging2
WHERE location LIKE '%,%'
AND location NOT LIKE '%, Non-U.S.';

-- Should return 0 rows (no more missing suffixes for known international cities)
-- Note: suffix removal in step above means these should now show clean city names
SELECT location, country
FROM layoffs_staging2
WHERE location IN (
    'Auckland', 'Bengaluru', 'Brisbane', 'Buenos Aires',
    'Cayman Islands', 'Gurugram', 'Kuala Lumpur', 'London',
    'Montreal', 'Mumbai', 'Singapore', 'Tel Aviv',
    'Vancouver', 'Nicosia', 'Trondheim'
);

-- Final clean location-country map
SELECT location, country, COUNT(*) AS occurrences
FROM layoffs_staging2
WHERE location IS NOT NULL AND country IS NOT NULL
GROUP BY location, country
ORDER BY location, occurrences DESC;
