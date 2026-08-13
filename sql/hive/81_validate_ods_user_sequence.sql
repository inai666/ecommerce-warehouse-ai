-- Tutorial 13: validate the isolated user-level sequence ODS table.

-- 1. File-to-table row count.
SELECT COUNT(*) AS total_rows
FROM ecommerce_ods.user_behavior_sequence_1pct;

-- 2. Complete selected-user count and raw behavior distribution.
SELECT COUNT(DISTINCT user_id) AS selected_users
FROM ecommerce_ods.user_behavior_sequence_1pct;

SELECT behavior, COUNT(*) AS behavior_rows
FROM ecommerce_ods.user_behavior_sequence_1pct
GROUP BY behavior
ORDER BY behavior_rows DESC;

-- 3. Structural quality: every value must be zero.
SELECT
  SUM(CASE WHEN user_id IS NULL THEN 1 ELSE 0 END) AS null_user_id,
  SUM(CASE WHEN item_id IS NULL THEN 1 ELSE 0 END) AS null_item_id,
  SUM(CASE WHEN category_id IS NULL THEN 1 ELSE 0 END) AS null_category_id,
  SUM(CASE WHEN behavior IS NULL OR behavior = '' THEN 1 ELSE 0 END) AS null_behavior,
  SUM(CASE WHEN event_ts IS NULL THEN 1 ELSE 0 END) AS null_event_ts,
  SUM(CASE WHEN behavior NOT IN ('pv', 'fav', 'cart', 'buy') THEN 1 ELSE 0 END) AS invalid_behavior
FROM ecommerce_ods.user_behavior_sequence_1pct;

-- 4. Business-time outliers remain in ODS for auditable DWD isolation.
SELECT
  SUM(CASE WHEN event_ts < 1511539200 THEN 1 ELSE 0 END) AS before_range,
  SUM(CASE WHEN event_ts >= 1512316800 THEN 1 ELSE 0 END) AS after_range,
  SUM(CASE WHEN event_ts < 1511539200 OR event_ts >= 1512316800 THEN 1 ELSE 0 END) AS total_outliers,
  MIN(event_ts) AS min_event_ts,
  MAX(event_ts) AS max_event_ts
FROM ecommerce_ods.user_behavior_sequence_1pct;

-- 5. Existing event-sample baselines must remain unchanged.
SELECT
  (SELECT COUNT(*) FROM ecommerce_ods.user_behavior_10k) AS baseline_10k_rows,
  (SELECT COUNT(*) FROM ecommerce_ods.user_behavior_1m) AS event_sample_1m_rows;

