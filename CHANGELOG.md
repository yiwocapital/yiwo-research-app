# Changelog

## v0.3.5 (2026-06-10)

### 你需要做什么

1. **如果你是 v0.3.4 用户，立刻升级** —— v0.3.4 的 `yra news sync-today` / `get-hour` 文件下载**全部 404**，本次修复
2. 升级 yra：`./install.sh`（一次重装二进制 + 3 个 skills）
3. **升级后必须重启 Claude Code**，新 skill 内容才会被加载（已加载的 skill 在内存里，不重启不会刷新）

### 修复（紧急）

- **`yra news sync-today` / `get-hour` 下载 404 回归**
  - v0.3.4 改用直连飞书 web API 时误把飞书 `children/list` 返回的 `token`（drive 节点 ID）当作 `obj_token`（文件内容 ID）放在 `FileMeta.Token` 里返回
  - 下载请求 hit `/space/api/box/stream/download/all/<DRIVE_NODE_ID>/` —— 该端点要的是文件内容 ID，所以全部 404
  - 改为正确返回 `obj_token`；新增单元测试 `TestParseAPIResponse_TokenIsObjTokenNotDriveID` 用真实数据（`nodcn...` drive ID → `DSWv...` obj_token）pin 住修复
  - 新增 live E2E 测试 `TestLive_FolderToFile_E2E`（`//go:build live`），跑 `FolderPage.ListFiles` → `FilePage.Download` 完整路径，并探测下载 URL body 不为 404 —— 这是 gold-standard 回归测试，未来同类型 bug 即使所有单元测试都过也会被它逮住
  - 已在真实 profile 上 `yra news sync-today` smoke：今日 12 个小时文件全量下载成功（355KB 真实新闻内容），0 个 404

### 新增功能

- **发布资产新增 `skills.tar.gz`**：yra-setup skill 的手动升级流程可以一次下载 yra 二进制 + skills 一起重装，不用 clone 仓库
- **升级流程原子化**：每次 yra 二进制升级时**强制同时重装 skills**，无脑 rm + cp（不做版本检查 —— 文件小，检查反而更复杂）

### 有什么变化

- yra-setup skill「升级 yra CLI」一节升级为「升级 yra CLI + skills（原子操作）」，手动流程也走 release 上的 `skills.tar.gz`
- 手动升级 macOS/Linux 改用 `install -m 0755` + 通配符（替 `mv` + `chmod`），原子性更好、BSD-tar 安全
- 手动升级 Windows 改用 `Copy-Item` / `tar.exe`（Windows 10 1803+ 自带）
- `publish.sh` 现在同时打包 `skills.tar.gz` 与 5 个平台二进制，作为 release 资产上传

## v0.3.4 (2026-06-10)

### 你需要做什么

1. 升级 yra：`./install.sh`

### 有什么变化

- `yra news get-hour` / `sync-today` 的文件下载实现更稳定（之前偶发因为飞书前端改版而失败，现在改为直连飞书 web API）
- 错误信息更清晰（不再出现 `more-btn` 这类内部术语）

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
