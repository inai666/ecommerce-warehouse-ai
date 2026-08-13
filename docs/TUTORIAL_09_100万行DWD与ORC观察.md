# 教程 9：100 万行 DWD、异常隔离与 ORC 观察

## 目标

复用 10K 已验证的清洗规则，把 1M ODS 加工为独立的 DWD 明细与异常隔离表，并观察数据规模扩大后的 YARN 作业时间与 ORC 文件体积。

## 独立输出

- 有效明细：`ecommerce_dwd.user_behavior_detail_1m`
- 异常隔离：`ecommerce_dwd.user_behavior_quarantine_1m`
- 有效明细 HDFS：`/warehouse/ecommerce/dwd/user_behavior_detail_1m`
- 异常 HDFS：`/warehouse/ecommerce/dwd/user_behavior_quarantine_1m`

10K 的两张 DWD 表保持不变，继续作为回归基线。

## 精确验收基线

| 检查项 | 预期结果 |
|---|---:|
| ODS | 1,000,000 |
| DWD 有效明细 | 999,429 |
| 异常隔离 | 571 |
| 对账差额 | 0 |
| 范围前异常 | 551 |
| 范围后异常 | 20 |
| DWD pv | 895,728 |
| DWD cart | 54,940 |
| DWD fav | 28,874 |
| DWD buy | 19,887 |
| DWD 用户 | 527,746 |
| DWD 商品 | 479,860 |
| DWD 类目 | 6,480 |

## 日期分区行数

| 日期 | 行数 |
|---|---:|
| 2017-11-25 | 104,008 |
| 2017-11-26 | 106,758 |
| 2017-11-27 | 101,072 |
| 2017-11-28 | 98,686 |
| 2017-11-29 | 102,440 |
| 2017-11-30 | 104,349 |
| 2017-12-01 | 108,486 |
| 2017-12-02 | 137,371 |
| 2017-12-03 | 136,259 |

## ORC 观察方法

构建完成后可执行：

```bash
hdfs dfs -du -h -s /warehouse/ecommerce/ods/dev_1m
hdfs dfs -du -h -s /warehouse/ecommerce/dwd/user_behavior_detail_1m
hdfs dfs -count /warehouse/ecommerce/dwd/user_behavior_detail_1m
```

原始 CSV 与 ORC 的字段数量不同，DWD 还新增了 `event_time`，因此这里只观察体积变化，不能把它当成严格的同字段压缩率实验。

ORC 的主要价值还包括列裁剪、统计信息和更适合 Hive 分析的读取方式。是否更快要结合具体查询、读取列、分区过滤和任务时间判断。

## 资源提示

1M 构建会比 10K 明显更久。只要日志持续刷新、YARN 任务仍为 RUNNING，就继续等待，不要重复提交同一脚本，也不要按 `Ctrl+C`。

