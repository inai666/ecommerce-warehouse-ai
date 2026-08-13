-- Performance fix for Tutorial 02 exploration queries.
-- Run once after user_behavior_dev has been created and loaded.

USE taobao_ods;

ALTER TABLE user_behavior_dev
  ADD KEY idx_behavior_user (behavior, user_id);

SHOW INDEX FROM user_behavior_dev;

