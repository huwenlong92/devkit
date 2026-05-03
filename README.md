# DevKit shell zsh 脚本工具箱

DevKit 是一组面向日常开发环境的 zsh 小工具，用来把常用命令、代理开关和 Codex 工作流收进一个可复用的 shell 工具箱。配置后只需要 source 一次入口脚本，就可以在任意终端里使用这些快捷命令。

当前包含：

- Codex 多模式快捷命令：`cx`、`cxr`、`cxf`、`cxs`、`cxv`，用于开发、只读分析、修复、SQL 检查和代码审查等场景。
- 代理管理命令：`proxy on|off|status|auto`，以及 npm、git 代理开关和临时代理执行命令 `p`。
- Starship prompt：默认使用 DevKit 内置的 `config/starship.default.toml`，也可以用本机的 `config/starship.toml` 覆盖。
- 统一加载入口：通过 `shell/index.zsh` 自动加载 `shell/` 下的工具模块，方便继续扩展新的开发脚本。

安装和使用说明见 [docs/usage.md](docs/usage.md)。
