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

_devkit_ghostty_message() {
  local icon="$1"
  local label="$2"
  local value="${3:-}"
  local color="${4:-32}"
  local bold reset

  if [[ -t 1 ]]; then
    bold=$'\033[1m'
    reset=$'\033[0m'
    printf "%s  \033[%sm%s%s%s" "$icon" "$color" "$bold" "$label" "$reset"
  else
    printf "%s  %s" "$icon" "$label"
  fi

  if [[ -n "$value" ]]; then
    printf "  %s" "$value"
  fi
  printf "\n"
}

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

  _devkit_ghostty_message "👻" "Ghostty status" "" 36
  printf "  %-24s %s\n" "TERM" "${TERM:-<empty>}"
  printf "  %-24s %s\n" "TERM_PROGRAM" "${TERM_PROGRAM:-<empty>}"
  printf "  %-24s %s\n" "GHOSTTY_RESOURCES_DIR" "${GHOSTTY_RESOURCES_DIR:-<empty>}"
  printf "  %-24s %s\n" "GHOSTTY_SHELL_FEATURES" "${GHOSTTY_SHELL_FEATURES:-<empty>}"
  printf "  %-24s %s\n" "config" "$config"
  printf "  %-24s %s\n" "config_exists" "$([ -f "$config" ] && echo yes || echo no)"
  printf "  %-24s %s\n" "zsh_integration" "${integration:-<empty>}"
  printf "  %-24s %s\n" "zsh_integration_readable" "$([ -n "$integration" ] && [ -r "$integration" ] && echo yes || echo no)"
}

ghostty_show_config() {
  _devkit_ghostty_command || return
  command ghostty +show-config "$@"
}

ghostty_install_terminfo() {
  local term="${DEVKIT_GHOSTTY_TERMINFO:-xterm-ghostty}"

  if [ $# -lt 1 ]; then
    _devkit_ghostty_message "❌" "Missing ssh target" "" 31 >&2
    _devkit_ghostty_message "👉" "Usage" "gty install-terminfo user@host" 36 >&2
    return 1
  fi

  if ! command -v infocmp >/dev/null 2>&1; then
    _devkit_ghostty_message "❌" "infocmp command not found" "" 31 >&2
    return 1
  fi

  if ! command -v ssh >/dev/null 2>&1; then
    _devkit_ghostty_message "❌" "ssh command not found" "" 31 >&2
    return 1
  fi

  _devkit_ghostty_message "⏫" "Install terminfo" "$term -> $*" 36
  _devkit_ghostty_terminfo_source "$term" | command ssh "$@" 'if command -v tic >/dev/null 2>&1; then tic -x -; else echo "tic command not found on remote host" >&2; exit 127; fi'
}

_devkit_ghostty_terminfo_source() {
  command infocmp -x "$1" | command awk '
    /^[[:space:]]*Setulc=/ {
      gsub(/%;m/, ";m")
    }
    !rewritten && $0 !~ /^[[:space:]]*#/ && $0 ~ /^[^[:space:]][^,]*,$/ {
      line = $0
      sub(/,$/, "", line)
      count = split(line, names, /\|/)
      if (count > 1 && names[count] !~ /[[:space:]]/) {
        line = names[1]
        for (i = 2; i < count; i++) {
          line = line "|" names[i]
        }
        print line "|" names[count] " terminal,"
        rewritten = 1
        next
      }
    }
    { print }
  '
}

_devkit_ghostty_command() {
  if ! command -v ghostty >/dev/null 2>&1; then
    _devkit_ghostty_message "❌" "ghostty command not found" "" 31 >&2
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
  gty ssh <ssh target/options>
  gty install-terminfo <ssh target/options>

Commands:
  status       显示 Ghostty 环境、配置文件和 zsh integration 状态
  path         显示当前 Ghostty 配置文件路径
  edit         创建并用 $EDITOR 打开配置文件
  show-config 透传 ghostty +show-config
  list-fonts  透传 ghostty +list-fonts
  list-themes 透传 ghostty +list-themes
  ssh-cache   透传 ghostty +ssh-cache
  ssh         使用兼容 TERM 连接 SSH
  install-terminfo
               将本机 xterm-ghostty terminfo 安装到远端账号

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
    ssh)
      shift
      ghostty_ssh "$@"
      ;;
    install-terminfo|ssh-terminfo)
      shift
      ghostty_install_terminfo "$@"
      ;;
    *)
      _devkit_ghostty_message "❌" "Unknown command" "$1" 31 >&2
      _devkit_ghostty_message "👉" "Try" "gty --help" 36 >&2
      return 1
      ;;
  esac
}

ghostty_ssh() {
  if [ $# -lt 1 ]; then
    cat <<'EOF'

gty ssh - Ghostty compatible SSH

Usage:
  gty ssh <ssh target/options>

Examples:
  gty ssh user@host
  gty ssh -p 2222 user@host
  gty ssh -i ~/.ssh/id_ed25519 user@host

EOF
    return 1
  fi

  TERM="${DEVKIT_GHOSTTY_SSH_TERM:-xterm-256color}" command ssh "$@"
}

# Ghostty 会自动给初始 zsh 注入 shell integration；这里再次 source 是安全的：
# 官方脚本会检测是否已经初始化。这样 `exec zsh` 或手动进入新 zsh 后仍能保留集成。
_devkit_ghostty_source_integration
