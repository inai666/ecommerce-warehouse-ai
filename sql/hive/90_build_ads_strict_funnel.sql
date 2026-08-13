-- Tutorial 15: strict funnel at user + item grain.
-- A later step must have event_ts >= the previous step's timestamp.

CREATE DATABASE IF NOT EXISTS ecommerce_ads;
USE ecommerce_ads;

CREATE EXTERNAL TABLE IF NOT EXISTS user_item_funnel_stage (
  user_id             BIGINT,
  item_id             BIGINT,
  first_pv_ts         BIGINT,
  first_intent_ts     BIGINT,
  first_buy_ts        BIGINT,
  has_pv              INT,
  has_intent_after_pv INT,
  has_buy_after_intent INT,
  pv_time             STRING,
  intent_time         STRING,
  buy_time            STRING
)
STORED AS ORC
LOCATION '/warehouse/ecommerce/ads/user_item_funnel_stage'
TBLPROPERTIES ('external.table.purge'='false');

CREATE EXTERNAL TABLE IF NOT EXISTS strict_funnel_summary (
  pv_pairs             BIGINT,
  intent_pairs         BIGINT,
  buy_pairs            BIGINT,
  pv_users             BIGINT,
  intent_users         BIGINT,
  buy_users            BIGINT,
  pv_to_intent_pct     DECIMAL(18,4),
  intent_to_buy_pct    DECIMAL(18,4),
  pv_to_buy_pct        DECIMAL(18,4)
)
STORED AS ORC
LOCATION '/warehouse/ecommerce/ads/strict_funnel_summary'
TBLPROPERTIES ('external.table.purge'='false');

-- Build the first PV per user-item pair.
WITH first_pv AS (
  SELECT user_id, item_id, MIN(event_ts) AS first_pv_ts
  FROM ecommerce_dwd.user_behavior_sequence_detail
  WHERE behavior = 'pv'
  GROUP BY user_id, item_id
),
-- Find the earliest intent event after (or at) the first PV.
first_intent AS (
  SELECT p.user_id, p.item_id, p.first_pv_ts,
         MIN(d.event_ts) AS first_intent_ts
  FROM first_pv p
  JOIN ecommerce_dwd.user_behavior_sequence_detail d
    ON d.user_id = p.user_id
   AND d.item_id = p.item_id
   AND d.behavior IN ('fav', 'cart')
   AND d.event_ts >= p.first_pv_ts
  GROUP BY p.user_id, p.item_id, p.first_pv_ts
),
first_buy AS (
  SELECT i.user_id, i.item_id, i.first_pv_ts, i.first_intent_ts,
         MIN(d.event_ts) AS first_buy_ts
  FROM first_intent i
  JOIN ecommerce_dwd.user_behavior_sequence_detail d
    ON d.user_id = i.user_id
   AND d.item_id = i.item_id
   AND d.behavior = 'buy'
   AND d.event_ts >= i.first_intent_ts
  GROUP BY i.user_id, i.item_id, i.first_pv_ts, i.first_intent_ts
)
INSERT OVERWRITE TABLE user_item_funnel_stage
SELECT
  p.user_id,
  p.item_id,
  p.first_pv_ts,
  i.first_intent_ts,
  b.first_buy_ts,
  1 AS has_pv,
  CASE WHEN i.first_intent_ts IS NULL THEN 0 ELSE 1 END AS has_intent_after_pv,
  CASE WHEN b.first_buy_ts IS NULL THEN 0 ELSE 1 END AS has_buy_after_intent,
  CAST(from_utc_timestamp(p.first_pv_ts * 1000, 'Asia/Shanghai') AS STRING) AS pv_time,
  CASE WHEN i.first_intent_ts IS NULL THEN NULL
       ELSE CAST(from_utc_timestamp(i.first_intent_ts * 1000, 'Asia/Shanghai') AS STRING) END AS intent_time,
  CASE WHEN b.first_buy_ts IS NULL THEN NULL
       ELSE CAST(from_utc_timestamp(b.first_buy_ts * 1000, 'Asia/Shanghai') AS STRING) END AS buy_time
FROM first_pv p
LEFT JOIN first_intent i ON i.user_id = p.user_id AND i.item_id = p.item_id
LEFT JOIN first_buy b ON b.user_id = p.user_id AND b.item_id = p.item_id;

INSERT OVERWRITE TABLE strict_funnel_summary
SELECT
  COUNT(*) AS pv_pairs,
  SUM(has_intent_after_pv) AS intent_pairs,
  SUM(has_buy_after_intent) AS buy_pairs,
  COUNT(DISTINCT user_id) AS pv_users,
  COUNT(DISTINCT CASE WHEN has_intent_after_pv = 1 THEN user_id END) AS intent_users,
  COUNT(DISTINCT CASE WHEN has_buy_after_intent = 1 THEN user_id END) AS buy_users,
  CAST(SUM(has_intent_after_pv) * 100.0 / COUNT(*) AS DECIMAL(18,4)) AS pv_to_intent_pct,
  CAST(SUM(has_buy_after_intent) * 100.0 / SUM(has_intent_after_pv) AS DECIMAL(18,4)) AS intent_to_buy_pct,
  CAST(SUM(has_buy_after_intent) * 100.0 / COUNT(*) AS DECIMAL(18,4)) AS pv_to_buy_pct
FROM user_item_funnel_stage;
