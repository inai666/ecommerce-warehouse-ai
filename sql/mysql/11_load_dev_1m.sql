-- Run 10_create_dev_table.sql first.
-- This replaces only the development table; the 10K smoke table is untouched.

USE taobao_ods;

TRUNCATE TABLE user_behavior_dev;

LOAD DATA LOCAL INFILE 'C:/job1/ecommerce-warehouse-ai/data/sample/user_behavior_1m.csv'
INTO TABLE user_behavior_dev
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
(user_id, item_id, category_id, behavior, @raw_event_ts)
SET event_ts = CAST(TRIM(TRAILING '\r' FROM @raw_event_ts) AS SIGNED),
    source_file = 'user_behavior_1m.csv';

SELECT ROW_COUNT() AS imported_rows;

