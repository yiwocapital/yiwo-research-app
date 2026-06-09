---
name: yra-news-summarize-today
name_zh: 今日市场总结
description: |
  生成今日财经市场消息的结构化摘要报告。
  通过 `yra` CLI 从飞书 Drive 拉取小时新闻文件，
  然后使用 AI 进行分析并生成综合摘要。
triggers:
  - "总结今天的市场消息"
  - "今天有什么财经新闻"
  - "今日市场动态"
  - "summarize today"
  - "market summary"
  - "today's news"
  - "daily market report"
capabilities:
  - read-data
  - analyze-content
  - generate-summary
---

# 今日市场消息总结

生成今日财经市场消息的综合摘要。

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
yra auth status --format json
```

- 如果 `authenticated: false` 或 `expired: true`：提示用户运行 `yra auth login`。
- 如果已认证：进入步骤 3。

### 步骤 3：列出今日的小时文件

运行：

```bash
yra news list-hours --date today --format json
```

返回 JSON 数组：

```json
[
  {
    "token": "...",
    "name": "26060909新闻.txt",
    "size": 15360,
    "modified_at": "2026-06-09T09:59:04+08:00"
  }
]
```

按文件名（升序）排序以获得时序顺序。

### 步骤 4：拉取每小时文件内容

对每个文件运行：

```bash
yra news get-hour --file 26060909新闻.txt --format json
```

返回结构化 JSON：

```json
{
  "filename": "26060509-news.txt",
  "file_type": "hourly",
  "overview": {
    "time_range": "2026年06月05日 09:00 - 10:00",
    "total_count": 119,
    "generated_at": "2026-06-05 09:59:04",
    "importance": {
      "critical": 12,
      "important": 107,
      "normal": 0
    }
  },
  "messages": [
    {
      "number": 1,
      "source": "国内",
      "time": "2026-06-05T09:00:00+08:00",
      "importance": "很重要",
      "content": "..."
    }
  ],
  "raw_content": "..."
}
```

**性能说明**：每小时文件大小为 10-50KB。拉取 24 小时约 1MB，对直接拉取完全可接受。如果出现性能问题，可只拉取最近 3-6 小时。

### 步骤 5：生成摘要

分析所有已拉取的消息，生成结构化的 Markdown 报告：

#### 报告结构

```markdown
# 📊 壹渥市场动态摘要 - YYYY年MM月DD日

## 📋 概览

| 指标 | 数值 |
|------|------|
| 统计时段 | HH:00 - HH:00 |
| 消息总数 | N 条 |
| 🔴 很重要 | N 条 |
| 🟡 重要 | N 条 |
| ⚪ 普通 | N 条 |

## 🔴 关键事件

### [主题1]
[2-3 句话概括该主题下的重要事件]

### [主题2]
...

## 📰 重要消息精选

### 1. [来源] HH:MM
**重要性**: 🔴 很重要

[消息摘要，1-2 句话]

> 原文: [关键引述]

### 2. ...

## 📊 来源分布

| 来源 | 消息数 | 很重要 | 重要 |
|------|--------|--------|------|
| 国内 | N | N | N |
| 国外 | N | N | N |
| 彭博社 | N | N | N |
| 路透社 | N | N | N |
```

#### 分析指南

1. **主题提取**：按主题对消息分组（如货币政策、大宗商品、股票、外汇等）
2. **重要性加权**：在摘要中优先呈现"很重要"的消息
3. **时序展开**：同一主题内按时间顺序呈现事件
4. **交叉引用**：注意来自不同来源的相关消息
5. **简洁性**：每个主题摘要控制在 2-3 句话
6. **客观性**：陈述事实，除非用户明确要求否则不做推测

### 步骤 6：处理边界情况

- **今日无数据**：报告"今日暂无市场动态数据"
- **数据不完整**：注明缺失的小时
- **API 错误**：报告结构化错误并建议重试
