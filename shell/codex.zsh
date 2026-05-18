# Codex 多模式快捷命令

_devkit_codex() {
  local _devkit_codex_fnm_enabled="${DEVKIT_CODEX_FNM_ENABLE:-${DEVKIT_FNM_ENABLE:-1}}"
  local _devkit_codex_fnm_version="${DEVKIT_CODEX_FNM_VERSION:-default}"

  if [ "$_devkit_codex_fnm_enabled" != "0" ] && command -v fnm >/dev/null 2>&1; then
    command fnm exec --using "$_devkit_codex_fnm_version" codex "$@"
  else
    command codex "$@"
  fi
}

codex() {
  _devkit_codex "$@"
}

cx() {
  proxy auto
  command cx "$@"
}

cxr() {
  cx --read "$@"
}

cxf() {
  cx --fix "$@"
}

cxs() {
  cx --sql "$@"
}

cxv() {
  cx --review "$@"
}
