#!/usr/bin/env bash
set -euo pipefail

OUTPUT_DIR="/home/hadoop/ecommerce_dashboard_exports"
LOG_FILE="${OUTPUT_DIR}/hive_export.log"

mkdir -p "${OUTPUT_DIR}"
: > "${LOG_FILE}"

export_query() {
  local name="$1"
  local expected_columns="$2"
  local sql="$3"
  local raw_file="${OUTPUT_DIR}/${name}.raw"
  hive --hiveconf hive.root.logger=ERROR,console -S -e \
    "set hive.cli.print.header=true; set hive.resultset.use.unique.column.names=false; ${sql}" \
    > "${raw_file}" 2>> "${LOG_FILE}"
  awk -F '\t' -v expected="${expected_columns}" 'NF == expected' "${raw_file}" \
    > "${OUTPUT_DIR}/${name}.tsv"
  rm -f "${raw_file}"
  echo "exported ${name}.tsv"
}

export_query "daily_dashboard" 16 "
SELECT dt, event_count, active_users, active_items, active_categories,
       pv_count, fav_count, cart_count, buy_count, buyer_users,
       events_per_user, buyer_rate_pct, pv_share_pct, fav_share_pct,
       cart_share_pct, buy_share_pct
FROM ecommerce_ads.daily_behavior_dashboard_1m
ORDER BY dt;
"

export_query "retention" 11 "
SELECT cohort_date, cohort_users, day_0_users, day_1_users, day_2_users,
       day_3_users, day_7_users, day_1_retention_pct,
       day_2_retention_pct, day_3_retention_pct, day_7_retention_pct
FROM ecommerce_ads.user_retention_summary
ORDER BY cohort_date;
"

export_query "rfv_summary" 6 "
SELECT segment_name, users, avg_recency_days, avg_frequency,
       avg_value_score, total_buy_events
FROM ecommerce_ads.user_rfv_summary
ORDER BY users DESC;
"

export_query "strict_funnel" 9 "
SELECT pv_pairs, intent_pairs, buy_pairs, pv_users, intent_users, buy_users,
       pv_to_intent_pct, intent_to_buy_pct, pv_to_buy_pct
FROM ecommerce_ads.strict_funnel_summary;
"

export_query "top_items" 10 "
SELECT item_id, category_id, event_count, active_users, pv_count,
       intent_count, buy_count, buyer_users, buy_event_rate_pct, item_tag
FROM ecommerce_ads.item_performance
ORDER BY buy_count DESC, buyer_users DESC, item_id
LIMIT 20;
"

export_query "high_traffic_no_buy" 10 "
SELECT item_id, category_id, event_count, active_users, pv_count,
       intent_count, buy_count, buyer_users, buy_event_rate_pct, item_tag
FROM ecommerce_ads.item_performance
WHERE item_tag = 'HIGH_TRAFFIC_NO_BUY'
ORDER BY pv_count DESC, item_id
LIMIT 20;
"

export_query "top_categories" 9 "
SELECT category_id, event_count, active_users, active_items, pv_count,
       intent_count, buy_count, buyer_users, buy_event_rate_pct
FROM ecommerce_ads.category_performance
ORDER BY buy_count DESC, event_count DESC
LIMIT 20;
"

echo "===== EXPORT FILES ====="
wc -l "${OUTPUT_DIR}"/*.tsv
echo "===== FILE HEADERS ====="
for file in "${OUTPUT_DIR}"/*.tsv; do
  printf '%s: ' "$(basename "${file}")"
  head -n 1 "${file}"
done
echo "===== EXPECTED LINE COUNTS (INCLUDING HEADER) ====="
echo "daily_dashboard.tsv=10"
echo "retention.tsv=8"
echo "rfv_summary.tsv=6"
echo "strict_funnel.tsv=2"
echo "top_items.tsv=21"
echo "high_traffic_no_buy.tsv=21"
echo "top_categories.tsv=21"
echo "Dashboard data exported to ${OUTPUT_DIR}"
