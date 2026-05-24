# ==============================================================================
# DevKit Proxy Module
# ==============================================================================

# ------------------------------------------------------------------------------
# 基础配置
# ------------------------------------------------------------------------------
export DEVKIT_PROXY_HOST="${DEVKIT_PROXY_HOST:-127.0.0.1}"
export DEVKIT_HTTP_PROXY_PORT="${DEVKIT_HTTP_PROXY_PORT:-7890}"
export DEVKIT_SOCKS_PROXY_PORT="${DEVKIT_SOCKS_PROXY_PORT:-7890}"
if [[ -z "${DEVKIT_PROXY_PORTS:-}" ]]; then
  case "$DEVKIT_HTTP_PROXY_PORT" in
    7890) export DEVKIT_PROXY_PORTS="7890,6666" ;;
    6666) export DEVKIT_PROXY_PORTS="6666,7890" ;;
    *) export DEVKIT_PROXY_PORTS="${DEVKIT_HTTP_PROXY_PORT},7890,6666" ;;
  esac
else
  export DEVKIT_PROXY_PORTS
fi
export DEVKIT_PROXY_CHECK_URL="${DEVKIT_PROXY_CHECK_URL:-https://www.google.com/generate_204}"
export DEVKIT_PROXY_IPINFO_URL="${DEVKIT_PROXY_IPINFO_URL:-https://ipinfo.io/json}"
export DEVKIT_PROXY_IPINFO_V6_URL="${DEVKIT_PROXY_IPINFO_V6_URL:-https://ipinfo.io/json}"
export DEVKIT_PROXY_CHECK_TIMEOUT="${DEVKIT_PROXY_CHECK_TIMEOUT:-5}"
export DEVKIT_PROXY_CONNECT_TIMEOUT="${DEVKIT_PROXY_CONNECT_TIMEOUT:-2}"
export DEVKIT_PROXY_FORWARD_LISTEN_PORT="${DEVKIT_PROXY_FORWARD_LISTEN_PORT:-6666}"
export DEVKIT_PROXY_FORWARD_TARGET_PORT="${DEVKIT_PROXY_FORWARD_TARGET_PORT:-7890}"
export DEVKIT_PROXY_FORWARD_PID_DIR="${DEVKIT_PROXY_FORWARD_PID_DIR:-/tmp}"
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

_devkit_proxy_refresh_urls() {
  _devkit_http_proxy="http://${DEVKIT_PROXY_HOST}:${DEVKIT_HTTP_PROXY_PORT}"
  _devkit_socks_proxy="socks5://${DEVKIT_PROXY_HOST}:${DEVKIT_SOCKS_PROXY_PORT}"
}

_devkit_proxy_use_port() {
  export DEVKIT_HTTP_PROXY_PORT="$1"
  export DEVKIT_SOCKS_PROXY_PORT="$1"
  _devkit_proxy_refresh_urls
}

# 代理地址
_devkit_proxy_refresh_urls

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
  printf "  ${dim}%-12s${reset} %s\n" "auto ports" "$DEVKIT_PROXY_PORTS"

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

_devkit_check_proxy() {
  local port="$1"
  local proxy_url="http://${DEVKIT_PROXY_HOST}:${port}"

  if ! (( $+commands[curl] )); then
    _devkit_check_port "$port"
    return
  fi

  curl -fsS -o /dev/null \
    --connect-timeout "$DEVKIT_PROXY_CONNECT_TIMEOUT" \
    --max-time "$DEVKIT_PROXY_CHECK_TIMEOUT" \
    --proxy "$proxy_url" \
    "$DEVKIT_PROXY_CHECK_URL" >/dev/null 2>&1
}

proxy_auto() {
  local -a candidate_ports checked_ports
  local port

  candidate_ports=("${(@s:,:)DEVKIT_PROXY_PORTS}")

  for port in "${candidate_ports[@]}"; do
    [[ -n "$port" ]] || continue
    (( ${checked_ports[(Ie)$port]} )) && continue
    checked_ports+=("$port")

    if _devkit_check_proxy "$port"; then
      _devkit_proxy_use_port "$port"
      proxy_on
      return
    fi
  done

  proxy_off
  _devkit_proxy_message "⚠️" "No proxy detected" "$DEVKIT_PROXY_PORTS" 33
}

# ------------------------------------------------------------------------------
# 端口转发
# ------------------------------------------------------------------------------
_devkit_proxy_forward_pid_file() {
  local listen="${1:-$DEVKIT_PROXY_FORWARD_LISTEN_PORT}"
  echo "${DEVKIT_PROXY_FORWARD_PID_DIR}/devkit-proxy-forward-${DEVKIT_PROXY_HOST}-${listen}.pid"
}

