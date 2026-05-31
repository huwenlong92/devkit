# ==============================================================================
# Docker container shortcuts
# ==============================================================================

_devkit_docker_context() {
  echo "${DEVKIT_DOCKER_CONTEXT:-home}"
}

_devkit_pg_container() {
  case "$1" in
    14) echo "${DEVKIT_POSTGRES14_CONTAINER:-postgresql-14}" ;;
    18) echo "${DEVKIT_POSTGRES18_CONTAINER:-postgresql-18}" ;;
  esac
}

_devkit_pg_user() {
  case "$1" in
    14) echo "${DEVKIT_POSTGRES14_USER:-postgres}" ;;
    18) echo "${DEVKIT_POSTGRES18_USER:-postgres}" ;;
  esac
}

_devkit_docker_require_container() {
  local container="$1"
  local docker_context="$(_devkit_docker_context)"

  if ! command -v docker >/dev/null 2>&1; then
    echo "❌ docker command not found" >&2
    return 127
  fi

  if ! command docker --context "$docker_context" container inspect "$container" >/dev/null 2>&1; then
    echo "❌ Docker container not found in context '$docker_context': $container" >&2
    return 1
  fi
}

_devkit_docker_exec() {
  local container="$1"
  local docker_context="$(_devkit_docker_context)"
  local docker_exec_flags=(-i)
  shift

  _devkit_docker_require_container "$container" || return

  if [ -t 0 ] && [ -t 1 ]; then
    docker_exec_flags=(-it)
  fi

  command docker --context "$docker_context" exec "${docker_exec_flags[@]}" "$container" "$@"
}

_devkit_pg_dump_help() {
  local version="$1"
  local command_name="pg${version}dump"

  cat <<EOF
${command_name} - dump a PostgreSQL ${version} database from the configured Docker context

Usage:
  ${command_name} <database> [dump-file] [-U user]
  ${command_name} <database> [dump-file] [-U user] -- [pg_dump args]

Defaults:
  file: ./<database>-<timestamp>.dump
  user: \$DEVKIT_POSTGRES${version}_USER or postgres
  format: custom dump, with --no-owner --no-acl

Examples:
  ${command_name} template_db
  ${command_name} template_db ./template.dump -U template_user
  ${command_name} template_db ./template-public.dump -U template_user -- -n public
  ${command_name} template_db ./template-schema.dump -U template_user -- --schema-only
EOF
}

_devkit_pg_restore_help() {
  local version="$1"
  local command_name="pg${version}restore"

  cat <<EOF
${command_name} - restore a PostgreSQL ${version} custom dump into a database

Usage:
  ${command_name} <dump-file> <database> [-U user] [--role role] [--clean]
  ${command_name} <dump-file> <database> [-U user] -- [pg_restore args]

Defaults:
  user: \$DEVKIT_POSTGRES${version}_USER or postgres
  restore options: --no-owner --no-acl

Examples:
  ${command_name} ./template.dump new_project_db -U new_project_user
  ${command_name} ./template.dump new_project_db -U postgres --role new_project_user
  ${command_name} ./template.dump new_project_db -U postgres --clean
EOF
}

_devkit_pg_dump() {
  local version="$1"
  local command_name="pg${version}dump"
  shift

  if [[ "${1:-}" == "help" || "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    _devkit_pg_dump_help "$version"
    return
  fi

  local container="$(_devkit_pg_container "$version")"
  local docker_context="$(_devkit_docker_context)"
  local user="$(_devkit_pg_user "$version")"
  local db=""
  local file=""
  local timestamp
  local -a extra_args

  while [ $# -gt 0 ]; do
    case "$1" in
      -U|--user)
        if [ -z "${2:-}" ]; then
          echo "❌ Missing value for $1" >&2
          return 2
        fi
        user="$2"
        shift 2
        ;;
      -f|--file)
        if [ -z "${2:-}" ]; then
          echo "❌ Missing value for $1" >&2
          return 2
        fi
        file="$2"
        shift 2
        ;;
      --)
        shift
        extra_args=("$@")
        break
        ;;
      -*)
        echo "❌ Unknown ${command_name} option: $1" >&2
        echo "Run: ${command_name} help" >&2
        return 2
        ;;
      *)
        if [ -z "$db" ]; then
          db="$1"
        elif [ -z "$file" ]; then
          file="$1"
        else
          echo "❌ Unexpected argument: $1" >&2
          echo "Run: ${command_name} help" >&2
          return 2
        fi
        shift
        ;;
    esac
  done

  if [ -z "$db" ]; then
    echo "❌ Missing database name" >&2
    echo "Run: ${command_name} help" >&2
    return 2
  fi

  if [ -z "$file" ]; then
    timestamp="$(date +%Y%m%d-%H%M%S)"
    file="./${db}-${timestamp}.dump"
  fi

  _devkit_docker_require_container "$container" || return

  echo "Dumping ${db} from ${container} (${docker_context}) as ${user} -> ${file}" >&2
  command docker --context "$docker_context" exec -i "$container" \
    pg_dump -U "$user" -d "$db" --format=custom --no-owner --no-acl "${extra_args[@]}" > "$file"
}

