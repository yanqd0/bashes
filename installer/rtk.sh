#!/usr/bin/env bash
#
# rtk 安装脚本
# 通过 wget 下载 GitHub Release 中符合当前架构的预编译二进制，安装到 ~/bin/
#
# 使用方式：
#   installer rtk                       # 自动检测最新版本并安装
#   RTK_VERSION=v0.42.3 installer rtk    # 指定版本安装（跳过版本检测）
#
# 参考：https://github.com/rtk-ai/rtk

source "$HOME/.bash/installer/_common.sh"

# ---------------------------------------------------------------------------
# 1. 检测操作系统与架构
# ---------------------------------------------------------------------------
_i_detect_os "darwin" "linux" || return 1
_i_detect_arch "x86_64" "aarch64" || return 1

# rtk 使用 Rust 目标三元组命名
case "${_I_OS}-${_I_ARCH}" in
linux-x86_64) _I_TARGET="x86_64-unknown-linux-musl" ;;
linux-aarch64) _I_TARGET="aarch64-unknown-linux-gnu" ;;
darwin-*) _I_TARGET="${_I_ARCH}-apple-darwin" ;;
esac

# ---------------------------------------------------------------------------
# 2. 配置
# ---------------------------------------------------------------------------
_i_setup "rtk" "rtk-ai/rtk" "v0.42.3" "RTK_VERSION"
[ -n "${RTK_INSTALL_DIR:-}" ] && _i_set_install_dir "$RTK_INSTALL_DIR"
[ -n "${RTK_VERSION:-}" ] && _I_VERSION="$RTK_VERSION"

# ---------------------------------------------------------------------------
# 3. 已安装检查
# ---------------------------------------------------------------------------
_i_check_installed "rtk" "--version" || return 0

# ---------------------------------------------------------------------------
# 4. 下载
# ---------------------------------------------------------------------------
_i_github_download "rtk-${_I_TARGET}.tar.gz" \
    "https://github.com/rtk-ai/rtk/releases/download/<tag>/rtk-<target>.tar.gz" ||
    return 1

# ---------------------------------------------------------------------------
# 5. 解压 & 安装
# ---------------------------------------------------------------------------
_i_extract 0 || return 1
_i_install_one "rtk" || return 1

# ---------------------------------------------------------------------------
# 6. 验证安装
# ---------------------------------------------------------------------------
_i_verify "${_I_INSTALL_DIR}/rtk" "--version" || {
    echo "[错误] rtk 安装后无法执行，请检查" >&2
    return 1
}
_i_path_warning "rtk"
_i_cleanup
