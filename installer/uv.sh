#!/usr/bin/env bash

if command -v uv &>/dev/null; then
    echo "uv 已安装，当前版本："
    uv --version
    return 0
fi

curl -LsSf https://uv.agentsmirror.com/install-cn.sh | sh

export UV_DEFAULT_INDEX="https://mirrors.aliyun.com/pypi/simple/"
export UV_PYTHON_INSTALL_MIRROR="https://registry.npmmirror.com/-/binary/python-build-standalone/"
