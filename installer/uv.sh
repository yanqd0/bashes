#!/usr/bin/env bash

if command -v uv &>/dev/null; then
    echo "uv 已安装，当前版本："
    uv --version
    return 0
fi

curl -LsSf https://uv.agentsmirror.com/install-cn.sh | sh

# 根据实际运行的 shell 选择配置文件
if [ -n "$ZSH_VERSION" ]; then
    _uv_rc="$HOME/.zshrc"
elif [ -n "$BASH_VERSION" ]; then
    _uv_rc="$HOME/.bashrc"
elif [ "$(uname -s)" = "Darwin" ]; then
    _uv_rc="$HOME/.zshrc"
else
    _uv_rc="$HOME/.bashrc"
fi

# 写入镜像源配置（避免重复写入）
if ! grep -q 'UV_DEFAULT_INDEX' "$_uv_rc" 2>/dev/null; then
    cat >>"$_uv_rc" <<'EOF'

# uv 镜像源（阿里云）{{{
export UV_DEFAULT_INDEX="https://mirrors.aliyun.com/pypi/simple/"
export UV_PYTHON_INSTALL_MIRROR="https://registry.npmmirror.com/-/binary/python-build-standalone/"
# }}}
EOF
fi

# 当前 shell 中立即生效
export UV_DEFAULT_INDEX="https://mirrors.aliyun.com/pypi/simple/"
export UV_PYTHON_INSTALL_MIRROR="https://registry.npmmirror.com/-/binary/python-build-standalone/"

unset _uv_rc
