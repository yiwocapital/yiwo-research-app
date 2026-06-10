---
name: yra-news-search
name_zh: 新闻搜索
description: |
  在历史财经市场新闻中搜索特定主题。
  支持关键词搜索、日期范围过滤。
triggers:
  - "搜索.*新闻"
  - "查找.*消息"
  - "search.*news"
  - "query.*market"
  - "查一下.*"
  - "有没有.*相关"
  - "关于.*的消息"
capabilities:
  - read-data
  - filter-content
  - search-keywords
---

# 新闻搜索

在历史市场新闻数据中搜索特定主题。基于 `yra news search` 命令，自动增量
同步本地缓存 + 内置文件扫描，**无需依赖系统 grep**。

## 前置条件

本 skill 需要先安装 `yra` CLI 并完成认证。如果尚未安装，请先运行 `yra-setup` skill。

## 故障排查

如果 `yra auth status` 报 `SingletonLock: File exists` 错误，说明上次运行遗留了孤立 Chrome 进程。手动清理：

```bash
pgrep -f yiwo-research-app | xargs -r kill -TERM
```

如果搜索结果为 0 但你确定该词应该有命中，先确认 `yra` CLI 版本 ≥ v0.3.6（运行 `yra version` 检查）——v0.3.6 之前没有 `yra news search` 子命令。

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

- 如果未认证或已过期：提示用户运行 `yra auth login`。
- 如果已认证：进入步骤 3。

### 步骤 3：解析搜索意图

从用户问题中提取：

| 参数 | 示例 | 对应 `yra news search` 参数 |
|------|------|------------------------------|
| 关键词 | "美联储"、"原油"、"通胀 加息" | 直接作为位置参数（多个 = AND 语义） |
| 单日 | "今天"、"昨天"、"6月5日" | `--date YYYYMMDD` |
| 单月 | "5 月"、"上个月"、"202605" | `--month YYYYMM` |
| 时间段 | "本周"、"最近 N 天"、"过去 7 天"、"6 月以来" | `--since YYYYMMDD` |
| 全部 | （未提到时间） | （无时间参数） |

**日期解析规则**（基于今天的日期 = `date +%Y%m%d`）：
- "今天" → `--date $(date +%Y%m%d)`
- "昨天" → `--date <昨天的 YYYYMMDD>`
- "本周" → `--since <本周一的 YYYYMMDD>`
- "最近 N 天" / "过去 N 天" → `--since <今天 - N 天的 YYYYMMDD>`
- "X 月" 单月 → `--month <YYYYMM>`
- "X 月以来" → `--since <X 月 1 日的 YYYYMMDD>`

### 步骤 4：执行搜索

一行命令搞定：

```bash
yra news search "<关键词1>" "<关键词2>" [--month YYYYMM | --date YYYYMMDD | --since YYYYMMDD]
```

**示例**：

```bash
# 全部历史中搜索美联储
yra news search 美联储

# 本月（6 月）关于加息的消息
yra news search 加息 --month 202606

# 6 月以来美联储 + 加息 同时出现（AND）
yra news search 美联储 加息 --since 20260601

# 昨天的通胀消息，5 行上下文
yra news search 通胀 --date 20260609 --context 5

# 跳过自动同步，只查本地缓存（debug 用）
yra news search 美联储 --no-sync
```

**首次搜索注意**：默认会先静默调用 `sync-archive`，首次可能需要 30s~2min
（全量下载最近 3 个月日报）。之后每次都很快（增量 + 标记文件双重快路径）。

### 步骤 5：解析 yra 输出

`yra news search` 直接给出人类可读的纯文本，格式如下：

```
=== 260605-daily-news.txt (line 15685) ===
  15684 │ ...上下文行...
→ 15685 │ 6月5日讯，美国5月份再次实现强劲的就业增长，引发了对今年晚些时候可能加息的担忧...
  15686 │ ...上下文行...

=== 260607-daily-news.txt (line 8421) ===
  ...

---
matches: 99  files: 1  searched: 1 files (date 20260605)
```

**字段说明**：
- `=== 文件名 (line N) ===`：每个 hit 一段
- `→ N │ <line>`：命中行，行号居中带箭头
- `  N │ <line>`：上下文行
- 末尾 `---` 后的统计：matches（命中数）、files（命中文件数）、searched（搜索的文件数）+ scope（搜索范围）

### 步骤 6：格式化输出给用户

把 yra 的结果整理成 Markdown 简报：

```markdown
# 🔍 搜索结果："[关键词]"

**搜索范围**：[scope 描述]
**匹配消息**：N 条（M 个文件）

---

## 主要发现

[2-3 句概括最关键的几条命中]

## 详细结果

### 📅 YYYY-MM-DD

> [命中行 + 必要的上下文，去掉无关行号噪音]

来源：[文件名]

### 📅 YYYY-MM-DD

> ...

---

## 📊 统计

| 维度 | 分布 |
|------|------|
| 按日期 | YYYY-MM-DD: N 条, ... |
| 按热度 | 命中最多的日期是 YYYY-MM-DD |
```

**整理原则**：
1. 不要把 yra 的全部上下文原样贴给用户——选择最有信息量的 hit
2. 同一主题的多条相邻命中可以合并讲一次
3. 保留关键数字、人名、机构名
4. 时间表述用 YYYY-MM-DD，便于用户对照

### 步骤 7：边界处理

- **0 命中**：yra 已经直接给出 `No matches for ...`。建议用户：
  - 试试更宽泛的关键词（如"加息" 换成 "利率"）
  - 扩大日期范围（去掉 `--month` / `--date`）
  - 检查拼写

- **命中过多**（matches > 100）：在结果开头给出建议：
  - "命中 N 条较多，建议加更具体的关键词或缩小时间范围"
  - 仍按上述模板输出，但只展示最有代表性的 10-20 条

- **`yra news search` 报错**：直接展示 stderr，参考故障排查段落。

- **`auth status` 失败**：让用户运行 `yra auth login`。

## 高级搜索模式

### 时间相关查询
- "昨天关于原油的消息" → `yra news search 原油 --date <昨天>`
- "本周美联储有什么动作" → `yra news search 美联储 --since <周一>`
- "6 月 1 日到 5 日通胀相关" → `yra news search 通胀 --since 20260601`，然后过滤 ≤ 6/5（或读用户意图：通常 since 已足够）

### 复合查询（AND）
- "美联储 + 加息" → `yra news search 美联储 加息`
- "Fed + rate cut" → `yra news search Fed "rate cut"`

### 大小写敏感
- 默认不区分大小写。如果用户明确要求精确匹配（如区分缩写大小写），加 `--case-sensitive`
