# MySQL 100 万行开发样本探索结果

## 环境

- 数据库：taobao_ods
- 表：user_behavior_dev
- 样本文件：user_behavior_1m.csv
- 导入日期：2026-08-12
- imported_rows：1000000

## Result 1：装载核对

- total_rows：1000000
- source_file_count：1
- first_loaded_at：2026-08-12 00:37:30
- last_loaded_at：2026-08-12 00:37:30

## Result 2：行为分布

| behavior | rows | pct |
|---|---:|---:|
| pv | 896299 | 89.6299% |
| cart | 54940 | 5.4940% |
| fav | 28874 | 2.8874% |
| buy | 19887 | 1.9887% |

## Result 3：样本规模

- users：527973
- items：480036
- categories：6480

## Result 4—9

- 主要日期范围：2017-11-25 至 2017-12-03；查询已过滤展示该主业务区间
- 小时分布观察：0—23 时均有记录；具体高峰：'21'
- business_time_outliers：571
- 各行为用户数：buy 19445；cart 51167；fav 26087；pv 493575
- 候选重复键数量/现象：0 行，100 万样本内没有五字段完全重复记录
- Top 商品观察：item_id 812879 的事件数最高（302），但 buy_events 为 0；热门程度不等于购买表现
- Result 7—9 是否发生超时：第 7 条首次发生 Error 2013（30 秒读取超时），增加索引后成功
- 性能处理：增加 `idx_behavior_user(behavior, user_id)`，Workbench read timeout 调整为 300 秒

## 我的解释

- 为什么 pv 远多于 buy：浏览是漏斗入口行为，购买是后续行为；如果用 pv 用户作转化率分母，必须明确这是行为日志转化而不是订单支付转化。
- 为什么 ODS 保留异常时间而不是立即删除：ODS 要保留源数据以便追溯；DWD 再按业务日期规则隔离并记录异常数量，直接删除会丢失质量证据。
- 为什么候选重复键不包含 row_id：row_id 是导入时生成的代理键，重复导入同一源事件也会得到不同 row_id；候选业务键应基于源字段和事件时间。

## 报错与处理

- 现象：
- 原因：
- 解决：
