---
name: yra-setup
name_zh: 安装与运维
description: |
  在已安装之后管理 yra CLI 和 yra skills。
  支持 Claude Code（~/.claude/skills/）和 Codex（~/.codex/skills/）两个 runtime。
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

在已安装之后管理 `yra` CLI 和相关 yra skills（`yra-news-summarize-today`、`yra-news-search`、`yra-setup`）。

> **重要**：本 skill **仅用于已安装之后的管理**。首次安装时本 skill 不可用——请参考 [INSTALL.md](../../INSTALL.md) 由用户**手动**执行。

## 支持的 AI 客户端

yra skills 同时支持两个客户端。安装时默认两个都装，可用 `--target` 控制。

| 客户端 | skills 目录 | 重启方式 |
|--------|------------|---------|
| Claude Code | `~/.claude/skills/` | 退出并重新打开 Claude Code |
| Codex | `~/.codex/skills/` | 退出并重新打开 Codex |

下文所有「`~/.claude/skills/`」的代码示例都同样适用于 `~/.codex/skills/`——遇到一个就把另一个也改了。

## 本 skill 能做什么

1. **检查状态** —— 诊断 yra CLI 和 skills 是否正常工作
2. **重新认证** —— 飞书扫码重新登录
3. **升级 yra CLI** —— 帮助用户下载 yra 二进制文件并安装新版本
4. **升级 skills** —— 帮助用户下载 skills 并安装新版本
5. **卸载 skills** —— 移除 Claude Code 和/或 Codex 中的 skill 目录
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

### 3. 升级 yra CLI + skills（原子操作）

> **关键陷阱（必读）**：tarball / zip 内的二进制文件名是 `yra_<OS>_<ARCH>`（带平台后缀，例如 `yra_Darwin_arm64` / `yra_Windows_x86_64.exe`），**不是 `yra` / `yra.exe`**。
> `tar -xzf ... -C ~/.local/bin/` 不会覆盖现有的 `~/.local/bin/yra`，而是会**新增**一个 `yra_Darwin_arm64` 之类的文件 —— PATH 里的旧版 `yra` 还在跑，`yra version` 仍是旧号，看似升级失败。
> **必须先解压到临时目录，再覆盖为 `yra`**。macOS/Linux 用 `install -m 0755` 一步完成「复制 + 0755 权限」；Windows 用 `Copy-Item -Force` 覆盖为 `yra.exe`。
>
> **每次升级 yra 必须同时升级 skills**。skills 文件小，无脑删旧装新（**不要做版本检查**）—— install.sh 和下面的手动流程都已按此设计。

**推荐路径**：cd 到 git clone 目录，`git pull` + `./install.sh`。一次完成 yra 二进制 + skills 的重装。默认 `--target both` 同时装到 Claude Code 和 Codex；只想装一个就传 `--target claude` / `--target codex`。

如果用户不想 clone 仓库，手动升级流程（自动检测平台，4 平台通杀）。

> **升级 skills 时怎么处理两个 runtime**：默认同时升级到 `~/.claude/skills/` 和 `~/.codex/skills/`。如果用户明确说「我只用 Claude」，就只升 `~/.claude/skills/`；反过来同理。

**macOS / Linux**（默认升两个 runtime；想限定就把第二个 `TARGET_DIR=` 改掉）：

