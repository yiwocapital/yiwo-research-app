---
name: yra-setup
name_zh: 安装与运维
description: |
  在已安装之后管理 yra CLI 和 Claude Code skills。
  用于升级 yra、升级 skills、重新认证、故障排除、卸载。
  首次安装请参考 INSTALL.md——本 skill 不能安装自己。
triggers:
  - "升级.*yra"
  - "升级.*skill"
  - "重装.*skill"
  - "卸载.*skill"
  - "更新.*CLI"
  - "upgrade.*yra"
  - "reinstall.*skill"
  - "uninstall.*skill"
  - "update.*cli"
  - "认证过期"
  - "重新登录"
  - "yra.*故障"
  - "troubleshoot.*yra"
capabilities:
  - manage-cli
  - manage-auth
  - manage-skills
  - troubleshoot
---

# YRA 安装与运维

在已安装之后管理 `yra` CLI 和相关 Claude Code skills（`yra-news-summarize-today`、`yra-news-search`、`yra-setup`）。

> **重要**：本 skill **仅用于已安装之后的管理**。首次安装时本 skill 不可用——请参考 [INSTALL.md](../../INSTALL.md) 由用户**手动**执行。

## 本 skill 能做什么

1. **检查状态** —— 诊断 yra CLI 和 skills 是否正常工作
2. **重新认证** —— 飞书扫码重新登录
3. **升级 yra CLI** —— 帮助用户下载 yra 二进制文件并安装新版本
4. **升级 skills** —— 帮助用户下载 skills 并安装新版本
5. **卸载 skills** —— 移除 Claude Code 中的 skill 符号链接
6. **故障排除** —— 按流程诊断常见问题

## 本 skill 不能做什么

- **首次安装 yra 或 skills**（因为还没有安装）

首次安装请引导用户参考 [INSTALL.md](../../INSTALL.md)。

## 常见操作

### 1. 检查 yra 版本

```bash
yra version
```

输出：
```
yra version v0.3.2 (commit: 3dd6621, built: 2026-06-09T15:50:37Z)
```

### 2. 重新认证

```bash
yra auth login
```

过程：
1. 打开浏览器跳转到飞书登录页面
2. 扫码或者输入账号密码登录
3. 成功后 CLI 输出认证成功消息

验证：

```bash
yra auth status --format json
```

预期输出：
```json
{"authenticated": true, "profile_dir": "/Users/.../browser-profile"}
```

**切换飞书账号**（同一台机器换用户）：

```bash
yra auth login --force
```

`--force` 会清掉当前 profile 并重弹扫码，等价于 `logout && login`。

### 3. 升级 yra CLI

终端用户按 [INSTALL.md](../../INSTALL.md) 中的命令手动下载新版本：

**macOS**：
```bash
curl -L -o /tmp/yra.tar.gz "https://github.com/yiwocapital/yiwo-research-app/releases/latest/download/yra_Darwin_arm64.tar.gz" && tar -xzf /tmp/yra.tar.gz -C ~/.local/bin/
```

**Linux**：
```bash
curl -L -o /tmp/yra.tar.gz "https://github.com/yiwocapital/yiwo-research-app/releases/latest/download/yra_Linux_x86_64.tar.gz" && tar -xzf /tmp/yra.tar.gz -C ~/.local/bin/
```

**Windows**：
```powershell
Invoke-WebRequest -Uri "https://github.com/yiwocapital/yiwo-research-app/releases/latest/download/yra_Windows_x86_64.zip" -OutFile "$env:TEMP\yra.zip"
Expand-Archive -Path "$env:TEMP\yra.zip" -DestinationPath "$env:LOCALAPPDATA\Programs\yra" -Force
```

> **提示**：升级不会清除用户的认证信息（token 保存在 `~/.config/yiwo-research-app/`）。

### 4. 卸载 skills

