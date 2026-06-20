-- ============================================================
-- EDA Q10: Did raising more money actually protect companies from
--           laying off a larger share of their workforce?
-- Concept: NTILE() bucketing on a continuous variable, then
--          aggregate comparison across buckets
-- ============================================================

WITH funding_buckets AS (
    SELECT
        company,
        funds_raised,
        percentage_laid_off,
        NTILE(5) OVER (ORDER BY funds_raised DESC) AS funding_quintile
    FROM layoffs_staging2
    WHERE funds_raised IS NOT NULL
    AND percentage_laid_off IS NOT NULL
)
SELECT
    funding_quintile,
    COUNT(*)                                   AS companies,
    ROUND(MIN(funds_raised), 0)                AS min_funding_in_group,
    ROUND(MAX(funds_raised), 0)                AS max_funding_in_group,
    ROUND(AVG(percentage_laid_off) * 100, 1)   AS avg_pct_workforce_cut
FROM funding_buckets
GROUP BY funding_quintile
ORDER BY funding_quintile;

-- Funding level correlated with severity: companies in the lowest funding quintile 
-- cut an average of 51% of their workforce per event, roughly 3x the rate of companies 
-- in the top two funding tiers — more capital raised was associated with smaller proportional cuts