```bash
# 1. 检测平台 → 构造 yra tarball + skills tarball URL
OS=$(uname -s)
ARCH=$(uname -m)
case "$OS" in Darwin) OS="Darwin" ;; Linux) OS="Linux" ;; *) echo "Unsupported: $OS" >&2; exit 1 ;; esac
case "$ARCH" in x86_64|amd64) ARCH="x86_64" ;; arm64|aarch64) ARCH="arm64" ;; *) echo "Unsupported: $ARCH" >&2; exit 1 ;; esac
RELEASE_BASE="https://github.com/yiwocapital/yiwo-research-app/releases/latest/download"
YRA_TARBALL_URL="${RELEASE_BASE}/yra_${OS}_${ARCH}.tar.gz"
SKILLS_TARBALL_URL="${RELEASE_BASE}/skills.tar.gz"

# 2. 升级 yra 二进制
curl -L -o /tmp/yra.tar.gz "$YRA_TARBALL_URL"
rm -rf /tmp/yra-extract && mkdir -p /tmp/yra-extract
tar -xzf /tmp/yra.tar.gz -C /tmp/yra-extract
# 通配符 yra_* 匹配 yra_Darwin_arm64 / yra_Linux_x86_64 / yra_Linux_arm64
install -m 0755 /tmp/yra-extract/yra_* "$HOME/.local/bin/yra"
# 顺手清掉历史升级失败残留
rm -f "$HOME/.local/bin/yra_"*
rm -rf /tmp/yra-extract /tmp/yra.tar.gz

# 3. 升级 skills（无脑 rm + cp，不做版本检查；同时升两个 runtime）
curl -L -o /tmp/yra-skills.tar.gz "$SKILLS_TARBALL_URL"
rm -rf /tmp/yra-skills-extract && mkdir -p /tmp/yra-skills-extract
tar -xzf /tmp/yra-skills.tar.gz -C /tmp/yra-skills-extract
for TARGET_DIR in "$HOME/.claude/skills" "$HOME/.codex/skills"; do
    mkdir -p "$TARGET_DIR"
    for skill in yra-news-summarize-today yra-news-search yra-setup; do
        rm -rf "$TARGET_DIR/$skill"
        cp -R "/tmp/yra-skills-extract/skills/$skill" "$TARGET_DIR/$skill"
    done
done
rm -rf /tmp/yra-skills-extract /tmp/yra-skills.tar.gz

# 4. 验证
yra version   # 重启 Claude Code / Codex 后 skills 才会被重新加载
```

> **为什么不用 `tar -xzf -C ~/.local/bin/`**：tar 包内顶层文件名是 `yra_<OS>_<ARCH>`（带后缀），直接解压到目标目录会留下一个平台后缀的二进制文件，PATH 里旧的 `yra` 没被覆盖，升级看起来「没生效」。
>
> **提示**：升级不会清除用户的认证信息（token 保存在 `~/.config/yiwo-research-app/`）。

**Windows**（PowerShell）：

```powershell
# 0. 平台检测 + 路径常量
$OS = "Windows"
$Arch = switch ($env:PROCESSOR_ARCHITECTURE) {
    "AMD64" { "x86_64" }
    "ARM64" { "arm64" }
    default { throw "Unsupported: $env:PROCESSOR_ARCHITECTURE" }
}
$BinName = "yra_${OS}_${Arch}"
$ReleaseBase = "https://github.com/yiwocapital/yiwo-research-app/releases/latest/download"
$YraTarballUrl = "${ReleaseBase}/${BinName}.tar.gz"
$SkillsTarballUrl = "${ReleaseBase}/skills.tar.gz"
$InstallDir = "$env:LOCALAPPDATA\Programs\yra"
# 同时升 Claude Code 和 Codex 两个 runtime；想限定就只保留其中一个
$SkillsTargets = @("$env:USERPROFILE\.claude\skills", "$env:USERPROFILE\.codex\skills")
$YraTarballPath = "$env:TEMP\yra.tar.gz"
$YraExtractDir = "$env:TEMP\yra-extract"
$SkillsTarballPath = "$env:TEMP\yra-skills.tar.gz"
$SkillsExtractDir = "$env:TEMP\yra-skills-extract"

# 1. 升级 yra 二进制
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
Invoke-WebRequest -Uri $YraTarballUrl -OutFile $YraTarballPath
Remove-Item -Recurse -Force $YraExtractDir -ErrorAction SilentlyContinue
tar -xzf $YraTarballPath -C $YraExtractDir   # Windows 10 1803+ 自带 tar.exe
# tar 顶层是 yra_Windows_x86_64.exe，重命名为 yra.exe
Move-Item -Force "${YraExtractDir}\${BinName}.exe" "${InstallDir}\yra.exe"
# 清理历史残留 + 临时文件
Remove-Item -Force "${InstallDir}\${BinName}.exe" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force $YraExtractDir
Remove-Item -Force $YraTarballPath

# 2. 升级 skills（无脑 rm + cp，不做版本检查；同时升两个 runtime）
Invoke-WebRequest -Uri $SkillsTarballUrl -OutFile $SkillsTarballPath
Remove-Item -Recurse -Force $SkillsExtractDir -ErrorAction SilentlyContinue
tar -xzf $SkillsTarballPath -C $SkillsExtractDir
foreach ($SkillsTarget in $SkillsTargets) {
    New-Item -ItemType Directory -Force -Path $SkillsTarget | Out-Null
    foreach ($skill in @("yra-news-summarize-today", "yra-news-search", "yra-setup")) {
        Remove-Item -Recurse -Force "${SkillsTarget}\${skill}" -ErrorAction SilentlyContinue
        Copy-Item -Recurse -Force -Path "${SkillsExtractDir}\skills\${skill}" -Destination "${SkillsTarget}\${skill}"
    }
}
Remove-Item -Recurse -Force $SkillsExtractDir
Remove-Item -Force $SkillsTarballPath

# 3. 验证
yra version   # 重启 Claude Code / Codex 后 skills 才会被重新加载
```

