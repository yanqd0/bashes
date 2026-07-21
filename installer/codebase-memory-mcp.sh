#!/usr/bin/env bash
#
# codebase-memory-mcp 安装脚本
# 通过 wget 下载 GitHub Release 预编译二进制，安装到 ~/bin/
#
# 使用方式：
#   installer codebase-memory-mcp                       # 自动检测最新版本并安装
#   CBM_VERSION=v0.9.0 installer codebase-memory-mcp    # 指定版本安装
#
# 参考：https://github.com/DeusData/codebase-memory-mcp

source "$HOME/.bash/installer/_common.sh"

# ---------------------------------------------------------------------------
# 1. 检测操作系统与架构（命名与官方发布资产一致）
# ---------------------------------------------------------------------------
_i_detect_os "darwin" "linux" || return 1
_i_detect_arch "amd64" "arm64" || return 1

# Linux 默认使用静态链接的 portable 构建，兼容 glibc 2.38 以下的旧发行版
_cbm_portable=""
[ "$_I_OS" = "linux" ] && _cbm_portable="-portable"

# ---------------------------------------------------------------------------
# 2. 配置
# ---------------------------------------------------------------------------
_i_setup "codebase-memory-mcp" "DeusData/codebase-memory-mcp" "v0.9.0" "CBM_VERSION"
[ -n "${CBM_INSTALL_DIR:-}" ] && _i_set_install_dir "$CBM_INSTALL_DIR"
[ -n "${CBM_VERSION:-}" ] && _I_VERSION="$CBM_VERSION"

# ---------------------------------------------------------------------------
# 3. 已安装检查
# ---------------------------------------------------------------------------
_i_check_installed "codebase-memory-mcp" "--version" || return 0

# ---------------------------------------------------------------------------
# 4. 下载（续传检测 → 版本检测 → 归档复用 → 下载）
# ---------------------------------------------------------------------------
_cbm_archive="codebase-memory-mcp-${_I_OS}-${_I_ARCH}${_cbm_portable}.tar.gz"
_i_github_download "$_cbm_archive" \
    "https://github.com/DeusData/codebase-memory-mcp/releases/download/<tag>/${_cbm_archive}" ||
    return 1

# ---------------------------------------------------------------------------
# 5. 解压 & 安装
# ---------------------------------------------------------------------------
_i_extract 0 || return 1
_i_install_one "codebase-memory-mcp" || return 1

# ---------------------------------------------------------------------------
# 6. macOS：移除 Gatekeeper 隔离属性并 ad-hoc 签名
# ---------------------------------------------------------------------------
if [ "$_I_OS" = "darwin" ]; then
    xattr -d com.apple.quarantine "${_I_INSTALL_DIR}/codebase-memory-mcp" 2>/dev/null || true
    codesign --sign - --force "${_I_INSTALL_DIR}/codebase-memory-mcp" 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# 7. 验证安装
# ---------------------------------------------------------------------------
_i_verify "${_I_INSTALL_DIR}/codebase-memory-mcp" "--version" || {
    echo "[错误] codebase-memory-mcp 安装后无法执行，请检查" >&2
    return 1
}
_i_path_warning "codebase-memory-mcp"
_i_cleanup
unset _cbm_portable _cbm_archive
