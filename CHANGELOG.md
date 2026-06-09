# Changelog

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
