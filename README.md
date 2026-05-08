# DevKit shell zsh 脚本工具箱

DevKit 是一组面向日常开发环境的 zsh 小工具，用来把常用命令、代理开关和 Codex 工作流收进一个可复用的 shell 工具箱。配置后只需要 source 一次入口脚本，就可以在任意终端里使用这些快捷命令。

当前包含：

- DevKit 管理命令：`devkit refresh`，用于拉取最新仓库内容并重新加载当前 shell 配置。
- Codex 多模式快捷命令：`cx`、`cxr`、`cxf`、`cxs`、`cxv`，用于开发、只读分析、修复、SQL 检查和代码审查等场景。
- 代理管理命令：`proxy on|off|status|auto`，以及 npm、pnpm、git 代理开关和临时代理执行命令 `p`。
- Starship prompt：内置主题库 `config/starship/themes/`，可用 `starship-theme` 切换到本机的 `config/starship.toml`。
- Ghostty 终端集成：在 Ghostty 内自动加载 zsh shell integration，并提供 `gty` 查看、编辑配置和检查环境。
- eza 文件列表增强：安装 `eza` 后自动启用 `ls`、`ll`、`la`、`lt` 快捷命令。
- gvm Go 版本管理：安装 `gvm` 后由 `shell/gvm.zsh` 统一加载 Go 版本环境、pkgset 和 Go Module 默认配置。
- fnm Node.js 版本管理：安装 `fnm` 后自动初始化，并默认根据 `.node-version` / `.nvmrc` 切换版本；迁移后可用 `DEVKIT_NVM_ENABLE=0` 禁用 nvm。
- pnpm 包管理器：自动配置 `PNPM_HOME` 到 `PATH`，安装 `pnpm` 后自动加载 zsh 补全。
- 统一加载入口：通过 `shell/index.zsh` 自动加载 `shell/` 下的工具模块，方便继续扩展新的开发脚本。

安装和使用说明见 [docs/usage.md](docs/usage.md)。

gvm 的快速安装与使用示例：

```bash
brew install mercurial bison
bash < <(curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)

gvm install go1.22.5 -B
gvm use go1.22.5 --default
gvm pkgset create my-project
gvm pkgset use my-project
```
