#!/usr/bin/env bash
#
# v2rayN 安装脚本
# V2Ray/Xray 代理客户端，基于 Avalonia 跨平台 GUI
# 多文件应用，安装到 ~/bin/v2rayN.app/，~bin/v2rayN 为软链接
#
# 使用方式：
#   installer v2rayN                       # 自动检测最新版本并安装
#   V2RAYN_VERSION=7.22.7 installer v2rayN  # 指定版本安装
#
# 参考：https://github.com/2dust/v2rayN

source "$HOME/.bash/installer/_common.sh"

# ---------------------------------------------------------------------------
# 1. 检测操作系统与架构
# ---------------------------------------------------------------------------
_i_detect_os "macos" "linux" || return 1
# v2rayN x86_64 用 '64' 命名（非 x86_64）
_i_detect_arch "64" "arm64" || return 1

# ---------------------------------------------------------------------------
# 2. 配置（v2rayN 是多文件 GUI 应用，安装到子目录）
# ---------------------------------------------------------------------------
_i_setup "v2rayN" "2dust/v2rayN" "7.22.7" "V2RAYN_VERSION"
[ -n "${V2RAYN_INSTALL_DIR:-}" ] && _i_set_install_dir "$V2RAYN_INSTALL_DIR"
# 默认为 ~/bin/v2rayN.app/，避免与软链接同名
_I_INSTALL_DIR="${_I_INSTALL_DIR}/v2rayN.app"
[ -n "${V2RAYN_VERSION:-}" ] && _I_VERSION="$V2RAYN_VERSION"

# ---------------------------------------------------------------------------
# 3. 已安装检查
# ---------------------------------------------------------------------------
if [ -f "${_I_INSTALL_DIR}/v2rayN" ]; then
    echo "v2rayN 已安装到 ${_I_INSTALL_DIR}"
    read -r -p "是否强制重新安装？[y/N] " REPLY
    case "${REPLY:-N}" in
    [yY] | [yY][eE][sS]) ;;
    *)
        echo "已取消。"
        return 0
        ;;
    esac
fi

# ---------------------------------------------------------------------------
# 4. 版本检测
# ---------------------------------------------------------------------------
_i_detect_version

# ---------------------------------------------------------------------------
# 5. 下载（v2rayN 使用 .zip 格式，~130MB）
# ---------------------------------------------------------------------------
_zip_name="v2rayN-${_I_OS}-${_I_ARCH}.zip"
_zip_downloading="${_I_CACHE_DIR}/${_zip_name}"

# 检查缓存的归档
_zip_archived="${_I_CACHE_DIR}/${_I_VERSION}/${_zip_name}"
if [ -f "$_zip_archived" ]; then
    echo "复用已缓存的文件: ${_zip_archived}"
else
    _zip_url="https://github.com/2dust/v2rayN/releases/download/${_I_TAG}/${_zip_name}"
    echo "下载: ${_zip_url}"
    wget -c --show-progress -O "$_zip_downloading" "$_zip_url" || {
        echo "[错误] 下载失败" >&2
        rm -f "$_zip_downloading"
        return 1
    }
    mkdir -p "$(dirname "$_zip_archived")"
    mv "$_zip_downloading" "$_zip_archived"
    echo "已归档: ${_zip_archived}"
fi

# ---------------------------------------------------------------------------
# 6. 解压 & 安装到 ~/bin/v2rayN.app/
# ---------------------------------------------------------------------------
_tmpdir=$(mktemp -d)

if ! command -v unzip &>/dev/null; then
    echo "[错误] 需要 unzip 命令，请先安装：sudo apt install unzip" >&2
    rm -rf "$_tmpdir"
    return 1
fi

echo "解压到 ${_I_INSTALL_DIR}/"
rm -rf "$_I_INSTALL_DIR"
mkdir -p "$_I_INSTALL_DIR"

unzip -o "$_zip_archived" -d "$_tmpdir" >/dev/null || {
    echo "[错误] 解压失败" >&2
    rm -rf "$_tmpdir"
    return 1
}

# 若解压后仅有一个顶层目录，则上移一层（--strip-components=1 等效）
_src_dir="$_tmpdir"
_items=("$_tmpdir"/*)
if [ ${#_items[@]} -eq 1 ] && [ -d "${_items[0]}" ]; then
    _src_dir="${_items[0]}"
fi

# v2rayN 是完整的应用包，全部文件安装到子目录
_count=0
for f in "$_src_dir"/*; do
    [ -e "$f" ] || continue
    name=$(basename "$f")
    cp -rf "$f" "${_I_INSTALL_DIR}/"
    if [ -f "$f" ]; then
        chmod +x "${_I_INSTALL_DIR}/${name}" 2>/dev/null || true
        echo "  ${name}"
    elif [ -d "$f" ]; then
        echo "  ${name}/"
    fi
    _count=$((_count + 1))
done

rm -rf "$_tmpdir"
echo "共安装 ${_count} 项"

# 创建 ~/bin/v2rayN 软链接指向主程序
ln -sf "${_I_INSTALL_DIR}/v2rayN" "${HOME}/bin/v2rayN" 2>/dev/null || {
    rm -f "${HOME}/bin/v2rayN"
    ln -sf "${_I_INSTALL_DIR}/v2rayN" "${HOME}/bin/v2rayN"
}
echo "  ~/bin/v2rayN -> ${_I_INSTALL_DIR}/v2rayN"

# 验证安装
# ---------------------------------------------------------------------------
echo ""
if [ -f "${_I_INSTALL_DIR}/v2rayN" ] || [ -f "${_I_INSTALL_DIR}/v2rayN.exe" ]; then
    echo "v2rayN 安装完成！"
    echo "启动: v2rayN"
else
    echo "[警告] 未找到 v2rayN 主程序，请检查压缩包内容" >&2
    echo "已安装内容："
    ls -la "$_I_INSTALL_DIR/" 2>/dev/null
fi

_i_cleanup
unset _zip_name _zip_downloading _zip_archived _zip_url _tmpdir _src_dir _items _count
