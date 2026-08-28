#!/usr/bin/env bash
#
# rclone 安装脚本
# Rclone — 命令行云存储同步工具，支持 40+ 存储后端
# 通过 wget 下载 GitHub Release 预编译二进制（zip），安装到 ~/bin/
#
# 使用方式：
#   installer rclone                        # 自动检测最新版本并安装
#   RCLONE_VERSION=v1.75.0 installer rclone # 指定版本安装（跳过版本检测）
#
# 参考：https://github.com/rclone/rclone

source "$HOME/.bash/installer/_common.sh"

# ---------------------------------------------------------------------------
# 1. 检测操作系统与架构
# rclone 资产命名：rclone-<tag>-<os>-<arch>.zip（文件名带 v 前缀），os 为 linux/osx，arch 为 amd64/arm64
# ---------------------------------------------------------------------------
_i_detect_os "osx" "linux" || return 1
_i_detect_arch "amd64" "arm64" || return 1

# ---------------------------------------------------------------------------
# 2. 配置
# ---------------------------------------------------------------------------
_i_setup "rclone" "rclone/rclone" "v1.75.0" "RCLONE_VERSION"
[ -n "${RCLONE_INSTALL_DIR:-}" ] && _i_set_install_dir "$RCLONE_INSTALL_DIR"
[ -n "${RCLONE_VERSION:-}" ] && _I_VERSION="$RCLONE_VERSION"

# ---------------------------------------------------------------------------
# 3. 已安装检查
# ---------------------------------------------------------------------------
_i_check_installed "rclone" "--version" || return 0

# ---------------------------------------------------------------------------
# 4. 下载（续传检测 → 版本检测 → 归档复用 → 下载）
# ---------------------------------------------------------------------------
_i_github_download "rclone-${_I_OS}-${_I_ARCH}.zip" \
    "https://github.com/rclone/rclone/releases/download/<tag>/rclone-<tag>-<os>-<arch>.zip" ||
    return 1

# ---------------------------------------------------------------------------
# 5. 解压 & 安装
# zip 为单顶层目录（如 rclone-v1.75.0-linux-amd64/），剥离后 rclone 直接在顶层
# ---------------------------------------------------------------------------
_i_extract 1 || return 1
_i_install_one "rclone" || return 1

# ---------------------------------------------------------------------------
# 6. 验证安装
# ---------------------------------------------------------------------------
_i_verify "${_I_INSTALL_DIR}/rclone" "--version" || {
    echo "[错误] rclone 安装后无法执行，请检查" >&2
    return 1
}
_i_path_warning "rclone"
_i_cleanup
