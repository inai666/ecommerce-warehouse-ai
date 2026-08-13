-- Tutorial 08: map the isolated headerless 1M CSV as a Hive ODS external table.

USE ecommerce_ods;

DROP TABLE IF EXISTS user_behavior_1m;

CREATE EXTERNAL TABLE user_behavior_1m (
  user_id     BIGINT,
  item_id     BIGINT,
  category_id BIGINT,
  behavior    STRING,
  event_ts    BIGINT
)
COMMENT 'Headerless fixed-seed 1M development sample'
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/warehouse/ecommerce/ods/dev_1m'
TBLPROPERTIES (
  'external.table.purge'='false',
  'skip.header.line.count'='0'
);

SHOW CREATE TABLE user_behavior_1m;

