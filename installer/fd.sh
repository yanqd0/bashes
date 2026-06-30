#!/usr/bin/env bash
#
# fd 安装脚本
# find 的现代化替代，语法简洁，搜索极快
# Rust 预编译二进制，安装到 ~/bin/
#
# 使用方式：
#   installer fd                       # 自动检测最新版本并安装
#   FD_VERSION=v10.4.2 installer fd     # 指定版本安装
#
# 参考：https://github.com/sharkdp/fd

source "$HOME/.bash/installer/_common.sh"

_i_rust_target || return 1
_i_setup "fd" "sharkdp/fd" "v10.4.2" "FD_VERSION"
[ -n "${FD_INSTALL_DIR:-}" ] && _i_set_install_dir "$FD_INSTALL_DIR"
[ -n "${FD_VERSION:-}" ] && _I_VERSION="$FD_VERSION"

_i_check_installed "fd" "--version" || return 0

_i_github_download "fd-${_I_TARGET}.tar.gz" \
    "https://github.com/sharkdp/fd/releases/download/<tag>/fd-<tag>-<target>.tar.gz" ||
    return 1

_i_extract 1 || return 1
_i_install_one "fd" || return 1

_i_verify "${_I_INSTALL_DIR}/fd" "--version" || {
    echo "[错误] fd 安装后无法执行，请检查" >&2
    return 1
}
_i_path_warning "fd"
_i_cleanup
