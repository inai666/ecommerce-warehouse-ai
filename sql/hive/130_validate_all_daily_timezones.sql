-- Final timezone regression for 10K, 1M, and user-sequence daily layers.

SELECT 'dwd_10k' AS layer, MIN(dt) AS min_dt, MAX(dt) AS max_dt, COUNT(*) AS row_count
FROM ecommerce_dwd.user_behavior_detail
UNION ALL
SELECT 'dws_10k', MIN(dt), MAX(dt), SUM(event_count)
FROM ecommerce_dws.user_behavior_daily
UNION ALL
SELECT 'ads_10k', MIN(dt), MAX(dt), SUM(event_count)
FROM ecommerce_ads.daily_behavior_dashboard
UNION ALL
SELECT 'dwd_1m', MIN(dt), MAX(dt), COUNT(*)
FROM ecommerce_dwd.user_behavior_detail_1m
UNION ALL
SELECT 'dws_1m', MIN(dt), MAX(dt), SUM(event_count)
FROM ecommerce_dws.user_behavior_daily_1m
UNION ALL
SELECT 'ads_1m', MIN(dt), MAX(dt), SUM(event_count)
FROM ecommerce_ads.daily_behavior_dashboard_1m
UNION ALL
SELECT 'dwd_sequence', MIN(dt), MAX(dt), COUNT(*)
FROM ecommerce_dwd.user_behavior_sequence_detail;

SELECT 'dwd_10k' AS layer, COUNT(*) AS invalid_rows
FROM ecommerce_dwd.user_behavior_detail
WHERE dt < '2017-11-25' OR dt > '2017-12-03'
UNION ALL
SELECT 'dwd_1m', COUNT(*)
FROM ecommerce_dwd.user_behavior_detail_1m
WHERE dt < '2017-11-25' OR dt > '2017-12-03'
UNION ALL
SELECT 'dwd_sequence', COUNT(*)
FROM ecommerce_dwd.user_behavior_sequence_detail
WHERE dt < '2017-11-25' OR dt > '2017-12-03';
