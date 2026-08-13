# 教程 19：ADS 数据导出与可视化准备

## 目标

将 Hive ADS 中已经验收的小型结果集导出到 Linux 本地，再下载到 Windows 构建可视化看板。看板只读取 ADS，不直接连接 DWD 明细。

## 导出内容

| 文件 | 内容 | 预计数据行 |
|---|---|---:|
| daily_dashboard.tsv | 1M 每日指标 | 9 |
| retention.tsv | cohort 留存 | 7 |
| rfv_summary.tsv | RFV 分群 | 5 |
| strict_funnel.tsv | 严格漏斗 | 1 |
| top_items.tsv | 热销商品 Top 20 | 20 |
| high_traffic_no_buy.tsv | 高流量无购买 Top 20 | 20 |
| top_categories.tsv | 热门类目 Top 20 | 20 |

每个 TSV 第一行是字段名。Hive 日志单独写入 `hive_export.log`，不会混进报表数据。

当前 Hive CLI 默认把部分 INFO 日志写到标准输出，仅使用 `-S` 不足以生成干净 TSV。导出脚本显式设置 `hive.root.logger=ERROR,console`，并用预期行数验收，避免日志被误当成数据。

该环境存在多个 SLF4J binding，实测日志级别参数仍不能完全阻止 INFO 日志进入标准输出。最终脚本先写临时原始输出，再按每份报表的固定制表符字段数过滤。过滤后同时打印行数和首行表头，双重确认 TSV 可用于看板。

## 为什么使用 ADS 导出

可视化层应读取口径稳定、规模较小的 ADS，而不是在浏览器或 Python 看板中重复扫描近百万条明细。这样可以降低延迟，也避免在多个展示工具中重复实现指标口径。

## 时区回归结论

10K、1M 和用户级 DWD 均已显式使用 `Asia/Shanghai`，日期范围为 `2017-11-25` 至 `2017-12-03`。三张 DWD 的越界日期检查均为 0。
