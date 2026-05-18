# Claude Code shortcut command

_devkit_claude() {
  local _devkit_claude_proxy_enabled="${DEVKIT_CLAUDE_PROXY_ENABLE:-1}"
  local _devkit_claude_fnm_enabled="${DEVKIT_CLAUDE_FNM_ENABLE:-${DEVKIT_FNM_ENABLE:-1}}"
  local _devkit_claude_fnm_version="${DEVKIT_CLAUDE_FNM_VERSION:-default}"

  if [ "$_devkit_claude_proxy_enabled" != "0" ] && (( $+functions[proxy_auto] )); then
    proxy_auto
  fi

  if [ "$_devkit_claude_fnm_enabled" != "0" ] && command -v fnm >/dev/null 2>&1; then
    command fnm exec --using "$_devkit_claude_fnm_version" claude "$@"
  else
    command claude "$@"
  fi
}

claude() {
  _devkit_claude "$@"
}
