# ==============================================================================
# DevKit GVM / Go 模块
# ==============================================================================

# 允许在加载 DevKit 前禁用本模块：
#   export DEVKIT_GVM_ENABLE=0
if [ "${DEVKIT_GVM_ENABLE:-1}" = "0" ]; then
  return 0 2>/dev/null || exit 0
fi

# GVM 默认安装目录；也可以通过 DEVKIT_GVM_ROOT 或 GVM_ROOT 覆盖。
export GVM_ROOT="${DEVKIT_GVM_ROOT:-${GVM_ROOT:-$HOME/.gvm}}"

_devkit_gvm_path_contains() {
  case ":$PATH:" in
    *":$1:"*) return 0 ;;
    *) return 1 ;;
  esac
}

_devkit_gvm_append_path() {
  [ -d "$1" ] || return 0
  _devkit_gvm_path_contains "$1" && return 0
  export PATH="${PATH:+$PATH:}$1"
}

_devkit_gvm_prepend_path() {
  [ -d "$1" ] || return 0
  _devkit_gvm_path_contains "$1" && return 0
  export PATH="$1${PATH:+:$PATH}"
}

_devkit_gvm_ensure_base_path() {
  for _devkit_gvm_base_path in \
    "/opt/homebrew/bin" \
    "/opt/homebrew/sbin" \
    "/usr/local/bin" \
    "/usr/bin" \
    "/bin" \
    "/usr/sbin" \
    "/sbin"
  do
    _devkit_gvm_append_path "$_devkit_gvm_base_path"
  done
}

_devkit_gvm_restore_cd() {
  (( $+functions[__gvm_oldcd] )) || return 0
  eval "$(functions __gvm_oldcd | command sed '1s/^__gvm_oldcd/cd/')"
  unfunction __gvm_oldcd 2>/dev/null
}

_devkit_gvm_ensure_base_path

# gvm 编译 Go 1.5+ 时需要 bison 3+；Homebrew 的 keg-only bison 不会默认进 PATH。
_devkit_gvm_bison_home="${DEVKIT_GVM_BISON_HOME:-}"
if [ -z "$_devkit_gvm_bison_home" ]; then
  for _devkit_gvm_bison_candidate in \
    "/opt/homebrew/opt/bison" \
    "/usr/local/opt/bison"
  do
    if [ -x "$_devkit_gvm_bison_candidate/bin/bison" ]; then
      _devkit_gvm_bison_home="$_devkit_gvm_bison_candidate"
      break
    fi
  done
fi

if [ -n "$_devkit_gvm_bison_home" ] && [ -d "$_devkit_gvm_bison_home/bin" ]; then
  _devkit_gvm_prepend_path "$_devkit_gvm_bison_home/bin"
  rehash 2>/dev/null
fi

# 自动查找 gvm 初始化脚本，也可以通过 DEVKIT_GVM_SCRIPT 手动指定。
_devkit_gvm_script="${DEVKIT_GVM_SCRIPT:-$GVM_ROOT/scripts/gvm}"

# 未安装 gvm 时安静跳过，Go 的基础配置由 go.zsh 兜底。
if [ ! -s "$_devkit_gvm_script" ]; then
  unset _devkit_gvm_script _devkit_gvm_bison_home _devkit_gvm_bison_candidate _devkit_gvm_base_path
  unfunction _devkit_gvm_path_contains _devkit_gvm_append_path _devkit_gvm_prepend_path _devkit_gvm_ensure_base_path 2>/dev/null
  return 0 2>/dev/null || exit 0
fi

# 加载 gvm，让 Go 版本、GOROOT、GOPATH 和 PATH 由 gvm/pkgset 统一接管。
. "$_devkit_gvm_script"
_devkit_gvm_restore_cd
_devkit_gvm_ensure_base_path

# Go Module 配置不绑定具体 Go 版本，统一放在 gvm 初始化之后设置。
export GO111MODULE="${GO111MODULE:-on}"
export GOPROXY="${GOPROXY:-https://goproxy.cn,direct}"
# export GOPROXY="https://proxy.golang.com.cn,direct"

