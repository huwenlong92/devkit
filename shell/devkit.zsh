# ==============================================================================
# DevKit 管理命令
# ==============================================================================

# bin/devkit 作为普通子进程不能修改当前 shell，因此在 zsh 中用函数包装：
# refresh 成功后立即重新加载 DevKit。
devkit() {
  case "${1:-}" in
    refresh|update|sync)
      command devkit "$@" || return
      source "$DEVKIT/shell/index.zsh"
      rehash 2>/dev/null
      echo "Reloaded DevKit shell config."
      ;;
    *)
      command devkit "$@"
      ;;
  esac
}
