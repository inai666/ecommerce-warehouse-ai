USE ecommerce_ods;

-- 1. Import scale: must be exactly 10000.
SELECT COUNT(*) AS total_rows
FROM user_behavior_10k;

-- 2. Behavior distribution: compare with the MySQL smoke baseline.
SELECT behavior, COUNT(*) AS behavior_rows
FROM user_behavior_10k
GROUP BY behavior
ORDER BY behavior_rows DESC;

-- 3. Null and enum quality checks: every value must be 0.
SELECT
  SUM(CASE WHEN user_id IS NULL THEN 1 ELSE 0 END) AS null_user_id,
  SUM(CASE WHEN item_id IS NULL THEN 1 ELSE 0 END) AS null_item_id,
  SUM(CASE WHEN category_id IS NULL THEN 1 ELSE 0 END) AS null_category_id,
  SUM(CASE WHEN behavior IS NULL OR behavior = '' THEN 1 ELSE 0 END) AS null_behavior,
  SUM(CASE WHEN event_ts IS NULL THEN 1 ELSE 0 END) AS null_event_ts,
  SUM(CASE WHEN behavior NOT IN ('pv', 'fav', 'cart', 'buy') THEN 1 ELSE 0 END) AS invalid_behavior
FROM user_behavior_10k;

-- 4. Business-range outliers. Keep them in ODS; DWD will isolate them.
SELECT
  SUM(CASE WHEN event_ts < 1511539200 OR event_ts >= 1512316800 THEN 1 ELSE 0 END) AS time_outliers
FROM user_behavior_10k;

-- 5. Preview raw rows.
SELECT *
FROM user_behavior_10k
LIMIT 10;

