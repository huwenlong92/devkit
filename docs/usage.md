# Usage

## Load DevKit

```bash
export DEVKIT="$HOME/devkit"
[ -f "$DEVKIT/shell/index.zsh" ] && source "$DEVKIT/shell/index.zsh"
```

建议把上面的内容放到 `~/.zshrc`，之后新开的终端会自动加载 `DEVKIT/bin` 和 `shell/` 下的快捷命令。

## Refresh DevKit

可以用一个命令拉取最新 DevKit，并重新加载当前 shell 配置：

```bash
devkit refresh
```

在已加载 DevKit 的 zsh 里，`devkit refresh` 会先在 `$DEVKIT` 目录执行 `git pull --ff-only`，成功后自动重新 `source "$DEVKIT/shell/index.zsh"`。

## Codex examples

`codex`、`cx` 以及 `cxr` / `cxf` / `cxs` / `cxv` 默认会通过 `fnm exec --using default` 运行 Codex，避免进入其他 Node.js 项目后被 `.node-version` / `.nvmrc` 切到没有安装 Codex 的版本。

```bash
# 开发模式：按项目规则完成开发任务
cx "实现登录页"

# 只读分析模式：只分析问题，不修改文件
cx --read "分析这个接口为什么慢"
cxr "看下这个模块的调用链"

# 修复模式：定位问题并做最小修改
cx --fix "修复单元测试失败"
cxf "修复用户列表分页异常"

# SQL 模式：重点检查 SQL、索引、Gorm 查询和事务
cx --sql "检查订单查询是否有 N+1 问题"
cxs "优化这段慢查询"

# 代码审查模式：只输出当前代码问题，按严重程度排列
cx --review "看下 bin/cx 写得是否合理"
cxv "审查最近的改动"
```

如果需要临时关闭这层固定 Node 版本的行为，可以在加载 DevKit 前设置：

```bash
export DEVKIT_CODEX_FNM_ENABLE=0

# 或者指定另一个 fnm 版本/别名
export DEVKIT_CODEX_FNM_VERSION=default
```

## Claude Code examples

`claude` 默认会先执行 `proxy auto`，再通过 `fnm exec --using default` 运行 Claude Code，避免进入其他 Node.js 项目后被 `.node-version` / `.nvmrc` 切到没有安装 Claude Code 的版本。

```bash
claude
claude "分析当前改动"
```

可以在加载 DevKit 前调整默认行为：

```bash
# 禁用 claude 启动前的代理自动检测
export DEVKIT_CLAUDE_PROXY_ENABLE=0

# 禁用 claude 固定 fnm Node 版本
export DEVKIT_CLAUDE_FNM_ENABLE=0

# 或者指定另一个 fnm 版本/别名
export DEVKIT_CLAUDE_FNM_VERSION=default
```

## Proxy examples

```bash
proxy status
proxy on
proxy off
proxy auto
proxy check
proxy ip

# 查看本机局域网 IP，以及不走代理的公网出口 IP / IPv6
ipcheck

# 直接检测当前网络 / VPN 出口
vpncheck

# 临时使用代理执行命令
p curl -I https://www.google.com

# npm / pnpm / git 代理开关
proxy npm on
proxy npm off
proxy pnpm on
proxy pnpm off
proxy git on
proxy git off

# 端口转发（默认 127.0.0.1:6666 -> 127.0.0.1:7890）
proxy forward start
proxy forward status
proxy forward stop
```

`proxy auto` 会按 `DEVKIT_PROXY_PORTS` 的顺序探测可用代理，默认包含当前配置端口、`7890` 和 `6666`。如果两个本地代理客户端分别监听不同端口，哪个端口当前能通过代理访问测试 URL，就会自动切到哪个端口：

```bash
export DEVKIT_PROXY_PORTS="7890,6666"
export DEVKIT_PROXY_CHECK_URL="https://www.google.com/generate_204"
```

`proxy check` 会通过 DevKit 当前代理检测外网访问，并请求 `ipinfo.io/json` 显示出口 IP、位置、运营商和时区。`vpncheck` 则不强制套 DevKit 代理，用当前 shell 网络环境直接检测，适合确认系统 VPN 是否生效。

`ipcheck` / `proxy ip` 会显示本机非 loopback 的局域网 IPv4/IPv6，并强制绕过 shell 代理查询公网出口 IP；如果当前网络有可用公网 IPv6，也会额外显示 IPv6 出口。

```bash
export DEVKIT_PROXY_IPINFO_URL="https://ipinfo.io/json"
export DEVKIT_PROXY_IPINFO_V6_URL="https://ipinfo.io/json"
```

`proxy forward` 依赖 `socat`。如果没有安装，运行 `proxy forward start` 时会提示安装命令；也可以提前安装：

```bash
brew install socat
```

默认会通过 `no_proxy/NO_PROXY` 让本机和常见内网地址不走代理：

