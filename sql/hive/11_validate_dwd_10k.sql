-- Tutorial 05 acceptance checks.

-- 1. Reconciliation: expected 10000 = 9997 + 3.
SELECT
  ods_rows,
  dwd_rows,
  quarantine_rows,
  ods_rows - dwd_rows - quarantine_rows AS reconciliation_gap
FROM
  (SELECT COUNT(*) AS ods_rows FROM ecommerce_ods.user_behavior_10k) o
CROSS JOIN
  (SELECT COUNT(*) AS dwd_rows FROM ecommerce_dwd.user_behavior_detail) d
CROSS JOIN
  (SELECT COUNT(*) AS quarantine_rows FROM ecommerce_dwd.user_behavior_quarantine) q;

-- 2. Daily partitions and event volume.
SELECT dt, COUNT(*) AS event_rows
FROM ecommerce_dwd.user_behavior_detail
GROUP BY dt
ORDER BY dt;

-- 3. Valid DWD behavior distribution.
SELECT behavior, COUNT(*) AS behavior_rows
FROM ecommerce_dwd.user_behavior_detail
GROUP BY behavior
ORDER BY behavior_rows DESC;

-- 4. Every rejected row must have an explainable reason.
SELECT reject_reason, COUNT(*) AS rejected_rows
FROM ecommerce_dwd.user_behavior_quarantine
GROUP BY reject_reason
ORDER BY reject_reason;

-- 5. Verify converted time and partition alignment.
SELECT user_id, item_id, behavior, event_ts, event_time, dt
FROM ecommerce_dwd.user_behavior_detail
ORDER BY event_ts
LIMIT 10;

-- 6. Inspect quarantined raw values without deleting them.
SELECT *
FROM ecommerce_dwd.user_behavior_quarantine
ORDER BY event_ts;

-- 7. Confirm Hive registered all date partitions.
SHOW PARTITIONS ecommerce_dwd.user_behavior_detail;

