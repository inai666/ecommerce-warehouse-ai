-- Tutorial 08: validate the isolated 1M ODS table.

-- 1. Scale must be exactly 1,000,000.
SELECT COUNT(*) AS total_rows
FROM ecommerce_ods.user_behavior_1m;

-- 2. Behavior distribution must match the fixed sample baseline.
SELECT behavior, COUNT(*) AS behavior_rows
FROM ecommerce_ods.user_behavior_1m
GROUP BY behavior
ORDER BY behavior_rows DESC;

-- 3. Nulls and invalid behavior must all be zero.
SELECT
  SUM(CASE WHEN user_id IS NULL THEN 1 ELSE 0 END) AS null_user_id,
  SUM(CASE WHEN item_id IS NULL THEN 1 ELSE 0 END) AS null_item_id,
  SUM(CASE WHEN category_id IS NULL THEN 1 ELSE 0 END) AS null_category_id,
  SUM(CASE WHEN behavior IS NULL OR behavior = '' THEN 1 ELSE 0 END) AS null_behavior,
  SUM(CASE WHEN event_ts IS NULL THEN 1 ELSE 0 END) AS null_event_ts,
  SUM(CASE WHEN behavior NOT IN ('pv', 'fav', 'cart', 'buy') THEN 1 ELSE 0 END) AS invalid_behavior
FROM ecommerce_ods.user_behavior_1m;

-- 4. ODS keeps business-time outliers for DWD quarantine.
SELECT
  SUM(CASE WHEN event_ts < 1511539200 OR event_ts >= 1512316800 THEN 1 ELSE 0 END) AS time_outliers,
  MIN(event_ts) AS min_event_ts,
  MAX(event_ts) AS max_event_ts
FROM ecommerce_ods.user_behavior_1m;

-- 5. Cardinality baseline for later analytical checks.
SELECT
  COUNT(DISTINCT user_id) AS users,
  COUNT(DISTINCT item_id) AS items,
  COUNT(DISTINCT category_id) AS categories
FROM ecommerce_ods.user_behavior_1m;

-- 6. The 10K baseline must remain isolated and unchanged.
SELECT COUNT(*) AS baseline_10k_rows
FROM ecommerce_ods.user_behavior_10k;

