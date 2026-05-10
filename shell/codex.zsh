# Codex 多模式快捷命令

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