start_forward() {
  local listen="${1:-$DEVKIT_PROXY_FORWARD_LISTEN_PORT}"
  local target="${2:-$DEVKIT_PROXY_FORWARD_TARGET_PORT}"
  local pid_file old_pid pid

  if ! (( $+commands[socat] )); then
    _devkit_proxy_message "❌" "Missing command" "socat" 31
    _devkit_proxy_message "👉" "Install" "brew install socat" 36
    return 127
  fi

  pid_file="$(_devkit_proxy_forward_pid_file "$listen")"

  if [[ -f "$pid_file" ]]; then
    old_pid="$(cat "$pid_file")"
    if [[ -n "$old_pid" ]] && kill -0 "$old_pid" 2>/dev/null; then
      _devkit_proxy_message "ℹ️" "Forward already running" "${DEVKIT_PROXY_HOST}:${listen}, pid=${old_pid}" 36
      return 0
    fi
    rm -f "$pid_file"
  fi

  socat "TCP-LISTEN:${listen},bind=${DEVKIT_PROXY_HOST},reuseaddr,fork" "TCP:${DEVKIT_PROXY_HOST}:${target}" &
  pid="$!"
  echo "$pid" > "$pid_file"

  sleep 0.2
  if ! kill -0 "$pid" 2>/dev/null; then
    rm -f "$pid_file"
    _devkit_proxy_message "❌" "Forward failed" "${DEVKIT_PROXY_HOST}:${listen} -> ${DEVKIT_PROXY_HOST}:${target}" 31
    return 1
  fi

  disown "$pid" 2>/dev/null || true
  _devkit_proxy_message "🔁" "Forward ON" "${DEVKIT_PROXY_HOST}:${listen} -> ${DEVKIT_PROXY_HOST}:${target}, pid=${pid}" 32
}

stop_forward() {
  local listen="${1:-$DEVKIT_PROXY_FORWARD_LISTEN_PORT}"
  local pid_file pid

  pid_file="$(_devkit_proxy_forward_pid_file "$listen")"

  if [[ ! -f "$pid_file" ]]; then
    _devkit_proxy_message "ℹ️" "Forward not running" "${DEVKIT_PROXY_HOST}:${listen}" 36
    return 0
  fi

  pid="$(cat "$pid_file")"

  if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
    kill "$pid" 2>/dev/null || true
    _devkit_proxy_message "⏹️" "Forward OFF" "${DEVKIT_PROXY_HOST}:${listen}, pid=${pid}" 31
  else
    _devkit_proxy_message "🧹" "Forward stale pid removed" "${DEVKIT_PROXY_HOST}:${listen}" 33
  fi

  rm -f "$pid_file"
}

forward_status() {
  local listen="${1:-$DEVKIT_PROXY_FORWARD_LISTEN_PORT}"
  local pid_file pid

  pid_file="$(_devkit_proxy_forward_pid_file "$listen")"

  if [[ ! -f "$pid_file" ]]; then
    _devkit_proxy_message "ℹ️" "Forward not running" "${DEVKIT_PROXY_HOST}:${listen}" 36
    return 0
  fi

  pid="$(cat "$pid_file")"
  if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
    _devkit_proxy_message "🔁" "Forward running" "${DEVKIT_PROXY_HOST}:${listen}, pid=${pid}" 32
  else
    _devkit_proxy_message "🧹" "Forward stale pid" "${DEVKIT_PROXY_HOST}:${listen}, pid=${pid}" 33
  fi
}

proxy_forward() {
  case "$1" in
    ""|start)
      start_forward "$2" "$3"
      ;;
    stop)
      stop_forward "$2"
      ;;
    status)
      forward_status "$2"
      ;;
    *)
      _devkit_proxy_message "👉" "Usage" "proxy forward start [listen] [target] | stop [listen] | status [listen]" 36
      ;;
  esac
}

# ------------------------------------------------------------------------------
# 测试
# ------------------------------------------------------------------------------
_devkit_json_get() {
  local json="$1"
  local key="$2"

  if (( $+commands[jq] )); then
    printf '%s' "$json" | jq -r --arg key "$key" '.[$key] // empty' 2>/dev/null
    return
  fi

  printf '%s\n' "$json" | sed -nE "s/^[[:space:]]*\"${key}\"[[:space:]]*:[[:space:]]*\"?([^\",}]*)\"?,?[[:space:]]*$/\\1/p" | head -n 1
}

