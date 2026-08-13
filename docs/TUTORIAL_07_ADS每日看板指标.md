# 教程 7：ADS 每日看板指标

## 目标

从 DWS 的稳定基础指标生成一张可直接供报表或接口读取的每日看板表。ADS 不再扫描 9,997 条 DWD 明细，而是读取 DWS 的 9 行日汇总。

```text
DWD 事件明细 -> DWS 可复用汇总 -> ADS 具体展示口径
```

## 新增指标

| 指标 | 公式 | 含义 |
|---|---|---|
| events_per_user | event_count / active_users | 人均有效行为次数 |
| buyer_rate_pct | buyer_users / active_users * 100 | 活跃用户中发生购买的比例 |
| pv_share_pct | pv_count / event_count * 100 | 浏览事件占全部行为比例 |
| fav_share_pct | fav_count / event_count * 100 | 收藏事件占比 |
| cart_share_pct | cart_count / event_count * 100 | 加购事件占比 |
| buy_share_pct | buy_count / event_count * 100 | 购买事件占比 |

所有除法都先判断分母是否为 0，避免产生空值或除零错误。比例字段使用四位小数，便于验收且不过度伪装精度。

## 重要口径限制

`buyer_rate_pct` 是购买用户率，不是严格意义上的漏斗转化率。

严格漏斗需要在用户粒度验证同一用户是否按 `pv -> fav/cart -> buy` 的顺序发生行为，并明确跨商品、跨天和重复行为如何处理。直接用 `buy_count / cart_count` 只能得到行为数量比，不能证明加购用户后来完成了购买。

后续漏斗专题会回到 DWD 明细，用用户与事件时间构造严格口径。

## 执行和验收

1. 上传 `30_build_ads_daily_dashboard_10k.sql` 和 `31_validate_ads_daily_dashboard_10k.sql`；
2. 执行 ADS 构建；
3. 验证日期范围与行数；
4. 验证所有比率处于合法范围；
5. 验证四类行为占比之和约为 100%；
6. 查看购买用户率最高的三个日期。

## 预期结果

- 看板行数：9；
- 日期：`2017-11-25` 至 `2017-12-03`；
- `invalid_rate_rows`：0；
- 每天四类行为占比之和约为 100%，只允许极小的四舍五入误差；
- 10K 样本中购买用户率最高日期预计为 `2017-11-29`，约 `2.7641%`。

