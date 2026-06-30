#!/usr/bin/env bash
#
# hyperfine 安装脚本
# 命令行基准测试工具，统计多次运行的执行时间
# Rust 预编译二进制，安装到 ~/bin/
#
# 使用方式：
#   installer hyperfine                       # 自动检测最新版本并安装
#   HYPERFINE_VERSION=v1.20.0 installer hyperfine  # 指定版本安装
#
# 参考：https://github.com/sharkdp/hyperfine

source "$HOME/.bash/installer/_common.sh"

_i_rust_target || return 1
_i_setup "hyperfine" "sharkdp/hyperfine" "v1.20.0" "HYPERFINE_VERSION"
[ -n "${HYPERFINE_INSTALL_DIR:-}" ] && _i_set_install_dir "$HYPERFINE_INSTALL_DIR"
[ -n "${HYPERFINE_VERSION:-}" ] && _I_VERSION="$HYPERFINE_VERSION"

_i_check_installed "hyperfine" "--version" || return 0

_i_github_download "hyperfine-${_I_TARGET}.tar.gz" \
    "https://github.com/sharkdp/hyperfine/releases/download/<tag>/hyperfine-<tag>-<target>.tar.gz" ||
    return 1

_i_extract 1 || return 1
_i_install_one "hyperfine" || return 1

_i_verify "${_I_INSTALL_DIR}/hyperfine" "--version" || {
    echo "[错误] hyperfine 安装后无法执行，请检查" >&2
    return 1
}
_i_path_warning "hyperfine"
_i_cleanup
