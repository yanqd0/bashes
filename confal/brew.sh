#!/usr/bin/env bash
#
# confal brew — 配置 Homebrew 国内镜像

# Git HTTP/1.1 — 国内镜像 HTTP/2 兼容性问题会导致卡住
git config --global http.version HTTP/1.1
echo "Git HTTP version 已设为 HTTP/1.1（国内镜像兼容）"

# 写入 Homebrew 国内镜像环境变量
if [ "$(uname)" = "Darwin" ]; then
    _brew_rc="$HOME/.zprofile"
else
    _brew_rc="$HOME/.bashrc"
fi

if grep -q 'HOMEBREW_BOTTLE_DOMAIN' "$_brew_rc" 2>/dev/null; then
    echo "Homebrew 环境变量已存在于 $_brew_rc，跳过写入"
else
    cat >> "$_brew_rc" <<'EOF'

# Homebrew 国内镜像配置（阿里云）— 可用 brew_switch 切换 {{{
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.aliyun.com/homebrew/homebrew-bottles"
export HOMEBREW_API_DOMAIN="https://mirrors.aliyun.com/homebrew/homebrew-bottles/api"
export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.aliyun.com/homebrew/homebrew-core.git"
export HOMEBREW_PIP_INDEX_URL="https://mirrors.aliyun.com/pypi/simple/"
export HOMEBREW_NO_AUTO_UPDATE=1
# }}}
EOF
    echo "Homebrew 国内镜像环境变量已写入 $_brew_rc"
fi

unset _brew_rc
