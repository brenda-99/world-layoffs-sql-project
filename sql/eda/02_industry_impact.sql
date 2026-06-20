-- ============================================================
-- EDA Q2: Which industries were hit hardest, and how concentrated
-- is the damage?
-- ============================================================

SELECT
    industry,
    SUM(total_laid_off) AS industry_total,
    COUNT(*) AS layoff_events,
    ROUND(
        SUM(total_laid_off) * 100.0 /
        SUM(SUM(total_laid_off)) OVER (), 1
    ) AS pct_of_all_layoffs
FROM layoffs_staging2
WHERE total_laid_off IS NOT NULL
GROUP BY industry
ORDER BY industry_total DESC
LIMIT 10;

-- Retail and Other alone accounts for 24.6% of every layoff in this dataset,  
-- which is more than the next two industries combined