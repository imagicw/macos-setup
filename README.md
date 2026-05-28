# macos-setup

macOS 开发环境一键恢复脚本，用于在新机器上快速还原常用工具和 zsh 配置。

## 包含内容

### Homebrew CLI 工具

| 工具 | 说明 |
|------|------|
| git | 版本控制 |
| gh | GitHub CLI |
| python@3.13 | Python 稳定版 |
| uv | 快速 Python 包管理器 |
| deno | JS/TS 运行时 |
| go | Go 语言 |
| gemini-cli | Gemini CLI |
| yarn | JS 包管理器 |
| pandoc | 文档格式转换 |
| ffmpeg | 音视频处理 |
| yt-dlp | 视频下载 |
| mackup | dotfiles 同步工具 |

### GUI 应用（cask）

| 应用 | 说明 |
|------|------|
| raycast | 启动器 |
| claude-code | Claude Code |
| discord | 即时通讯 |
| handbrake | 视频转码 |
| imageoptim | 图片压缩 |
| input-source-pro | 输入法切换增强 |
| squirrel | Rime 输入法 |
| termius | SSH 客户端 |
| warp | 终端 |
| blackhole-2ch | 虚拟音频驱动 |

### zsh 配置

- **框架**：oh-my-zsh
- **主题**：powerlevel10k
- **插件**：
  - `zsh-autosuggestions` — 历史补全建议
  - `zsh-syntax-highlighting` — 命令实时高亮
  - `zsh-history-substring-search` — ↑↓ 前缀搜索历史

### Node.js 环境

- nvm 管理 Node.js 版本（默认安装 Node 24）
- pnpm（通过 corepack 安装）

## 使用方法

### 旧机器：备份配置

```bash
mackup backup
```

配置会同步到 iCloud Drive 的 `Mackup` 文件夹，包含 `.zshrc`、`.p10k.zsh`、`.gitconfig`、Warp、Rime 等。

### 新机器：恢复环境

**1. 运行脚本**

```bash
bash restore_zsh_env.sh
```

**2. 登录 iCloud，等待 Mackup 文件夹同步完成**

**3. 删除脚本写入的 bootstrap 配置**

```bash
rm ~/.zshrc ~/.zprofile ~/.gitconfig
```

**4. 执行 mackup restore**

```bash
mackup restore
```

**5. 重新打开终端**

p10k 配置向导会自动启动，按提示完成 prompt 样式配置。

## 需要手动处理的内容

| 项目 | 说明 |
|------|------|
| JetBrains Toolbox | 前往 [jetbrains.com/toolbox](https://www.jetbrains.com/toolbox-app/) 下载安装 |
| OrbStack | 前往 [orbstack.dev](https://orbstack.dev) 下载安装 |
| SSH 密钥 | 从旧机器手动复制 `~/.ssh/` 下的私钥文件 |
| Raycast 配置 | 使用 Raycast 内置导出：Settings → Advanced → Export |