_devkit_gvm_read_environment_value() {
  local _devkit_gvm_env_key="$1"
  local _devkit_gvm_env_file="$2"
  local _devkit_gvm_env_line _devkit_gvm_env_value

  [ -r "$_devkit_gvm_env_file" ] || return 1

  while IFS= read -r _devkit_gvm_env_line; do
    case "$_devkit_gvm_env_line" in
      *"$_devkit_gvm_env_key=\""*\")
        _devkit_gvm_env_value="${_devkit_gvm_env_line#*$_devkit_gvm_env_key=\"}"
        _devkit_gvm_env_value="${_devkit_gvm_env_value%%\"*}"
        if [ -n "$_devkit_gvm_env_value" ]; then
          print -r -- "$_devkit_gvm_env_value"
          return 0
        fi
        ;;
    esac
  done < "$_devkit_gvm_env_file"

  return 1
}

_devkit_gvm_trim() {
  local _devkit_gvm_trim_value="$1"

  _devkit_gvm_trim_value="${_devkit_gvm_trim_value//$'\r'/}"
  _devkit_gvm_trim_value="${_devkit_gvm_trim_value#"${_devkit_gvm_trim_value%%[![:space:]]*}"}"
  _devkit_gvm_trim_value="${_devkit_gvm_trim_value%"${_devkit_gvm_trim_value##*[![:space:]]}"}"
  print -r -- "$_devkit_gvm_trim_value"
}

_devkit_gvm_normalize_version() {
  local _devkit_gvm_version

  _devkit_gvm_version="$(_devkit_gvm_trim "${1%%#*}")"
  _devkit_gvm_version="${_devkit_gvm_version%%[[:space:]]*}"

  case "$_devkit_gvm_version" in
    "")
      return 1
      ;;
    go[0-9]*|release.r*|system|master)
      print -r -- "$_devkit_gvm_version"
      ;;
    v[0-9]*)
      print -r -- "go${_devkit_gvm_version#v}"
      ;;
    [0-9]*)
      print -r -- "go$_devkit_gvm_version"
      ;;
    *)
      return 1
      ;;
  esac
}

_devkit_gvm_read_dot_go_version() {
  local _devkit_gvm_file="$1"
  local _devkit_gvm_line _devkit_gvm_version

  [ -r "$_devkit_gvm_file" ] || return 1

  while IFS= read -r _devkit_gvm_line || [ -n "$_devkit_gvm_line" ]; do
    _devkit_gvm_version="$(_devkit_gvm_normalize_version "$_devkit_gvm_line")" || continue
    print -r -- "$_devkit_gvm_version"
    return 0
  done < "$_devkit_gvm_file"

  return 1
}

_devkit_gvm_read_go_file_version() {
  local _devkit_gvm_file="$1"
  local _devkit_gvm_line _devkit_gvm_toolchain_version _devkit_gvm_go_version

  [ -r "$_devkit_gvm_file" ] || return 1

  while IFS= read -r _devkit_gvm_line || [ -n "$_devkit_gvm_line" ]; do
    _devkit_gvm_line="${_devkit_gvm_line%%//*}"
    _devkit_gvm_line="$(_devkit_gvm_trim "$_devkit_gvm_line")"

    case "$_devkit_gvm_line" in
      toolchain[[:space:]]*)
        _devkit_gvm_toolchain_version="$(_devkit_gvm_normalize_version "${_devkit_gvm_line#toolchain}")" || true
        ;;
      go[[:space:]]*)
        _devkit_gvm_go_version="$(_devkit_gvm_normalize_version "${_devkit_gvm_line#go}")" || true
        ;;
    esac
  done < "$_devkit_gvm_file"

  if [ -n "$_devkit_gvm_toolchain_version" ]; then
    print -r -- "$_devkit_gvm_toolchain_version"
    return 0
  fi

  if [ -n "$_devkit_gvm_go_version" ]; then
    print -r -- "$_devkit_gvm_go_version"
    return 0
  fi

  return 1
}

