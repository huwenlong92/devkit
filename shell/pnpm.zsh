# ==============================================================================
# DevKit pnpm 模块
# ==============================================================================

# 允许在加载 DevKit 前禁用本模块：
#   export DEVKIT_PNPM_ENABLE=0
if [ "${DEVKIT_PNPM_ENABLE:-1}" = "0" ]; then
  return 0 2>/dev/null || exit 0
fi

# pnpm setup 默认使用这个目录；允许用户在加载 DevKit 前覆盖。
export PNPM_HOME="${PNPM_HOME:-$HOME/Library/pnpm}"

case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

_devkit_pnpm_load_completion() {
  # 加载 pnpm 命令补全；未安装 pnpm、旧版本不支持 completions 或 compinit 未加载时安静跳过。
  if (( $+functions[compdef] )) && command -v pnpm >/dev/null 2>&1; then
    eval "$(command pnpm completion zsh 2>/dev/null)"
  fi
}

_devkit_pnpm_read_package_manager() {
  local package_json="$1"

  [ -f "$package_json" ] || return 1
  command -v node >/dev/null 2>&1 || return 1

  command node -e '
const fs = require("fs");

try {
  const packageJson = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
  const packageManager = packageJson.packageManager || "";

  if (packageManager) {
    process.stdout.write(packageManager);
  }
} catch (_) {
  process.exit(1);
}
' "$package_json"
}

_devkit_pnpm_package_uses_pnpm_scripts() {
  local package_json="$1"

  [ -f "$package_json" ] || return 1
  command -v node >/dev/null 2>&1 || return 1

  command node -e '
const fs = require("fs");

try {
  const packageJson = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
  const scripts = packageJson.scripts || {};
  const hasPnpmScript = Object.values(scripts).some((script) =>
    typeof script === "string" && /(^|&&\s*|\|\|\s*|[;|()\n]\s*)pnpm(?=$|[\s;&|()\n])/.test(script.trim())
  );

  process.exit(hasPnpmScript ? 0 : 1);
} catch (_) {
  process.exit(1);
}
' "$package_json"
}

_devkit_pnpm_find_project_root() {
  local dir="${PWD:A}"
  local package_json
  local package_manager

  while [ "$dir" != "/" ]; do
    if [ -f "$dir/pnpm-workspace.yaml" ] || [ -f "$dir/pnpm-lock.yaml" ]; then
      print -r -- "$dir"
      return 0
    fi

    package_json="$dir/package.json"
    package_manager="$(_devkit_pnpm_read_package_manager "$package_json")"
    if [[ "$package_manager" == pnpm || "$package_manager" == pnpm@* ]]; then
      print -r -- "$dir"
      return 0
    fi

    if [ -n "$package_manager" ]; then
      dir="${dir:h}"
      continue
    fi

    if _devkit_pnpm_package_uses_pnpm_scripts "$package_json"; then
      print -r -- "$dir"
      return 0
    fi

    if [ "${DEVKIT_PNPM_ASSUME_PACKAGE_JSON:-1}" = "1" ] && [ -f "$package_json" ]; then
      print -r -- "$dir"
      return 0
    fi

    dir="${dir:h}"
  done

  return 1
}

_devkit_pnpm_corepack_auto_install() {
  [ "${DEVKIT_PNPM_COREPACK_AUTO_INSTALL:-1}" = "1" ] || return 0
  command -v pnpm >/dev/null 2>&1 && return 0
  command -v corepack >/dev/null 2>&1 || return 0

  local root
  root="$(_devkit_pnpm_find_project_root)" || return 0

  if [ "$root" = "$_devkit_pnpm_corepack_last_root" ]; then
    return 0
  fi
  _devkit_pnpm_corepack_last_root="$root"

  local package_manager
  package_manager="$(_devkit_pnpm_read_package_manager "$root/package.json")"
  if [[ "$package_manager" != pnpm && "$package_manager" != pnpm@* ]]; then
    package_manager="${DEVKIT_PNPM_COREPACK_DEFAULT:-pnpm@latest}"
  fi

  printf 'DevKit: pnpm not found; enabling via Corepack for %s\n' "$root" >&2

  if ! (cd "$root" && command corepack enable pnpm >/dev/null 2>&1); then
    printf 'DevKit: corepack enable pnpm failed\n' >&2
    return 1
  fi

  if ! (cd "$root" && command corepack install >/dev/null 2>&1); then
    if ! (cd "$root" && command corepack prepare "$package_manager" --activate >/dev/null 2>&1); then
      printf 'DevKit: corepack could not install %s\n' "$package_manager" >&2
      return 1
    fi
  fi

  rehash 2>/dev/null

  local pnpm_version
  if command -v pnpm >/dev/null 2>&1 && pnpm_version="$(command pnpm --version 2>/dev/null)" && [ -n "$pnpm_version" ]; then
    _devkit_pnpm_load_completion
    printf 'DevKit: pnpm is ready: %s\n' "$pnpm_version" >&2
  else
    printf 'DevKit: pnpm was not usable after Corepack setup\n' >&2
  fi
}

_devkit_pnpm_load_completion

if [ "${DEVKIT_PNPM_COREPACK_AUTO_INSTALL:-1}" = "1" ]; then
  autoload -U add-zsh-hook
  add-zsh-hook -d chpwd _devkit_pnpm_corepack_auto_install 2>/dev/null
  add-zsh-hook chpwd _devkit_pnpm_corepack_auto_install
  _devkit_pnpm_corepack_auto_install
fi