终端用户**通常没有本地仓库**，无法使用 `scripts/uninstall-skills.sh`。直接删除符号链接即可：

**macOS / Linux**：
```bash
rm -f ~/.claude/skills/yra-news-summarize-today \
      ~/.claude/skills/yra-news-search \
      ~/.claude/skills/yra-setup
```

**Windows**：
```powershell
Remove-Item "$env:USERPROFILE\.claude\skills\yra-news-summarize-today" -Force
Remove-Item "$env:USERPROFILE\.claude\skills\yra-news-search" -Force
Remove-Item "$env:USERPROFILE\.claude\skills\yra-setup" -Force
```

卸载后需要重启 Claude Code 才会生效。

### 5. 诊断问题

```bash
# 检查 CLI 可用
which yra && yra version

# 检查认证状态（JSON）
yra auth status --format json

# 检查 skills 是否安装
ls -la ~/.claude/skills/yra-news-summarize-today \
       ~/.claude/skills/yra-news-search \
       ~/.claude/skills/yra-setup

# 测试数据访问
yra news list-hours --date today --format json
```

## 故障排除流程

当用户报告问题时，按此流程处理：

```
用户报告问题
  ↓
yra 是否已安装？ → which yra
  ↓ 否
    → 未安装；引导用户参考 INSTALL.md
  ↓ 是
    ↓
    yra 是否已认证？ → yra auth status --format json
    ↓ 否 / 已过期
      → 运行：yra auth login
    ↓ 是
      ↓
      skills 是否存在？ → ls ~/.claude/skills/yra-news-* ~/.claude/skills/yra-setup
      ↓ 否
        → 让用户重新运行 INSTALL.md 的"安装 Skills"部分
      ↓ 是
        ↓
        自安装以来是否重启过 Claude Code？（需要用户确认）
        ↓ 否
          → 提示用户重启 Claude Code
        ↓ 是
          ↓
          测试数据访问：yra news list-hours --date today
          ↓ 失败
            → 跑带 --debug 看 chromedp 日志
            → 如果 SingletonLock 冲突：pgrep -f yiwo-research-app | xargs -r kill -TERM
            → 如果 context canceled：yra auth login --force 重扫一次
            → 仍然失败 → 联系开发团队
          ↓ 成功
            → skill 工作流应该正常；检查具体命令
```

## 常见错误码

| 错误 | 含义 | 处理 |
|------|------|------|
| `SingletonLock: File exists` | 上次 yra 遗留的 Chrome 进程 | `pgrep -f yiwo-research-app \| xargs -r kill -TERM`，然后重试 |
| `context canceled` | chromedp context 提前取消（v0.3.0 旧 bug） | 升级到 v0.3.1+ 或 `yra auth login --force` 重扫 |
| `chrome failed to start` | 本机无 Chrome/Edge/Chromium | 安装 Chrome 后重试 |
| 飞书 `1061004` | 没有 Drive 访问权限 | 联系数据管理员 |
| 飞书 `1061045` | 临时错误 | 等待几秒后重试 |

## 安全说明

- yra 0.3+ 不再持有任何飞书应用凭证（cookie 由本机 Chrome profile 管理）
- profile 目录权限 0700，其他用户无法读取 cookie
- 所有操作对飞书 Drive 都是只读的
- 本 skill 在用户机器上执行 shell 命令 —— 仅在用户**明确请求**时执行

## 不应使用本 skill 的情况

- 用户说"首次安装 yra" → 引导参考 INSTALL.md，不要自己运行安装脚本
- 用户希望修改飞书应用凭证 → **v0.3+ 已无此概念**，凭证完全在用户浏览器 session 里
- 用户希望更改 `yra` 读取的文件夹 → 需要代码变更和重新构建（folder token 硬编码在 `main.go`）
- 用户希望升级 skills 内容 → 需要开发者发布新版本（更新 install/ 子仓库的 SKILL.md + 跑 release 流程）
