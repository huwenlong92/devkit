# ==============================================================================
# DevKit Go 模块
# ==============================================================================

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
