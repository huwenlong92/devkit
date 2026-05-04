# ==============================================================================
# DevKit FNM 模块
# ==============================================================================

# 允许在加载 DevKit 前禁用本模块：
#   export DEVKIT_FNM_ENABLE=0
if [ "${DEVKIT_FNM_ENABLE:-1}" = "0" ]; then
  return 0 2>/dev/null || exit 0
fi

# 未安装 fnm 时安静跳过
if ! command -v fnm >/dev/null 2>&1; then
  return 0 2>/dev/null || exit 0
fi

# 默认开启目录切换时自动读取 .node-version / .nvmrc。
_devkit_fnm_env_options="--shell zsh"
if [ "${DEVKIT_FNM_USE_ON_CD:-1}" = "1" ]; then
  _devkit_fnm_env_options="$_devkit_fnm_env_options --use-on-cd"
fi

eval "$(command fnm env ${(z)_devkit_fnm_env_options})"

# 加载 fnm 命令补全；旧版本不支持 completions 时安静跳过。
eval "$(command fnm completions --shell zsh 2>/dev/null)"

unset _devkit_fnm_env_options
