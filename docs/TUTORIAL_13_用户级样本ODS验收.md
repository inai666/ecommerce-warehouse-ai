# 教程 13：用户级样本 ODS 验收

## 目标

把用户级样本映射为独立 Hive ODS 外部表，证明文件完整、用户完整且与已有事件样本隔离。

- HDFS：`/warehouse/ecommerce/ods/user_sequence_1pct`
- Hive 表：`ecommerce_ods.user_behavior_sequence_1pct`
- 表头：无
- ODS 仍保留业务时间异常，DWD 再隔离

## 验收基线

| 检查项 | 预期结果 |
|---|---:|
| 总行数 | 976,621 |
| 去重用户 | 9,660 |
| pv | 874,671 |
| cart | 54,728 |
| fav | 27,964 |
| buy | 19,258 |
| 空值与非法 behavior | 全部 0 |
| 范围前异常 | 506 |
| 范围后异常 | 18 |
| 异常合计 | 524 |
| 10K 事件样本 | 10,000 |
| 1M 事件样本 | 1,000,000 |

## 为什么先做 ODS

严格漏斗不能直接读取 Windows CSV。先建立 ODS，才能保留可追溯的原始输入；随后 DWD 统一时间范围、生成分区并隔离异常，专题分析只读取干净的 DWD。

预期后续对账：

```text
976621 ODS = 976097 DWD + 524 quarantine
```

