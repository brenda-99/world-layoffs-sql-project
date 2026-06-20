-- ==============================================================
-- EDA Q4: How did monthly layoffs change month-over-month --
--          were things getting better or worse, and by how much?
-- ==============================================================

WITH monthly AS (
    SELECT
        DATE_FORMAT(`date`, '%Y-%m') AS month, 
        SUM(total_laid_off)          AS monthly_total
    FROM layoffs_staging2
    WHERE total_laid_off IS NOT NULL
    GROUP BY DATE_FORMAT(`date`, '%Y-%m')
)
SELECT
    month,
    monthly_total,
    LAG(monthly_total) OVER (ORDER BY month)            AS previous_month,
    monthly_total - LAG(monthly_total) OVER (ORDER BY month) AS change_vs_prev,
    ROUND(
        (monthly_total - LAG(monthly_total) OVER (ORDER BY month)) * 100.0 /
        LAG(monthly_total) OVER (ORDER BY month), 1
    ) AS pct_change_vs_prev
FROM monthly
ORDER BY month;


-- 2021-11 saw a 9309.1% spike vs the prior month,
--  the sharpest single-month acceleration in the entire dataset


