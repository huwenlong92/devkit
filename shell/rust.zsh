# ==============================================================================
# DevKit Rust 模块
# ==============================================================================

# 允许在加载 DevKit 前禁用本模块：
#   export DEVKIT_RUST_ENABLE=0
if [ "${DEVKIT_RUST_ENABLE:-1}" = "0" ]; then
  return 0 2>/dev/null || exit 0
fi

# Cargo 环境文件路径，也可以通过 DEVKIT_CARGO_ENV 手动指定
_devkit_cargo_env="${DEVKIT_CARGO_ENV:-$HOME/.cargo/env}"

# 加载 Cargo 环境变量；未安装 Rust/Cargo 时安静跳过 PATH 初始化。
if [ -s "$_devkit_cargo_env" ]; then
  . "$_devkit_cargo_env"
fi

unset _devkit_cargo_env

# rustup 不存在时，保留 Cargo 环境，跳过项目版本锁定。
command -v rustup >/dev/null 2>&1 || return 0 2>/dev/null || exit 0

_devkit_rust_trim() {
  local _devkit_rust_trim_value="$1"

  _devkit_rust_trim_value="${_devkit_rust_trim_value//$'\r'/}"
  _devkit_rust_trim_value="${_devkit_rust_trim_value#"${_devkit_rust_trim_value%%[![:space:]]*}"}"
  _devkit_rust_trim_value="${_devkit_rust_trim_value%"${_devkit_rust_trim_value##*[![:space:]]}"}"
  print -r -- "$_devkit_rust_trim_value"
}

_devkit_rust_normalize_toolchain() {
  local _devkit_rust_toolchain

  _devkit_rust_toolchain="$(_devkit_rust_trim "${1%%#*}")"
  _devkit_rust_toolchain="${_devkit_rust_toolchain%%[[:space:]]*}"

  [ -n "$_devkit_rust_toolchain" ] || return 1
  print -r -- "$_devkit_rust_toolchain"
}

_devkit_rust_read_plain_toolchain_file() {
  local _devkit_rust_file="$1"
  local _devkit_rust_line _devkit_rust_toolchain

  [ -r "$_devkit_rust_file" ] || return 1

  while IFS= read -r _devkit_rust_line || [ -n "$_devkit_rust_line" ]; do
    _devkit_rust_toolchain="$(_devkit_rust_normalize_toolchain "$_devkit_rust_line")" || continue
    print -r -- "$_devkit_rust_toolchain"
    return 0
  done < "$_devkit_rust_file"

  return 1
}

_devkit_rust_read_toml_toolchain_file() {
  local _devkit_rust_file="$1"
  local _devkit_rust_line _devkit_rust_value

  [ -r "$_devkit_rust_file" ] || return 1

  while IFS= read -r _devkit_rust_line || [ -n "$_devkit_rust_line" ]; do
    _devkit_rust_line="${_devkit_rust_line%%#*}"
    _devkit_rust_line="$(_devkit_rust_trim "$_devkit_rust_line")"

    case "$_devkit_rust_line" in
      channel[[:space:]]*=*)
        _devkit_rust_value="${_devkit_rust_line#channel}"
        _devkit_rust_value="${_devkit_rust_value#*=}"
        _devkit_rust_value="$(_devkit_rust_trim "$_devkit_rust_value")"
        _devkit_rust_value="${_devkit_rust_value#\"}"
        _devkit_rust_value="${_devkit_rust_value%\"}"
        _devkit_rust_value="${_devkit_rust_value#\'}"
        _devkit_rust_value="${_devkit_rust_value%\'}"
        _devkit_rust_value="$(_devkit_rust_normalize_toolchain "$_devkit_rust_value")" || return 1
        print -r -- "$_devkit_rust_value"
        return 0
        ;;
      channel=*)
        _devkit_rust_value="${_devkit_rust_line#channel=}"
        _devkit_rust_value="$(_devkit_rust_trim "$_devkit_rust_value")"
        _devkit_rust_value="${_devkit_rust_value#\"}"
        _devkit_rust_value="${_devkit_rust_value%\"}"
        _devkit_rust_value="${_devkit_rust_value#\'}"
        _devkit_rust_value="${_devkit_rust_value%\'}"
        _devkit_rust_value="$(_devkit_rust_normalize_toolchain "$_devkit_rust_value")" || return 1
        print -r -- "$_devkit_rust_value"
        return 0
        ;;
    esac
  done < "$_devkit_rust_file"

  return 1
}

