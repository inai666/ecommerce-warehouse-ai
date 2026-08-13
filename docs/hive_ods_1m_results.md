# Hive ODS 1M 验收结果

验收日期：2026-08-12

- ODS 表：`ecommerce_ods.user_behavior_1m`
- HDFS 目录：`/warehouse/ecommerce/ods/dev_1m`
- 总行数：1,000,000
- pv：896,299
- cart：54,940
- fav：28,874
- buy：19,887
- 五字段空值与非法 behavior：全部为 0
- 业务时间范围外：571
- 用户：527,973
- 商品：480,036
- 类目：6,480
- 10K 基线表仍为 10,000 行

结论：1M ODS 已完整映射且与 10K 基线隔离，可以进入独立 DWD 加工。
