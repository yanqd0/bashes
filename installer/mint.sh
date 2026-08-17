#!/usr/bin/env bash
#
# mint 安装脚本
# 通过 wget 下载 GitHub Release 预编译二进制，安装到 ~/bin/
# Linux x86_64 走 musl 静态预编译；macOS 走 apple-darwin 预编译
# Linux aarch64 无预编译，打印源码编译指引
#
# 使用方式：
#   installer mint                      # 自动检测最新版本并安装
#   MINT_VERSION=0.5.0 installer mint   # 指定版本安装（跳过版本检测）
#
# 参考：https://github.com/yanqd0/mint

source "$HOME/.bash/installer/_common.sh"

# ---------------------------------------------------------------------------
# 1. 检测操作系统与架构
# ---------------------------------------------------------------------------
_i_detect_os "darwin" "linux" || return 1
_i_detect_arch "x86_64" "aarch64" || return 1

# mint 使用 Rust 目标三元组命名，但仅 Linux x86_64 提供 musl 预编译
case "${_I_OS}-${_I_ARCH}" in
linux-x86_64) _I_TARGET="x86_64-unknown-linux-musl" ;;
darwin-*) _I_TARGET="${_I_ARCH}-apple-darwin" ;;
linux-aarch64)
    echo "[提示] mint 未提供 Linux aarch64 预编译，请从源码编译安装："
    echo ""
    echo "  cargo install --locked --git https://github.com/yanqd0/mint"
    echo ""
    echo "依赖：Rust 工具链（可先执行 installer rustup）"
    return 1
    ;;
*)
    echo "[错误] 不支持的目标平台: ${_I_OS}-${_I_ARCH}" >&2
    return 1
    ;;
esac

# ---------------------------------------------------------------------------
# 2. 配置
# ---------------------------------------------------------------------------
_i_setup "mint" "yanqd0/mint" "0.5.0" "MINT_VERSION"
[ -n "${MINT_INSTALL_DIR:-}" ] && _i_set_install_dir "$MINT_INSTALL_DIR"
[ -n "${MINT_VERSION:-}" ] && _I_VERSION="$MINT_VERSION"

# ---------------------------------------------------------------------------
# 3. 已安装检查
# ---------------------------------------------------------------------------
_i_check_installed "mint" "--version" || return 0

# ---------------------------------------------------------------------------
# 4. 下载
# ---------------------------------------------------------------------------
_i_github_download "mint-faa-${_I_TARGET}.tar.xz" \
    "https://github.com/yanqd0/mint/releases/download/<tag>/mint-faa-<target>.tar.xz" ||
    return 1

# ---------------------------------------------------------------------------
# 5. 解压 & 安装
#    （cargo-dist 归档为平铺结构，mint 二进制直接位于顶层）
# ---------------------------------------------------------------------------
_i_extract 0 || return 1
_i_install_one "mint" || return 1

# ---------------------------------------------------------------------------
# 6. 验证安装
# ---------------------------------------------------------------------------
_i_verify "${_I_INSTALL_DIR}/mint" "--version" || {
    echo "[错误] mint 安装后无法执行，请检查" >&2
    return 1
}
_i_path_warning "mint"
_i_cleanup
