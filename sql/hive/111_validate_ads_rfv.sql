USE ecommerce_ads;

SELECT COUNT(*) AS profile_users,
       MIN(recency_days) AS min_recency,
       MAX(recency_days) AS max_recency,
       SUM(frequency_events) AS profile_events,
       SUM(buy_count) AS profile_buy_events,
       SUM(value_score) AS profile_value_score
FROM user_rfv_profile;

SELECT *
FROM user_rfv_summary
ORDER BY users DESC;

SELECT r_score, f_score, v_score, COUNT(*) AS users
FROM user_rfv_profile
GROUP BY r_score, f_score, v_score
ORDER BY r_score DESC, f_score DESC, v_score DESC;

SELECT COUNT(*) AS invalid_profile_rows
FROM user_rfv_profile
WHERE recency_days < 0
   OR frequency_events <= 0
   OR value_score < frequency_events
   OR r_score NOT IN (1,2,3,4)
   OR f_score NOT IN (1,2,3,4)
   OR v_score NOT IN (1,2,3,4)
   OR segment_name IS NULL;

SELECT user_id, last_active_date, recency_days, frequency_events,
       pv_count, fav_count, cart_count, buy_count, value_score,
       r_score, f_score, v_score, segment_name
FROM user_rfv_profile
ORDER BY value_score DESC, frequency_events DESC
LIMIT 20;

