#!/usr/bin/env bash
#
# ripgrep 安装脚本
# grep 的现代化替代，以正则快速递归搜索文件内容
# Rust 预编译二进制，安装到 ~/bin/
#
# 使用方式：
#   installer ripgrep                       # 自动检测最新版本并安装
#   RIPGREP_VERSION=15.2.0 installer ripgrep # 指定版本安装
#
# 注意：
#   - 可执行文件名为 rg（非 ripgrep）
#   - Release tag 不带 v 前缀（如 15.2.0）
#   - Linux 资产使用 musl 目标（无 gnu 资产），故需自行映射目标三元组
#
# 参考：https://github.com/BurntSushi/ripgrep

source "$HOME/.bash/installer/_common.sh"

# ---------------------------------------------------------------------------
# 1. 检测操作系统与架构并映射为 ripgrep 目标三元组
#   ripgrep 资产命名：ripgrep-<tag>-<target>.tar.gz
#   关键差异：Linux 仅提供 musl 目标；macOS 为 apple-darwin
# ---------------------------------------------------------------------------
_i_detect_os "apple-darwin" "unknown-linux-musl" || return 1
_i_detect_arch "x86_64" "aarch64" || return 1
_I_TARGET="${_I_ARCH}-${_I_OS}"

# ---------------------------------------------------------------------------
# 2. 配置
# ---------------------------------------------------------------------------
_i_setup "ripgrep" "BurntSushi/ripgrep" "15.2.0" "RIPGREP_VERSION"
[ -n "${RIPGREP_INSTALL_DIR:-}" ] && _i_set_install_dir "$RIPGREP_INSTALL_DIR"
[ -n "${RIPGREP_VERSION:-}" ] && _I_VERSION="$RIPGREP_VERSION"

# ---------------------------------------------------------------------------
# 3. 已安装检查（可执行文件为 rg）
# ---------------------------------------------------------------------------
_i_check_installed "rg" "--version" || return 0

# ---------------------------------------------------------------------------
# 4. 下载
# ---------------------------------------------------------------------------
_i_github_download "ripgrep-${_I_TARGET}.tar.gz" \
    "https://github.com/BurntSushi/ripgrep/releases/download/<tag>/ripgrep-<tag>-<target>.tar.gz" ||
    return 1

# ---------------------------------------------------------------------------
# 5. 解压 & 安装
#   归档内顶层目录为 ripgrep-<tag>-<target>/rg，剥离 1 层后 rg 位于根
# ---------------------------------------------------------------------------
_i_extract 1 || return 1
_i_install_one "rg" || return 1

# ---------------------------------------------------------------------------
# 6. 验证安装
# ---------------------------------------------------------------------------
_i_verify "${_I_INSTALL_DIR}/rg" "--version" || {
    echo "[错误] ripgrep 安装后无法执行，请检查" >&2
    return 1
}
_i_path_warning "rg"
_i_cleanup
