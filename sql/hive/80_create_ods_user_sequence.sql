-- Tutorial 13: map the user-level sequence sample as an isolated ODS table.

USE ecommerce_ods;

DROP TABLE IF EXISTS user_behavior_sequence_1pct;

CREATE EXTERNAL TABLE user_behavior_sequence_1pct (
  user_id     BIGINT,
  item_id     BIGINT,
  category_id BIGINT,
  behavior    STRING,
  event_ts    BIGINT
)
COMMENT 'Headerless deterministic 1 percent user-level sequence sample'
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/warehouse/ecommerce/ods/user_sequence_1pct'
TBLPROPERTIES (
  'external.table.purge'='false',
  'skip.header.line.count'='0'
);

SHOW CREATE TABLE user_behavior_sequence_1pct;

