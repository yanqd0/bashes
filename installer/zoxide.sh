#!/usr/bin/env bash
#
# zoxide 安装脚本
# 智能 cd 替代，根据访问频率自动跳转
# Rust 预编译二进制，安装到 ~/bin/
#
# 使用方式：
#   installer zoxide                       # 自动检测最新版本并安装
#   ZOXIDE_VERSION=v0.9.9 installer zoxide  # 指定版本安装
#
# 参考：https://github.com/ajeetdsouza/zoxide

source "$HOME/.bash/installer/_common.sh"

# zoxide Linux x64 仅提供 musl 构建，需覆盖默认 gnu 目标
_i_rust_target || return 1
case "$(uname -s)-$(uname -m)" in
Linux-x86_64) _I_TARGET="${_I_TARGET/gnu/musl}" ;;
Linux-aarch64) _I_TARGET="${_I_TARGET/gnu/musl}" ;;
esac

_i_setup "zoxide" "ajeetdsouza/zoxide" "v0.9.9" "ZOXIDE_VERSION"
[ -n "${ZOXIDE_INSTALL_DIR:-}" ] && _i_set_install_dir "$ZOXIDE_INSTALL_DIR"
[ -n "${ZOXIDE_VERSION:-}" ] && _I_VERSION="$ZOXIDE_VERSION"

_i_check_installed "zoxide" "--version" || return 0

# zoxide 资产中的版本号不含 v 前缀，用 <ver>
_i_github_download "zoxide-${_I_TARGET}.tar.gz" \
    "https://github.com/ajeetdsouza/zoxide/releases/download/<tag>/zoxide-<ver>-<target>.tar.gz" ||
    return 1

_i_extract 0 || return 1
_i_install_one "zoxide" || return 1

_i_verify "${_I_INSTALL_DIR}/zoxide" "--version" || {
    echo "[错误] zoxide 安装后无法执行，请检查" >&2
    return 1
}
_i_path_warning "zoxide"
_i_cleanup
