# ==============================================================================
# DevKit Go 模块
# ==============================================================================

# 允许在加载 DevKit 前禁用本模块：
#   export DEVKIT_GO_ENABLE=0
if [ "${DEVKIT_GO_ENABLE:-1}" = "0" ]; then
  return 0 2>/dev/null || exit 0
fi

# 如果安装了 gvm，则 Go 版本、GOROOT、GOPATH 和 PATH 由 gvm.zsh 统一接管。
_devkit_go_gvm_root="${DEVKIT_GVM_ROOT:-${GVM_ROOT:-$HOME/.gvm}}"
_devkit_go_gvm_script="${DEVKIT_GVM_SCRIPT:-$_devkit_go_gvm_root/scripts/gvm}"
if [ "${DEVKIT_GVM_ENABLE:-1}" != "0" ] && [ -s "$_devkit_go_gvm_script" ]; then
  unset _devkit_go_gvm_root _devkit_go_gvm_script
  return 0 2>/dev/null || exit 0
fi
unset _devkit_go_gvm_root _devkit_go_gvm_script

# Go 工作区
export GOPATH="${GOPATH:-$HOME/data/golang}"
export GOBIN="${GOBIN:-$GOPATH/bin}"

# Go Module 配置
export GO111MODULE="${GO111MODULE:-on}"
export GOPROXY="${GOPROXY:-https://goproxy.cn,direct}"
# export GOPROXY="https://proxy.golang.com.cn,direct"

# Go 安装的命令会放在 GOBIN 中。
typeset -U path PATH
path=("$GOBIN" $path)
export PATH