```bash
localhost,127.0.0.1,::1,0.0.0.0,*.local,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,169.254.0.0/16
```

可以在加载 DevKit 前覆盖：

```bash
export DEVKIT_NO_PROXY="localhost,127.0.0.1,::1,192.168.1.0/24"
```

## eza file listing

DevKit 会在本机已经安装 `eza` 时自动启用文件列表增强；未安装时会安静跳过，保留系统 `ls`。

```bash
# macOS
brew install eza

# 常用快捷命令
ls
ll
la
lt
```

默认快捷命令：

```bash
ls  # eza --group-directories-first --icons=auto
ll  # long + git + long-iso time
la  # ll + hidden files
lt  # tree, default level 2
```

可以在加载 DevKit 之前覆盖默认选项：

```bash
export DEVKIT_EZA_BASE_OPTIONS="--group-directories-first --icons=never"
export DEVKIT_EZA_LONG_OPTIONS="-lh --git --time-style=long-iso"
export DEVKIT_EZA_TREE_LEVEL=3

# 或者禁用本模块
export DEVKIT_EZA_ENABLE=0
```

## fnm Node.js versions

DevKit 会在本机已经安装 `fnm` 时自动初始化 Node.js 版本管理；未安装时会安静跳过。

```bash
# macOS
brew install fnm

# 安装并使用 Node.js
fnm install --lts
fnm use --lts
```

默认会启用 `fnm env --shell zsh --version-file-strategy recursive --use-on-cd`，进入包含 `.node-version` 或 `.nvmrc` 的目录及其子目录时自动切换 Node.js 版本。

可以在加载 DevKit 之前调整默认行为：

```bash
# 禁用目录切换自动读取版本文件
export DEVKIT_FNM_USE_ON_CD=0

# 切回 fnm 默认的仅当前目录策略
export DEVKIT_FNM_VERSION_FILE_STRATEGY=local

# 或者禁用本模块
export DEVKIT_FNM_ENABLE=0
```

如果已经从 `nvm` 迁移到 `fnm`，建议在加载 DevKit 之前禁用 nvm 模块，避免两个 Node.js 版本管理器同时改写 PATH：

```bash
export DEVKIT_NVM_ENABLE=0
```

## gvm Go versions

DevKit 会在本机已经安装 `gvm` 时自动初始化 Go 版本管理；未安装时会安静跳过，并由 `go.zsh` 保留基础 Go 环境兜底。

安装 gvm 前先安装依赖：

```bash
xcode-select --install
brew install mercurial bison
```

然后执行官方 installer：

```bash
bash < <(curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)
```

安装完成后重新打开终端，或手动加载：

```bash
source "$HOME/.gvm/scripts/gvm"
```

```bash
# 安装并使用 Go 版本
gvm install go1.22.5 -B
gvm use go1.22.5 --default

# 查看当前 Go 环境
gvm list
go version
```

加载 gvm 后，Go 版本、`GOROOT`、`GOPATH` 和 `PATH` 由 gvm/pkgset 接管；DevKit 只统一补上 Go Module 默认配置：

```bash
export GO111MODULE="${GO111MODULE:-on}"
export GOPROXY="${GOPROXY:-https://goproxy.cn,direct}"
```

DevKit 默认会在 `cd` 后自动读取当前目录或父目录中的 Go 版本声明，进入项目时切到项目版本，离开项目后切回 gvm 默认版本。查找顺序是 `.go-version`、`go.work`、`go.mod`；`go.work` / `go.mod` 中优先使用 `toolchain`，没有时使用 `go`。如果项目存在 `.go-pkgset`，也会自动切换对应 pkgset。

```bash
# 项目根目录
echo "go1.25.10" > .go-version

# 或者通过 go.mod / go.work 声明
go 1.25
toolchain go1.25.10
```

Homebrew 的 bison 是 keg-only 包，不会默认覆盖系统自带版本；`gvm.zsh` 会自动把 `/opt/homebrew/opt/bison/bin` 或 `/usr/local/opt/bison/bin` 放到 `PATH` 前面，确保 gvm 使用 bison 3+。如果安装在其它位置，可以手动指定：

```bash
export DEVKIT_GVM_BISON_HOME="/opt/homebrew/opt/bison"
```

可以在加载 DevKit 之前覆盖默认路径、禁用模块，或指定进入 shell 时自动使用的版本：

```bash
export DEVKIT_GVM_ROOT="$HOME/.gvm"
export DEVKIT_GVM_DEFAULT_VERSION=go1.22.5
export DEVKIT_GVM_DEFAULT_PKGSET=global

# 禁用随目录自动切换 Go 版本
export DEVKIT_GVM_AUTO_USE=0

# 或者禁用 gvm 模块，继续使用 go.zsh 的基础 GOPATH/GOBIN 配置
export DEVKIT_GVM_ENABLE=0
```

常用示例：

