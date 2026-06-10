# 安装指南

本文档面向**终端用户**。`install.sh` 会一次性安装 `yra` CLI 和 Claude Code skills。不涉及代码、编译或开发。

## 你需要知道什么

`yra` 是一个命令行工具（CLI），通过驱动本机 Chrome 浏览器从飞书云文档 Drive 拉取财经新闻数据给你使用。它已经预编译好，**不需要你自己编译**。

工具的工作方式：
- 第一次使用时，需要在 headed Chrome 里用飞书 App **扫码登录**
- 登录后，cookie 保存在本机 `~/.config/yiwo-research-app/browser-profile/`（目录权限 0700）
- cookie 在浏览器里 30 天内有效，30 天后再扫一次即可
- 所有数据访问都使用**你自己的飞书账号权限**，读取你被授权查看的内容

## 系统要求

- 操作系统：**macOS** / **Linux** / **Windows**（10 及以上）
- 飞书账号：相关数据资源需要**壹渥观察**授权，否则无法使用
- 浏览器：**Chrome** / **Edge** / **Chromium**（任一）—— yra 会调用本机已装的浏览器

## 安装

打开终端，粘贴：

```bash
git clone https://github.com/yiwocapital/yiwo-research-app.git
cd yiwo-research-app
./install.sh
```

`install.sh` 会自动：
1. 检测你的操作系统和 CPU 架构
2. 验证本机有 Chrome/Edge/Chromium（没有则提示安装）
3. 从 [GitHub Releases](https://github.com/yiwocapital/yiwo-research-app/releases) 下载对应平台的 `yra` 二进制
4. 安装到 `~/.local/bin/yra`
5. 复制 3 个 Claude Code skills 到 `~/.claude/skills/`

需要自定义路径或只装部分：

```bash
./install.sh --help
```

常用选项：
- `--bin-dir <path>`：自定义 yra 二进制目录（默认 `~/.local/bin`）
- `--skills-dir <path>`：自定义 skills 父目录（默认 `~`，最终落到 `~/.claude/skills`）
- `--cli-only`：只装 yra，不装 skills
- `--skills-only`：只装 skills，不装 yra
- `--version v0.3.0`：安装指定版本（默认 latest）

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
yra version v0.3.0 (commit: <short-sha>, built: <date>)
```

如果显示"command not found"或类似错误，请回到上面的"配置 PATH"部分。

## 飞书扫码登录

首次使用前必须扫码登录。**重要**：本机必须有 Chrome / Edge / Chromium 之一。

### 步骤 1：触发登录流程

```bash
yra auth login
```

这会：
1. 启动 headed Chrome 窗口
2. 打开飞书登录页 `https://accounts.feishu.cn/accounts/page/login?...`
3. 窗口里出现**二维码**

**关键操作**：

1. 打开手机飞书 App
2. 扫 Chrome 窗口里的二维码
3. 在飞书 App 上点"确认登录"
4. Chrome 窗口**自动**跳转到 `https://yiwocapital.feishu.cn/drive/home/`
5. 终端打印"登录成功"，cookie 已保存

> yra 不会自动打开 Chrome（避免占用你的工作浏览器）——它会用 chromedp 启动一个独立的 headless-when-needed 实例。**扫码页面就在那个弹出的窗口里**。如果窗口没看到，看任务栏 / Dock。

整个登录过程通常 5-30 秒。如果 5 分钟没扫码完成，命令会超时退出。

### 步骤 2：验证登录状态

```bash
yra auth status
```

预期输出（人类可读）：
```
Profile: /Users/你的用户名/.config/yiwo-research-app/browser-profile
Status: authenticated (cookies still valid)
```

或者 JSON 格式（`--format json`）：
```json
{
  "profile_dir": "/Users/你的用户名/.config/yiwo-research-app/browser-profile",
  "authenticated": true
}
```

如果 `authenticated` 是 `false`，说明 cookie 过期或缺失，重新 `yra auth login` 即可。

### Cookie 生命周期

- Chrome 的 cookie 默认 30 天有效
- 30 天后再扫一次（`yra auth login`）
- **整个过程完全自动**——你只需要在过期时手动重扫

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

## 撤销权限并重新登录

如果你之前登录时漏了某项权限，或想换一个飞书账号：

```bash
# 1. 清除本机 profile
yra auth logout

# 2. 重新走登录流程
yra auth login
```

第二步会打开 headed Chrome，**这次记得登录时勾选所有需要的权限**（飞书网页版会显示 Drive 访问权限）。

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
rm -rf ~/.claude/skills/yra-setup
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
./install.sh --version v0.3.0
```

升级**不会**清除你的 profile（cookie 保留在 `~/.config/yiwo-research-app/browser-profile/`）。

## 常见问题

### "yra: command not found"

PATH 没有正确配置。回到"配置 PATH"部分。

### "could not find a supported browser" / "no supported browser found on this system"

yra 找不到 Chrome / Edge / Chromium。安装一个：
- macOS: `brew install --cask google-chrome`
- Linux: `sudo apt update && sudo apt install -y chromium-browser`
- Windows: 下载 Chrome 安装

### headed Chrome 窗口没看到

`yra auth login` 启动的 Chrome 是独立进程，窗口可能在其他窗口后面。检查：
- macOS: 任务栏 / Dock
- Windows: 任务栏
- Linux: 看所有工作区

### "登录超时（5 分钟）"

二维码 5 分钟没扫完。重跑 `yra auth login`。

### "Browser.downloadProgress: ... state: completed" 但没文件落地

这是 v0.3.0 早期版本的 selector 问题。yarp 会：
- 找 `[data-e2e="more-operate-btn"]` 或 `[data-e2e="suite-more-btn"]`（更多按钮）
- 等菜单出现
- 找带 `<span class="item-badge-label">下载</span>` 的菜单项并 click

如果飞书改了 UI，按"撤销权限并重新登录"先确认 cookie 还在，再联系维护者更新 selectors。

### Chrome 弹欢迎对话框

v0.3.0 已在 profile 里写 `First Run` sentinel 和 `Default/Preferences`，正常情况下**不会**再弹"Welcome to Google Chrome"。如果还有，勾掉两个 checkbox（"设为默认浏览器"、"发送使用统计"）即可。

### Windows Defender 报警

下载的二进制是内部工具，未在微软商店签名。点击"更多信息"→"仍要运行"即可。

## 数据隐私

- 本工具**只读**通过你的浏览器会话访问飞书 Drive 中你被授权读取的内容
- 不会上传或修改你的任何文件
- cookie 保存在本地 `~/.config/yiwo-research-app/browser-profile/`（目录权限 0700）
- 不会向任何第三方发送数据
- 不向二进制里嵌入任何账号凭证——你看到的 yra 二进制可安全审计

## 获取帮助

如遇问题：
1. 查看上面的"常见问题"部分
2. 在 GitHub Issues 提交问题
3. 联系壹渥技术团队
