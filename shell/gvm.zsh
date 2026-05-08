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
  typeset -U path PATH
  path=("$_devkit_gvm_bison_home/bin" $path)
  export PATH
  rehash 2>/dev/null
fi

# 自动查找 gvm 初始化脚本，也可以通过 DEVKIT_GVM_SCRIPT 手动指定。
_devkit_gvm_script="${DEVKIT_GVM_SCRIPT:-$GVM_ROOT/scripts/gvm}"

# 未安装 gvm 时安静跳过，Go 的基础配置由 go.zsh 兜底。
if [ ! -s "$_devkit_gvm_script" ]; then
  unset _devkit_gvm_script _devkit_gvm_bison_home _devkit_gvm_bison_candidate
  return 0 2>/dev/null || exit 0
fi

# 加载 gvm，让 Go 版本、GOROOT、GOPATH 和 PATH 由 gvm/pkgset 统一接管。
. "$_devkit_gvm_script"

# Go Module 配置不绑定具体 Go 版本，统一放在 gvm 初始化之后设置。
export GO111MODULE="${GO111MODULE:-on}"
export GOPROXY="${GOPROXY:-https://goproxy.cn,direct}"
# export GOPROXY="https://proxy.golang.com.cn,direct"

# 可选：加载 DevKit 时自动切到指定 Go 版本 / pkgset。
#   export DEVKIT_GVM_DEFAULT_VERSION=go1.22.5
#   export DEVKIT_GVM_DEFAULT_PKGSET=global
if [ -n "$DEVKIT_GVM_DEFAULT_VERSION" ] && command -v gvm >/dev/null 2>&1; then
  if [ -n "$DEVKIT_GVM_DEFAULT_PKGSET" ]; then
    gvm use "$DEVKIT_GVM_DEFAULT_VERSION@$DEVKIT_GVM_DEFAULT_PKGSET" >/dev/null 2>&1
  else
    gvm use "$DEVKIT_GVM_DEFAULT_VERSION" >/dev/null 2>&1
  fi
fi

unset _devkit_gvm_script _devkit_gvm_bison_home _devkit_gvm_bison_candidate
