-- Tutorial 06 acceptance checks.

-- 1. Exactly one summary row per business date.
SELECT COUNT(*) AS daily_rows,
       MIN(dt) AS min_dt,
       MAX(dt) AS max_dt
FROM ecommerce_dws.user_behavior_daily;

-- 2. Daily metrics.
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
FROM ecommerce_dws.user_behavior_daily
ORDER BY dt;

-- 3. DWS totals must reconcile to the DWD detail layer.
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
    FROM ecommerce_dws.user_behavior_daily
  ) s
CROSS JOIN
  (SELECT COUNT(*) AS dwd_events FROM ecommerce_dwd.user_behavior_detail) d;

-- 4. Internal arithmetic must hold for every date.
SELECT
  dt,
  event_count,
  pv_count + fav_count + cart_count + buy_count AS behavior_sum,
  event_count - (pv_count + fav_count + cart_count + buy_count) AS behavior_gap
FROM ecommerce_dws.user_behavior_daily
ORDER BY dt;

-- 5. Confirm all date partitions are registered.
SHOW PARTITIONS ecommerce_dws.user_behavior_daily;

