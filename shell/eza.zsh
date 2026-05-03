# ==============================================================================
# DevKit eza 模块
# ==============================================================================

# 设置 DEVKIT_EZA_ENABLE=0 可跳过本模块。
if [ "${DEVKIT_EZA_ENABLE:-1}" = "0" ]; then
  return 0 2>/dev/null || exit 0
fi

# 未安装 eza 时安静跳过，保留系统 ls。
if ! command -v eza >/dev/null 2>&1; then
  return 0 2>/dev/null || exit 0
fi

# 可在加载 DevKit 前覆盖这些选项。
export DEVKIT_EZA_BASE_OPTIONS="${DEVKIT_EZA_BASE_OPTIONS:---group-directories-first --icons=auto}"
export DEVKIT_EZA_LONG_OPTIONS="${DEVKIT_EZA_LONG_OPTIONS:--lh --git --time-style=long-iso}"
export DEVKIT_EZA_TREE_LEVEL="${DEVKIT_EZA_TREE_LEVEL:-2}"

ls() {
  command eza ${(z)DEVKIT_EZA_BASE_OPTIONS} "$@"
}

ll() {
  command eza ${(z)DEVKIT_EZA_BASE_OPTIONS} ${(z)DEVKIT_EZA_LONG_OPTIONS} "$@"
}

la() {
  command eza ${(z)DEVKIT_EZA_BASE_OPTIONS} ${(z)DEVKIT_EZA_LONG_OPTIONS} -a "$@"
}

lt() {
  command eza ${(z)DEVKIT_EZA_BASE_OPTIONS} --tree --level "$DEVKIT_EZA_TREE_LEVEL" "$@"
}
