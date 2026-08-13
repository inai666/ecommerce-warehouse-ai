-- Tutorial 07 acceptance checks.

-- 1. Coverage: one row per valid business date.
SELECT COUNT(*) AS dashboard_rows,
       MIN(dt) AS min_dt,
       MAX(dt) AS max_dt
FROM ecommerce_ads.daily_behavior_dashboard;

-- 2. Dashboard output ordered by date.
SELECT
  dt,
  event_count,
  active_users,
  events_per_user,
  buyer_users,
  buyer_rate_pct,
  pv_share_pct,
  fav_share_pct,
  cart_share_pct,
  buy_share_pct
FROM ecommerce_ads.daily_behavior_dashboard
ORDER BY dt;

-- 3. All rates must stay in meaningful numeric ranges.
SELECT COUNT(*) AS invalid_rate_rows
FROM ecommerce_ads.daily_behavior_dashboard
WHERE events_per_user < 0
   OR buyer_rate_pct < 0 OR buyer_rate_pct > 100
   OR pv_share_pct < 0 OR pv_share_pct > 100
   OR fav_share_pct < 0 OR fav_share_pct > 100
   OR cart_share_pct < 0 OR cart_share_pct > 100
   OR buy_share_pct < 0 OR buy_share_pct > 100;

-- 4. Behavior shares should add to approximately 100% after rounding.
SELECT
  dt,
  CAST(pv_share_pct + fav_share_pct + cart_share_pct + buy_share_pct
       AS DECIMAL(18,4)) AS behavior_share_sum,
  ABS(CAST(pv_share_pct + fav_share_pct + cart_share_pct + buy_share_pct
       AS DECIMAL(18,4)) - 100.0000) AS share_gap
FROM ecommerce_ads.daily_behavior_dashboard
ORDER BY dt;

-- 5. Rank dates by purchasing-user rate; this is descriptive, not a strict funnel.
SELECT dt, active_users, buyer_users, buyer_rate_pct
FROM ecommerce_ads.daily_behavior_dashboard
ORDER BY buyer_rate_pct DESC, dt
LIMIT 3;

SHOW PARTITIONS ecommerce_ads.daily_behavior_dashboard;

