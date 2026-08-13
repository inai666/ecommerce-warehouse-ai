-- Tutorial 16: user retention by first active day (user-level sequence sample).

CREATE DATABASE IF NOT EXISTS ecommerce_ads;
USE ecommerce_ads;

CREATE EXTERNAL TABLE IF NOT EXISTS user_retention_stage (
  user_id       BIGINT,
  cohort_date   STRING,
  active_date   STRING,
  day_number    INT
)
STORED AS ORC
LOCATION '/warehouse/ecommerce/ads/user_retention_stage'
TBLPROPERTIES ('external.table.purge'='false');

CREATE EXTERNAL TABLE IF NOT EXISTS user_retention_summary (
  cohort_date          STRING,
  cohort_users          BIGINT,
  day_0_users          BIGINT,
  day_1_users          BIGINT,
  day_2_users          BIGINT,
  day_3_users          BIGINT,
  day_7_users          BIGINT,
  day_1_retention_pct  DECIMAL(18,4),
  day_2_retention_pct  DECIMAL(18,4),
  day_3_retention_pct  DECIMAL(18,4),
  day_7_retention_pct  DECIMAL(18,4)
)
STORED AS ORC
LOCATION '/warehouse/ecommerce/ads/user_retention_summary'
TBLPROPERTIES ('external.table.purge'='false');

-- Deduplicate to one user/date before calculating date differences.
INSERT OVERWRITE TABLE user_retention_stage
SELECT
  d.user_id,
  c.cohort_date,
  d.active_date,
  datediff(d.active_date, c.cohort_date) AS day_number
FROM
  (
    SELECT DISTINCT user_id, dt AS active_date
    FROM ecommerce_dwd.user_behavior_sequence_detail
  ) d
JOIN
  (
    SELECT user_id, MIN(active_date) AS cohort_date
    FROM
      (
        SELECT DISTINCT user_id, dt AS active_date
        FROM ecommerce_dwd.user_behavior_sequence_detail
      ) ud
    GROUP BY user_id
  ) c
ON c.user_id = d.user_id;

INSERT OVERWRITE TABLE user_retention_summary
SELECT
  cohort_date,
  COUNT(DISTINCT CASE WHEN day_number = 0 THEN user_id END) AS cohort_users,
  COUNT(DISTINCT CASE WHEN day_number = 0 THEN user_id END) AS day_0_users,
  COUNT(DISTINCT CASE WHEN day_number = 1 THEN user_id END) AS day_1_users,
  COUNT(DISTINCT CASE WHEN day_number = 2 THEN user_id END) AS day_2_users,
  COUNT(DISTINCT CASE WHEN day_number = 3 THEN user_id END) AS day_3_users,
  COUNT(DISTINCT CASE WHEN day_number = 7 THEN user_id END) AS day_7_users,
  CAST(COUNT(DISTINCT CASE WHEN day_number = 1 THEN user_id END) * 100.0 /
       COUNT(DISTINCT CASE WHEN day_number = 0 THEN user_id END) AS DECIMAL(18,4)),
  CAST(COUNT(DISTINCT CASE WHEN day_number = 2 THEN user_id END) * 100.0 /
       COUNT(DISTINCT CASE WHEN day_number = 0 THEN user_id END) AS DECIMAL(18,4)),
  CAST(COUNT(DISTINCT CASE WHEN day_number = 3 THEN user_id END) * 100.0 /
       COUNT(DISTINCT CASE WHEN day_number = 0 THEN user_id END) AS DECIMAL(18,4)),
  CAST(COUNT(DISTINCT CASE WHEN day_number = 7 THEN user_id END) * 100.0 /
       COUNT(DISTINCT CASE WHEN day_number = 0 THEN user_id END) AS DECIMAL(18,4))
FROM user_retention_stage
GROUP BY cohort_date;
