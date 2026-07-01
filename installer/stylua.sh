#!/usr/bin/env bash
#
# stylua 安装脚本
# Lua 代码格式化工具，Rust 预编译，单一二进制
# 通过 GitHub Release zip 下载，安装到 ~/bin/
#
# 使用方式：
#   installer stylua                       # 自动检测最新版本并安装
#   STYLUA_VERSION=v2.5.2 installer stylua  # 指定版本安装
#
# 参考：https://github.com/JohnnyMorganz/StyLua

source "$HOME/.bash/installer/_common.sh"

# ---------------------------------------------------------------------------
# 1. 检测操作系统与架构
# ---------------------------------------------------------------------------
_i_detect_os "macos" "linux" || return 1
_i_detect_arch "x86_64" "aarch64" || return 1

# ---------------------------------------------------------------------------
# 2. 配置
# ---------------------------------------------------------------------------
_i_setup "stylua" "JohnnyMorganz/StyLua" "v2.5.2" "STYLUA_VERSION"
[ -n "${STYLUA_INSTALL_DIR:-}" ] && _i_set_install_dir "$STYLUA_INSTALL_DIR"
[ -n "${STYLUA_VERSION:-}" ] && _I_VERSION="$STYLUA_VERSION"

# ---------------------------------------------------------------------------
# 3. 已安装检查
# ---------------------------------------------------------------------------
_i_check_installed "stylua" "--version" || return 0

# ---------------------------------------------------------------------------
# 4. 下载（stylua 使用 .zip 格式，无法复用 _i_github_download）
# ---------------------------------------------------------------------------
_i_detect_version

_zip_name="stylua-${_I_OS}-${_I_ARCH}.zip"
_zip_downloading="${_I_CACHE_DIR}/${_zip_name}"

# 检查缓存的归档
_zip_archived="${_I_CACHE_DIR}/${_I_VERSION}/${_zip_name}"
if [ -f "$_zip_archived" ]; then
    echo "复用已缓存的文件: ${_zip_archived}"
else
    # 构建下载 URL：stylua-<os>-<arch>.zip（不含版本号）
    _zip_url="https://github.com/JohnnyMorganz/StyLua/releases/download/${_I_TAG}/${_zip_name}"
    echo "下载: ${_zip_url}"
    wget --show-progress -O "$_zip_downloading" "$_zip_url" || {
        echo "[错误] 下载失败" >&2
        rm -f "$_zip_downloading"
        return 1
    }
    mkdir -p "$(dirname "$_zip_archived")"
    mv "$_zip_downloading" "$_zip_archived"
    echo "已归档: ${_zip_archived}"
fi

# ---------------------------------------------------------------------------
# 5. 解压 & 安装
# ---------------------------------------------------------------------------
_tmpdir=$(mktemp -d)

if ! command -v unzip &>/dev/null; then
    echo "[错误] 需要 unzip 命令，请先安装：sudo apt install unzip" >&2
    rm -rf "$_tmpdir"
    return 1
fi

echo "解压..."
unzip -o "$_zip_archived" -d "$_tmpdir" >/dev/null || {
    echo "[错误] 解压失败" >&2
    rm -rf "$_tmpdir"
    return 1
}

# stylua 是单一二进制，直接安装
echo "安装到 ${_I_INSTALL_DIR}/"
mkdir -p "$_I_INSTALL_DIR"
cp -f "${_tmpdir}/stylua" "${_I_INSTALL_DIR}/stylua" 2>/dev/null || {
    # stylua zip 内部可能包含 LICENSE 等，只有 stylua 这一个二进制
    _src=$(find "$_tmpdir" -name "stylua" -type f 2>/dev/null | head -1)
    if [ -z "$_src" ]; then
        echo "[错误] 未找到 stylua 二进制文件" >&2
        rm -rf "$_tmpdir"
        return 1
    fi
    cp -f "$_src" "${_I_INSTALL_DIR}/stylua"
}
chmod +x "${_I_INSTALL_DIR}/stylua"
echo "  stylua"

rm -rf "$_tmpdir"

# ---------------------------------------------------------------------------
# 6. 验证安装
# ---------------------------------------------------------------------------
echo ""
if "${_I_INSTALL_DIR}/stylua" --version 2>/dev/null; then
    echo "stylua 安装完成！"
else
    rm -f "${_I_INSTALL_DIR}/stylua"
    echo "[错误] stylua 安装后无法执行，请检查" >&2
    return 1
fi

_i_path_warning "stylua"
_i_cleanup
unset _zip_name _zip_downloading _zip_archived _zip_url _tmpdir _src
