# Changelog

## v0.3.0 (2026-06-08)

### Breaking changes

- **完全重写飞书访问层**：飞书 Open API (OAuth user_access_token) → chromedp 浏览器自动化
- **不再需要**飞书 app / OAuth / `FEISHU_APP_ID` / `FEISHU_APP_SECRET`
- **不再需要**企业租户成员关系（普通内部用户都能用）
- 原因：原方案要求 CLI 用户登录的飞书账号必须在数据生产者租户内

### 用户需要做的

1. 升级 yra：`./install.sh`
2. **安装 Chrome / Edge / Chromium**（任一，本机已装即可）
3. **删旧 OAuth 凭证**：`rm -f ~/.config/yiwo-research-app/config.enc`
4. **重新登录**：`yra auth login` → headed Chrome 弹出 → 用飞书 App **扫码**
5. 验证：`yra auth status` + `yra news list-hours --date $(date +%Y%m%d)`

### 新增

- `apps/pkg/yrafeushupage/` — 新的浏览器自动化 Go 库（**唯一的飞书访问入口**）
- `yra auth login` — 弹 headed Chrome → QR 扫码
- `yra auth logout` — 删除浏览器 profile（下次需重新扫码）
- `yra auth status` — 检查 cookie 是否还活着
- `--format json` 错误 JSON 输出含 `error_code` / `exit_code` / `context` / `fix` 字段
- Live test 框架（`//go:build live`）— 跑 `go test -tags=live ./apps/pkg/yrafeushupage/...` 验证 selector 健壮性

### 移除

- 内部 `apps/yra/internal/feishu/` 包（Open API 整个 client）
- 内部 `apps/yra/internal/auth/server.go`（OAuth callback HTTP server）
- 内部 `apps/yra/internal/auth/browser.go`（系统浏览器跳转）
- `model.AuthState` 类型 + 关联的 IsExpired / CanRefresh / RefreshIsExpired 方法
- `config` 包的加密 config.enc（`AES-GCM` 加密 + 机器派生密钥）
- `Makefile` 的 `FEISHU_APP_ID` / `FEISHU_APP_SECRET` ldflags 注入
- `cmd/yra/main.go` 的 `appID` / `appSecret` 变量
- `model.AuthState` JSON 字段（access_token / refresh_token / scope / etc.）

### 安全原则（CLAUDE.md 重写）

- **原则 1**：所有飞书资源访问必须走用户自己的浏览器会话（不得用 tenant_access_token / 预填 cookie）
- **原则 2**：profile 目录权限必须用户私有（0700）
- **原则 3**：发布给用户的二进制不内嵌任何账号凭证（无 ldflags 注入 app_id / app_secret）

### 已知限制

- Windows / Linux 浏览器路径：当前只测了 macOS（`/Applications/Google Chrome.app`）；其他平台需要后续补 `findBrowserExecutable` 的 `candidatePaths` 路径
- v0.3.0 first slice 限制：每个 yra 命令启动一次 Chrome（冷启动 1-2s）；频繁调用可考虑 future work 加 session 池
- 错误信息仍以英文为主（agent 友好），中文用户路径后续优化
