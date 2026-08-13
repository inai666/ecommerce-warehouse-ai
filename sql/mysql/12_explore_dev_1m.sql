-- Tutorial 02: exploratory ODS SQL for the 1M development sample.

USE taobao_ods;

-- 1. Row count and load metadata
SELECT COUNT(*) AS total_rows,
       MIN(loaded_at) AS first_loaded_at,
       MAX(loaded_at) AS last_loaded_at,
       COUNT(DISTINCT source_file) AS source_file_count
FROM user_behavior_dev;

-- 2. Behavior distribution
SELECT behavior, COUNT(*) AS behavior_rows,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM user_behavior_dev), 4) AS pct
FROM user_behavior_dev
GROUP BY behavior
ORDER BY behavior_rows DESC;

-- 3. Entity scale: these are counts in the sample, not the whole business.
SELECT COUNT(DISTINCT user_id) AS users,
       COUNT(DISTINCT item_id) AS items,
       COUNT(DISTINCT category_id) AS categories
FROM user_behavior_dev;

-- 4. Daily distribution in China Standard Time (server is UTC+8).
SELECT DATE(FROM_UNIXTIME(event_ts)) AS event_date,
       COUNT(*) AS rows,
       COUNT(DISTINCT user_id) AS active_users,
       SUM(behavior = 'pv') AS pv,
       SUM(behavior = 'buy') AS buy_events
FROM user_behavior_dev
WHERE event_ts >= UNIX_TIMESTAMP('2017-11-25 00:00:00')
  AND event_ts < UNIX_TIMESTAMP('2017-12-04 00:00:00')
GROUP BY DATE(FROM_UNIXTIME(event_ts))
ORDER BY event_date;

-- 5. Hour-of-day distribution
SELECT HOUR(FROM_UNIXTIME(event_ts)) AS event_hour,
       COUNT(*) AS rows,
       COUNT(DISTINCT user_id) AS active_users
FROM user_behavior_dev
WHERE event_ts >= UNIX_TIMESTAMP('2017-11-25 00:00:00')
  AND event_ts < UNIX_TIMESTAMP('2017-12-04 00:00:00')
GROUP BY HOUR(FROM_UNIXTIME(event_ts))
ORDER BY event_hour;

-- 6. Business-time outliers. Keep them in ODS; DWD will isolate them.
SELECT COUNT(*) AS business_time_outliers,
       MIN(event_ts) AS min_outlier_ts,
       MAX(event_ts) AS max_outlier_ts
FROM user_behavior_dev
WHERE event_ts < UNIX_TIMESTAMP('2017-11-25 00:00:00')
   OR event_ts >= UNIX_TIMESTAMP('2017-12-04 00:00:00');

-- 7. Behavior-specific user counts
SELECT behavior, COUNT(DISTINCT user_id) AS users,
       COUNT(*) AS events
FROM user_behavior_dev
GROUP BY behavior
ORDER BY behavior;

-- 8. Candidate duplicate business keys (not row_id)
SELECT user_id, item_id, category_id, behavior, event_ts,
       COUNT(*) AS copies
FROM user_behavior_dev
GROUP BY user_id, item_id, category_id, behavior, event_ts
HAVING COUNT(*) > 1
ORDER BY copies DESC
LIMIT 20;

-- 9. Top 20 items by behavior event count
SELECT item_id,
       COUNT(*) AS events,
       SUM(behavior = 'pv') AS pv,
       SUM(behavior = 'buy') AS buy_events,
       COUNT(DISTINCT user_id) AS users
FROM user_behavior_dev
GROUP BY item_id
ORDER BY events DESC
LIMIT 20;
