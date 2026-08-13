# 教程 8：扩容到 100 万行开发样本

## 目标

把已经在 10K 样本上验证过的数仓流程提升到固定随机 100 万行样本，观察数据量增加后的任务时间、YARN 执行和 ORC 存储效果。

10K 全链路继续保留作为回归基线，不覆盖、不删除。

## 隔离原则

100 万行必须使用独立路径和表：

| 层级 | 10K 基线 | 1M 开发样本 |
|---|---|---|
| ODS HDFS | `/warehouse/ecommerce/ods/raw` | `/warehouse/ecommerce/ods/dev_1m` |
| ODS 表 | `user_behavior_10k` | `user_behavior_1m` |
| DWD 表 | `user_behavior_detail` | `user_behavior_detail_1m` |
| 异常表 | `user_behavior_quarantine` | `user_behavior_quarantine_1m` |
| DWS 表 | `user_behavior_daily` | `user_behavior_daily_1m` |
| ADS 表 | `daily_behavior_dashboard` | `daily_behavior_dashboard_1m` |

不能把 `user_behavior_1m.csv` 上传到 `/warehouse/ecommerce/ods/raw`。Hive 外部表会读取目录内所有数据文件，这会让 10K 基线表变成 1,010,000 行。

## Windows 源文件基线

- 文件：`data/sample/user_behavior_1m.csv`
- 行数：1,000,000
- 字节数：36,667,283
- SHA-256：`b5777d3a82cb3194384f3aeefc3f631fea4283989d5b15c5bce4cb9fc8d14653`
- 表头：无

## 第一阶段验收

1. 从 Windows 上传到 `/home/hadoop/user_behavior_1m.csv`；
2. Linux 执行 `wc -l`，必须为 1,000,000；
3. Linux 执行 `sha256sum`，必须与清单一致；
4. 创建 `/warehouse/ecommerce/ods/dev_1m`；
5. 上传到 HDFS 并核对字节数；
6. 再创建独立 Hive ODS 表。

后续脚本仍执行 ODS、DWD、DWS、ADS 逐层对账，不直接跳到最终指标。

## HDFS 上传验收结果

- Linux 本地行数：1,000,000；
- Linux SHA-256 与 Windows 源文件一致；
- 1M HDFS 目录：`/warehouse/ecommerce/ods/dev_1m`；
- HDFS 文件字节数：36,667,283；
- 10K 目录 `/warehouse/ecommerce/ods/raw` 仍只包含原 10K 文件。

## 1M ODS 验收基线

| 检查项 | 预期结果 |
|---|---:|
| 总行数 | 1,000,000 |
| pv | 896,299 |
| cart | 54,940 |
| fav | 28,874 |
| buy | 19,887 |
| 用户数 | 527,973 |
| 商品数 | 480,036 |
| 类目数 | 6,480 |
| 空值与非法 behavior | 全部 0 |
| 业务时间范围外记录 | 571 |
| 10K 基线表行数 | 10,000 |

最后一项用于证明扩容没有污染原来的回归基线。
