# 教程 1：把 1 万行样本导入 MySQL

目标：把 `user_behavior_10k.csv` 导入 `taobao_ods.user_behavior_smoke`，然后证明导入结果正确。先做 1 万行；验收全部通过后才导入 100 万行。

## 1. 你要理解的表设计

原始 CSV 五列映射为：

| CSV 位置 | MySQL 字段 | 类型 | 原因 |
|---|---|---|---|
| 1 | user_id | BIGINT | 用户 ID，不能用 INT 冒险 |
| 2 | item_id | BIGINT | 商品 ID |
| 3 | category_id | BIGINT | 类目 ID |
| 4 | behavior | VARCHAR(10) | 保留 pv/fav/cart/buy 原值 |
| 5 | event_ts | BIGINT | ODS 先保存原始秒级时间戳 |

表中额外增加 `row_id`、`source_file`、`loaded_at`，用于追踪导入批次。`row_id` 不是源数据业务主键，不能拿它做事件去重。

## 2. 在 Workbench 创建表

1. 打开 MySQL Workbench，进入你能正常连接的本地连接。
2. 左侧 `SCHEMAS` 找到 `taobao_ods`。如果没显示，点击刷新图标。
3. 点击顶部 `File > Open SQL Script...`。
4. 打开：`C:\job1\ecommerce-warehouse-ai\sql\mysql\00_create_smoke_table.sql`。
5. 点击闪电图标执行全部 SQL。
6. 输出区应出现 `taobao_ods.user_behavior_smoke` 的建表语句。
7. 左侧右键 `Tables > Refresh All`，确认出现 `user_behavior_smoke`。

不要手工改字段名。脚本已经针对 MySQL 5.7，未依赖 8.0 才有的 CHECK 强约束。

## 3. 导入方式 A：执行 LOAD DATA（推荐）

1. 在 Workbench 打开一个新查询页。
2. 先运行：

```sql
SHOW VARIABLES LIKE 'local_infile';
```

3. 如果结果是 `ON`，打开并执行：

```text
C:\job1\ecommerce-warehouse-ai\sql\mysql\01_load_smoke.sql
```

4. 最后一行 `imported_rows` 应为 `10000`。

### 如果报错 3948 / local data is disabled

这是客户端或服务器禁用了本地文件导入，不是 CSV 损坏。如果 `SHOW VARIABLES LIKE 'local_infile'` 已经返回 `ON`，说明服务器端正常，需要给当前 Workbench 连接开启客户端能力：

1. 回到 Workbench 首页（左上角小房子图标）。
2. 找到当前连接，点击连接右侧的扳手图标或右键 `Edit Connection`。
3. 打开 `Advanced` 页签。
4. 在最下方 `Others` 文本框单独增加一行：

```text
OPT_LOCAL_INFILE=1
```

5. 点击 `Test Connection`，成功后点 `OK`。
6. 关闭当前 SQL Editor 连接并重新打开，旧会话不会自动获得新参数。
7. 重新执行 `SHOW VARIABLES LIKE 'local_infile';`，确认仍为 `ON`。
8. 再执行 `01_load_smoke.sql`。

如果报错是 `2068: LOAD DATA LOCAL INFILE file request rejected due to restrictions on access`，也使用相同步骤。

不要执行来源不明的全局安全配置修改。当前只是允许这个本地 Workbench 连接读取你明确指定的 CSV。

若仍失败，执行 `sql/mysql/03_diagnose_load_data.sql`，把结果和完整错误码发回。

### 如果报找不到文件

SQL 中必须使用正斜杠路径：

```text
C:/job1/ecommerce-warehouse-ai/data/sample/user_behavior_10k.csv
```

不要写成未转义的单反斜杠。

### 如何看到完整错误

在底部 `Action Output` 中单击红叉所在行，不要把鼠标停在 SQL 文本列上；横向拖宽 `Message` 列，或右键该行复制错误。需要的是 `Error Code: xxxx` 后面的完整句子，而不是失败的 SQL 内容。

## 4. 导入方式 B：Workbench Table Data Import Wizard

只在方式 A 不能用时采用：

1. 左侧右键 `taobao_ods` 下的 `Tables`。
2. 选择 `Table Data Import Wizard`。
3. 选择文件 `C:\job1\ecommerce-warehouse-ai\data\sample\user_behavior_10k.csv`。
4. 选择 `Use existing table`，表选 `user_behavior_smoke`。
5. 这份 CSV **没有表头**。如果界面有 `First row contains column names`，必须取消勾选。
6. 映射前五个输入列到 `user_id,item_id,category_id,behavior,event_ts`。
7. `row_id` 不映射，让 AUTO_INCREMENT 自动生成；`source_file/loaded_at` 使用默认值。
8. 导入前先执行 `TRUNCATE TABLE taobao_ods.user_behavior_smoke;`，避免重复导入。
9. 点击 `Next` 执行，完成页应显示导入 10000 行、失败 0 行。

如果向导无法正确映射无表头 CSV，停止操作并使用方式 A，不要为了“导进去”随意改列。

## 5. 执行验收 SQL

打开并执行：

```text
C:\job1\ecommerce-warehouse-ai\sql\mysql\02_validate_smoke.sql
```

逐项判断：

- `total_rows` 必须是 `10000`；
- behavior 只能有 `pv/fav/cart/buy`；
- 五个空值统计和 `invalid_behavior` 必须全为 `0`；
- 查看最小/最大时间，理解异常时间仍保留在 ODS；
- `business_time_outliers` 可以大于 0，它表示业务范围异常，不表示导入失败；
- 最后一个查询检查五字段完整重复行。

## 6. 时区怎么判断

`FROM_UNIXTIME()` 使用 MySQL 会话时区。先看：

```sql
SELECT @@session.time_zone, @@system_time_zone;
```

若会话为 `SYSTEM` 且系统是中国时区，显示结果通常是北京时间。暂时不要全局修改服务器时区；把查询结果记录到学习笔记，Hive 阶段再统一时区规则。

## 7. 今天的验收证据

- [ ] 表已创建；
- [ ] 导入 10000 行，失败 0 行；
- [ ] 空值与非法 behavior 为 0；
- [ ] 保存 behavior 分布和异常时间数量；
- [ ] 能解释 `row_id` 为什么不是业务主键；
- [ ] 把实际结果填入 `docs/mysql_smoke_results.md`；
- [ ] 提交 Git。
