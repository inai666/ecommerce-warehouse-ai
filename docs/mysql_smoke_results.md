# MySQL 1 万行冒烟导入结果

## 环境

- 数据库：taobao_ods
- MySQL 服务：MySQL57
- 导入日期：2026-08-11
- 导入方式：LOAD DATA LOCAL INFILE
- `@@session.time_zone`：SYSTEM
- `@@system_time_zone`：China Standard Time（UTC+08:00；Workbench 中因 MySQL 5.7/Windows 字符编码显示为乱码）

## 验收结果

- total_rows：10000
- pv：8951
- cart：573
- fav：291
- buy：185
- 空值数量：user_id/item_id/category_id/behavior/event_ts 均为 0
- 非法 behavior：0
- business_time_outliers：3
- 完整重复记录组数：0

## 我的解释

- 为什么 `event_ts` 在 ODS 保存为 BIGINT：ODS 需要保留源文件的原始秒级 Unix 时间戳，避免在进入原始层时因时区转换或异常值处理而改变源数据；统一时间字段在 DWD 再生成。
- 为什么 `row_id` 不能作为业务去重依据：row_id 是 MySQL 导入时自动生成的代理键，同一条源记录重复导入也会得到不同 row_id，不能表示真实事件唯一性。
- 为什么业务时间异常不等于 CSV 格式错误：异常时间戳仍然是可以解析的整数，只是落在项目定义的 2017-11-25 至 2017-12-03 业务范围之外；它属于业务质量问题，不是 CSV 列结构或数据类型错误。

## 报错与处理

- 现象：
- 原因：
- 解决：
- 防止再次发生：
