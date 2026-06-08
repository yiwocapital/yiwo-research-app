# 安装指南

本文档面向**终端用户**。`install.sh` 会一次性安装 `yra` CLI 和 Claude Code skills。不涉及代码、编译或开发。

## 你需要知道什么

`yra` 是一个命令行工具（CLI），它会从飞书 Drive 拉取财经新闻数据给你使用。它已经预编译好，**不需要你自己编译**。

工具的工作方式：
- 第一次使用时，需要在你的浏览器里完成一次飞书 OAuth 授权（飞书会显示具体权限让你勾选）
- 授权后，访问令牌加密保存在本地。后续 30 天内无需重新授权（令牌会自动续期）
- 所有数据访问都使用**你自己的飞书账号权限**，读取你被授权查看的内容

## 系统要求

- 操作系统：**macOS** / **Linux** / **Windows**（10 及以上）
- 飞书账号：在壹渥组织租户内有效
- 浏览器：用于完成飞书 OAuth 授权（Chrome、Safari、Edge、Firefox 均可）

## 安装

打开终端，粘贴：

```bash
git clone https://github.com/yiwocapital/yiwo-research-app.git
cd yiwo-research-app
./install.sh
```

`install.sh` 会自动：
1. 检测你的操作系统和 CPU 架构
2. 从 [GitHub Releases](https://github.com/yiwocapital/yiwo-research-app/releases) 下载对应平台的 `yra` 二进制
3. 安装到 `~/.local/bin/yra`
4. 复制 3 个 Claude Code skills 到 `~/.claude/skills/`

需要自定义路径或只装部分：

```bash
./install.sh --help
```

常用选项：
- `--bin-dir <path>`：自定义 yra 二进制目录（默认 `~/.local/bin`）
- `--skills-dir <path>`：自定义 skills 父目录（默认 `~`，最终落到 `~/.claude/skills`）
- `--cli-only`：只装 yra，不装 skills
- `--skills-only`：只装 skills，不装 yra
- `--version v0.1.0`：安装指定版本（默认 latest）

## 配置 PATH（重要！）

安装后，必须让系统能找到 `yra` 命令。

### macOS

默认情况下 macOS 不会自动包含 `~/.local/bin` 这个目录。`install.sh` 在结束时如果检测到这点会提示你。你需要：

1. 打开 `~/.zshrc`（用 `nano ~/.zshrc` 或 `code ~/.zshrc`）
2. 在文件末尾添加一行：
   ```bash
   export PATH="$HOME/.local/bin:$PATH"
   ```
3. 保存文件，然后在终端运行：
   ```bash
   source ~/.zshrc
   ```
4. 验证：
   ```bash
   which yra
   ```
   应该输出类似 `/Users/你的用户名/.local/bin/yra`。

> **如果你的 shell 是 bash**（很罕见）：把 `~/.zshrc` 替换为 `~/.bash_profile`。

### Linux

大多数 Linux 发行版默认 PATH 包含 `~/.local/bin`，但 Ubuntu/Debian 桌面版可能不包含。处理方式与 macOS 相同——把 `export PATH="$HOME/.local/bin:$PATH"` 加入 `~/.bashrc`，然后 `source ~/.bashrc`。

### Windows

`install.sh` 当前不直接支持 Windows（脚本里 OS 检测会退出）。Windows 用户请在 PowerShell 中：

```powershell
# 下载 yra 二进制
Invoke-WebRequest -Uri "https://github.com/yiwocapital/yiwo-research-app/releases/latest/download/yra_Windows_x86_64.zip" -OutFile "$env:TEMP\yra.zip"

# 创建安装目录
New-Item -ItemType Directory -Force -Path "$env:LOCALAPPDATA\Programs\yra"
Expand-Archive -Path "$env:TEMP\yra.zip" -DestinationPath "$env:LOCALAPPDATA\Programs\yra"
Rename-Item "$env:LOCALAPPDATA\Programs\yra\yra_Windows_x86_64.exe" "$env:LOCALAPPDATA\Programs\yra\yra.exe"
```

然后把 `%LOCALAPPDATA%\Programs\yra` 加入 PATH：
1. 按 `Win` 键，搜索"环境变量"，选择"编辑系统环境变量"
2. 点击"环境变量"按钮
3. 在"用户变量"中找到 `Path`，双击打开
4. 点击"新建"，粘贴：`%LOCALAPPDATA%\Programs\yra`
5. 一路点击"确定"保存
6. **关闭并重新打开 PowerShell**

## 验证安装

打开新的终端窗口（重要——已经打开的需要关闭重开），运行：

```bash
yra version
```

预期输出：
```
yra version v0.1.0 (commit: unknown, built: 2026-06-08)
```

如果显示"command not found"或类似错误，请回到上面的"配置 PATH"部分。

## 飞书认证

首次使用前必须完成飞书 OAuth 授权。授权后，工具会在你本地保存一个加密的访问令牌。

### 步骤 1：触发授权流程

```bash
yra auth login
```

**重要**：`yra` 启动后会监听本地 `8080` 端口，用于接收飞书回调。
- 如果你的电脑**已经有程序占用 8080 端口**，授权会失败（详见下方"常见问题"）
- 不要关闭这个终端窗口——它会一直等待浏览器授权

### 步骤 2：在浏览器授权

终端会输出：
```
Opening browser for Feishu authentication...
If the browser doesn't open automatically, please visit:
https://open.feishu.cn/open-apis/authen/v1/index?app_id=...&scope=drive%3Adrive%3Areadonly...
```

**关键操作**：

1. 浏览器跳转到飞书授权页（如果没自动打开，复制 URL 手动粘贴）
2. **登录**你的飞书账号（如果还没登录）
3. 飞书会显示**权限列表**，会包含类似这样的条目：
   - ✅ **查看、评论和下载云空间中所有文件**（对应 `drive:drive:readonly`）
   - 其他默认身份权限（自动勾选）

   **必须勾选"查看、评论和下载云空间中所有文件"**这一项，否则后续数据访问会失败。
4. 点击**"同意"**或**"授权"**按钮
5. 浏览器显示"Authentication Successful"
6. 回到终端——CLI 自动完成

### 步骤 3：验证认证状态

```bash
yra auth status --format json
```

预期输出（**关键看 `scope` 字段**）：

```json
{
  "authenticated": true,
  "expired": false,
  "expires_at": "2026-06-07T18:00:00+08:00",
  "scope": "drive:drive:readonly"
}
```

如果 `scope` 字段**不包含** `drive:drive:readonly`，说明授权时没有勾选对应权限。需要重新授权（见下方"撤销权限并重新授权"）。

## 试一下

```bash
# 列出今天的小时文件
yra news list-hours --date today

# 获取 9 点的新闻（JSON 格式）
yra news get-hour --file 26060509-news.txt --format json

# 列出 6 月的日报
yra news list-dailies --month 202606

# 获取 6 月 4 日的日报
yra news get-daily --file 260604-daily-news.txt
```

## 撤销权限并重新授权

如果你之前授权时漏勾了某些权限，或想换一个飞书账号：

```bash
# 1. 清除本地保存的令牌
yra auth logout

# 2. 重新走授权流程
yra auth login
```

第二步会打开浏览器，**这次记得勾选所有需要的权限**。

## 令牌自动续期

- 访问令牌默认 **2 小时**过期
- 工具会在令牌过期**前 60 秒**自动用刷新令牌续期
- 刷新令牌默认 **30 天**有效
- 30 天后，或飞书主动撤销令牌时，必须重新 `auth login`

整个过程**完全自动**，正常使用中你不需要做任何事情。

## 卸载

```bash
# 在 git clone 的目录里
./uninstall.sh

# 或者在任意位置
bash /path/to/yiwo-research-app/uninstall.sh

# 跳过确认提示
./uninstall.sh --yes
```

`uninstall.sh` 会删除 yra 二进制和 3 个 skills 目录。

仅删 yra 二进制：
```bash
rm -f ~/.local/bin/yra
rm -rf ~/.config/yiwo-research-app
```

仅删 skills：
```bash
rm -rf ~/.claude/skills/yra-news-summarize-today
rm -rf ~/.claude/skills/yra-news-search-news
rm -rf ~/.claude/skills/yra-news-setup
```

## 升级

升级到最新版本，重新跑 `./install.sh`（在同一 git clone 目录内）：

```bash
cd yiwo-research-app
git pull
./install.sh
```

或者指定版本：

```bash
./install.sh --version v0.2.0
```

升级不会清除你的认证信息（令牌保存在 `~/.config/yiwo-research-app/config.enc`）。

## 常见问题

### "yra: command not found"

PATH 没有正确配置。回到"配置 PATH"部分。

### "Error: app credentials not configured. This binary was built without Feishu app credentials"

你下载的二进制没有内置飞书应用的 `app_id` 和 `app_secret`。请从官方渠道（壹渥内部发布地址）获取正确的二进制，不要使用未签名版本。

### OAuth 授权页面没有"查看、评论和下载云空间"等 Drive 权限

这说明当前飞书应用后台还没申请 `drive:drive:readonly` 等权限。请联系壹渥技术团队确认应用权限已经申请并发布。

### "Error: 8080 端口被占用"

CLI 需要用 8080 端口接收飞书回调。请：

1. 找出占用 8080 端口的程序：
   ```bash
   # macOS / Linux
   lsof -i :8080
   # 或
   netstat -an | grep 8080
   ```
2. 关闭该程序（或换一台没有占用的电脑）
3. 重新运行 `yra auth login`

### "feishu API error: 99991679 ... required one of these privileges: [drive:drive, drive:drive:readonly, space:document:retrieve]"

当前令牌的 `scope` 字段不包含 `drive:drive:readonly`。**这是因为你之前授权时漏勾了 Drive 权限**。解决：

1. `yra auth logout`
2. `yra auth login` —— 这次记得勾选"查看、评论和下载云空间中所有文件"
3. 重新验证：`yra auth status --format json`，确认 `scope` 包含 `drive:drive:readonly`

### "feishu API error: 1061004"

你的飞书账号没有被授权访问壹渥数据 Drive。联系数据管理员开通权限。

### "not authenticated" 或 "token expired"

令牌过期。运行 `yra auth login` 重新授权。

### 浏览器没自动打开

终端会打印一个 URL，手动复制到浏览器即可。

### Windows Defender 报警

下载的二进制是内部工具，未在微软商店签名。点击"更多信息"→"仍要运行"即可。

## 数据隐私

- 本工具**只读**访问飞书 Drive 中你被授权读取的内容
- 不会上传或修改你的任何文件
- OAuth 令牌加密保存在本地（`~/.config/yiwo-research-app/config.enc`）
- 不会向任何第三方发送数据
- 飞书应用后台**只申请了只读权限**（`drive:drive:readonly`），没有任何写权限

## 获取帮助

如遇问题：
1. 查看上面的"常见问题"部分
2. 在 GitHub Issues 提交问题
3. 联系壹渥技术团队
