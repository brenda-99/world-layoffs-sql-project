-- ============================================================
-- EDA Q3: Which countries drove the global total, and how much
--          of the world's layoffs sit in just the top few?
-- ============================================================

WITH country_totals AS (
    SELECT
        country,
        SUM(total_laid_off) AS country_total
    FROM layoffs_staging2
    WHERE total_laid_off IS NOT NULL
    GROUP BY country
)
SELECT
    country,
    country_total,
    ROUND(
        country_total* 100.0 /
        SUM(country_total) OVER (), 1
    ) AS pct_of_total,    
    ROUND(
        SUM(country_total) OVER (ORDER BY country_total DESC) * 100.0 /
        SUM(country_total) OVER (), 1
    ) AS running_pct_of_total
FROM country_totals
ORDER BY country_total DESC
LIMIT 10;

-- The top 5 countries alone account for ~87% of global layoffs, 
-- with the United States making up to ~72% alone 
-- The remaining countries combined make up less than 20%



