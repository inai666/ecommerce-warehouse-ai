# 教程 2：100 万行开发样本与 ODS 探索

## 目标

把 100 万行固定随机样本导入独立的 `user_behavior_dev` 表，完成第一轮 ODS 探索，并回答：样本里有多少用户、商品、类目？行为比例如何？日期和小时分布如何？异常时间多少？有没有需要在 DWD 去重的候选键？

10K 冒烟表继续保留，不要覆盖。它是以后修改 SQL 后的快速回归测试基准。

## 1. 建立开发表

在 Workbench 打开并执行：

```text
C:\job1\ecommerce-warehouse-ai\sql\mysql\10_create_dev_table.sql
```

左侧刷新 `taobao_ods > Tables`，应看到：

- `user_behavior_smoke`：10000 行冒烟表；
- `user_behavior_dev`：后面装载 100 万行。

`CREATE TABLE ... LIKE ...` 会复制字段和索引结构，但不会复制数据。这样既避免重新写 DDL，又不会破坏昨天的验收基线。

## 2. 导入 100 万行

打开并执行：

```text
C:\job1\ecommerce-warehouse-ai\sql\mysql\11_load_dev_1m.sql
```

成功结果：

```text
imported_rows
1000000
```

脚本先 `TRUNCATE user_behavior_dev`，因此重复执行不会翻倍；它不会清空 `user_behavior_smoke`。

100 万行导入可能需要几十秒到几分钟。期间不要反复点击执行，也不要关闭 Workbench。若出现错误，先看红叉对应的完整 Error Code，不要继续执行探索 SQL。

## 3. 执行探索 SQL

打开并执行：

```text
C:\job1\ecommerce-warehouse-ai\sql\mysql\12_explore_dev_1m.sql
```

脚本有 9 条查询，结果会出现在底部 `Result 1` 到 `Result 9`。建议一次点击一个结果页，不要只看最后一个。

如果第 7 条或后续查询出现 `Error Code: 2013`，并且耗时正好是 `30.000 sec`，这是 Workbench 读取超时。前面成功的查询和已经导入的 100 万行不会丢失。按本节后面的“Error 2013 处理”操作，不要重新导入。

### Result 1：装载核对

必须是：

- `total_rows = 1000000`；
- `source_file_count = 1`；
- `first_loaded_at` 和 `last_loaded_at` 有值。

### Result 2：行为分布

固定样本的参考值：

| behavior | 约行数 | 约占比 |
|---|---:|---:|
| pv | 896299 | 89.6299% |
| cart | 54940 | 5.4940% |
| fav | 28874 | 2.8874% |
| buy | 19887 | 1.9887% |

你看到的占比应与此完全一致，因为导入的是同一个固定 seed 样本。

### Result 3：规模

这是“100 万行样本里的去重用户/商品/类目数”，不是天猫全站规模。把三个数记录下来，并思考：为什么行数不能直接当用户数？

### Result 4：日期分布

该查询只展示 2017-11-25 至 2017-12-03 的主要业务日期，避免少量异常时间把结果页拉得很长。异常记录仍保留在表中，并由 Result 6 单独统计；DWD 才定义过滤/隔离规则。

### Result 5：小时分布

小时值应在 0—23，查询只统计主要业务日期范围。观察是否存在明显高峰，注意这是行为发生时间分布，不等于用户在线时长。

### Result 6：异常时间

参考值：`business_time_outliers = 571`。这是样本中早于 2017-11-25 或晚于 2017-12-03 的记录数，应该与 `docs/profile.md` 一致。

### Result 7：行为用户数

同一个用户可能同时出现在 pv、fav、cart、buy 中，所以四类用户数相加通常大于总用户数。不要把它们相加当作独立用户数。

### Result 8：重复候选

如果有行，说明相同的 `user_id + item_id + category_id + behavior + event_ts` 出现多次。不要马上在 ODS 删除；先记录数量，DWD 再使用窗口函数制定去重规则。

### Result 9：热门商品

这是探索性排名，不是最终 ADS TopN。此时还没有处理异常时间、重复事件和窗口边界，不能把它直接写进简历。

### Error 2013 处理

1. 打开 `Edit > Preferences > SQL Editor`。
2. 把 `DBMS connection read timeout interval (in seconds)` 从 `30` 改成 `300`。
3. 点击 `OK`，完全退出并重新启动 Workbench。
4. 打开并执行一次 `sql/mysql/13_add_exploration_indexes.sql`。
5. 索引建立完成后，只选中 `12_explore_dev_1m.sql` 中第 7、8、9 条查询再执行。

如果索引脚本提示 `Duplicate key name 'idx_behavior_user'`，说明索引已经建立，直接进入第 5 步。建立索引不会删除或修改原始记录，也不需要重新导入 CSV。

## 4. 填写结果记录

把实际结果填入：

```text
C:\job1\ecommerce-warehouse-ai\docs\mysql_dev_1m_results.md
```

必须写三句自己的解释：

1. 为什么 `pv` 远多于 `buy`，这对转化率分母有什么影响？
2. 为什么 ODS 可以保留异常时间，而 ADS 不能直接把异常混进去？
3. 为什么候选重复键不包含 `row_id`？

## 5. 完成标准

- [ ] `user_behavior_dev` 成功导入 1000000 行；
- [ ] 10K 冒烟表仍然存在且仍为 10000 行；
- [ ] Result 1—9 全部执行成功；
- [ ] 行为分布与固定样本参考值一致；
- [ ] 异常时间约 571 行；
- [ ] 完成 `mysql_dev_1m_results.md`；
- [ ] Git 提交 SQL、教程和结果记录，但不提交 CSV。

## 6. 这一阶段暂时不做什么

- 不把 100 万行继续导入另一张重复的“清洗表”；下一阶段才进入 DWD；
- 不急着写复杂指标；先确认原始数据的分布和边界；
- 不导入 1 亿全量；100 万已经足够开发 SQL；
- 不删除异常时间和重复候选；先保留证据。
