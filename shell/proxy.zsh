# ==============================================================================
# DevKit Proxy Module
# ==============================================================================

# ------------------------------------------------------------------------------
# 基础配置
# ------------------------------------------------------------------------------
export DEVKIT_PROXY_HOST="${DEVKIT_PROXY_HOST:-127.0.0.1}"
export DEVKIT_HTTP_PROXY_PORT="${DEVKIT_HTTP_PROXY_PORT:-6666}"
export DEVKIT_SOCKS_PROXY_PORT="${DEVKIT_SOCKS_PROXY_PORT:-7890}"
typeset -ga DEVKIT_NO_PROXY_ITEMS

if [[ -n "${DEVKIT_NO_PROXY:-}" ]]; then
  DEVKIT_NO_PROXY_ITEMS=("${(@s:,:)DEVKIT_NO_PROXY}")
else
  DEVKIT_NO_PROXY_ITEMS=(
    localhost
    127.0.0.1
    ::1
    0.0.0.0
    "*.local"
    10.0.0.0/8
    172.16.0.0/12
    192.168.0.0/16
    169.254.0.0/16
    100.64.0.0/10
  )
fi

_devkit_proxy_refresh_no_proxy() {
  export DEVKIT_NO_PROXY="${(j:,:)DEVKIT_NO_PROXY_ITEMS}"
}

_devkit_proxy_refresh_no_proxy

# 代理地址
_devkit_http_proxy="http://${DEVKIT_PROXY_HOST}:${DEVKIT_HTTP_PROXY_PORT}"
_devkit_socks_proxy="socks5://${DEVKIT_PROXY_HOST}:${DEVKIT_SOCKS_PROXY_PORT}"

_devkit_proxy_apply_no_proxy() {
  _devkit_proxy_refresh_no_proxy
  export no_proxy="$DEVKIT_NO_PROXY"
  export NO_PROXY="$DEVKIT_NO_PROXY"
}

_devkit_proxy_message() {
  local icon="$1"
  local label="$2"
  local value="${3:-}"
  local color="${4:-32}"
  local bold reset

  if [[ -t 1 ]]; then
    bold=$'\033[1m'
    reset=$'\033[0m'
    printf "%s  \033[%sm%s%s" "$icon" "$color" "$bold" "$label"
    printf "%s" "$reset"
  else
    printf "%s  %s" "$icon" "$label"
  fi

  if [[ -n "$value" ]]; then
    printf "  %s" "$value"
  fi
  printf "\n"
}

# ------------------------------------------------------------------------------
# 基础开关
# ------------------------------------------------------------------------------
proxy_on() {
  export http_proxy="$_devkit_http_proxy"
  export https_proxy="$_devkit_http_proxy"
  export all_proxy="$_devkit_socks_proxy"

  export HTTP_PROXY="$http_proxy"
  export HTTPS_PROXY="$https_proxy"
  export ALL_PROXY="$all_proxy"
  _devkit_proxy_apply_no_proxy

  _devkit_proxy_message "✅" "Proxy ON" "$http_proxy" 32
}

proxy_off() {
  unset http_proxy https_proxy all_proxy
  unset HTTP_PROXY HTTPS_PROXY ALL_PROXY
  unset no_proxy NO_PROXY
  _devkit_proxy_message "❌" "Proxy OFF" "" 31
}