```bash
# 查看所有可安装版本
gvm listall

# 新建并使用一个项目 pkgset
gvm pkgset create my-project
gvm pkgset use my-project

# 直接切换到某个版本和 pkgset
gvm use go1.22.5@my-project

# 给当前项目创建本地 pkgset
gvm pkgset create --local
gvm pkgset use --local
```

## pnpm package manager

DevKit 会自动把 `PNPM_HOME` 加入 `PATH`，方便使用 `pnpm setup` 或 Corepack 安装的 pnpm；已安装 `pnpm` 时会自动加载补全。

进入 Node.js 项目时，如果当前 shell 没有 `pnpm` 命令但有 `corepack`，DevKit 会默认通过 Corepack 启用 pnpm。触发条件是当前目录或父目录存在 `package.json`、`pnpm-lock.yaml`、`pnpm-workspace.yaml`，或 `package.json` 里声明了 `packageManager: "pnpm@..."`，或 scripts 里使用了 `pnpm` 命令。若 `packageManager` 明确声明为其他包管理器，DevKit 会尊重该声明并跳过自动启用 pnpm。

```bash
# 推荐配合 Corepack 安装
corepack enable
corepack prepare pnpm@latest --activate

# 查看版本
pnpm --version
```

默认的 `PNPM_HOME` 是：

```bash
$HOME/Library/pnpm
```

可以在加载 DevKit 之前覆盖或禁用：

```bash
export PNPM_HOME="$HOME/.local/share/pnpm"

# 禁用进入 pnpm 项目时的 Corepack 自动安装
export DEVKIT_PNPM_COREPACK_AUTO_INSTALL=0

# 只在明确的 pnpm 项目中自动启用，不把普通 package.json 项目默认视作 pnpm 项目
export DEVKIT_PNPM_ASSUME_PACKAGE_JSON=0

# 没有 packageManager 版本声明时，覆盖默认安装版本
export DEVKIT_PNPM_COREPACK_DEFAULT=pnpm@9

# 或者禁用本模块
export DEVKIT_PNPM_ENABLE=0
```

## Ghostty terminal

DevKit 会在 Ghostty 中自动加载 zsh shell integration，补上 `exec zsh`、手动进入新 zsh 等场景下 Ghostty 自动注入丢失的问题。未在 Ghostty 中运行时会安静跳过。

```bash
# 查看 Ghostty 环境、配置路径和 zsh integration 状态
gty status

# 显示当前配置文件路径
gty path

# 创建并用 $EDITOR 打开配置文件
gty edit
```

默认配置路径使用 Ghostty 新版推荐的 XDG 位置：

```bash
$HOME/.config/ghostty/config.ghostty
```

如果已存在旧版配置文件 `$HOME/.config/ghostty/config`，且还没有 `config.ghostty`，`gty path` 和 `gty edit` 会继续使用旧文件，避免迁移时误开空配置。

常用 Ghostty CLI 也可以通过 `gty` 透传：

```bash
gty show-config
gty show-config --default --docs
gty list-fonts
gty list-themes
gty ssh-cache --help
```

Ghostty 的 zsh shell integration 路径来自 Ghostty 启动时设置的 `GHOSTTY_RESOURCES_DIR`：

```bash
$GHOSTTY_RESOURCES_DIR/shell-integration/zsh/ghostty-integration
```

可以在加载 DevKit 之前覆盖或禁用：

```bash
export DEVKIT_GHOSTTY_CONFIG_DIR="$HOME/.config/ghostty"
export DEVKIT_GHOSTTY_CONFIG="$HOME/.config/ghostty/config.ghostty"

# 或者禁用本模块
export DEVKIT_GHOSTTY_ENABLE=0
```

如果需要启用 Ghostty 的 SSH / sudo shell integration 特性，请在 Ghostty 配置文件中设置，例如：

```bash
shell-integration-features = sudo,ssh-env,ssh-terminfo
```

## Starship prompt themes

DevKit 会在本机已经安装 `starship` 时加载 prompt。默认主题来自 `config/starship/themes/default.toml`；如果存在 `config/starship.toml`，则会优先使用这个本机当前主题，该文件已被 `.gitignore` 忽略。

```bash
# macOS
brew install starship

# 查看可用主题
starship-theme list
starship list

# 切换主题，会生成/覆盖 config/starship.toml
starship-theme use default
starship-theme use compact
starship use compact

# 查看当前主题
starship-theme current
starship current
```

主题库放在：

```bash
config/starship/themes/
```

可以新增自己的主题文件，例如 `config/starship/themes/work.toml`，然后执行：

```bash
starship-theme use work
```

如果只想临时编辑本机当前主题，可以直接改：

```bash
$DEVKIT/config/starship.toml
```

也可以在加载 DevKit 之前显式指定其它配置文件，跳过主题库：

```bash
export DEVKIT_STARSHIP_CONFIG="$HOME/.config/starship.toml"
```
