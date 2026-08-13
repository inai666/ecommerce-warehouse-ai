-- A count of 10,000 alone is not enough; run every check below.

USE taobao_ods;

SELECT COUNT(*) AS total_rows
FROM user_behavior_smoke;

SELECT behavior, COUNT(*) AS behavior_rows
FROM user_behavior_smoke
GROUP BY behavior
ORDER BY behavior_rows DESC;

SELECT
  SUM(user_id IS NULL) AS null_user_id,
  SUM(item_id IS NULL) AS null_item_id,
  SUM(category_id IS NULL) AS null_category_id,
  SUM(behavior IS NULL OR behavior = '') AS null_behavior,
  SUM(event_ts IS NULL) AS null_event_ts,
  SUM(behavior NOT IN ('pv', 'fav', 'cart', 'buy')) AS invalid_behavior
FROM user_behavior_smoke;

SELECT
  MIN(event_ts) AS min_event_ts,
  FROM_UNIXTIME(MIN(event_ts)) AS min_server_time,
  MAX(event_ts) AS max_event_ts,
  FROM_UNIXTIME(MAX(event_ts)) AS max_server_time
FROM user_behavior_smoke;

SELECT @@session.time_zone AS session_time_zone,
       @@system_time_zone AS system_time_zone;

SELECT COUNT(*) AS business_time_outliers
FROM user_behavior_smoke
WHERE event_ts < UNIX_TIMESTAMP('2017-11-25 00:00:00')
   OR event_ts >= UNIX_TIMESTAMP('2017-12-04 00:00:00');

SELECT user_id, item_id, category_id, behavior, event_ts,
       FROM_UNIXTIME(event_ts) AS event_time_server_zone
FROM user_behavior_smoke
ORDER BY row_id
LIMIT 20;

SELECT user_id, item_id, category_id, behavior, event_ts, COUNT(*) AS copies
FROM user_behavior_smoke
GROUP BY user_id, item_id, category_id, behavior, event_ts
HAVING COUNT(*) > 1
ORDER BY copies DESC
LIMIT 20;

