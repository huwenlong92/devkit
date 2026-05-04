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

## Proxy examples

```bash
proxy status
proxy on
proxy off
proxy auto

# 临时使用代理执行命令
p curl -I https://www.google.com

# npm / pnpm / git 代理开关
proxy npm on
proxy npm off
proxy pnpm on
proxy pnpm off
proxy git on
proxy git off
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

默认会启用 `fnm env --use-on-cd --shell zsh`，进入包含 `.node-version` 或 `.nvmrc` 的目录时自动切换 Node.js 版本。

可以在加载 DevKit 之前调整默认行为：

```bash
# 禁用目录切换自动读取版本文件
export DEVKIT_FNM_USE_ON_CD=0

# 或者禁用本模块
export DEVKIT_FNM_ENABLE=0
```

如果已经从 `nvm` 迁移到 `fnm`，建议在加载 DevKit 之前禁用 nvm 模块，避免两个 Node.js 版本管理器同时改写 PATH：

```bash
export DEVKIT_NVM_ENABLE=0
```

## pnpm package manager

DevKit 会自动把 `PNPM_HOME` 加入 `PATH`，方便使用 `pnpm setup` 或 Corepack 安装的 pnpm；未安装 `pnpm` 时会安静跳过补全加载。

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

# 或者禁用本模块
export DEVKIT_PNPM_ENABLE=0
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
