#!/usr/bin/env bash
#
# hexyl 安装脚本
# 十六进制查看器，语法着色，比 xxd/od 更直观
# Rust 预编译二进制，安装到 ~/bin/
#
# 使用方式：
#   installer hexyl                       # 自动检测最新版本并安装
#   HEXYL_VERSION=v0.17.0 installer hexyl  # 指定版本安装
#
# 参考：https://github.com/sharkdp/hexyl

source "$HOME/.bash/installer/_common.sh"

_i_rust_target || return 1
_i_setup "hexyl" "sharkdp/hexyl" "v0.17.0" "HEXYL_VERSION"
[ -n "${HEXYL_INSTALL_DIR:-}" ] && _i_set_install_dir "$HEXYL_INSTALL_DIR"
[ -n "${HEXYL_VERSION:-}" ] && _I_VERSION="$HEXYL_VERSION"

_i_check_installed "hexyl" "--version" || return 0

_i_github_download "hexyl-${_I_TARGET}.tar.gz" \
    "https://github.com/sharkdp/hexyl/releases/download/<tag>/hexyl-<tag>-<target>.tar.gz" ||
    return 1

_i_extract 1 || return 1
_i_install_one "hexyl" || return 1

_i_verify "${_I_INSTALL_DIR}/hexyl" "--version" || {
    echo "[错误] hexyl 安装后无法执行，请检查" >&2
    return 1
}
_i_path_warning "hexyl"
_i_cleanup
