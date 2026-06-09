#!/usr/bin/env bash

if command -v rtk &>/dev/null; then
    echo "rtk 已安装，当前版本："
    rtk --version
    read -r -p "是否强制重新安装？[y/N] " REPLY
    case "${REPLY:-N}" in
        [yY]|[yY][eE][sS]) ;;
        *) echo "已取消。"; exit 0 ;;
    esac
fi

if [[ $(uname) = 'Darwin' ]]; then
    brew install rtk
else
    curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh
fi
