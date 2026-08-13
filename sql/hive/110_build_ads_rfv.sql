-- Tutorial 17: RFV user segmentation without a monetary field.

USE ecommerce_ads;

CREATE EXTERNAL TABLE IF NOT EXISTS user_rfv_profile (
  user_id          BIGINT,
  last_active_date STRING,
  recency_days     INT,
  frequency_events BIGINT,
  pv_count         BIGINT,
  fav_count        BIGINT,
  cart_count       BIGINT,
  buy_count        BIGINT,
  value_score      BIGINT,
  r_score          INT,
  f_score          INT,
  v_score          INT,
  segment_name     STRING
)
STORED AS ORC
LOCATION '/warehouse/ecommerce/ads/user_rfv_profile'
TBLPROPERTIES ('external.table.purge'='false');

CREATE EXTERNAL TABLE IF NOT EXISTS user_rfv_summary (
  segment_name       STRING,
  users              BIGINT,
  avg_recency_days   DECIMAL(18,4),
  avg_frequency      DECIMAL(18,4),
  avg_value_score    DECIMAL(18,4),
  total_buy_events   BIGINT
)
STORED AS ORC
LOCATION '/warehouse/ecommerce/ads/user_rfv_summary'
TBLPROPERTIES ('external.table.purge'='false');

INSERT OVERWRITE TABLE user_rfv_profile
SELECT
  user_id,
  last_active_date,
  datediff('2017-12-04', last_active_date) AS recency_days,
  frequency_events,
  pv_count,
  fav_count,
  cart_count,
  buy_count,
  value_score,
  CASE
    WHEN datediff('2017-12-04', last_active_date) <= 1 THEN 4
    WHEN datediff('2017-12-04', last_active_date) = 2 THEN 3
    WHEN datediff('2017-12-04', last_active_date) = 3 THEN 2
    ELSE 1
  END AS r_score,
  CASE
    WHEN frequency_events >= 155 THEN 4
    WHEN frequency_events >= 74 THEN 3
    WHEN frequency_events >= 32 THEN 2
    ELSE 1
  END AS f_score,
  CASE
    WHEN value_score >= 188 THEN 4
    WHEN value_score >= 93 THEN 3
    WHEN value_score >= 42 THEN 2
    ELSE 1
  END AS v_score,
  CASE
    WHEN buy_count >= 1
      AND datediff('2017-12-04', last_active_date) <= 2
      AND frequency_events >= 74
      AND value_score >= 93 THEN 'CORE_VALUE'
    WHEN buy_count >= 1
      AND datediff('2017-12-04', last_active_date) <= 3 THEN 'ACTIVE_BUYER'
    WHEN buy_count = 0
      AND (fav_count + cart_count) >= 1 THEN 'HIGH_INTENT_NON_BUYER'
    WHEN datediff('2017-12-04', last_active_date) >= 4 THEN 'AT_RISK'
    ELSE 'GENERAL_ACTIVE'
  END AS segment_name
FROM (
  SELECT
    user_id,
    MAX(dt) AS last_active_date,
    COUNT(*) AS frequency_events,
    SUM(CASE WHEN behavior = 'pv' THEN 1 ELSE 0 END) AS pv_count,
    SUM(CASE WHEN behavior = 'fav' THEN 1 ELSE 0 END) AS fav_count,
    SUM(CASE WHEN behavior = 'cart' THEN 1 ELSE 0 END) AS cart_count,
    SUM(CASE WHEN behavior = 'buy' THEN 1 ELSE 0 END) AS buy_count,
    SUM(CASE behavior
          WHEN 'pv' THEN 1
          WHEN 'fav' THEN 2
          WHEN 'cart' THEN 3
          WHEN 'buy' THEN 5
          ELSE 0 END) AS value_score
  FROM ecommerce_dwd.user_behavior_sequence_detail
  GROUP BY user_id
) u;

INSERT OVERWRITE TABLE user_rfv_summary
SELECT
  segment_name,
  COUNT(*) AS users,
  CAST(AVG(recency_days) AS DECIMAL(18,4)) AS avg_recency_days,
  CAST(AVG(frequency_events) AS DECIMAL(18,4)) AS avg_frequency,
  CAST(AVG(value_score) AS DECIMAL(18,4)) AS avg_value_score,
  SUM(buy_count) AS total_buy_events
FROM user_rfv_profile
GROUP BY segment_name;

