# Usage

## Load DevKit

```bash
export DEVKIT="$HOME/devkit"
[ -f "$DEVKIT/shell/index.zsh" ] && source "$DEVKIT/shell/index.zsh"
```

建议把上面的内容放到 `~/.zshrc`，之后新开的终端会自动加载 `DEVKIT/bin` 和 `shell/` 下的快捷命令。

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

# npm / git 代理开关
proxy npm on
proxy npm off
proxy git on
proxy git off
```

## Starship prompt

DevKit 会在本机已经安装 `starship` 时加载 prompt。默认配置来自 `config/starship.default.toml`，如果存在 `config/starship.toml`，则会优先使用这个本机覆盖配置；该文件已被 `.gitignore` 忽略。

```bash
# macOS
brew install starship

# 查看当前配置
starship explain
```

如果想基于默认配置调整，可以先复制一份本机配置：

```bash
cp "$DEVKIT/config/starship.default.toml" "$DEVKIT/config/starship.toml"
```

也可以在加载 DevKit 之前显式指定其它配置文件：

```bash
export DEVKIT_STARSHIP_CONFIG="$HOME/.config/starship.toml"
```