proxy_status() {
  _devkit_proxy_refresh_no_proxy
  local -a active_no_proxy_items
  local bold dim cyan green yellow red reset
  local http_proxy_display https_proxy_display all_proxy_display

  if [[ -t 1 ]]; then
    bold=$'\033[1m'
    dim=$'\033[2m'
    cyan=$'\033[36m'
    green=$'\033[32m'
    yellow=$'\033[33m'
    red=$'\033[31m'
    reset=$'\033[0m'
  else
    bold=""
    dim=""
    cyan=""
    green=""
    yellow=""
    red=""
    reset=""
  fi

  if [[ -n "${no_proxy:-}" ]]; then
    active_no_proxy_items=("${(@s:,:)no_proxy}")
  else
    active_no_proxy_items=()
  fi

  http_proxy_display="${red}<empty>${reset}"
  https_proxy_display="${red}<empty>${reset}"
  all_proxy_display="${red}<empty>${reset}"

  [[ -n "${http_proxy:-}" ]] && http_proxy_display="${green}${http_proxy}${reset}"
  [[ -n "${https_proxy:-}" ]] && https_proxy_display="${green}${https_proxy}${reset}"
  [[ -n "${all_proxy:-}" ]] && all_proxy_display="${green}${all_proxy}${reset}"

  echo "${bold}${cyan}DevKit Proxy${reset}"
  printf "  ${dim}%-12s${reset} %s\n" "host" "$DEVKIT_PROXY_HOST"
  printf "  ${dim}%-12s${reset} %s\n" "http port" "$DEVKIT_HTTP_PROXY_PORT"
  printf "  ${dim}%-12s${reset} %s\n" "socks port" "$DEVKIT_SOCKS_PROXY_PORT"

  echo
  echo "${bold}${cyan}Environment${reset}"
  printf "  ${dim}%-12s${reset} %s\n" "http_proxy" "$http_proxy_display"
  printf "  ${dim}%-12s${reset} %s\n" "https_proxy" "$https_proxy_display"
  printf "  ${dim}%-12s${reset} %s\n" "all_proxy" "$all_proxy_display"
  if (( ${#active_no_proxy_items[@]} )); then
    printf "  ${dim}%-12s${reset} ${yellow}%s items${reset}\n" "no_proxy" "${#active_no_proxy_items[@]}"
  else
    printf "  ${dim}%-12s${reset} ${red}%s${reset}\n" "no_proxy" "<empty>"
  fi

  echo
  echo "${bold}${cyan}No proxy items${reset}"
  if (( ${#DEVKIT_NO_PROXY_ITEMS[@]} )); then
    local item
    for item in "${DEVKIT_NO_PROXY_ITEMS[@]}"; do
      printf "  ${yellow}-${reset} %s\n" "$item"
    done
  else
    echo "  ${red}<empty>${reset}"
  fi
}

# ------------------------------------------------------------------------------
# 模式
# ------------------------------------------------------------------------------
proxy_http() {
  export http_proxy="$_devkit_http_proxy"
  export https_proxy="$_devkit_http_proxy"
  unset all_proxy
  unset ALL_PROXY
  export HTTP_PROXY="$http_proxy"
  export HTTPS_PROXY="$https_proxy"
  _devkit_proxy_apply_no_proxy
  _devkit_proxy_message "🌐" "HTTP Proxy" "$http_proxy" 36
}

proxy_socks() {
  export all_proxy="$_devkit_socks_proxy"
  unset http_proxy https_proxy
  unset HTTP_PROXY HTTPS_PROXY
  export ALL_PROXY="$all_proxy"
  _devkit_proxy_apply_no_proxy
  _devkit_proxy_message "🧦" "SOCKS Proxy" "$all_proxy" 36
}

# ------------------------------------------------------------------------------
# 临时代理（推荐）
# ------------------------------------------------------------------------------
p() {
  http_proxy="$_devkit_http_proxy" \
  https_proxy="$_devkit_http_proxy" \
  all_proxy="$_devkit_socks_proxy" \
  no_proxy="$DEVKIT_NO_PROXY" \
  NO_PROXY="$DEVKIT_NO_PROXY" \
  "$@"
}

# ------------------------------------------------------------------------------
# npm / pnpm
# ------------------------------------------------------------------------------
npm_proxy_on() {
  npm config set proxy "$_devkit_http_proxy"
  npm config set https-proxy "$_devkit_http_proxy"
  npm config set noproxy "$DEVKIT_NO_PROXY"
  _devkit_proxy_message "📦" "npm proxy ON" "$_devkit_http_proxy" 32
}

npm_proxy_off() {
  npm config delete proxy
  npm config delete https-proxy
  npm config delete noproxy
  _devkit_proxy_message "📦" "npm proxy OFF" "" 31
}

pnpm_proxy_on() {
  pnpm config set proxy "$_devkit_http_proxy"
  pnpm config set https-proxy "$_devkit_http_proxy"
  pnpm config set noproxy "$DEVKIT_NO_PROXY"
  _devkit_proxy_message "📦" "pnpm proxy ON" "$_devkit_http_proxy" 32
}

pnpm_proxy_off() {
  pnpm config delete proxy
  pnpm config delete https-proxy
  pnpm config delete noproxy
  _devkit_proxy_message "📦" "pnpm proxy OFF" "" 31
}

# ------------------------------------------------------------------------------
# git
# ------------------------------------------------------------------------------
git_proxy_on() {
  git config --global http.proxy "$_devkit_http_proxy"
  git config --global https.proxy "$_devkit_http_proxy"
  git config --global http.noProxy "$DEVKIT_NO_PROXY"
  _devkit_proxy_message "🌿" "git proxy ON" "$_devkit_http_proxy" 32
}

git_proxy_off() {
  git config --global --unset http.proxy 2>/dev/null
  git config --global --unset https.proxy 2>/dev/null
  git config --global --unset http.noProxy 2>/dev/null
  _devkit_proxy_message "🌿" "git proxy OFF" "" 31
}

# ------------------------------------------------------------------------------
# 自动检测
# ------------------------------------------------------------------------------
_devkit_check_port() {
  nc -z "$DEVKIT_PROXY_HOST" "$1" >/dev/null 2>&1
}

proxy_auto() {
  if _devkit_check_port "$DEVKIT_HTTP_PROXY_PORT"; then
    proxy_on
  elif _devkit_check_port "$DEVKIT_SOCKS_PROXY_PORT"; then
    proxy_socks
  else
    proxy_off
    _devkit_proxy_message "⚠️" "No proxy detected" "" 33
  fi
}

# ------------------------------------------------------------------------------
# 测试
# ------------------------------------------------------------------------------
ptest() {
  _devkit_proxy_message "🧪" "Testing proxy" "$_devkit_http_proxy" 36
  p curl -I --max-time 10 https://www.google.com
}

# ------------------------------------------------------------------------------
# 节点切换（预留）
# ------------------------------------------------------------------------------
proxy_use() {
  case "$1" in
    hk|sg|jp)
      _devkit_proxy_message "🚧" "Switch node" "$1（后面接 clash API）" 33
      ;;
    *)
      _devkit_proxy_message "👉" "Usage" "proxy use [hk|sg|jp]" 36
      ;;
  esac
}

# ------------------------------------------------------------------------------
# CLI 入口
# ------------------------------------------------------------------------------
proxy() {
  case "$1" in
    ""|-h|--help|help)
      cat <<'EOF'

🧰 DevKit Proxy CLI

基础：
  proxy on
  proxy off
  proxy status
  proxy auto
  proxy test

模式：
  proxy http
  proxy socks

工具：
  proxy npm on|off
  proxy pnpm on|off
  proxy git on|off

节点（预留）：
  proxy use hk|sg|jp

推荐：
  p curl google.com

EOF
      ;;

    on) proxy_on ;;
    off) proxy_off ;;
    status) proxy_status ;;
    auto) proxy_auto ;;
    test) ptest ;;

    http) proxy_http ;;
    socks) proxy_socks ;;

    npm)
      [[ "$2" == "on" ]] && npm_proxy_on || npm_proxy_off
      ;;
    pnpm)
      [[ "$2" == "on" ]] && pnpm_proxy_on || pnpm_proxy_off
      ;;
    git)
      [[ "$2" == "on" ]] && git_proxy_on || git_proxy_off
      ;;

    use) proxy_use "$2" ;;

    *)
      _devkit_proxy_message "❌" "Unknown command" "$1" 31
      _devkit_proxy_message "👉" "Try" "proxy --help" 36
      ;;
  esac
}

# ------------------------------------------------------------------------------
# 兼容旧命令
# ------------------------------------------------------------------------------
alias pon="proxy_on"
alias poff="proxy_off"
alias psx="proxy_status"
alias pauto="proxy_auto"
