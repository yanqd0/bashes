#!/usr/bin/env bash

if command -v rustup &>/dev/null; then
    echo "rustup 已安装，当前版本："
    rustup --version
    return 0
fi

confal rustup

if [[ $(uname) = 'Darwin' ]]; then
    brew install rustup
    _rustup_rc="$HOME/.zshrc"
else
    curl --proto '=https' --tlsv1.2 -sSf https://mirrors.aliyun.com/repo/rust/rustup-init.sh | sh
    _rustup_rc="$HOME/.bashrc"
fi

if ! grep -q 'RUSTUP_DIST_SERVER' "$_rustup_rc" 2>/dev/null; then
    cat >> "$_rustup_rc" <<'EOF'

# Rustup Aliyun mirror {{{
export RUSTUP_DIST_SERVER="https://mirrors.aliyun.com/rustup"
export RUSTUP_UPDATE_ROOT="https://mirrors.aliyun.com/rustup/rustup"
# }}}
EOF
fi

unset _rustup_rc
