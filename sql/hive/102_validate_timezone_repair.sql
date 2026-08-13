-- Validate the Shanghai-time repair before rebuilding downstream analyses.

SELECT
  MIN(dt) AS min_dt,
  MAX(dt) AS max_dt,
  COUNT(*) AS dwd_rows,
  COUNT(DISTINCT user_id) AS valid_users
FROM ecommerce_dwd.user_behavior_sequence_detail;

SELECT COUNT(*) AS invalid_dt_rows
FROM ecommerce_dwd.user_behavior_sequence_detail
WHERE dt < '2017-11-25' OR dt > '2017-12-03';

SELECT dt, COUNT(*) AS event_rows
FROM ecommerce_dwd.user_behavior_sequence_detail
GROUP BY dt
ORDER BY dt;

SELECT event_ts, event_time, dt
FROM ecommerce_dwd.user_behavior_sequence_detail
ORDER BY event_ts
LIMIT 5;

SHOW PARTITIONS ecommerce_dwd.user_behavior_sequence_detail;

