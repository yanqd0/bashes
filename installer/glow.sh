#!/usr/bin/env bash
#
# glow 安装脚本
# Glow — Charmbracelet 出品的终端 Markdown 预览工具
# 通过 wget 下载 GitHub Release 预编译二进制，安装到 ~/bin/
#
# 使用方式：
#   installer glow                       # 自动检测最新版本并安装
#   GLOW_VERSION=v2.1.2 installer glow    # 指定版本安装（跳过版本检测）
#
# 参考：https://github.com/charmbracelet/glow

source "$HOME/.bash/installer/_common.sh"

# ---------------------------------------------------------------------------
# 1. 检测操作系统与架构
# ---------------------------------------------------------------------------
_i_detect_os "Darwin" "Linux" || return 1
_i_detect_arch "x86_64" "arm64" || return 1

# ---------------------------------------------------------------------------
# 2. 配置
# ---------------------------------------------------------------------------
_i_setup "glow" "charmbracelet/glow" "v2.1.2" "GLOW_VERSION"
[ -n "${GLOW_INSTALL_DIR:-}" ] && _i_set_install_dir "$GLOW_INSTALL_DIR"
[ -n "${GLOW_VERSION:-}" ] && _I_VERSION="$GLOW_VERSION"

# ---------------------------------------------------------------------------
# 3. 已安装检查
# ---------------------------------------------------------------------------
_i_check_installed "glow" "--version" || return 0

# ---------------------------------------------------------------------------
# 4. 下载（续传检测 → 版本检测 → 归档复用 → 下载）
# ---------------------------------------------------------------------------
_i_github_download "glow-${_I_OS}_${_I_ARCH}.tar.gz" \
    "https://github.com/charmbracelet/glow/releases/download/<tag>/glow_<ver>_${_I_OS}_${_I_ARCH}.tar.gz" ||
    return 1

# ---------------------------------------------------------------------------
# 5. 解压 & 安装
# ---------------------------------------------------------------------------
_i_extract 1 || return 1
_i_install_one "glow" || return 1

# ---------------------------------------------------------------------------
# 6. 验证安装
# ---------------------------------------------------------------------------
_i_verify "${_I_INSTALL_DIR}/glow" "--version" || {
    echo "[错误] glow 安装后无法执行，请检查" >&2
    return 1
}
_i_path_warning "glow"
_i_cleanup
