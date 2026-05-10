# ==============================================================================
# DevKit Proxy Module
# ==============================================================================

# ------------------------------------------------------------------------------
# 基础配置
# ------------------------------------------------------------------------------
export DEVKIT_PROXY_HOST="${DEVKIT_PROXY_HOST:-127.0.0.1}"
export DEVKIT_HTTP_PROXY_PORT="${DEVKIT_HTTP_PROXY_PORT:-6666}"
export DEVKIT_SOCKS_PROXY_PORT="${DEVKIT_SOCKS_PROXY_PORT:-7890}"
#export DEVKIT_NO_PROXY="${DEVKIT_NO_PROXY:-localhost,127.0.0.1,::1,0.0.0.0,*.local,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,169.254.0.0/16}"
export DEVKIT_NO_PROXY="${DEVKIT_NO_PROXY:-localhost,127.0.0.1,::1,0.0.0.0,*.local,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,169.254.0.0/16,100.64.0.0/10}"

# 代理地址
_devkit_http_proxy="http://${DEVKIT_PROXY_HOST}:${DEVKIT_HTTP_PROXY_PORT}"
_devkit_socks_proxy="socks5://${DEVKIT_PROXY_HOST}:${DEVKIT_SOCKS_PROXY_PORT}"

_devkit_proxy_apply_no_proxy() {
  export no_proxy="$DEVKIT_NO_PROXY"
  export NO_PROXY="$DEVKIT_NO_PROXY"
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

  echo "✅ Proxy ON -> $http_proxy"
}

proxy_off() {
  unset http_proxy https_proxy all_proxy
  unset HTTP_PROXY HTTPS_PROXY ALL_PROXY
  unset no_proxy NO_PROXY
  echo "❌ Proxy OFF"
}

proxy_status() {
  echo "http_proxy=${http_proxy:-<empty>}"
  echo "https_proxy=${https_proxy:-<empty>}"
  echo "all_proxy=${all_proxy:-<empty>}"
  echo "no_proxy=${no_proxy:-<empty>}"
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
  echo "🌐 HTTP Proxy"
}

proxy_socks() {
  export all_proxy="$_devkit_socks_proxy"
  unset http_proxy https_proxy
  unset HTTP_PROXY HTTPS_PROXY
  export ALL_PROXY="$all_proxy"
  _devkit_proxy_apply_no_proxy
  echo "🧦 SOCKS Proxy"
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
  echo "📦 npm proxy ON"
}

npm_proxy_off() {
  npm config delete proxy
  npm config delete https-proxy
  npm config delete noproxy
  echo "📦 npm proxy OFF"
}

pnpm_proxy_on() {
  pnpm config set proxy "$_devkit_http_proxy"
  pnpm config set https-proxy "$_devkit_http_proxy"
  pnpm config set noproxy "$DEVKIT_NO_PROXY"
  echo "📦 pnpm proxy ON"
}

pnpm_proxy_off() {
  pnpm config delete proxy
  pnpm config delete https-proxy
  pnpm config delete noproxy
  echo "📦 pnpm proxy OFF"
}

# ------------------------------------------------------------------------------
# git
# ------------------------------------------------------------------------------
git_proxy_on() {
  git config --global http.proxy "$_devkit_http_proxy"
  git config --global https.proxy "$_devkit_http_proxy"
  git config --global http.noProxy "$DEVKIT_NO_PROXY"
  echo "🌿 git proxy ON"
}

git_proxy_off() {
  git config --global --unset http.proxy 2>/dev/null
  git config --global --unset https.proxy 2>/dev/null
  git config --global --unset http.noProxy 2>/dev/null
  echo "🌿 git proxy OFF"
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
    echo "⚠️ No proxy detected"
  fi
}

# ------------------------------------------------------------------------------
# 测试
# ------------------------------------------------------------------------------
ptest() {
  echo "Testing proxy..."
  p curl -I --max-time 10 https://www.google.com
}

# ------------------------------------------------------------------------------
# 节点切换（预留）
# ------------------------------------------------------------------------------
proxy_use() {
  case "$1" in
    hk|sg|jp)
      echo "🚧 switch node -> $1（后面接 clash API）"
      ;;
    *)
      echo "Usage: proxy use [hk|sg|jp]"
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
      echo "❌ Unknown: $1"
      echo "👉 proxy --help"
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
