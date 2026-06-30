#!/usr/bin/env bash
#
# difftastic 安装脚本
# 语义化 diff 工具，理解代码结构而非逐行对比
# Rust 预编译二进制，安装到 ~/bin/
#
# 使用方式：
#   installer difftastic                       # 自动检测最新版本并安装
#   DIFFTASTIC_VERSION=0.69.0 installer difftastic  # 指定版本安装
#
# 参考：https://github.com/Wilfred/difftastic

source "$HOME/.bash/installer/_common.sh"

_i_rust_target || return 1
_i_setup "difftastic" "Wilfred/difftastic" "0.69.0" "DIFFTASTIC_VERSION"
[ -n "${DIFFTASTIC_INSTALL_DIR:-}" ] && _i_set_install_dir "$DIFFTASTIC_INSTALL_DIR"
[ -n "${DIFFTASTIC_VERSION:-}" ] && _I_VERSION="$DIFFTASTIC_VERSION"

# difftastic 的二进制名是 difft（不是 difftastic）
_i_check_installed "difft" "--version" || return 0

# difftastic 资产不含版本号：difft-<target>.tar.gz
_i_github_download "difft-${_I_TARGET}.tar.gz" \
    "https://github.com/Wilfred/difftastic/releases/download/<tag>/difft-<target>.tar.gz" ||
    return 1

_i_extract 0 || return 1
_i_install_one "difft" || return 1

_i_verify "${_I_INSTALL_DIR}/difft" "--version" || {
    echo "[错误] difft 安装后无法执行，请检查" >&2
    return 1
}
_i_path_warning "difft"
_i_cleanup
