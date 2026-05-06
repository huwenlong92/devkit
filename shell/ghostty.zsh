# ==============================================================================
# DevKit Ghostty 模块
# ==============================================================================

# 设置 DEVKIT_GHOSTTY_ENABLE=0 可跳过本模块。
if [ "${DEVKIT_GHOSTTY_ENABLE:-1}" = "0" ]; then
  return 0 2>/dev/null || exit 0
fi

# Ghostty 1.2.3+ 推荐 config.ghostty；旧版仍会读取 config。
export DEVKIT_GHOSTTY_CONFIG_DIR="${DEVKIT_GHOSTTY_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/ghostty}"
export DEVKIT_GHOSTTY_CONFIG="${DEVKIT_GHOSTTY_CONFIG:-$DEVKIT_GHOSTTY_CONFIG_DIR/config.ghostty}"
export DEVKIT_GHOSTTY_LEGACY_CONFIG="${DEVKIT_GHOSTTY_LEGACY_CONFIG:-$DEVKIT_GHOSTTY_CONFIG_DIR/config}"

_devkit_ghostty_integration_path() {
  [ -n "$GHOSTTY_RESOURCES_DIR" ] || return 1
  printf '%s\n' "$GHOSTTY_RESOURCES_DIR/shell-integration/zsh/ghostty-integration"
}

_devkit_ghostty_source_integration() {
  local integration
  integration="$(_devkit_ghostty_integration_path)" || return 0

  [ -r "$integration" ] || return 0
  source "$integration"
}

_devkit_ghostty_config_path() {
  if [ -f "$DEVKIT_GHOSTTY_CONFIG" ] || [ ! -f "$DEVKIT_GHOSTTY_LEGACY_CONFIG" ]; then
    printf '%s\n' "$DEVKIT_GHOSTTY_CONFIG"
  else
    printf '%s\n' "$DEVKIT_GHOSTTY_LEGACY_CONFIG"
  fi
}

ghostty_config_path() {
  _devkit_ghostty_config_path
}

ghostty_edit_config() {
  local config
  config="$(_devkit_ghostty_config_path)"

  mkdir -p "${config:h}"
  [ -f "$config" ] || : > "$config"
  "${EDITOR:-vi}" "$config"
}

ghostty_status() {
  local config integration
  config="$(_devkit_ghostty_config_path)"
  integration="$(_devkit_ghostty_integration_path 2>/dev/null)"

  echo "TERM=${TERM:-<empty>}"
  echo "TERM_PROGRAM=${TERM_PROGRAM:-<empty>}"
  echo "GHOSTTY_RESOURCES_DIR=${GHOSTTY_RESOURCES_DIR:-<empty>}"
  echo "GHOSTTY_SHELL_FEATURES=${GHOSTTY_SHELL_FEATURES:-<empty>}"
  echo "config=$config"
  echo "config_exists=$([ -f "$config" ] && echo yes || echo no)"
  echo "zsh_integration=${integration:-<empty>}"
  echo "zsh_integration_readable=$([ -n "$integration" ] && [ -r "$integration" ] && echo yes || echo no)"
}

ghostty_show_config() {
  _devkit_ghostty_command || return
  command ghostty +show-config "$@"
}

_devkit_ghostty_command() {
  if ! command -v ghostty >/dev/null 2>&1; then
    echo "ghostty command not found" >&2
    return 1
  fi
}

gty() {
  case "${1:-}" in
    ""|-h|--help|help)
      cat <<'EOF'

DevKit Ghostty CLI

Usage:
  gty status
  gty path
  gty edit
  gty show-config [ghostty +show-config args]
  gty list-fonts
  gty list-themes
  gty ssh-cache [ghostty +ssh-cache args]

Commands:
  status       显示 Ghostty 环境、配置文件和 zsh integration 状态
  path         显示当前 Ghostty 配置文件路径
  edit         创建并用 $EDITOR 打开配置文件
  show-config 透传 ghostty +show-config
  list-fonts  透传 ghostty +list-fonts
  list-themes 透传 ghostty +list-themes
  ssh-cache   透传 ghostty +ssh-cache

Environment:
  DEVKIT_GHOSTTY_ENABLE=0              禁用本模块
  DEVKIT_GHOSTTY_CONFIG_DIR=<dir>      覆盖 Ghostty 配置目录
  DEVKIT_GHOSTTY_CONFIG=<file>         覆盖主配置文件路径

EOF
      ;;
    status|doctor)
      ghostty_status
      ;;
    path|config-path)
      ghostty_config_path
      ;;
    edit|config)
      ghostty_edit_config
      ;;
    show-config)
      shift
      ghostty_show_config "$@"
      ;;
    list-fonts)
      shift
      _devkit_ghostty_command || return
      command ghostty +list-fonts "$@"
      ;;
    list-themes|themes)
      shift
      _devkit_ghostty_command || return
      command ghostty +list-themes "$@"
      ;;
    ssh-cache)
      shift
      _devkit_ghostty_command || return
      command ghostty +ssh-cache "$@"
      ;;
    *)
      echo "Unknown command: $1" >&2
      echo "Try: gty --help" >&2
      return 1
      ;;
  esac
}

# Ghostty 会自动给初始 zsh 注入 shell integration；这里再次 source 是安全的：
# 官方脚本会检测是否已经初始化。这样 `exec zsh` 或手动进入新 zsh 后仍能保留集成。
_devkit_ghostty_source_integration
