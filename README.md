# 电商用户行为离线数仓与分析平台

基于天池淘宝用户行为日志，在三节点 Hadoop/Hive 环境中构建可审计的离线数仓，完成数据画像、ODS/DWD/DWS/ADS 分层、严格漏斗、用户留存、RFV 分层、商品/类目分析和本地交互看板。

## 项目亮点

- 扫描 100,150,807 行源数据，使用流式蓄水池抽样生成固定随机 10K/1M 事件样本；
- 发现事件抽样会破坏行为序列，改用确定性用户级哈希抽样，保留 9,660 个用户的 976,621 条完整事件；
- 在 `master + slave1 + slave2` 三节点集群验收 HDFS、YARN 和 MapReduce；
- 使用 Hive 外部表构建 ODS、ORC DWD、DWS、ADS，所有层级设置严格行数对账；
- 将 1M CSV 的逻辑体积由 35.0 MB 转换为 14.2 MB ORC，约减少 59.4%；
- 将 524 条用户级样本异常时间记录隔离到 quarantine 表，不静默删除；
- 基于同一用户、同一商品和时间顺序构建严格漏斗，而不是直接相除行为总数；
- 定位 Hive/JVM 默认 UTC 导致的日期错分问题，显式转换 `Asia/Shanghai` 并回归重建三套链路；
- 构建留存、RFV、商品/类目专题和无需后端依赖的交互看板。

## 架构

```text
UserBehavior.csv.zip
  -> Python 流式画像与抽样
  -> MySQL 冒烟验证
  -> HDFS 原始文件
  -> Hive ODS 外部表（原样保留）
  -> Hive DWD ORC（清洗、日期分区、异常隔离）
  -> Hive DWS（日粒度基础汇总）
  -> Hive ADS（看板、漏斗、留存、RFV、商品/类目）
  -> TSV 导出
  -> 本地交互看板
```

集群角色：

| 节点 | 角色 |
|---|---|
| master | NameNode、DataNode、NodeManager |
| slave1 | ResourceManager、DataNode、NodeManager |
| slave2 | SecondaryNameNode、DataNode、NodeManager |

## 核心结果

| 项目 | 结果 |
|---|---:|
| 全量源数据 | 100,150,807 行 |
| 1M 事件样本 DWD | 999,429 行有效，571 行异常 |
| 用户级样本 DWD | 976,097 行有效，524 行异常 |
| 严格漏斗 | 691,122 PV 对 -> 11,101 意向对 -> 1,023 购买对 |
| PV 到意向 | 1.6062% |
| 意向到购买 | 9.2154% |
| `2017-11-25` 次日留存 | 78.3510% |
| RFV 核心价值用户 | 3,580 |
| 有效商品 / 类目 | 396,750 / 5,788 |
| 高流量无购买候选 | 1,732 |

## 看板

入口：[dashboard/index.html](dashboard/index.html)

若直接双击打开受到浏览器限制，可在项目根目录运行：

```powershell
python -m http.server 8765 --bind 127.0.0.1
```

访问 `http://127.0.0.1:8765/dashboard/`。

## 目录

```text
dashboard/       本地交互看板
data/dashboard/  ADS 导出的轻量 TSV
docs/            20 个教程、验收结果、复盘与求职材料
scripts/         流式抽样、用户级抽样、ADS 导出脚本
sql/mysql/       MySQL 导入与探索
sql/hive/        ODS/DWD/DWS/ADS 构建及验收 SQL
```

## 数据口径与限制

- 数据只有 `user_id,item_id,category_id,behavior,timestamp`，没有金额、价格和订单号；
- `buy` 是购买行为事件，不等于已支付订单；
- 不能计算 GMV、客单价或标准 RFM，项目使用透明权重的 RFV；
- 日趋势来自事件随机 1M 样本，序列专题来自约 1% 用户级样本；
- 所有结论用于工程训练与方法验证，不宣称代表全量线上业务。

## 深入阅读

- [工程复盘](docs/PROJECT_RETROSPECTIVE.md)
- [简历项目描述](docs/RESUME_PROJECT.md)
- [面试答辩手册](docs/INTERVIEW_GUIDE.md)
- [环境清单](docs/environment_inventory.md)
- [时区修复记录](docs/timezone_repair_results.md)
- [完整教程](docs/TUTORIAL_00_基线诊断与数据抽样.md)

