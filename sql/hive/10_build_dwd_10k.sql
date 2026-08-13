-- Tutorial 05: clean the 10K ODS sample into valid DWD data and quarantine.

CREATE DATABASE IF NOT EXISTS ecommerce_dwd
COMMENT 'Clean detail layer for the ecommerce behavior project'
LOCATION '/warehouse/ecommerce/hive/dwd';

USE ecommerce_dwd;

CREATE EXTERNAL TABLE IF NOT EXISTS user_behavior_detail (
  user_id     BIGINT,
  item_id     BIGINT,
  category_id BIGINT,
  behavior    STRING,
  event_ts    BIGINT,
  event_time  STRING
)
PARTITIONED BY (dt STRING)
STORED AS ORC
LOCATION '/warehouse/ecommerce/dwd/user_behavior_detail'
TBLPROPERTIES ('external.table.purge'='false');

CREATE EXTERNAL TABLE IF NOT EXISTS user_behavior_quarantine (
  user_id        BIGINT,
  item_id        BIGINT,
  category_id    BIGINT,
  behavior       STRING,
  event_ts       BIGINT,
  reject_reason  STRING
)
STORED AS ORC
LOCATION '/warehouse/ecommerce/dwd/user_behavior_quarantine'
TBLPROPERTIES ('external.table.purge'='false');

SET hive.exec.dynamic.partition=true;
SET hive.exec.dynamic.partition.mode=nonstrict;

ALTER TABLE user_behavior_detail DROP IF EXISTS PARTITION (dt='2017-11-24');

-- INSERT OVERWRITE replaces this fixed sample's date partitions and quarantine output.
INSERT OVERWRITE TABLE user_behavior_detail PARTITION (dt)
SELECT
  user_id,
  item_id,
  category_id,
  behavior,
  event_ts,
  CAST(from_utc_timestamp(event_ts * 1000, 'Asia/Shanghai') AS STRING) AS event_time,
  date_format(from_utc_timestamp(event_ts * 1000, 'Asia/Shanghai'), 'yyyy-MM-dd') AS dt
FROM ecommerce_ods.user_behavior_10k
WHERE user_id IS NOT NULL
  AND item_id IS NOT NULL
  AND category_id IS NOT NULL
  AND behavior IN ('pv', 'fav', 'cart', 'buy')
  AND event_ts >= 1511539200
  AND event_ts < 1512316800;

INSERT OVERWRITE TABLE user_behavior_quarantine
SELECT
  user_id,
  item_id,
  category_id,
  behavior,
  event_ts,
  CASE
    WHEN user_id IS NULL OR item_id IS NULL OR category_id IS NULL THEN 'NULL_BUSINESS_KEY'
    WHEN behavior IS NULL OR behavior NOT IN ('pv', 'fav', 'cart', 'buy') THEN 'INVALID_BEHAVIOR'
    WHEN event_ts IS NULL THEN 'NULL_EVENT_TS'
    WHEN event_ts < 1511539200 THEN 'EVENT_TIME_BEFORE_RANGE'
    WHEN event_ts >= 1512316800 THEN 'EVENT_TIME_AFTER_RANGE'
    ELSE 'UNKNOWN'
  END AS reject_reason
FROM ecommerce_ods.user_behavior_10k
WHERE user_id IS NULL
   OR item_id IS NULL
   OR category_id IS NULL
   OR behavior IS NULL
   OR behavior NOT IN ('pv', 'fav', 'cart', 'buy')
   OR event_ts IS NULL
   OR event_ts < 1511539200
   OR event_ts >= 1512316800;
