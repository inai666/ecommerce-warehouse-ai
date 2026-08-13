-- Tutorial 02: create a separate 1M development table.
-- Keep user_behavior_smoke (10K) unchanged as the regression baseline.

USE taobao_ods;

CREATE TABLE IF NOT EXISTS user_behavior_dev LIKE user_behavior_smoke;

SHOW CREATE TABLE user_behavior_dev;