_devkit_pg_restore() {
  local version="$1"
  local command_name="pg${version}restore"
  shift

  if [[ "${1:-}" == "help" || "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    _devkit_pg_restore_help "$version"
    return
  fi

  local container="$(_devkit_pg_container "$version")"
  local docker_context="$(_devkit_docker_context)"
  local user="$(_devkit_pg_user "$version")"
  local file=""
  local db=""
  local role=""
  local clean="0"
  local -a extra_args restore_args

  while [ $# -gt 0 ]; do
    case "$1" in
      -U|--user)
        if [ -z "${2:-}" ]; then
          echo "❌ Missing value for $1" >&2
          return 2
        fi
        user="$2"
        shift 2
        ;;
      --role)
        if [ -z "${2:-}" ]; then
          echo "❌ Missing value for $1" >&2
          return 2
        fi
        role="$2"
        shift 2
        ;;
      --clean)
        clean="1"
        shift
        ;;
      --)
        shift
        extra_args=("$@")
        break
        ;;
      -*)
        echo "❌ Unknown ${command_name} option: $1" >&2
        echo "Run: ${command_name} help" >&2
        return 2
        ;;
      *)
        if [ -z "$file" ]; then
          file="$1"
        elif [ -z "$db" ]; then
          db="$1"
        else
          echo "❌ Unexpected argument: $1" >&2
          echo "Run: ${command_name} help" >&2
          return 2
        fi
        shift
        ;;
    esac
  done

  if [ -z "$file" ] || [ -z "$db" ]; then
    echo "❌ Missing dump file or database name" >&2
    echo "Run: ${command_name} help" >&2
    return 2
  fi

  if [ ! -f "$file" ]; then
    echo "❌ Dump file not found: $file" >&2
    return 1
  fi

  _devkit_docker_require_container "$container" || return

  restore_args=(-U "$user" -d "$db" --no-owner --no-acl)
  if [ -n "$role" ]; then
    restore_args+=(--role "$role")
  fi
  if [ "$clean" = "1" ]; then
    restore_args+=(--clean --if-exists)
  fi
  restore_args+=("${extra_args[@]}")

  echo "Restoring ${file} into ${db} on ${container} (${docker_context}) as ${user}" >&2
  command docker --context "$docker_context" exec -i "$container" \
    pg_restore "${restore_args[@]}" < "$file"
}

_devkit_docker_shortcuts_help() {
  local docker_context="$(_devkit_docker_context)"

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
  pg14dump <db> [file] [-U user]  Dump a PostgreSQL 14 database
  pg14restore <file> <db> [-U user]
                                  Restore a PostgreSQL 14 dump
  pg18 [psql args]                Open psql in postgresql-18 as postgres
  pg18sh [shell args]             Open bash in postgresql-18
  pg18dump <db> [file] [-U user]  Dump a PostgreSQL 18 database
  pg18restore <file> <db> [-U user]
                                  Restore a PostgreSQL 18 dump
  p14 / p18                       Aliases for pg14 / pg18
  p14dump / p18dump               Aliases for pg14dump / pg18dump
  p14restore / p18restore         Aliases for pg14restore / pg18restore

Examples:
  pg18 -d postgres -c 'select 1'
  pg18dump template_db ./template.dump -U template_user
  pg18restore ./template.dump new_project_db -U new_project_user
  pg18restore ./template.dump new_project_db -U postgres --role new_project_user
  pg18restore ./template.dump new_project_db -U postgres --clean
  pg14dump template_db ./template14.dump -U template_user
  pg14restore ./template14.dump new_project_db -U new_project_user
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
  local docker_context="$(_devkit_docker_context)"

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

  _devkit_docker_exec "$(_devkit_pg_container 14)" psql -U "$(_devkit_pg_user 14)" "$@"
}

pg14sh() {
  if [ "${1:-}" = "help" ]; then
    _devkit_docker_shortcuts_help
    return
  fi

  _devkit_docker_exec "$(_devkit_pg_container 14)" bash "$@"
}

pg14dump() {
  _devkit_pg_dump 14 "$@"
}

pg14restore() {
  _devkit_pg_restore 14 "$@"
}

pg18() {
  if [ "${1:-}" = "help" ]; then
    _devkit_docker_shortcuts_help
    return
  fi

  _devkit_docker_exec "$(_devkit_pg_container 18)" psql -U "$(_devkit_pg_user 18)" "$@"
}

pg18sh() {
  if [ "${1:-}" = "help" ]; then
    _devkit_docker_shortcuts_help
    return
  fi

  _devkit_docker_exec "$(_devkit_pg_container 18)" bash "$@"
}

pg18dump() {
  _devkit_pg_dump 18 "$@"
}

pg18restore() {
  _devkit_pg_restore 18 "$@"
}

alias r74="redis74"
alias r74sh="redis74sh"
alias p14="pg14"
alias p14sh="pg14sh"
alias p14dump="pg14dump"
alias p14restore="pg14restore"
alias p18="pg18"
alias p18sh="pg18sh"
alias p18dump="pg18dump"
alias p18restore="pg18restore"
alias dkd="devkit-docker"
