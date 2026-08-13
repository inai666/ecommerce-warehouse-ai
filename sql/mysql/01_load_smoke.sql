-- Run 00_create_smoke_table.sql first.
-- LOCAL reads the file from the Workbench/client computer.

USE taobao_ods;

TRUNCATE TABLE user_behavior_smoke;

LOAD DATA LOCAL INFILE 'C:/job1/ecommerce-warehouse-ai/data/sample/user_behavior_10k.csv'
INTO TABLE user_behavior_smoke
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
(user_id, item_id, category_id, behavior, @raw_event_ts)
SET event_ts = CAST(TRIM(TRAILING '\r' FROM @raw_event_ts) AS SIGNED),
    source_file = 'user_behavior_10k.csv';

SELECT ROW_COUNT() AS imported_rows;

