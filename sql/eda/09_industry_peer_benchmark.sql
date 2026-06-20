-- ============================================================
-- EDA Q9: How does each company's single largest layoff event
--          compare to the average company in its own industry?
-- Concept: Correlated subquery + CTE for peer benchmarking
-- ============================================================

WITH biggest_event_per_company AS (
    SELECT
        company,
        industry,
        MAX(total_laid_off) AS biggest_single_event
    FROM layoffs_staging2
    WHERE total_laid_off IS NOT NULL
    GROUP BY company, industry
)
SELECT
    company,
    industry,
    biggest_single_event,
    ROUND(AVG(biggest_single_event) OVER (PARTITION BY industry), 0) AS industry_avg_biggest_event,
    ROUND(
        biggest_single_event / AVG(biggest_single_event) OVER (PARTITION BY industry), 1
    ) AS times_above_industry_avg
FROM biggest_event_per_company
ORDER BY times_above_industry_avg DESC
LIMIT 15;

-- Amazon's largest single layoff event was ~50x
--  the average for its own industry -- a clear outlier even within an
--  already-struggling sector
