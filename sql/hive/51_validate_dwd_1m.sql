-- Tutorial 09 acceptance checks.

-- 1. Strict row reconciliation.
SELECT
  ods_rows,
  dwd_rows,
  quarantine_rows,
  ods_rows - dwd_rows - quarantine_rows AS reconciliation_gap
FROM
  (SELECT COUNT(*) AS ods_rows FROM ecommerce_ods.user_behavior_1m) o
CROSS JOIN
  (SELECT COUNT(*) AS dwd_rows FROM ecommerce_dwd.user_behavior_detail_1m) d
CROSS JOIN
  (SELECT COUNT(*) AS quarantine_rows FROM ecommerce_dwd.user_behavior_quarantine_1m) q;

-- 2. Rejection reasons must explain all 571 outliers.
SELECT reject_reason, COUNT(*) AS rejected_rows
FROM ecommerce_dwd.user_behavior_quarantine_1m
GROUP BY reject_reason
ORDER BY reject_reason;

-- 3. Valid DWD behavior distribution.
SELECT behavior, COUNT(*) AS behavior_rows
FROM ecommerce_dwd.user_behavior_detail_1m
GROUP BY behavior
ORDER BY behavior_rows DESC;

-- 4. Date partitions and row volumes.
SELECT dt, COUNT(*) AS event_rows
FROM ecommerce_dwd.user_behavior_detail_1m
GROUP BY dt
ORDER BY dt;

-- 5. Valid-layer cardinality after outlier isolation.
SELECT
  COUNT(DISTINCT user_id) AS users,
  COUNT(DISTINCT item_id) AS items,
  COUNT(DISTINCT category_id) AS categories
FROM ecommerce_dwd.user_behavior_detail_1m;

-- 6. Verify time conversion and partition alignment.
SELECT user_id, item_id, behavior, event_ts, event_time, dt
FROM ecommerce_dwd.user_behavior_detail_1m
ORDER BY event_ts
LIMIT 10;

SHOW PARTITIONS ecommerce_dwd.user_behavior_detail_1m;

