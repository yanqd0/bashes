#!/usr/bin/env bash
#
# yazi 安装脚本
# 终端文件管理器，支持预览、多面板、异步 I/O
# 需要安装 yazi 和 ya 两个二进制
#
# 使用方式：
#   installer yazi                       # 自动检测最新版本并安装
#   YAZI_VERSION=v26.5.6 installer yazi   # 指定版本安装
#
# 注意：yazi 使用 .zip 格式发布，解压逻辑与 tar.gz 不同
#
# 参考：https://github.com/sxyazi/yazi

source "$HOME/.bash/installer/_common.sh"

# macOS：yazi 有 darwin 预编译 zip，但 zip 解压需要特殊处理
_i_rust_target || return 1
_i_setup "yazi" "sxyazi/yazi" "v26.5.6" "YAZI_VERSION"
[ -n "${YAZI_INSTALL_DIR:-}" ] && _i_set_install_dir "$YAZI_INSTALL_DIR"
[ -n "${YAZI_VERSION:-}" ] && _I_VERSION="$YAZI_VERSION"

_i_check_installed "yazi" "--version" || return 0

# yazi 使用 .zip 格式，资产名 yazi-<target>.zip
# 占位符替换后下载
_zip_archive="yazi-${_I_TARGET}.zip"
_zip_downloading="${_I_CACHE_DIR}/${_zip_archive}"
_zip_version_file="${_I_CACHE_DIR}/.version"

# 检查续传（zip 不支持断点续传，仅检查是否已下载）
if [ -f "$_zip_downloading" ] && [ -f "$_zip_version_file" ]; then
    echo "发现未完成的下载，将重新下载..."
    rm -f "$_zip_downloading"
fi

# 确定版本并检查归档
_i_detect_version
_zip_archived="${_I_CACHE_DIR}/${_I_VERSION}/${_zip_archive}"

if [ -f "$_zip_archived" ]; then
    echo "复用已缓存的文件: ${_zip_archived}"
else
    # 构建下载 URL
    local ver_no_v="${_I_VERSION#v}"
    local _zip_url
    _zip_url=$(echo "https://github.com/sxyazi/yazi/releases/download/<tag>/yazi-<target>.zip" | sed \
        -e "s|<tag>|${_I_VERSION}|g" \
        -e "s|<target>|${_I_TARGET}|g")

    echo "下载: ${_zip_url}"
    echo "$_I_VERSION" >"$_zip_version_file"
    wget --show-progress -O "$_zip_downloading" "$_zip_url" || {
        echo "[错误] 下载失败" >&2
        return 1
    }
    mkdir -p "$(dirname "$_zip_archived")"
    mv "$_zip_downloading" "$_zip_archived"
    echo "已归档: ${_zip_archived}"
fi

# 解压 zip（使用 unzip）
_tmpdir=$(mktemp -d)
echo "解压到 ${_I_INSTALL_DIR}/"
mkdir -p "$_I_INSTALL_DIR"

if ! command -v unzip &>/dev/null; then
    echo "[错误] 需要 unzip 命令，请先安装：sudo apt install unzip" >&2
    rm -rf "$_tmpdir"
    return 1
fi

unzip -o "$_zip_archived" -d "$_tmpdir" >/dev/null || {
    echo "[错误] 解压失败" >&2
    rm -rf "$_tmpdir"
    return 1
}

# 安装 yazi 和 ya 两个二进制
_count=0
for _bin in yazi ya; do
    _src=$(find "$_tmpdir" -name "$_bin" -type f 2>/dev/null | head -1)
    if [ -n "$_src" ]; then
        cp -f "$_src" "${_I_INSTALL_DIR}/"
        chmod +x "${_I_INSTALL_DIR}/${_bin}"
        echo "  ${_bin}"
        _count=$((_count + 1))
    fi
done

rm -rf "$_tmpdir"

echo "共安装 ${_count} 个二进制文件"
[ "$_count" -gt 0 ] || {
    echo "[错误] 未找到可安装的二进制文件" >&2
    return 1
}

echo ""
if "${_I_INSTALL_DIR}/yazi" --version 2>/dev/null; then
    echo "yazi 安装完成！"
else
    echo "[错误] yazi 安装后无法执行" >&2
    return 1
fi

_i_path_warning "yazi"
_i_cleanup
unset _zip_archive _zip_downloading _zip_version_file _zip_archived _zip_url _tmpdir _src _bin _count
