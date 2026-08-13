# 项目最终验收清单

## 数据与抽样

- [x] 源文件 MD5 校验通过；
- [x] 全量物理行数 100,150,807；
- [x] 固定随机 10K/1M 事件样本；
- [x] 确定性 1% 用户级样本，976,621 行、9,660 用户；
- [x] 样本清单和 SHA-256 已记录。

## 基础设施

- [x] 三节点 HDFS 正常，3 个 DataNode；
- [x] 三节点 YARN 正常，3 个 NodeManager；
- [x] MapReduce WordCount 成功；
- [x] HDFS 无 corrupt/missing/under-replicated blocks。

## 数仓

- [x] ODS 原样保留；
- [x] DWD ORC、日期分区和异常隔离；
- [x] DWS 每日基础指标；
- [x] ADS 每日看板；
- [x] 10K、1M、用户级样本目录和表隔离；
- [x] `INSERT OVERWRITE` 幂等重跑；
- [x] 所有行数与行为分布对账。

## 专题

- [x] 严格漏斗；
- [x] cohort 留存；
- [x] RFV 用户分层；
- [x] 商品与类目分析；
- [x] 高流量无购买候选识别。

## 工程问题

- [x] MySQL LOCAL INFILE；
- [x] MySQL timeout 与索引；
- [x] Hive CTE 语法兼容；
- [x] Hive 保留关键字；
- [x] Hive UTC/上海时区；
- [x] SLF4J 日志污染 TSV；
- [x] 所有修复完成回归验收。

## 交付

- [x] 20 个分步教程；
- [x] 构建与验收 SQL；
- [x] 本地交互看板；
- [x] 项目 README；
- [x] 工程复盘；
- [x] 简历项目描述；
- [x] 面试答辩手册。

结论：项目教学与求职展示范围已完成。后续工作属于增强项，不是当前交付阻塞项。