_devkit_print_ipinfo() {
  local info_json="$1"
  local ip city region country loc org timezone printed

  printed=0
  ip="$(_devkit_json_get "$info_json" "ip")"
  city="$(_devkit_json_get "$info_json" "city")"
  region="$(_devkit_json_get "$info_json" "region")"
  country="$(_devkit_json_get "$info_json" "country")"
  loc="$(_devkit_json_get "$info_json" "loc")"
  org="$(_devkit_json_get "$info_json" "org")"
  timezone="$(_devkit_json_get "$info_json" "timezone")"

  [[ -n "$ip" ]] && { _devkit_proxy_message "🌐" "IP" "$ip" 36; printed=1; }
  [[ -n "$city$region$country" ]] && { _devkit_proxy_message "📍" "Location" "${city}${city:+, }${region}${region:+, }${country}" 36; printed=1; }
  [[ -n "$loc" ]] && { _devkit_proxy_message "🧭" "Coordinates" "$loc" 36; printed=1; }
  [[ -n "$org" ]] && { _devkit_proxy_message "🏢" "Org" "$org" 36; printed=1; }
  [[ -n "$timezone" ]] && { _devkit_proxy_message "🕒" "Timezone" "$timezone" 36; printed=1; }

  (( printed ))
}

_devkit_network_check() {
  local use_devkit_proxy="${1:-0}"
  local route_label route_value info_json access_status info_status
  local -a curl_cmd

  if ! (( $+commands[curl] )); then
    _devkit_proxy_message "❌" "Missing command" "curl" 31
    return 127
  fi

  if [[ "$use_devkit_proxy" == "1" ]]; then
    curl_cmd=(p curl)
    route_label="Testing proxy"
    route_value="$_devkit_http_proxy"
  else
    curl_cmd=(curl)
    route_label="Testing network"
    route_value="${http_proxy:-${HTTP_PROXY:-direct}}"
  fi

  _devkit_proxy_message "🧪" "$route_label" "$route_value" 36

  if "${curl_cmd[@]}" -fsS -o /dev/null \
    --connect-timeout "$DEVKIT_PROXY_CONNECT_TIMEOUT" \
    --max-time "$DEVKIT_PROXY_CHECK_TIMEOUT" \
    "$DEVKIT_PROXY_CHECK_URL" >/dev/null 2>&1; then
    _devkit_proxy_message "✅" "External access" "$DEVKIT_PROXY_CHECK_URL" 32
    access_status=0
  else
    _devkit_proxy_message "❌" "External access failed" "$DEVKIT_PROXY_CHECK_URL" 31
    access_status=1
  fi

  info_json="$("${curl_cmd[@]}" -fsSL \
    --connect-timeout "$DEVKIT_PROXY_CONNECT_TIMEOUT" \
    --max-time "$DEVKIT_PROXY_CHECK_TIMEOUT" \
    "$DEVKIT_PROXY_IPINFO_URL" 2>/dev/null)"
  info_status="$?"

  if [[ "$info_status" == "0" && -n "$info_json" ]]; then
    _devkit_print_ipinfo "$info_json" || _devkit_proxy_message "⚠️" "IP info unavailable" "$DEVKIT_PROXY_IPINFO_URL" 33
  else
    _devkit_proxy_message "⚠️" "IP info unavailable" "$DEVKIT_PROXY_IPINFO_URL" 33
  fi

  return "$access_status"
}

_devkit_primary_interface() {
  local iface

  if (( $+commands[route] )); then
    iface="$(route -n get default 2>/dev/null | awk '/interface:/{print $2; exit}')"
  fi
  if [[ -z "$iface" ]] && (( $+commands[netstat] )); then
    iface="$(netstat -rn -f inet 2>/dev/null | awk '$1 == "default" && $NF !~ /^(lo|utun|awdl|llw|bridge)/ {print $NF; exit}')"
  fi
  if [[ -z "$iface" ]] && (( $+commands[ip] )); then
    iface="$(ip route show default 2>/dev/null | awk '{print $5; exit}')"
  fi

  printf '%s\n' "$iface"
}

