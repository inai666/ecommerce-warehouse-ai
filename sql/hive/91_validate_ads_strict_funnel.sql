USE ecommerce_ads;

SELECT * FROM strict_funnel_summary;

-- Stage counts must be monotonic: PV >= intent >= buy.
SELECT
  pv_pairs,
  intent_pairs,
  buy_pairs,
  pv_pairs - intent_pairs AS pv_intent_gap,
  intent_pairs - buy_pairs AS intent_buy_gap
FROM strict_funnel_summary;

-- No stage can have a timestamp earlier than its predecessor.
SELECT COUNT(*) AS invalid_sequence_rows
FROM user_item_funnel_stage
WHERE (has_intent_after_pv = 1 AND intent_time < pv_time)
   OR (has_buy_after_intent = 1 AND buy_time < intent_time);

-- Inspect successful complete paths.
SELECT user_id, item_id, pv_time, intent_time, buy_time
FROM user_item_funnel_stage
WHERE has_buy_after_intent = 1
ORDER BY buy_time
LIMIT 20;

-- Inspect stage loss counts.
SELECT has_pv, has_intent_after_pv, has_buy_after_intent, COUNT(*) AS pairs
FROM user_item_funnel_stage
GROUP BY has_pv, has_intent_after_pv, has_buy_after_intent
ORDER BY has_pv DESC, has_intent_after_pv DESC, has_buy_after_intent DESC;

