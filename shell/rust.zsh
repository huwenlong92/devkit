# ==============================================================================
# DevKit Rust 模块
# ==============================================================================

# Cargo 环境文件路径，也可以通过 DEVKIT_CARGO_ENV 手动指定
_devkit_cargo_env="${DEVKIT_CARGO_ENV:-$HOME/.cargo/env}"

# 未安装 Rust/Cargo 时安静跳过
if [ ! -s "$_devkit_cargo_env" ]; then
  unset _devkit_cargo_env
  return 0 2>/dev/null || exit 0
fi

# 加载 Cargo 环境变量
. "$_devkit_cargo_env"

unset _devkit_cargo_env
