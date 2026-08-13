-- Tutorial 14 acceptance checks.

-- 1. Strict row reconciliation.
SELECT
  ods_rows,
  dwd_rows,
  quarantine_rows,
  ods_rows - dwd_rows - quarantine_rows AS reconciliation_gap
FROM
  (SELECT COUNT(*) AS ods_rows FROM ecommerce_ods.user_behavior_sequence_1pct) o
CROSS JOIN
  (SELECT COUNT(*) AS dwd_rows FROM ecommerce_dwd.user_behavior_sequence_detail) d
CROSS JOIN
  (SELECT COUNT(*) AS quarantine_rows FROM ecommerce_dwd.user_behavior_sequence_quarantine) q;

-- 2. Every rejected row must be explained.
SELECT reject_reason, COUNT(*) AS rejected_rows
FROM ecommerce_dwd.user_behavior_sequence_quarantine
GROUP BY reject_reason
ORDER BY reject_reason;

-- 3. Valid behavior distribution.
SELECT behavior, COUNT(*) AS behavior_rows
FROM ecommerce_dwd.user_behavior_sequence_detail
GROUP BY behavior
ORDER BY behavior_rows DESC;

-- 4. DWD cardinality. One selected user has only out-of-range records.
SELECT
  COUNT(DISTINCT user_id) AS valid_users,
  COUNT(DISTINCT item_id) AS valid_items,
  COUNT(DISTINCT category_id) AS valid_categories
FROM ecommerce_dwd.user_behavior_sequence_detail;

-- 5. Daily partitions and volumes.
SELECT dt, COUNT(*) AS event_rows
FROM ecommerce_dwd.user_behavior_sequence_detail
GROUP BY dt
ORDER BY dt;

-- 6. Verify converted time and partition alignment.
SELECT user_id, item_id, behavior, event_ts, event_time, dt
FROM ecommerce_dwd.user_behavior_sequence_detail
ORDER BY event_ts
LIMIT 10;

SHOW PARTITIONS ecommerce_dwd.user_behavior_sequence_detail;

