#!/usr/bin/env bash
#
# herdr 安装脚本
# herdr — tmux 的现代替代品，Rust 编写的终端复用器/编码代理运行时
# GitHub Release 直接发布裸单二进制（非压缩包），安装到 ~/bin/
#
# 注意：
#   - 官方 Release 资产是原始可执行文件（如 herdr-linux-x86_64），无 tar/zip 包裹，
#     须走 _i_download_single + _i_install_single（raw 单二进制路径）。
#   - 资产按 <os>-<arch> 命名：OS 用 linux/macos，架构用 x86_64/aarch64。
#   - 本工具全部 unix 平台（linux/macos × x86_64/aarch64）均有预编译。
#
# 使用方式：
#   installer herdr                      # 自动检测最新版本并安装
#   HERDR_VERSION=v0.8.2 installer herdr # 指定版本安装（跳过版本检测）
#   installer --version v0.8.2 herdr     # 同上（选项置于工具名之前）
#
# 参考：https://github.com/herdrdev/herdr

source "$HOME/.bash/installer/_common.sh"

# ---------------------------------------------------------------------------
# 1. 检测操作系统与架构
#    herdr 资产用 linux/macos + x86_64/aarch64 标签
# ---------------------------------------------------------------------------
_i_detect_os "macos" "linux" || return 1
_i_detect_arch "x86_64" "aarch64" || return 1

# ---------------------------------------------------------------------------
# 2. 配置
# ---------------------------------------------------------------------------
_i_setup "herdr" "herdrdev/herdr" "v0.8.2" "HERDR_VERSION"
[ -n "${HERDR_INSTALL_DIR:-}" ] && _i_set_install_dir "$HERDR_INSTALL_DIR"
[ -n "${HERDR_VERSION:-}" ] && _I_VERSION="$HERDR_VERSION"

# ---------------------------------------------------------------------------
# 3. 已安装检查
# ---------------------------------------------------------------------------
_i_check_installed "herdr" "--version" || return 0

# ---------------------------------------------------------------------------
# 4. 下载裸单二进制（raw 模式：续传→版本检测→复用→下载→归档）
# ---------------------------------------------------------------------------
_i_download_single "herdr-${_I_OS}-${_I_ARCH}" \
    "https://github.com/herdrdev/herdr/releases/download/<tag>/herdr-${_I_OS}-${_I_ARCH}" ||
    return 1

# ---------------------------------------------------------------------------
# 5. 安装（直接拷贝已下载二进制，无需解压）
# ---------------------------------------------------------------------------
_i_install_single "herdr" || return 1

# ---------------------------------------------------------------------------
# 6. 验证安装
# ---------------------------------------------------------------------------
_i_verify "${_I_INSTALL_DIR}/herdr" "--version" || {
    echo "[错误] herdr 安装后无法执行，请检查" >&2
    return 1
}
_i_path_warning "herdr"
_i_cleanup