_devkit_rust_read_toolchain_file() {
  local _devkit_rust_file="$1"

  case "${_devkit_rust_file:t}" in
    rust-toolchain.toml)
      _devkit_rust_read_toml_toolchain_file "$_devkit_rust_file"
      ;;
    rust-toolchain)
      _devkit_rust_read_toml_toolchain_file "$_devkit_rust_file" || _devkit_rust_read_plain_toolchain_file "$_devkit_rust_file"
      ;;
    .rust-version)
      _devkit_rust_read_plain_toolchain_file "$_devkit_rust_file"
      ;;
  esac
}

_devkit_rust_find_project_toolchain() {
  local _devkit_rust_dir="${PWD:-$(pwd)}"
  local _devkit_rust_toolchain

  while [ -n "$_devkit_rust_dir" ]; do
    if [ -f "$_devkit_rust_dir/rust-toolchain.toml" ]; then
      _devkit_rust_toolchain="$(_devkit_rust_read_toolchain_file "$_devkit_rust_dir/rust-toolchain.toml")" && {
        print -r -- "$_devkit_rust_toolchain"
        return 0
      }
    fi

    if [ -f "$_devkit_rust_dir/rust-toolchain" ]; then
      _devkit_rust_toolchain="$(_devkit_rust_read_toolchain_file "$_devkit_rust_dir/rust-toolchain")" && {
        print -r -- "$_devkit_rust_toolchain"
        return 0
      }
    fi

    if [ -f "$_devkit_rust_dir/.rust-version" ]; then
      _devkit_rust_toolchain="$(_devkit_rust_read_toolchain_file "$_devkit_rust_dir/.rust-version")" && {
        print -r -- "$_devkit_rust_toolchain"
        return 0
      }
    fi

    [ "$_devkit_rust_dir" = "/" ] && break
    _devkit_rust_dir="${_devkit_rust_dir:h}"
  done

  return 1
}

_devkit_rust_toolchain_is_installed() {
  local _devkit_rust_toolchain="$1"

  command rustup run "$_devkit_rust_toolchain" rustc --version >/dev/null 2>&1
}

_devkit_rust_auto_use() {
  local _devkit_rust_target

  [ "${DEVKIT_RUST_AUTO_USE:-1}" != "0" ] || return 0
  [ "$_devkit_rust_auto_switching" != "1" ] || return 0
  command -v rustup >/dev/null 2>&1 || return 0

  if _devkit_rust_target="$(_devkit_rust_find_project_toolchain)"; then
    :
  else
    _devkit_rust_target="$_devkit_rust_auto_default_toolchain"
  fi

  [ "$_devkit_rust_target" != "$_devkit_rust_auto_current_toolchain" ] || return 0

  _devkit_rust_auto_switching=1
  if [ -n "$_devkit_rust_target" ]; then
    if _devkit_rust_toolchain_is_installed "$_devkit_rust_target"; then
      export RUSTUP_TOOLCHAIN="$_devkit_rust_target"
      _devkit_rust_auto_current_toolchain="$_devkit_rust_target"
    else
      print -u2 -- "devkit: rustup toolchain $_devkit_rust_target is not installed; install it with 'rustup toolchain install $_devkit_rust_target' or adjust the project Rust version."
      if [ -n "$_devkit_rust_auto_default_toolchain" ]; then
        export RUSTUP_TOOLCHAIN="$_devkit_rust_auto_default_toolchain"
        _devkit_rust_auto_current_toolchain="$_devkit_rust_auto_default_toolchain"
      else
        unset RUSTUP_TOOLCHAIN
        _devkit_rust_auto_current_toolchain=""
      fi
    fi
  else
    unset RUSTUP_TOOLCHAIN
    _devkit_rust_auto_current_toolchain=""
  fi
  _devkit_rust_auto_switching=0
}

typeset -g _devkit_rust_auto_default_toolchain="${DEVKIT_RUST_DEFAULT_TOOLCHAIN:-${RUSTUP_TOOLCHAIN:-}}"
typeset -g _devkit_rust_auto_current_toolchain="${RUSTUP_TOOLCHAIN:-}"
typeset -g _devkit_rust_auto_switching=0

if [ "${DEVKIT_RUST_AUTO_USE:-1}" != "0" ]; then
  autoload -Uz add-zsh-hook 2>/dev/null
  add-zsh-hook -d chpwd _devkit_rust_auto_use 2>/dev/null
  add-zsh-hook chpwd _devkit_rust_auto_use 2>/dev/null
  _devkit_rust_auto_use
fi
