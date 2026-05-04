# ==============================================================================
# DevKit NVM 模块
# ==============================================================================

# 允许在加载 DevKit 前禁用本模块：
  export DEVKIT_NVM_ENABLE=0
if [ "${DEVKIT_NVM_ENABLE:-1}" = "0" ]; then
  return 0 2>/dev/null || exit 0
fi

# NVM 配置目录
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

# 自动查找 nvm 脚本路径，也可以通过 DEVKIT_NVM_SCRIPT 手动指定
_devkit_nvm_script="${DEVKIT_NVM_SCRIPT:-}"
if [ -z "$_devkit_nvm_script" ]; then
  for _devkit_nvm_candidate in \
    "$NVM_DIR/nvm.sh" \
    "/opt/homebrew/opt/nvm/nvm.sh" \
    "/usr/local/opt/nvm/nvm.sh"
  do
    if [ -s "$_devkit_nvm_candidate" ]; then
      _devkit_nvm_script="$_devkit_nvm_candidate"
      break
    fi
  done
fi

# 自动查找 nvm 命令补全路径，也可以通过 DEVKIT_NVM_COMPLETION 手动指定
_devkit_nvm_completion="${DEVKIT_NVM_COMPLETION:-}"
if [ -z "$_devkit_nvm_completion" ]; then
  for _devkit_nvm_candidate in \
    "$NVM_DIR/bash_completion" \
    "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" \
    "/usr/local/opt/nvm/etc/bash_completion.d/nvm"
  do
    if [ -s "$_devkit_nvm_candidate" ]; then
      _devkit_nvm_completion="$_devkit_nvm_candidate"
      break
    fi
  done
fi

# 未安装 nvm 时安静跳过
if [ ! -s "$_devkit_nvm_script" ]; then
  unset _devkit_nvm_script _devkit_nvm_completion _devkit_nvm_candidate
  return 0 2>/dev/null || exit 0
fi

# 加载 nvm
. "$_devkit_nvm_script"

# 加载 nvm 命令补全
[ -s "$_devkit_nvm_completion" ] && . "$_devkit_nvm_completion"

unset _devkit_nvm_script _devkit_nvm_completion _devkit_nvm_candidate
