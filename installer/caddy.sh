#!/usr/bin/env bash
#
# caddy 安装脚本
# Caddy — Go 语言编写的极简 Web 服务器，自动 HTTPS
# 预编译二进制，安装到 ~/bin/
#
# 使用方式：
#   installer caddy                      # 自动检测最新版本并安装
#   CADDY_VERSION=v2.9.1 installer caddy # 指定版本安装
#
# 参考：https://github.com/caddyserver/caddy

source "$HOME/.bash/installer/_common.sh"

# ---------------------------------------------------------------------------
# 1. 检测操作系统与架构
# ---------------------------------------------------------------------------
_i_detect_os "Darwin" "Linux" || return 1
_i_detect_arch "x86_64" "arm64" || return 1

# ---------------------------------------------------------------------------
# 2. 配置
# ---------------------------------------------------------------------------
_i_setup "caddy" "caddyserver/caddy" "v2.9.1" "CADDY_VERSION"
[ -n "${CADDY_INSTALL_DIR:-}" ] && _i_set_install_dir "$CADDY_INSTALL_DIR"
[ -n "${CADDY_VERSION:-}" ] && _I_VERSION="$CADDY_VERSION"

# ---------------------------------------------------------------------------
# 3. 已安装检查
# ---------------------------------------------------------------------------
_i_check_installed "caddy" "--version" || return 0

# ---------------------------------------------------------------------------
# 4. 下载（续传检测 → 版本检测 → 归档复用 → 下载）
#   Release 归档名: caddy_<ver>_<os>_<arch>.tar.gz
# ---------------------------------------------------------------------------
_i_github_download "caddy_${_I_OS}_${_I_ARCH}.tar.gz" \
    "https://github.com/caddyserver/caddy/releases/download/<tag>/caddy_<ver>_${_I_OS}_${_I_ARCH}.tar.gz" ||
    return 1

# ---------------------------------------------------------------------------
# 5. 解压 & 安装
# ---------------------------------------------------------------------------
# 归档内文件直接在根目录（无外层目录），无需 strip
_i_extract 0 || return 1
_i_install_one "caddy" || return 1

# ---------------------------------------------------------------------------
# 6. 验证安装
# ---------------------------------------------------------------------------
_i_verify "${_I_INSTALL_DIR}/caddy" "--version" || {
    echo "[错误] caddy 安装后无法执行，请检查" >&2
    return 1
}
_i_path_warning "caddy"
_i_cleanup
