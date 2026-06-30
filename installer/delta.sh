#!/usr/bin/env bash
#
# delta 安装脚本
# git diff 美化工具，支持语法高亮、行号、并排对比
# Rust 预编译二进制，安装到 ~/bin/
#
# 使用方式：
#   installer delta                       # 自动检测最新版本并安装
#   DELTA_VERSION=0.19.2 installer delta   # 指定版本安装
#
# 参考：https://github.com/dandavison/delta

source "$HOME/.bash/installer/_common.sh"

_i_rust_target || return 1
_i_setup "delta" "dandavison/delta" "0.19.2" "DELTA_VERSION"
[ -n "${DELTA_INSTALL_DIR:-}" ] && _i_set_install_dir "$DELTA_INSTALL_DIR"
[ -n "${DELTA_VERSION:-}" ] && _I_VERSION="$DELTA_VERSION"

_i_check_installed "delta" "--version" || return 0

# delta 的 tag 无 v 前缀（如 0.19.2），URL 中直接使用 <tag>
_i_github_download "delta-${_I_TARGET}.tar.gz" \
    "https://github.com/dandavison/delta/releases/download/<tag>/delta-<tag>-<target>.tar.gz" ||
    return 1

_i_extract 1 || return 1
_i_install_one "delta" || return 1

_i_verify "${_I_INSTALL_DIR}/delta" "--version" || {
    echo "[错误] delta 安装后无法执行，请检查" >&2
    return 1
}
_i_path_warning "delta"
_i_cleanup
