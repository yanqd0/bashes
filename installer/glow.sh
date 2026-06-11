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

# ---------------------------------------------------------------------------
# 1. 检测操作系统与架构（无网络请求，始终先行）
# ---------------------------------------------------------------------------

# 操作系统：GoReleaser 命名：Linux / Darwin
_glow_os=""
case "$(uname -s)" in
    Linux)  _glow_os="Linux" ;;
    Darwin) _glow_os="Darwin" ;;
    *)
        echo "[错误] 不支持的操作系统: $(uname -s)" >&2
        return 1
        ;;
esac

# CPU 架构：GoReleaser 命名：x86_64 / arm64
_glow_arch=""
case "$(uname -m)" in
    x86_64|amd64)   _glow_arch="x86_64" ;;
    arm64|aarch64)  _glow_arch="arm64" ;;
    *)
        echo "[错误] 不支持的 CPU 架构: $(uname -m)" >&2
        return 1
        ;;
esac

# 目标标识符（用于缓存文件命名）
_glow_target="${_glow_os}_${_glow_arch}"

# ---------------------------------------------------------------------------
# 2. 缓存路径 & 续传检测
# ---------------------------------------------------------------------------
_glow_repo="charmbracelet/glow"
_glow_fallback_version="v2.1.2"
_glow_install_dir="${GLOW_INSTALL_DIR:-$HOME/bin}"
_glow_cache_dir="$HOME/Downloads/installer/glow"
mkdir -p "$_glow_cache_dir"

_glow_archive="glow-${_glow_target}.tar.gz"
_glow_downloading="${_glow_cache_dir}/${_glow_archive}"     # 下载中临时文件
_glow_version_file="${_glow_cache_dir}/.version"             # 记录版本号

_glow_resuming=false

# 检查是否有未完成的下载：临时文件存在 且 .version 可读
if [ -f "$_glow_downloading" ] && [ -f "$_glow_version_file" ]; then
    _glow_resuming=true
    _glow_version=$(cat "$_glow_version_file")
    echo "发现未完成的下载（版本 ${_glow_version}），将续传..."
    echo "  文件: ${_glow_downloading}"
    echo "  已下载: $(du -h "$_glow_downloading" | cut -f1)"
fi

# ---------------------------------------------------------------------------
# 3. 若非续传，则执行完整流程：已安装检查 → 版本确定 → 归档复用检查
# ---------------------------------------------------------------------------
if ! $_glow_resuming; then
    # 3a. 已安装检查
    if command -v glow &>/dev/null; then
        echo "glow 已安装，当前版本："
        glow --version 2>/dev/null || true
        read -r -p "是否强制重新安装？[y/N] " REPLY
        case "${REPLY:-N}" in
            [yY]|[yY][eE][sS]) ;;
            *) echo "已取消。"; return 0 ;;
        esac
    fi

    # 3b. 确定版本号
    #     优先 GLOW_VERSION 环境变量（零请求）→ HEAD 重定向（1 次轻量请求）→ 回退默认版本
    if [ -n "$GLOW_VERSION" ]; then
        _glow_version="$GLOW_VERSION"
        echo "使用指定版本: ${_glow_version}"
    else
        echo "正在查询最新版本..."
        _glow_location=$(wget -q --max-redirect=0 --server-response \
            "https://github.com/${_glow_repo}/releases/latest" 2>&1 | \
            sed -n '/^  Location:/s/.*tag\/\([^[:space:]]*\).*/\1/p')

        if [ -n "$_glow_location" ]; then
            _glow_version="$_glow_location"
            echo "最新版本: ${_glow_version}"
        else
            _glow_version="$_glow_fallback_version"
            echo "无法连接 GitHub，回退到默认版本: ${_glow_version}"
            echo "  （可设置 GLOW_VERSION=vX.Y.Z 来指定其他版本）"
        fi
    fi

    _glow_tag="${_glow_version}"

    # 3c. 归档复用检查：同版本已下载过则直接复用
    _glow_archived="${_glow_cache_dir}/${_glow_version}/${_glow_archive}"
    if [ -f "$_glow_archived" ]; then
        echo "复用已缓存的文件: ${_glow_archived}"
        _glow_use_archived=true
    else
        _glow_use_archived=false
        # 将版本号写入 .version，以便中断后能续传
        echo "$_glow_version" > "$_glow_version_file"
    fi
fi

# ---------------------------------------------------------------------------
# 4. 下载
# ---------------------------------------------------------------------------
if $_glow_resuming || ! ${_glow_use_archived:-false}; then
    # GoReleaser 资产命名：文件中的版本号不含 v 前缀
    _glow_version_no_v="${_glow_version#v}"
    _glow_download_url="https://github.com/${_glow_repo}/releases/download/${_glow_tag:-${_glow_version}}/glow_${_glow_version_no_v}_${_glow_target}.tar.gz"

    if $_glow_resuming; then
        echo "继续下载: ${_glow_download_url}"
    else
        echo "下载: ${_glow_download_url}"
    fi

    # wget -c: 断点续传；--show-progress: 强制显示进度条；-O: 写入指定文件
    wget -c --show-progress -O "$_glow_downloading" "$_glow_download_url"

    # 下载完成，归档到版本子目录
    _glow_archived="${_glow_cache_dir}/${_glow_version}/${_glow_archive}"
    mkdir -p "$(dirname "$_glow_archived")"
    mv "$_glow_downloading" "$_glow_archived"
    echo "已归档: ${_glow_archived}"
else
    _glow_archived="${_glow_cache_dir}/${_glow_version}/${_glow_archive}"
fi

# ---------------------------------------------------------------------------
# 5. 安装
# ---------------------------------------------------------------------------
_glow_tmpdir=$(mktemp -d)
trap 'rm -rf "$_glow_tmpdir"' RETURN

# 安全检查：拒绝含绝对路径或路径穿越（..）的压缩包（CWE-22）
echo "校验压缩包安全性..."
if tar -tzf "$_glow_archived" 2>/dev/null | grep -qE '^/|(^|/)\.\.(/|$)'; then
    echo "[错误] 压缩包包含不安全的路径，拒绝解压" >&2
    return 1
fi

# 解压 & 安装
echo "安装到 ${_glow_install_dir}/"
mkdir -p "$_glow_install_dir"
tar -xzf "$_glow_archived" -C "$_glow_tmpdir"
# 二进制文件名固定为 glow，-f 支持从旧版本覆盖升级
mv -f "${_glow_tmpdir}/glow" "${_glow_install_dir}/glow"
chmod +x "${_glow_install_dir}/glow"

# ---------------------------------------------------------------------------
# 6. 验证安装
# ---------------------------------------------------------------------------
echo ""
echo "安装完成！"
"${_glow_install_dir}/glow" --version 2>/dev/null || true

# PATH 提示
if ! command -v glow &>/dev/null; then
    echo "[提示] ~/bin 不在 PATH 中，请将以下行添加到 ~/.bashrc 或 ~/.zshrc："
    echo "       export PATH=\"\$HOME/bin:\$PATH\""
fi

# 清理临时变量
unset _glow_os _glow_arch _glow_target _glow_repo _glow_version _glow_tag
unset _glow_version_no_v _glow_install_dir _glow_archive _glow_downloading
unset _glow_download_url _glow_tmpdir _glow_location _glow_resuming
unset _glow_cache_dir _glow_version_file _glow_archived _glow_use_archived
unset _glow_fallback_version