### 4. 卸载 skills

直接删除 skills 文件即可。**同时清 Claude Code + Codex 两个 runtime**（用户说「我只用 X」时再只删对应那个）：

**macOS / Linux**：
```bash
# 全部
rm -rf ~/.claude/skills/yra-news-summarize-today \
       ~/.claude/skills/yra-news-search \
       ~/.claude/skills/yra-setup \
       ~/.codex/skills/yra-news-summarize-today \
       ~/.codex/skills/yra-news-search \
       ~/.codex/skills/yra-setup

# 只删 Claude Code
# rm -rf ~/.claude/skills/yra-news-summarize-today \
#        ~/.claude/skills/yra-news-search \
#        ~/.claude/skills/yra-setup

# 只删 Codex
# rm -rf ~/.codex/skills/yra-news-summarize-today \
#        ~/.codex/skills/yra-news-search \
#        ~/.codex/skills/yra-setup
```

**Windows**：
```powershell
# 全部
Remove-Item "$env:USERPROFILE\.claude\skills\yra-news-summarize-today" -Force
Remove-Item "$env:USERPROFILE\.claude\skills\yra-news-search" -Force
Remove-Item "$env:USERPROFILE\.claude\skills\yra-setup" -Force
Remove-Item "$env:USERPROFILE\.codex\skills\yra-news-summarize-today" -Force
Remove-Item "$env:USERPROFILE\.codex\skills\yra-news-search" -Force
Remove-Item "$env:USERPROFILE\.codex\skills\yra-setup" -Force
```

卸载后需要**重启对应的 AI 客户端**（Claude Code / Codex）才会生效。

### 5. 诊断问题

```bash
# 检查 CLI 可用
which yra && yra version

# 检查认证状态（JSON）
yra auth status --format json

# 检查 skills 是否安装（Claude Code）
ls -la ~/.claude/skills/yra-news-summarize-today \
       ~/.claude/skills/yra-news-search \
       ~/.claude/skills/yra-setup

# 检查 skills 是否安装（Codex）
ls -la ~/.codex/skills/yra-news-summarize-today \
       ~/.codex/skills/yra-news-search \
       ~/.codex/skills/yra-setup

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
                       → ls ~/.codex/skills/yra-news-* ~/.codex/skills/yra-setup
      ↓ 否
        → 让用户重新运行 INSTALL.md 的"安装 Skills"部分
        → 提示用 --target 控制范围：只想装 Claude Code 就 --target claude，
          只想装 Codex 就 --target codex，默认两个都装
      ↓ 是
        ↓
        自安装以来是否重启过对应 AI 客户端？（Claude Code / Codex）
        ↓ 否
          → 提示用户重启对应的 AI 客户端
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

## 安全说明

- yra 0.3+ 不再持有任何飞书应用凭证（cookie 由本机 Chrome profile 管理）
- profile 目录权限 0700，其他用户无法读取 cookie
- 所有操作对飞书 Drive 都是只读的
- 本 skill 在用户机器上执行 shell 命令 —— 仅在用户**明确请求**时执行

## 不应使用本 skill 的情况

- 用户说"首次安装 yra" → 引导参考 INSTALL.md，不要自己运行安装脚本
- 用户希望修改飞书应用凭证 → **v0.3+ 已无此概念**，凭证完全在用户浏览器 session 里
