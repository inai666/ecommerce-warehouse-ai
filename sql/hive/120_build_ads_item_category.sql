-- Tutorial 18: item and category performance analysis.

USE ecommerce_ads;

CREATE EXTERNAL TABLE IF NOT EXISTS item_performance (
  item_id          BIGINT,
  category_id      BIGINT,
  event_count      BIGINT,
  active_users     BIGINT,
  pv_count         BIGINT,
  intent_count     BIGINT,
  buy_count        BIGINT,
  buyer_users      BIGINT,
  buy_event_rate_pct DECIMAL(18,4),
  item_tag         STRING
)
STORED AS ORC
LOCATION '/warehouse/ecommerce/ads/item_performance'
TBLPROPERTIES ('external.table.purge'='false');

CREATE EXTERNAL TABLE IF NOT EXISTS category_performance (
  category_id        BIGINT,
  event_count        BIGINT,
  active_users       BIGINT,
  active_items       BIGINT,
  pv_count           BIGINT,
  intent_count       BIGINT,
  buy_count          BIGINT,
  buyer_users        BIGINT,
  buy_event_rate_pct DECIMAL(18,4)
)
STORED AS ORC
LOCATION '/warehouse/ecommerce/ads/category_performance'
TBLPROPERTIES ('external.table.purge'='false');

INSERT OVERWRITE TABLE item_performance
SELECT
  item_id,
  MAX(category_id) AS category_id,
  COUNT(*) AS event_count,
  COUNT(DISTINCT user_id) AS active_users,
  SUM(CASE WHEN behavior = 'pv' THEN 1 ELSE 0 END) AS pv_count,
  SUM(CASE WHEN behavior IN ('fav', 'cart') THEN 1 ELSE 0 END) AS intent_count,
  SUM(CASE WHEN behavior = 'buy' THEN 1 ELSE 0 END) AS buy_count,
  COUNT(DISTINCT CASE WHEN behavior = 'buy' THEN user_id END) AS buyer_users,
  CAST(SUM(CASE WHEN behavior = 'buy' THEN 1 ELSE 0 END) * 100.0 / COUNT(*)
       AS DECIMAL(18,4)) AS buy_event_rate_pct,
  CASE
    WHEN SUM(CASE WHEN behavior = 'pv' THEN 1 ELSE 0 END) >= 20
      AND SUM(CASE WHEN behavior = 'buy' THEN 1 ELSE 0 END) = 0
      THEN 'HIGH_TRAFFIC_NO_BUY'
    WHEN SUM(CASE WHEN behavior = 'buy' THEN 1 ELSE 0 END) >= 5
      THEN 'TOP_SELLER'
    ELSE 'NORMAL'
  END AS item_tag
FROM ecommerce_dwd.user_behavior_sequence_detail
GROUP BY item_id;

INSERT OVERWRITE TABLE category_performance
SELECT
  category_id,
  COUNT(*) AS event_count,
  COUNT(DISTINCT user_id) AS active_users,
  COUNT(DISTINCT item_id) AS active_items,
  SUM(CASE WHEN behavior = 'pv' THEN 1 ELSE 0 END) AS pv_count,
  SUM(CASE WHEN behavior IN ('fav', 'cart') THEN 1 ELSE 0 END) AS intent_count,
  SUM(CASE WHEN behavior = 'buy' THEN 1 ELSE 0 END) AS buy_count,
  COUNT(DISTINCT CASE WHEN behavior = 'buy' THEN user_id END) AS buyer_users,
  CAST(SUM(CASE WHEN behavior = 'buy' THEN 1 ELSE 0 END) * 100.0 / COUNT(*)
       AS DECIMAL(18,4)) AS buy_event_rate_pct
FROM ecommerce_dwd.user_behavior_sequence_detail
GROUP BY category_id;

