---
name: yra-news-summarize-today
name_zh: 今日市场简报
description: |
  生成今日财经市场消息的结构化简报（壹渥简报风格）。
  通过 `yra` CLI 从飞书 Drive 拉取小时新闻文件的原始文本，
  由 AI 整理为「核心要点 + 宏观 / 行业 / 个股」三大类的简报。
triggers:
  - "总结今天的市场消息"
  - "今天有什么财经新闻"
  - "今日市场动态"
  - "今日简报"
  - "生成今日简报"
  - "summarize today"
  - "market summary"
  - "today's news"
  - "daily market report"
  - "yiwo brief"
capabilities:
  - read-data
  - analyze-content
  - generate-summary
---

# 今日市场消息简报

生成今日财经市场消息的结构化简报。输出为「壹渥简报（Yiwo Brief）」风格的 Markdown，按 **核心要点 + 宏观 / 行业 / 个股** 整理。

## 前置条件

本 skill 需要先安装 `yra` CLI 并完成认证。如果尚未安装，请先运行 `yra-setup` skill。

## 故障排查

如果 `yra auth status` 报 `SingletonLock: File exists` 错误，说明上次运行遗留了孤立 Chrome 进程。手动清理：

```bash
pgrep -f yiwo-research-app | xargs -r kill -TERM
```

如果仍然报 `context canceled` 错误，请确认 `yra` CLI 版本 ≥ v0.3.0（运行 `yra version` 检查）。v0.3.0 之前的版本存在已知的 context 取消 bug。

## 工作流程

### 步骤 1：验证 `yra` 已安装

运行 `which yra` 检查 CLI 是否已安装。

- **未安装**：请先运行 `yra-setup` skill。
- **已安装**：进入步骤 2。

### 步骤 2：验证认证

运行：

```bash
yra auth status
```

- 如果输出显示未认证或已过期：提示用户运行 `yra auth login`。
- 如果已认证：进入步骤 3。

### 步骤 3：列出今日的小时文件

运行（**默认 `human` 格式，不要加 `--format json`**，纯文件名列表最省 token）：

```bash
yra news list-hours --date today
```

返回简单的文件名列表：

```
NAME
----
26061009-news.txt
26061010-news.txt
26061011-news.txt
...
```

- 文件名格式：`YYMMDDHH-news.txt`（年月日小时各 2 位，零填充）。
- 按文件名升序天然就是时序顺序。

### 步骤 4：下载今日所有小时文件到本地缓存

运行：

```bash
yra news sync-today
```

输出是若干个绝对路径，每行一个，例如：

```
/Users/foo/.cache/yiwo-research-app/news/today/26061009-news.txt
/Users/foo/.cache/yiwo-research-app/news/today/26061010-news.txt
/Users/foo/.cache/yiwo-research-app/news/today/26061011-news.txt
```

- stderr 同时输出本次的清理 / 下载 / 跳过统计（例：`cleaned 0 stale, downloaded 3, skipped 0 (already cached)`），仅供观察，不影响后续步骤。
- 默认行为：已缓存的同名文件**跳过**；如需强制刷新加 `--force`。
- 该命令会自动清理缓存目录下所有**非今日**的残留文件。

逐个 Read 这些路径得到飞书原文 Markdown，**不需要再走 JSON**——文件内容即可直接喂给 LLM 分析。

### 步骤 5：生成简报

阅读步骤 4 返回的所有文件路径对应的原始文本，按下面的模板生成 Markdown 简报。

#### 简报模板

```markdown
# 壹渥简报（Yiwo Brief）YYYYMMDD-HH-HH

## 核心要点

- [3-5 条最关键的当日要点，每条 1-2 句，覆盖宏观、行业、个股中最重磅的事件]
- ...

## 宏观

- [国内外货币政策、利率、汇率、通胀、宏观经济数据、政策动向、地缘政治等]
- ...

## 行业

- [板块级别变化：AI / 半导体 / 能源 / 汽车 / 消费 / 地产 / 医药等]
- ...

## 个股

- [具体上市公司事件：业绩、并购、回购、管理层变动、清单事件、关键产品等]
- ...
```

#### 标题构造规则

- 时段范围 = 已拉取的最早小时到最晚小时。
- 示例：今天 2026-06-10，拉到 09 时到 15 时的文件 → 标题写 `20260610-09-15`。
- 标题里的年份用 4 位 `YYYY`，与正文一致；不要用文件名里的 2 位 `YY`。

#### 简报撰写规则

1. **不要带引用标记**：参考文档里 `[21, 22]`、`[源 3]` 这类引用编号一律去掉。
2. **用自己的话浓缩**：不要原文整段照抄；提取关键事实重新组织。
3. **每条 bullet 1–3 句**：保持精炼，必要时附带一两个关键数字。
4. **重要性优先**：优先纳入「很重要」级别的消息；过滤噪音。
5. **保留关键数字**：百分比、金额、销量、规模、利率、点位等数据要保留。
6. **分类纪律**：
   - **宏观**：影响整体经济 / 利率 / 汇率 / 通胀 / 国家级政策 / 地缘的事件。
   - **行业**：影响一整个板块或产业链的事件。
   - **个股**：单一上市公司层面，公司名后用括号标注代码，如「比亚迪 (002594.SZ)」、「美团 (3690.HK)」、「葛兰素史克 (GSK)」。
7. **客观陈述**：陈述事实，不做主观推测，除非用户明确要求。
8. **缺失时段**：如发现某些小时缺失（例如 09、10、12 三个文件而缺 11），在简报开头加一行说明，例如：`> 注：本时段缺失 11:00 数据。`

### 步骤 6：边界情况

- **今日无数据**：报告「今日暂无市场动态数据」，并建议稍后再试。
- **CLI 报错**：直接展示 `yra` 的错误输出，并参考「故障排查」章节给出建议。
- **拉取过慢**：考虑只取最近 6 小时；如多次失败，提示用户检查浏览器 profile 是否仍登录。
