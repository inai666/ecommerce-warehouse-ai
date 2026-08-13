# 教程 0：基线诊断与数据抽样

## 0. 你现在处于哪一步

你已经完成：

- 练习了一部分 SQL 题；
- 新建了数据库；
- 下载了 `UserBehavior.csv.zip`；
- 数据包 MD5 已核对无误。

现在不要急着把 1 亿行导进 MySQL，也不要先搭 Hadoop。第一步是确认“这份数据到底长什么样”，并生成后续开发用的小样本。

## 1. 先理解四个概念

### 1.1 CSV 基本结构

这份 CSV 没有表头，每一行固定五列：

```text
user_id,item_id,category_id,behavior,timestamp
```

例如：

```text
1,2268318,2520377,pv,1511544070
```

含义是：用户 1 在 Unix 时间戳 `1511544070` 时，对商品 `2268318` 发生了一次 `pv` 行为。

四种行为：

- `pv`：浏览详情页；
- `fav`：收藏；
- `cart`：加入购物车；
- `buy`：购买行为。

### 1.2 Unix 时间戳

时间戳是从 1970-01-01 00:00:00 UTC 开始累计的秒数。它本身不带中国时区。

项目统一转换为 `Asia/Shanghai`。不能直接看到 `1511544070` 就猜日期，必须让程序转换并抽查。

### 1.3 为什么不能 `head` 取最终样本

`head` 只拿文件开头。如果原文件按用户、时间或商品排序，开头 100 万行可能偏向少数用户或日期，得到的指标会偏。

脚本使用固定随机种子 `42` 的 Vitter Algorithm L 蓄水池抽样：

- 数据只扫描一遍；
- 内存只保留 100 万行左右，不把 1 亿行全部装入 Pandas；
- 每一行被选中的概率相同；
- 同样的源文件、代码和 seed 会得到同样的样本。
- 算法会计算下一次替换需要跳过多少行，避免对 1 亿行逐行生成随机数。

### 1.4 为什么要同时生成 1 万和 100 万行

- `1 万行`：用于快速建表、查语法和测试报错，几秒内完成后续 SQL。
- `100 万行`：用于开发指标和观察比较真实的分布。
- `全量`：等小样本流程完全正确后再使用。

## 2. 我已经替你准备好的内容

```text
ecommerce-warehouse-ai/
├─ README.md
├─ .gitignore
├─ data/sample/
├─ docs/
│  └─ TUTORIAL_00_基线诊断与数据抽样.md
├─ scripts/
│  ├─ sample_and_profile.py
│  └─ run_tutorial_00.ps1
├─ sql/mysql/
└─ logs/
```

`.gitignore` 已经排除大数据文件、密码和运行日志，避免以后误把 3GB 数据推到 GitHub。

## 3. 一键执行

打开 PowerShell，逐行执行：

```powershell
cd C:\job1\ecommerce-warehouse-ai
powershell -ExecutionPolicy Bypass -File .\scripts\run_tutorial_00.ps1
```

脚本会直接读取下载目录中的 ZIP，不需要解压。处理 1 亿行需要一些时间；每处理 500 万行会显示一次进度。

成功时最后会看到：

```text
Tutorial 00 completed.
Open: C:\job1\ecommerce-warehouse-ai\docs\profile.md
```

## 4. 脚本具体做了什么

1. 检查 ZIP 是否存在。
2. 检查 Python 是否可用。
3. 从 ZIP 流式读取 `UserBehavior.csv`。
4. 全量统计总行数与列结构异常；在固定随机 100 万样本上统计各列空值、行为枚举、最小/最大时间戳。
5. 用固定 seed 生成 100 万行蓄水池随机样本。
6. 从开发样本再固定抽取 1 万行烟雾样本。
7. 统计样本完整重复行数。
8. 生成 20 行人工核对表，附带上海时区时间。
9. 写出 `docs/profile.md` 和 `docs/source_manifest.json`。

额外的日期范围复核可以随时重复运行：

```powershell
python .\scripts\analyze_existing_sample.py
```

它只读取已经生成的 100 万样本，不会再次扫描 950 MB ZIP。

## 5. 运行后你亲自检查什么

### 5.1 看画像报告

```powershell
notepad .\docs\profile.md
```

逐项回答：

- 总行数是多少？
- 是否存在不是 5 列的行？
- `behavior` 是否只有 `pv/fav/cart/buy`？
- 最早和最晚时间是什么？是否存在超出主要日期范围的异常时间？
- 100 万行样本里有多少完整重复行？

把答案写到 `docs/learning_notes.md`，不要只看数字。

本次样本已经发现 `571/1,000,000` 行超出 2017-11-25 至 2017-12-03 的主要范围。正确处理方式是 ODS 保留、DWD 隔离并统计，不是在读取源文件时直接丢弃。

### 5.2 人工检查 20 行

用 Excel、记事本或 VS Code 打开：

```text
data/sample/manual_check_20.csv
```

逐行检查：

- 原始字段是否正好五列；
- `user_id/item_id/category_id/timestamp` 是否能解释为整数；
- `behavior` 是否属于四种枚举；
- `event_time_shanghai` 是否是正常日期时间；
- CSV 原时间戳与转换结果是否对应。

然后在 `docs/learning_notes.md` 写一句结论，例如：

```text
随机核对 20 行，字段未错位；时间戳为秒级 Unix 时间戳，按 Asia/Shanghai 转换正常。
```

### 5.3 用 PowerShell 做三个验收

Windows PowerShell 不使用图片里的 `wc/awk/cut`，对应命令如下：

```powershell
# 1 万行样本的行数
(Get-Content .\data\sample\user_behavior_10k.csv | Measure-Object -Line).Lines

# 检查是否有不是 5 列的行，应输出 0
(Get-Content .\data\sample\user_behavior_10k.csv |
  Where-Object { ($_ -split ',').Count -ne 5 } |
  Measure-Object).Count

# 查看 behavior 分布
Get-Content .\data\sample\user_behavior_10k.csv |
  ForEach-Object { ($_ -split ',')[3] } |
  Group-Object | Sort-Object Count -Descending
```

100 万行不要频繁用 `Get-Content` 做多次全扫描，直接看 `profile.md`，更快。

## 6. 常见问题

### 报“找不到 ZIP”

检查数据是否还在：

```powershell
Test-Path C:\Users\jujin\Downloads\UserBehavior.csv.zip
```

如果移动过文件，手工运行脚本并修改 `--input`：

```powershell
python .\scripts\sample_and_profile.py `
  --input "D:\你的目录\UserBehavior.csv.zip" `
  --rows 1000000 `
  --smoke-rows 10000 `
  --seed 42 `
  --output-dir .\data\sample `
  --profile .\docs\profile.md
```

### 电脑内存占用升高

100 万行蓄水池会使用一定内存，但不会接近把 1 亿行读进 Pandas 的级别。关闭大型游戏、多个浏览器标签和其他占内存程序即可。

### 中途关闭窗口

不会损坏源 ZIP。删除未完成的样本文件后重新运行即可；脚本先写 `.tmp`，成功后才替换正式文件。

## 7. 今天的完成标准

- [ ] `docs/profile.md` 已生成；
- [ ] 1 万行和 100 万行样本已生成；
- [ ] 画像中的坏列数、空值、枚举和时间范围已理解；
- [ ] 人工核对 20 行并写结论；
- [ ] 能用自己的话解释蓄水池抽样为什么不需要把全量放进内存；
- [ ] 完成一次 Git 提交。

完成这些之后，下一步才是把 1 万行样本导入你已经建立的 MySQL 数据库，并做 ODS 原始表验收。
