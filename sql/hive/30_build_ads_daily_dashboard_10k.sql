-- Tutorial 07: produce dashboard-ready daily indicators from DWS.

CREATE DATABASE IF NOT EXISTS ecommerce_ads
COMMENT 'Application-facing metrics for the ecommerce behavior project'
LOCATION '/warehouse/ecommerce/hive/ads';

USE ecommerce_ads;

CREATE EXTERNAL TABLE IF NOT EXISTS daily_behavior_dashboard (
  event_count       BIGINT,
  active_users      BIGINT,
  active_items      BIGINT,
  active_categories BIGINT,
  pv_count          BIGINT,
  fav_count         BIGINT,
  cart_count        BIGINT,
  buy_count         BIGINT,
  buyer_users       BIGINT,
  events_per_user   DECIMAL(18,4),
  buyer_rate_pct    DECIMAL(18,4),
  pv_share_pct      DECIMAL(18,4),
  fav_share_pct     DECIMAL(18,4),
  cart_share_pct    DECIMAL(18,4),
  buy_share_pct     DECIMAL(18,4)
)
PARTITIONED BY (dt STRING)
STORED AS ORC
LOCATION '/warehouse/ecommerce/ads/daily_behavior_dashboard'
TBLPROPERTIES ('external.table.purge'='false');

SET hive.exec.dynamic.partition=true;
SET hive.exec.dynamic.partition.mode=nonstrict;

ALTER TABLE daily_behavior_dashboard DROP IF EXISTS PARTITION (dt='2017-11-24');

INSERT OVERWRITE TABLE daily_behavior_dashboard PARTITION (dt)
SELECT
  event_count,
  active_users,
  active_items,
  active_categories,
  pv_count,
  fav_count,
  cart_count,
  buy_count,
  buyer_users,
  CAST(CASE WHEN active_users = 0 THEN 0
       ELSE event_count * 1.0 / active_users END AS DECIMAL(18,4)) AS events_per_user,
  CAST(CASE WHEN active_users = 0 THEN 0
       ELSE buyer_users * 100.0 / active_users END AS DECIMAL(18,4)) AS buyer_rate_pct,
  CAST(CASE WHEN event_count = 0 THEN 0
       ELSE pv_count * 100.0 / event_count END AS DECIMAL(18,4)) AS pv_share_pct,
  CAST(CASE WHEN event_count = 0 THEN 0
       ELSE fav_count * 100.0 / event_count END AS DECIMAL(18,4)) AS fav_share_pct,
  CAST(CASE WHEN event_count = 0 THEN 0
       ELSE cart_count * 100.0 / event_count END AS DECIMAL(18,4)) AS cart_share_pct,
  CAST(CASE WHEN event_count = 0 THEN 0
       ELSE buy_count * 100.0 / event_count END AS DECIMAL(18,4)) AS buy_share_pct,
  dt
FROM ecommerce_dws.user_behavior_daily;
