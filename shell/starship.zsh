# ==============================================================================
# DevKit Starship 模块
# ==============================================================================

# Starship 配置文件：
# 1. STARSHIP_CONFIG / DEVKIT_STARSHIP_CONFIG 可以显式指定；
# 2. config/starship.toml 是 starship-theme 生成的本机当前主题；
# 3. config/starship/themes/default.toml 是 DevKit 默认主题。
if [ -z "$STARSHIP_CONFIG" ]; then
  if [ -n "$DEVKIT_STARSHIP_CONFIG" ]; then
    export STARSHIP_CONFIG="$DEVKIT_STARSHIP_CONFIG"
  elif [ -f "$DEVKIT/config/starship.toml" ]; then
    export STARSHIP_CONFIG="$DEVKIT/config/starship.toml"
  else
    export STARSHIP_CONFIG="$DEVKIT/config/starship/themes/default.toml"
  fi
fi

# 未安装 starship 时安静跳过。
if ! command -v starship >/dev/null 2>&1; then
  return 0 2>/dev/null || exit 0
fi

# 加载 Starship prompt。
eval "$(starship init zsh)"
