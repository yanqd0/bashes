#!/usr/bin/env bash
#
# nvm 安装脚本 — Node Version Manager
# 官方方式：curl/wget 拉取官方 install.sh 执行，安装到 $NVM_DIR（默认 ~/.nvm）
# nvm 是 shell 函数库，非预编译二进制，不走 _common.sh 流程
# 参考：https://github.com/nvm-sh/nvm

NVM_VERSION="v0.40.6"

# 已安装检查：nvm 是 shell 函数，非交互 shell 中 command -v 不可靠，改用文件检查
if [ -s "${NVM_DIR:-$HOME/.nvm}/nvm.sh" ]; then
    echo "nvm 已安装，当前版本："
    bash -c '. "${NVM_DIR:-$HOME/.nvm}/nvm.sh" && nvm --version' 2>/dev/null || echo "（版本读取失败）"
    echo -n "是否强制重新安装？[y/N] " >&2
    read -r REPLY
    case "${REPLY:-N}" in
    [yY] | [yY][eE][sS]) ;;
    *) echo "已取消。" && return 0 ;;
    esac
fi

# 官方方式安装（curl 优先，wget 兜底）
if command -v curl &>/dev/null; then
    curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash
else
    wget -qO- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash
fi

# 补充当前 shell 的 rc（官方脚本可能只写它检测到的 profile，双 shell 用户需兜底）
_nvm_rc=""
if [ -n "${ZSH_VERSION:-}" ]; then
    _nvm_rc="$HOME/.zshrc"
elif [ -n "${BASH_VERSION:-}" ]; then
    _nvm_rc="$HOME/.bashrc"
fi
if [ -n "$_nvm_rc" ] && ! grep -q "NVM_DIR" "$_nvm_rc" 2>/dev/null; then
    cat >>"$_nvm_rc" <<'EOF'

# NVM {{{
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"    # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # nvm bash_completion
# }}}
EOF
    echo "已将 nvm 配置补充写入 $_nvm_rc"
fi

# 验证
if bash -c '. "${NVM_DIR:-$HOME/.nvm}/nvm.sh" && nvm --version' 2>/dev/null; then
    echo "nvm 安装完成！当前 shell 需重新加载配置生效（source ~/.bashrc 或重开终端）"
    echo "提示：国内网络可配置 Node 镜像加速 nvm install node（镜像配置见 confal，可选）"
else
    echo "[错误] nvm 安装失败，请检查网络后重试" >&2
    return 1
fi

unset _nvm_rc
