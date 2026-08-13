# Hive ODS 10K 验收结果

验收日期：2026-08-12

- 数据库：`ecommerce_ods`
- 外部表：`user_behavior_10k`
- HDFS 源路径：`/warehouse/ecommerce/ods/raw`
- 总行数：10,000
- pv：8,951
- cart：573
- fav：291
- buy：185
- 五字段空值：全部为 0
- 非法 behavior：0
- 业务时间范围外记录：3
- 与 MySQL 10K 冒烟基线一致

结论：无表头 CSV 已无损映射为 Hive ODS 外部表，可以进入 DWD 清洗与异常隔离。
