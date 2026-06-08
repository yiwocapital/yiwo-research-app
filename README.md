# YIWO Research App (壹渥观察)

终端用户安装包和文档仓库。

## 安装

请阅读 [INSTALL.md](INSTALL.md) 获取详细安装步骤，或直接用统一的安装脚本：

```bash
git clone https://github.com/yiwocapital/yiwo-research-app.git
cd yiwo-research-app
./install.sh
```

这个脚本会一次性安装：
- `yra` CLI 二进制到 `~/.local/bin/`
- 3 个 Claude Code skills 到 `~/.claude/skills/`

需要自定义路径或只装部分：

```bash
./install.sh --help
```

卸载：

```bash
./uninstall.sh
```

## 许可

内部使用。
