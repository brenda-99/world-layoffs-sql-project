-- ============================================================
-- EDA Q8: Are well-funded, late-stage companies more or less likely
--          to lay off a large share of their workforce?
-- Concept: GROUP BY with AVG() on a percentage column, CASE WHEN
--          for custom bucketing
-- ============================================================

SELECT
    stage,
    COUNT(*) AS layoff_events,
    ROUND(AVG(percentage_laid_off) * 100, 1)  AS avg_pct_workforce_cut,
    SUM(CASE WHEN percentage_laid_off = 1 THEN 1 ELSE 0 END) AS full_shutdowns
FROM layoffs_staging2
WHERE stage IS NOT NULL
AND percentage_laid_off IS NOT NULL
GROUP BY stage
ORDER BY avg_pct_workforce_cut DESC;

-- Early-stage companies (Seed) cut an average of
--  82.3% of their workforce per event -- nearly
--  5x the rate of Post-IPO companies -- even though Post-IPO
--  companies post the largest absolute headcount numbers
