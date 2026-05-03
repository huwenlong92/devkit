# ==============================================================================
# DevKit Starship 模块
# ==============================================================================

# Starship 配置文件：
# 1. STARSHIP_CONFIG / DEVKIT_STARSHIP_CONFIG 可以显式指定；
# 2. config/starship.toml 是本机覆盖配置；
# 3. config/starship.default.toml 是 DevKit 默认模板。
if [ -z "$STARSHIP_CONFIG" ]; then
  if [ -n "$DEVKIT_STARSHIP_CONFIG" ]; then
    export STARSHIP_CONFIG="$DEVKIT_STARSHIP_CONFIG"
  elif [ -f "$DEVKIT/config/starship.toml" ]; then
    export STARSHIP_CONFIG="$DEVKIT/config/starship.toml"
  else
    export STARSHIP_CONFIG="$DEVKIT/config/starship.default.toml"
  fi
fi

# 未安装 starship 时安静跳过。
if ! command -v starship >/dev/null 2>&1; then
  return 0 2>/dev/null || exit 0
fi

# 加载 Starship prompt。
eval "$(starship init zsh)"
