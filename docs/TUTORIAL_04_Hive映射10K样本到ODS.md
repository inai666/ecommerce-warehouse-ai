# 教程 4：Hive 映射 10K 样本到 ODS

## 目标

把已经上传到 HDFS 的无表头 CSV 映射为 Hive 外部表，并用 MySQL 冒烟结果交叉验证数据是否完整。

本阶段只建立 ODS 原始层。ODS 的职责是忠实保留源数据，因此暂时不删除异常时间、不转换行为枚举，也不去重。

## 输入与表

- HDFS 文件：`/warehouse/ecommerce/ods/raw/user_behavior_10k.csv`
- Hive 数据库：`ecommerce_ods`
- Hive 外部表：`ecommerce_ods.user_behavior_10k`
- CSV 行数：10,000
- CSV 表头：无
- 字段顺序：`user_id,item_id,category_id,behavior,event_ts`

外部表的优势是：删除 Hive 表定义时，不应删除 HDFS 原始 CSV。脚本同时设置了 `external.table.purge=false`，强调保留原始文件。

## 执行顺序

1. 用 `hive -e "SHOW DATABASES;"` 验证 Hive CLI 和 metastore；
2. 将 `sql/hive` 下的两个 SQL 文件上传到 master；
3. 执行 `00_create_ods_10k.sql`；
4. 执行 `01_validate_ods_10k.sql`；
5. 对照 MySQL 的 10K 冒烟基线验收。

## 验收基线

| 检查项 | 预期结果 |
|---|---:|
| 总行数 | 10,000 |
| pv | 8,951 |
| cart | 573 |
| fav | 291 |
| buy | 185 |
| 空值字段 | 全部 0 |
| 非法 behavior | 0 |
| 业务时间范围外记录 | 3 |

如果总行数为 9,999，优先检查是否错误设置为跳过一行表头。本项目的样本没有表头，`skip.header.line.count` 必须为 `0`。

## 为什么不直接转成日期

源文件的第五列是 Unix 秒级时间戳，ODS 使用 `BIGINT` 原样保存。日期转换、时区统一和异常时间隔离将在 DWD 层完成，这能让清洗规则可追踪，也便于回查原始值。

