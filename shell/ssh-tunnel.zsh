# ==============================================================================
# DevKit SSH Tunnel Module
# ==============================================================================

export DEVKIT_VISPP_DB_SSH_TARGET="${DEVKIT_VISPP_DB_SSH_TARGET:-vispp.pro}"
export DEVKIT_VISPP_DB_LOCAL_HOST="${DEVKIT_VISPP_DB_LOCAL_HOST:-127.0.0.1}"
export DEVKIT_VISPP_DB_LOCAL_PORT="${DEVKIT_VISPP_DB_LOCAL_PORT:-15432}"
export DEVKIT_VISPP_DB_REMOTE_HOST="${DEVKIT_VISPP_DB_REMOTE_HOST:-127.0.0.1}"
export DEVKIT_VISPP_DB_REMOTE_PORT="${DEVKIT_VISPP_DB_REMOTE_PORT:-5432}"
export DEVKIT_VISPP_DB_CONTROL_PATH="${DEVKIT_VISPP_DB_CONTROL_PATH:-/tmp/devkit-vispp-db-ssh.sock}"
export DEVKIT_VISPP_DB_SERVER_ALIVE_INTERVAL="${DEVKIT_VISPP_DB_SERVER_ALIVE_INTERVAL:-60}"
export DEVKIT_VISPP_DB_SERVER_ALIVE_COUNT_MAX="${DEVKIT_VISPP_DB_SERVER_ALIVE_COUNT_MAX:-3}"

_devkit_ssh_tunnel_message() {
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

_devkit_vispp_db_forward_spec() {
  printf "%s:%s:%s:%s" \
    "$DEVKIT_VISPP_DB_LOCAL_HOST" \
    "$DEVKIT_VISPP_DB_LOCAL_PORT" \
    "$DEVKIT_VISPP_DB_REMOTE_HOST" \
    "$DEVKIT_VISPP_DB_REMOTE_PORT"
}

_devkit_vispp_db_status_quiet() {
  command ssh \
    -S "$DEVKIT_VISPP_DB_CONTROL_PATH" \
    -O check \
    "$DEVKIT_VISPP_DB_SSH_TARGET" >/dev/null 2>&1
}

_devkit_vispp_db_start() {
  local forward_spec
  forward_spec="$(_devkit_vispp_db_forward_spec)"

  if _devkit_vispp_db_status_quiet; then
    _devkit_ssh_tunnel_message "✅" "vispp-db already running" \
      "${DEVKIT_VISPP_DB_LOCAL_HOST}:${DEVKIT_VISPP_DB_LOCAL_PORT}" 32
    return
  fi

  [[ -S "$DEVKIT_VISPP_DB_CONTROL_PATH" ]] && command rm -f "$DEVKIT_VISPP_DB_CONTROL_PATH"

  command ssh \
    -M \
    -S "$DEVKIT_VISPP_DB_CONTROL_PATH" \
    -f \
    -N \
    -L "$forward_spec" \
    -o ExitOnForwardFailure=yes \
    -o ServerAliveInterval="$DEVKIT_VISPP_DB_SERVER_ALIVE_INTERVAL" \
    -o ServerAliveCountMax="$DEVKIT_VISPP_DB_SERVER_ALIVE_COUNT_MAX" \
    "$DEVKIT_VISPP_DB_SSH_TARGET" || return

  _devkit_ssh_tunnel_message "✅" "vispp-db tunnel started" \
    "${DEVKIT_VISPP_DB_LOCAL_HOST}:${DEVKIT_VISPP_DB_LOCAL_PORT} -> ${DEVKIT_VISPP_DB_REMOTE_HOST}:${DEVKIT_VISPP_DB_REMOTE_PORT} via ${DEVKIT_VISPP_DB_SSH_TARGET}" 32
}

_devkit_vispp_db_stop() {
  if ! _devkit_vispp_db_status_quiet; then
    _devkit_ssh_tunnel_message "❌" "vispp-db not running" "" 31
    return
  fi

  command ssh \
    -S "$DEVKIT_VISPP_DB_CONTROL_PATH" \
    -O exit \
    "$DEVKIT_VISPP_DB_SSH_TARGET" >/dev/null || return

  _devkit_ssh_tunnel_message "✅" "vispp-db tunnel stopped" "" 32
}

_devkit_vispp_db_status() {
  if _devkit_vispp_db_status_quiet; then
    _devkit_ssh_tunnel_message "✅" "vispp-db running" \
      "${DEVKIT_VISPP_DB_LOCAL_HOST}:${DEVKIT_VISPP_DB_LOCAL_PORT} -> ${DEVKIT_VISPP_DB_REMOTE_HOST}:${DEVKIT_VISPP_DB_REMOTE_PORT} via ${DEVKIT_VISPP_DB_SSH_TARGET}" 32
  else
    _devkit_ssh_tunnel_message "❌" "vispp-db not running" "" 31
    return 1
  fi
}

_devkit_vispp_db_usage() {
  cat <<'EOF'
vispp-db - SSH tunnel for vispp.pro PostgreSQL

Usage:
  vispp-db start
  vispp-db stop
  vispp-db restart
  vispp-db status

Default tunnel:
  127.0.0.1:15432 -> 127.0.0.1:5432 via vispp.pro

Environment:
  DEVKIT_VISPP_DB_SSH_TARGET
  DEVKIT_VISPP_DB_LOCAL_HOST
  DEVKIT_VISPP_DB_LOCAL_PORT
  DEVKIT_VISPP_DB_REMOTE_HOST
  DEVKIT_VISPP_DB_REMOTE_PORT
  DEVKIT_VISPP_DB_CONTROL_PATH
EOF
}

vispp-db() {
  case "${1:-start}" in
    start)
      _devkit_vispp_db_start
      ;;
    stop)
      _devkit_vispp_db_stop
      ;;
    restart)
      _devkit_vispp_db_status_quiet && _devkit_vispp_db_stop
      _devkit_vispp_db_start
      ;;
    status)
      _devkit_vispp_db_status
      ;;
    help|-h|--help)
      _devkit_vispp_db_usage
      ;;
    *)
      _devkit_ssh_tunnel_message "❌" "Unknown vispp-db command" "$1" 31
      _devkit_vispp_db_usage >&2
      return 2
      ;;
  esac
}
