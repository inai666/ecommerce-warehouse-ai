-- Tutorial 04: map the headerless 10K CSV in HDFS as a Hive external table.
-- ODS preserves source values; timestamp cleanup belongs in DWD.

CREATE DATABASE IF NOT EXISTS ecommerce_ods
COMMENT 'Raw ODS layer for the ecommerce behavior project'
LOCATION '/warehouse/ecommerce/hive/ods';

USE ecommerce_ods;

DROP TABLE IF EXISTS user_behavior_10k;

CREATE EXTERNAL TABLE user_behavior_10k (
  user_id     BIGINT,
  item_id     BIGINT,
  category_id BIGINT,
  behavior    STRING,
  event_ts    BIGINT
)
COMMENT 'Headerless fixed-seed 10K behavior sample'
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/warehouse/ecommerce/ods/raw'
TBLPROPERTIES (
  'external.table.purge'='false',
  'skip.header.line.count'='0'
);

SHOW CREATE TABLE user_behavior_10k;

