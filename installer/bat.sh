#!/usr/bin/env bash
#
# bat 安装脚本
# cat 的现代化替代，支持语法高亮和 Git 标记
# Rust 预编译二进制，安装到 ~/bin/
#
# 使用方式：
#   installer bat                       # 自动检测最新版本并安装
#   BAT_VERSION=v0.26.1 installer bat    # 指定版本安装
#
# 参考：https://github.com/sharkdp/bat

source "$HOME/.bash/installer/_common.sh"

_i_rust_target || return 1
_i_setup "bat" "sharkdp/bat" "v0.26.1" "BAT_VERSION"
[ -n "${BAT_INSTALL_DIR:-}" ] && _i_set_install_dir "$BAT_INSTALL_DIR"
[ -n "${BAT_VERSION:-}" ] && _I_VERSION="$BAT_VERSION"

_i_check_installed "bat" "--version" || return 0

_i_github_download "bat-${_I_TARGET}.tar.gz" \
    "https://github.com/sharkdp/bat/releases/download/<tag>/bat-<tag>-<target>.tar.gz" ||
    return 1

_i_extract 1 || return 1
_i_install_one "bat" || return 1

_i_verify "${_I_INSTALL_DIR}/bat" "--version" || {
    echo "[错误] bat 安装后无法执行，请检查" >&2
    return 1
}
_i_path_warning "bat"
_i_cleanup
