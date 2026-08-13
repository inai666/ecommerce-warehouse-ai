USE ecommerce_ads;

SELECT COUNT(*) AS item_rows,
       SUM(event_count) AS item_events,
       SUM(pv_count) AS item_pv,
       SUM(intent_count) AS item_intent,
       SUM(buy_count) AS item_buy
FROM item_performance;

SELECT COUNT(*) AS category_rows,
       SUM(event_count) AS category_events,
       SUM(pv_count) AS category_pv,
       SUM(intent_count) AS category_intent,
       SUM(buy_count) AS category_buy
FROM category_performance;

SELECT item_tag, COUNT(*) AS items
FROM item_performance
GROUP BY item_tag
ORDER BY items DESC;

-- Highest traffic items.
SELECT item_id, category_id, event_count, active_users, pv_count,
       intent_count, buy_count, buyer_users, buy_event_rate_pct, item_tag
FROM item_performance
ORDER BY event_count DESC, item_id
LIMIT 20;

-- Best sellers by purchase events, with traffic context.
SELECT item_id, category_id, event_count, active_users, pv_count,
       intent_count, buy_count, buyer_users, buy_event_rate_pct
FROM item_performance
WHERE buy_count > 0
ORDER BY buy_count DESC, buyer_users DESC, item_id
LIMIT 20;

-- High-traffic items with no purchases: candidates for investigation, not proof of a defect.
SELECT item_id, category_id, event_count, active_users, pv_count,
       intent_count, buy_count, item_tag
FROM item_performance
WHERE item_tag = 'HIGH_TRAFFIC_NO_BUY'
ORDER BY pv_count DESC, item_id
LIMIT 20;

-- Category ranking.
SELECT category_id, event_count, active_users, active_items,
       pv_count, intent_count, buy_count, buyer_users, buy_event_rate_pct
FROM category_performance
ORDER BY buy_count DESC, event_count DESC
LIMIT 20;

SELECT COUNT(*) AS invalid_metric_rows
FROM item_performance
WHERE event_count <> pv_count + intent_count + buy_count
   OR buy_event_rate_pct < 0 OR buy_event_rate_pct > 100;

