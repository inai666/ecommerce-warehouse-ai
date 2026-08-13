USE ecommerce_ads;

SELECT COUNT(*) AS stage_rows,
       COUNT(DISTINCT user_id) AS stage_users,
       MIN(cohort_date) AS min_cohort_date,
       MAX(cohort_date) AS max_cohort_date
FROM user_retention_stage;

SELECT *
FROM user_retention_summary
ORDER BY cohort_date;

-- Retention counts cannot exceed cohort users.
SELECT COUNT(*) AS invalid_retention_rows
FROM user_retention_summary
WHERE day_1_users > cohort_users
   OR day_2_users > cohort_users
   OR day_3_users > cohort_users
   OR day_7_users > cohort_users
   OR day_1_retention_pct < 0 OR day_1_retention_pct > 100
   OR day_2_retention_pct < 0 OR day_2_retention_pct > 100
   OR day_3_retention_pct < 0 OR day_3_retention_pct > 100
   OR day_7_retention_pct < 0 OR day_7_retention_pct > 100;

-- Cohort-day detail for manual inspection.
SELECT cohort_date, day_number, COUNT(DISTINCT user_id) AS users
FROM user_retention_stage
GROUP BY cohort_date, day_number
ORDER BY cohort_date, day_number;