_devkit_gvm_read_dot_go_pkgset() {
  local _devkit_gvm_file="$1"
  local _devkit_gvm_line _devkit_gvm_pkgset

  [ -r "$_devkit_gvm_file" ] || return 1

  while IFS= read -r _devkit_gvm_line || [ -n "$_devkit_gvm_line" ]; do
    _devkit_gvm_pkgset="$(_devkit_gvm_trim "${_devkit_gvm_line%%#*}")"
    _devkit_gvm_pkgset="${_devkit_gvm_pkgset%%[[:space:]]*}"

    if [ -n "$_devkit_gvm_pkgset" ]; then
      print -r -- "$_devkit_gvm_pkgset"
      return 0
    fi
  done < "$_devkit_gvm_file"

  return 1
}

_devkit_gvm_find_project_version() {
  local _devkit_gvm_dir="${PWD:-$(pwd)}"
  local _devkit_gvm_version

  while [ -n "$_devkit_gvm_dir" ]; do
    if [ -f "$_devkit_gvm_dir/.go-version" ]; then
      _devkit_gvm_version="$(_devkit_gvm_read_dot_go_version "$_devkit_gvm_dir/.go-version")" && {
        print -r -- "$_devkit_gvm_version"
        return 0
      }
    fi

    if [ -f "$_devkit_gvm_dir/go.work" ]; then
      _devkit_gvm_version="$(_devkit_gvm_read_go_file_version "$_devkit_gvm_dir/go.work")" && {
        print -r -- "$_devkit_gvm_version"
        return 0
      }
    fi

    if [ -f "$_devkit_gvm_dir/go.mod" ]; then
      _devkit_gvm_version="$(_devkit_gvm_read_go_file_version "$_devkit_gvm_dir/go.mod")" && {
        print -r -- "$_devkit_gvm_version"
        return 0
      }
    fi

    [ "$_devkit_gvm_dir" = "/" ] && break
    _devkit_gvm_dir="${_devkit_gvm_dir:h}"
  done

  return 1
}

_devkit_gvm_find_project_pkgset() {
  local _devkit_gvm_dir="${PWD:-$(pwd)}"
  local _devkit_gvm_pkgset

  while [ -n "$_devkit_gvm_dir" ]; do
    if [ -f "$_devkit_gvm_dir/.go-pkgset" ]; then
      _devkit_gvm_pkgset="$(_devkit_gvm_read_dot_go_pkgset "$_devkit_gvm_dir/.go-pkgset")" && {
        print -r -- "$_devkit_gvm_pkgset"
        return 0
      }
    fi

    [ "$_devkit_gvm_dir" = "/" ] && break
    _devkit_gvm_dir="${_devkit_gvm_dir:h}"
  done

  return 1
}

_devkit_gvm_default_target() {
  if [ -z "$_devkit_gvm_auto_default_version" ]; then
    return 1
  fi

  if [ -n "$_devkit_gvm_auto_default_pkgset" ]; then
    print -r -- "$_devkit_gvm_auto_default_version|$_devkit_gvm_auto_default_pkgset"
  else
    print -r -- "$_devkit_gvm_auto_default_version|"
  fi
}

_devkit_gvm_use_target() {
  local _devkit_gvm_target_version="$1"
  local _devkit_gvm_target_pkgset="$2"

  gvm use "$_devkit_gvm_target_version" --quiet >/dev/null 2>&1 || return 1

  if [ -n "$_devkit_gvm_target_pkgset" ]; then
    gvm pkgset use "$_devkit_gvm_target_pkgset" --quiet >/dev/null 2>&1 || return 1
  fi
}

_devkit_gvm_auto_use() {
  local _devkit_gvm_target _devkit_gvm_target_version _devkit_gvm_target_pkgset _devkit_gvm_project_version _devkit_gvm_project_pkgset

  [ "${DEVKIT_GVM_AUTO_USE:-1}" != "0" ] || return 0
  [ "$_devkit_gvm_auto_switching" != "1" ] || return 0
  command -v gvm >/dev/null 2>&1 || return 0

  _devkit_gvm_project_pkgset="$(_devkit_gvm_find_project_pkgset)" || _devkit_gvm_project_pkgset=""

  if _devkit_gvm_project_version="$(_devkit_gvm_find_project_version)"; then
    if [[ "$_devkit_gvm_project_version" == *@* ]]; then
      _devkit_gvm_target_version="${_devkit_gvm_project_version%@*}"
      _devkit_gvm_target_pkgset="${_devkit_gvm_project_version#*@}"
    else
      _devkit_gvm_target_version="$_devkit_gvm_project_version"
      _devkit_gvm_target_pkgset=""
    fi
    [ -n "$_devkit_gvm_target_pkgset" ] || _devkit_gvm_target_pkgset="$_devkit_gvm_project_pkgset"
  elif [ -n "$_devkit_gvm_project_pkgset" ]; then
    _devkit_gvm_target_version="$_devkit_gvm_auto_default_version"
    _devkit_gvm_target_pkgset="$_devkit_gvm_project_pkgset"
  else
    _devkit_gvm_target="$(_devkit_gvm_default_target)" || return 0
    _devkit_gvm_target_version="${_devkit_gvm_target%%|*}"
    _devkit_gvm_target_pkgset="${_devkit_gvm_target#*|}"
  fi

  [ -n "$_devkit_gvm_target_version" ] || return 0
  _devkit_gvm_target="$_devkit_gvm_target_version|$_devkit_gvm_target_pkgset"
  [ "$_devkit_gvm_target" != "$_devkit_gvm_auto_current_target" ] || return 0

  _devkit_gvm_auto_switching=1
  if _devkit_gvm_use_target "$_devkit_gvm_target_version" "$_devkit_gvm_target_pkgset"; then
    _devkit_gvm_auto_current_target="$_devkit_gvm_target"
  else
    print -u2 -- "devkit: gvm use $_devkit_gvm_target_version failed; install it with 'gvm install $_devkit_gvm_target_version' or adjust the project Go version."
  fi
  _devkit_gvm_auto_switching=0
}

typeset -g _devkit_gvm_auto_default_version="${DEVKIT_GVM_DEFAULT_VERSION:-}"
typeset -g _devkit_gvm_auto_default_pkgset="${DEVKIT_GVM_DEFAULT_PKGSET:-}"
typeset -g _devkit_gvm_auto_current_target=""
typeset -g _devkit_gvm_auto_switching=0

if [ -z "$_devkit_gvm_auto_default_version" ]; then
  _devkit_gvm_auto_default_version="$(_devkit_gvm_read_environment_value gvm_go_name "$GVM_ROOT/environments/default")"
fi

if [ -z "$_devkit_gvm_auto_default_pkgset" ]; then
  _devkit_gvm_auto_default_pkgset="$(_devkit_gvm_read_environment_value gvm_pkgset_name "$GVM_ROOT/environments/default")"
fi

# 可选：加载 DevKit 时自动切到指定 Go 版本 / pkgset。
#   export DEVKIT_GVM_DEFAULT_VERSION=go1.22.5
#   export DEVKIT_GVM_DEFAULT_PKGSET=global
if [ -n "$DEVKIT_GVM_DEFAULT_VERSION" ] && command -v gvm >/dev/null 2>&1; then
  if [ -n "$DEVKIT_GVM_DEFAULT_PKGSET" ]; then
    _devkit_gvm_use_target "$DEVKIT_GVM_DEFAULT_VERSION" "$DEVKIT_GVM_DEFAULT_PKGSET" >/dev/null 2>&1
  else
    _devkit_gvm_use_target "$DEVKIT_GVM_DEFAULT_VERSION" "" >/dev/null 2>&1
  fi
fi

if [ "${DEVKIT_GVM_AUTO_USE:-1}" != "0" ] && command -v gvm >/dev/null 2>&1; then
  autoload -Uz add-zsh-hook 2>/dev/null
  add-zsh-hook -d chpwd _devkit_gvm_auto_use 2>/dev/null
  add-zsh-hook chpwd _devkit_gvm_auto_use 2>/dev/null
  _devkit_gvm_auto_use
fi

unset _devkit_gvm_script _devkit_gvm_bison_home _devkit_gvm_bison_candidate _devkit_gvm_base_path
unfunction _devkit_gvm_path_contains _devkit_gvm_append_path _devkit_gvm_prepend_path _devkit_gvm_ensure_base_path _devkit_gvm_restore_cd _devkit_gvm_read_environment_value 2>/dev/null
