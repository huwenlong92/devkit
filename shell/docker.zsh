# ==============================================================================
# Docker container shortcuts
# ==============================================================================

_devkit_docker_exec() {
  local container="$1"
  local docker_context="${DEVKIT_DOCKER_CONTEXT:-home}"
  local docker_exec_flags=(-i)
  shift

  if ! command -v docker >/dev/null 2>&1; then
    echo "❌ docker command not found" >&2
    return 127
  fi

  if ! command docker --context "$docker_context" container inspect "$container" >/dev/null 2>&1; then
    echo "❌ Docker container not found in context '$docker_context': $container" >&2
    return 1
  fi

  if [ -t 0 ] && [ -t 1 ]; then
    docker_exec_flags=(-it)
  fi

  command docker --context "$docker_context" exec "${docker_exec_flags[@]}" "$container" "$@"
}

_devkit_docker_shortcuts_help() {
  local docker_context="${DEVKIT_DOCKER_CONTEXT:-home}"

  cat <<EOF
DevKit Docker shortcuts

Context:
  docker --context ${docker_context}

Module:
  devkit-docker help              Show this help
  devkit-docker context           Print configured Docker context
  devkit-docker status            Show configured containers
  dkd                             Alias for devkit-docker

Redis:
  redis74 [redis-cli args]        Open redis-cli in redis-74
  redis74sh [shell args]          Open sh in redis-74
  r74                             Alias for redis74
  r74sh                           Alias for redis74sh

PostgreSQL:
  pg14 [psql args]                Open psql in postgresql-14 as postgres
  pg14sh [shell args]             Open bash in postgresql-14
  pg18 [psql args]                Open psql in postgresql-18 as postgres
  pg18sh [shell args]             Open bash in postgresql-18
  p14 / p18                       Aliases for pg14 / pg18

Examples:
  pg18 -d postgres -c 'select 1'
  pg14 -d postgres
  redis74 -a "\$REDIS_PASSWORD" PING

Config:
  DEVKIT_DOCKER_CONTEXT           Default: home
  DEVKIT_REDIS74_CONTAINER        Default: redis-74
  DEVKIT_POSTGRES14_CONTAINER     Default: postgresql-14
  DEVKIT_POSTGRES14_USER          Default: postgres
  DEVKIT_POSTGRES18_CONTAINER     Default: postgresql-18
  DEVKIT_POSTGRES18_USER          Default: postgres
EOF
}

devkit-docker() {
  local docker_context="${DEVKIT_DOCKER_CONTEXT:-home}"

  case "${1:-help}" in
    help|-h|--help)
      _devkit_docker_shortcuts_help
      ;;
    context)
      echo "$docker_context"
      ;;
    status)
      if ! command -v docker >/dev/null 2>&1; then
        echo "❌ docker command not found" >&2
        return 127
      fi

      command docker --context "$docker_context" ps \
        --filter "name=^/${DEVKIT_REDIS74_CONTAINER:-redis-74}$" \
        --filter "name=^/${DEVKIT_POSTGRES14_CONTAINER:-postgresql-14}$" \
        --filter "name=^/${DEVKIT_POSTGRES18_CONTAINER:-postgresql-18}$" \
        --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
      ;;
    *)
      echo "❌ Unknown devkit-docker command: $1" >&2
      echo "Run: devkit-docker help" >&2
      return 1
      ;;
  esac
}

redis74() {
  if [ "${1:-}" = "help" ]; then
    _devkit_docker_shortcuts_help
    return
  fi

  _devkit_docker_exec "${DEVKIT_REDIS74_CONTAINER:-redis-74}" redis-cli "$@"
}

redis74sh() {
  if [ "${1:-}" = "help" ]; then
    _devkit_docker_shortcuts_help
    return
  fi

  _devkit_docker_exec "${DEVKIT_REDIS74_CONTAINER:-redis-74}" sh "$@"
}

pg14() {
  if [ "${1:-}" = "help" ]; then
    _devkit_docker_shortcuts_help
    return
  fi

  _devkit_docker_exec "${DEVKIT_POSTGRES14_CONTAINER:-postgresql-14}" psql -U "${DEVKIT_POSTGRES14_USER:-postgres}" "$@"
}

pg14sh() {
  if [ "${1:-}" = "help" ]; then
    _devkit_docker_shortcuts_help
    return
  fi

  _devkit_docker_exec "${DEVKIT_POSTGRES14_CONTAINER:-postgresql-14}" bash "$@"
}

pg18() {
  if [ "${1:-}" = "help" ]; then
    _devkit_docker_shortcuts_help
    return
  fi

  _devkit_docker_exec "${DEVKIT_POSTGRES18_CONTAINER:-postgresql-18}" psql -U "${DEVKIT_POSTGRES18_USER:-postgres}" "$@"
}

pg18sh() {
  if [ "${1:-}" = "help" ]; then
    _devkit_docker_shortcuts_help
    return
  fi

  _devkit_docker_exec "${DEVKIT_POSTGRES18_CONTAINER:-postgresql-18}" bash "$@"
}

alias r74="redis74"
alias r74sh="redis74sh"
alias p14="pg14"
alias p14sh="pg14sh"
alias p18="pg18"
alias p18sh="pg18sh"
alias dkd="devkit-docker"
