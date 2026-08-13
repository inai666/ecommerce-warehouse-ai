-- Tutorial 06: aggregate valid DWD events into daily DWS metrics.

CREATE DATABASE IF NOT EXISTS ecommerce_dws
COMMENT 'Reusable summary layer for the ecommerce behavior project'
LOCATION '/warehouse/ecommerce/hive/dws';

USE ecommerce_dws;

CREATE EXTERNAL TABLE IF NOT EXISTS user_behavior_daily (
  event_count     BIGINT,
  active_users    BIGINT,
  active_items    BIGINT,
  active_categories BIGINT,
  pv_count        BIGINT,
  fav_count       BIGINT,
  cart_count      BIGINT,
  buy_count       BIGINT,
  buyer_users     BIGINT
)
PARTITIONED BY (dt STRING)
STORED AS ORC
LOCATION '/warehouse/ecommerce/dws/user_behavior_daily'
TBLPROPERTIES ('external.table.purge'='false');

SET hive.exec.dynamic.partition=true;
SET hive.exec.dynamic.partition.mode=nonstrict;

ALTER TABLE user_behavior_daily DROP IF EXISTS PARTITION (dt='2017-11-24');

INSERT OVERWRITE TABLE user_behavior_daily PARTITION (dt)
SELECT
  COUNT(*) AS event_count,
  COUNT(DISTINCT user_id) AS active_users,
  COUNT(DISTINCT item_id) AS active_items,
  COUNT(DISTINCT category_id) AS active_categories,
  SUM(CASE WHEN behavior = 'pv' THEN 1 ELSE 0 END) AS pv_count,
  SUM(CASE WHEN behavior = 'fav' THEN 1 ELSE 0 END) AS fav_count,
  SUM(CASE WHEN behavior = 'cart' THEN 1 ELSE 0 END) AS cart_count,
  SUM(CASE WHEN behavior = 'buy' THEN 1 ELSE 0 END) AS buy_count,
  COUNT(DISTINCT CASE WHEN behavior = 'buy' THEN user_id END) AS buyer_users,
  dt
FROM ecommerce_dwd.user_behavior_detail
GROUP BY dt;
