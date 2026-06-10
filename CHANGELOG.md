# Changelog

## v0.3.3 (2026-06-10)

### 你需要做什么

1. 升级 yra：`./install.sh`
2. 刷新 skill：`yra-setup` skill 跑一遍（或重新跑 `./install.sh`），让 `~/.claude/skills/yra-news-summarize-today/SKILL.md` 同步到新版「简报」格式

### 新增功能

- **`yra news sync-today [--force]`** —— 一行拉取今日所有小时新闻文件到本地缓存目录
  - 默认跳过已缓存的同名文件；`--force` 强制刷新
  - 自动清理缓存里所有**非今日**的残留文件
  - stdout 按文件名升序输出绝对路径（每行一个），方便管线消费
  - stderr 一行统计：`cleaned N stale, downloaded M, skipped K (already cached)`
- **缓存目录**（多平台）：
  - macOS / Linux：`~/.cache/yiwo-research-app/news/today/`
  - Windows：`%LOCALAPPDATA%\yiwo-research-app\cache\news\today\`
  - 文件权限 `0600`、目录 `0700`（用户私有）

### Skill 更新

- **`yra-news-summarize-today`** 全面重做：
  - 报告改为「壹渥简报（Yiwo Brief）」格式：**核心要点 + 宏观 / 行业 / 个股** 三大类
  - 输入流程改为 `yra news sync-today` 一行命令，移除原来的 bash 循环 + JSON 解析
  - 默认走原文 txt（不再 `--format json`），更省 token

### 有什么变化

- 之前要先 `yra news list-hours` 再循环 `get-hour --format json`，现在 `yra news sync-today` 一行搞定
- 简报内容更聚焦、更适合交易决策参考

## v0.3.0 (2026-06-09)

### 你需要做什么

1. 升级 yra：`./install.sh`
2. **安装 Chrome / Edge / Chromium**（任一，本机已装即可跳过）
3. **重新登录**：`yra auth login` → 弹 headed Chrome → 用飞书 App 扫码
4. 验证：`yra auth status` + `yra news list-hours --date $(date +%Y%m%d)`

### 新增功能

- **扫码登录**：`yra auth login` —— 弹浏览器窗口，用飞书 App 扫一下码
- **登出**：`yra auth logout` —— 删除当前登录态，方便换号
- **强制重新登录**：`yra auth login --force` —— 清掉当前登录态并重扫（一行切账号）
- **检查登录状态**：`yra auth status` —— 看 cookie 是否还有效，过期会提示

### 有什么变化

- 登录方式变了：以前用 OAuth 账号密码，现在改成浏览器扫码
- 你的本机现在需要装一个 Chrome / Edge / Chromium
- 不再需要任何飞书 app 凭证（没有 app id / app secret 需要保管）

### Skills 调整

- `yra-news-search-news` 重命名为 `yra-news-search`（升级时自动清理旧目录）

### 已知限制

- Windows / Linux 浏览器路径还在补；当前 macOS 体验最好
- 每个 yra 命令启动一次 Chrome（冷启动 1-2 秒）
- 错误提示以英文为主（机器友好），后续会优化
