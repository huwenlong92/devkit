# ==============================================================================
# DevKit pnpm 模块
# ==============================================================================

# 允许在加载 DevKit 前禁用本模块：
#   export DEVKIT_PNPM_ENABLE=0
if [ "${DEVKIT_PNPM_ENABLE:-1}" = "0" ]; then
  return 0 2>/dev/null || exit 0
fi

# pnpm setup 默认使用这个目录；允许用户在加载 DevKit 前覆盖。
export PNPM_HOME="${PNPM_HOME:-$HOME/Library/pnpm}"

case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# 加载 pnpm 命令补全；未安装 pnpm 或旧版本不支持时安静跳过。
if command -v pnpm >/dev/null 2>&1; then
  eval "$(command pnpm completion zsh 2>/dev/null)"
fi