_devkit_print_lan_ips() {
  local found iface ip

  found=0
  iface="$(_devkit_primary_interface)"

  if [[ -n "$iface" ]]; then
    if (( $+commands[ipconfig] )); then
      ip="$(ipconfig getifaddr "$iface" 2>/dev/null)"
    fi
    if [[ -z "$ip" ]] && (( $+commands[ifconfig] )); then
      ip="$(ifconfig "$iface" 2>/dev/null | awk '/^[[:space:]]*inet / && $2 != "127.0.0.1" {print $2; exit}')"
    elif [[ -z "$ip" ]] && (( $+commands[ip] )); then
      ip="$(ip -o -4 addr show dev "$iface" scope global 2>/dev/null | awk '{ split($4, a, "/"); print a[1]; exit }')"
    fi

    if [[ -n "$ip" ]]; then
      _devkit_proxy_message "🏠" "LAN IPv4" "${iface}: ${ip}" 36
      found=1
    fi

    if (( $+commands[ifconfig] )); then
      while read -r ip; do
        [[ -n "$ip" ]] || continue
        _devkit_proxy_message "🏠" "LAN IPv6" "${iface}: ${ip}" 36
        found=1
      done < <(ifconfig "$iface" 2>/dev/null | awk '/^[[:space:]]*inet6 / && $2 != "::1" && $2 !~ /^fe80:/ {print $2}')
    elif (( $+commands[ip] )); then
      while read -r ip; do
        [[ -n "$ip" ]] || continue
        _devkit_proxy_message "🏠" "LAN IPv6" "${iface}: ${ip}" 36
        found=1
      done < <(ip -o -6 addr show dev "$iface" scope global 2>/dev/null | awk '{ split($4, a, "/"); print a[1] }')
    fi
  fi

  if ! (( found )); then
    _devkit_proxy_message "⚠️" "LAN IP unavailable" "no non-loopback IPv4/IPv6 found" 33
    return 1
  fi
}

ipcheck() {
  local info_json info_status public_found
  local -a curl_cmd

  if ! (( $+commands[curl] )); then
    _devkit_proxy_message "❌" "Missing command" "curl" 31
    return 127
  fi

  public_found=0
  _devkit_print_lan_ips
  _devkit_proxy_message "🧪" "Testing direct public IP" "no proxy" 36

  curl_cmd=(
    env
    -u http_proxy
    -u https_proxy
    -u all_proxy
    -u HTTP_PROXY
    -u HTTPS_PROXY
    -u ALL_PROXY
    curl
    --noproxy "*"
  )

  info_json="$("${curl_cmd[@]}" -fsSL \
    --connect-timeout "$DEVKIT_PROXY_CONNECT_TIMEOUT" \
    --max-time "$DEVKIT_PROXY_CHECK_TIMEOUT" \
    "$DEVKIT_PROXY_IPINFO_URL" 2>/dev/null)"
  info_status="$?"

  if [[ "$info_status" == "0" && -n "$info_json" ]]; then
    if _devkit_print_ipinfo "$info_json"; then
      public_found=1
    else
      _devkit_proxy_message "⚠️" "Direct IP unavailable" "$DEVKIT_PROXY_IPINFO_URL" 33
    fi
  else
    _devkit_proxy_message "❌" "Direct IP unavailable" "$DEVKIT_PROXY_IPINFO_URL" 31
  fi

  _devkit_proxy_message "🧪" "Testing direct public IPv6" "no proxy" 36
  info_json="$("${curl_cmd[@]}" -6 -fsSL \
    --connect-timeout "$DEVKIT_PROXY_CONNECT_TIMEOUT" \
    --max-time "$DEVKIT_PROXY_CHECK_TIMEOUT" \
    "$DEVKIT_PROXY_IPINFO_V6_URL" 2>/dev/null)"
  info_status="$?"

  if [[ "$info_status" == "0" && -n "$info_json" ]]; then
    if _devkit_print_ipinfo "$info_json"; then
      public_found=1
    else
      _devkit_proxy_message "ℹ️" "Public IPv6 unavailable" "$DEVKIT_PROXY_IPINFO_V6_URL" 36
    fi
  else
    _devkit_proxy_message "ℹ️" "Public IPv6 unavailable" "$DEVKIT_PROXY_IPINFO_V6_URL" 36
  fi

  (( public_found ))
}

ptest() {
  _devkit_network_check 1
}

vpncheck() {
  _devkit_network_check 0
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
  proxy check
  proxy ip
  proxy test

模式：
  proxy http
  proxy socks

工具：
  proxy npm on|off
  proxy pnpm on|off
  proxy git on|off
  proxy forward start [listen] [target]
  proxy forward stop [listen]
  proxy forward status [listen]

依赖：
  proxy forward 需要 socat；未安装时执行：brew install socat

节点（预留）：
  proxy use hk|sg|jp

推荐：
  ipcheck
  vpncheck
  proxy check
  p curl google.com
  start_forward
  stop_forward

EOF
      ;;

    on) proxy_on ;;
    off) proxy_off ;;
    status) proxy_status ;;
    auto) proxy_auto ;;
    check|test) ptest ;;
    ip|ipcheck) ipcheck ;;

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

    forward) proxy_forward "$2" "$3" "$4" ;;

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
alias pcheck="ptest"
alias vcheck="vpncheck"
alias myip="ipcheck"
alias fwdon="start_forward"
alias fwdoff="stop_forward"
