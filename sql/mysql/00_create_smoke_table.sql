-- Tutorial 01: create the MySQL smoke-test table.
-- Target: MySQL 5.7, database taobao_ods.

CREATE DATABASE IF NOT EXISTS taobao_ods
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

USE taobao_ods;

CREATE TABLE IF NOT EXISTS user_behavior_smoke (
  row_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'load surrogate key',
  user_id BIGINT NOT NULL COMMENT 'user identifier',
  item_id BIGINT NOT NULL COMMENT 'item identifier',
  category_id BIGINT NOT NULL COMMENT 'category identifier',
  behavior VARCHAR(10) NOT NULL COMMENT 'pv/fav/cart/buy',
  event_ts BIGINT NOT NULL COMMENT 'raw Unix timestamp in seconds',
  source_file VARCHAR(100) NOT NULL DEFAULT 'user_behavior_10k.csv',
  loaded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (row_id),
  KEY idx_user_event_ts (user_id, event_ts),
  KEY idx_behavior_event_ts (behavior, event_ts),
  KEY idx_item_event_ts (item_id, event_ts)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  COMMENT='Tutorial smoke table; preserves raw behavior fields';

SHOW CREATE TABLE user_behavior_smoke;

