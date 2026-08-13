-- Tutorial 10 acceptance checks.

SELECT COUNT(*) AS daily_rows,
       MIN(dt) AS min_dt,
       MAX(dt) AS max_dt
FROM ecommerce_dws.user_behavior_daily_1m;

SELECT
  dt,
  event_count,
  active_users,
  active_items,
  active_categories,
  pv_count,
  fav_count,
  cart_count,
  buy_count,
  buyer_users
FROM ecommerce_dws.user_behavior_daily_1m
ORDER BY dt;

SELECT
  dws_events,
  dwd_events,
  dws_events - dwd_events AS event_gap,
  pv_count,
  fav_count,
  cart_count,
  buy_count
FROM
  (
    SELECT
      SUM(event_count) AS dws_events,
      SUM(pv_count) AS pv_count,
      SUM(fav_count) AS fav_count,
      SUM(cart_count) AS cart_count,
      SUM(buy_count) AS buy_count
    FROM ecommerce_dws.user_behavior_daily_1m
  ) s
CROSS JOIN
  (SELECT COUNT(*) AS dwd_events FROM ecommerce_dwd.user_behavior_detail_1m) d;

SELECT
  dt,
  event_count - (pv_count + fav_count + cart_count + buy_count) AS behavior_gap
FROM ecommerce_dws.user_behavior_daily_1m
ORDER BY dt;

-- 10K regression table must remain unchanged.
SELECT COUNT(*) AS baseline_10k_daily_rows,
       SUM(event_count) AS baseline_10k_events
FROM ecommerce_dws.user_behavior_daily;

SHOW PARTITIONS ecommerce_dws.user_behavior_daily_1m;

