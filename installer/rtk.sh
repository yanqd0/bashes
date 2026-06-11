#!/usr/bin/env bash
#
# rtk 安装脚本
# 通过 wget 下载 GitHub Release 中符合当前架构的预编译二进制，安装到 ~/bin/
#
# 使用方式：
#   installer rtk                       # 自动检测最新版本并安装
#   RTK_VERSION=v0.42.3 installer rtk    # 指定版本安装（跳过版本检测）
#
# 缓存策略：
#   ~/Downloads/installer/rtk/.version               — 记录下载中/已完成的版本号
#   ~/Downloads/installer/rtk/rtk-<target>.tar.gz    — 下载中临时文件（中断后用于续传）
#   ~/Downloads/installer/rtk/<version>/...          — 下载完成后的归档，同版本可复用
#
# 参考：https://github.com/rtk-ai/rtk

# ---------------------------------------------------------------------------
# 1. 检测操作系统与架构（无网络请求，始终先行）
# ---------------------------------------------------------------------------

# 操作系统：Linux → linux，macOS → darwin
_rtk_os=""
case "$(uname -s)" in
    Linux)  _rtk_os="linux" ;;
    Darwin) _rtk_os="darwin" ;;
    *)
        echo "[错误] 不支持的操作系统: $(uname -s)" >&2
        return 1
        ;;
esac

# CPU 架构
_rtk_arch=""
case "$(uname -m)" in
    x86_64|amd64) _rtk_arch="x86_64" ;;
    arm64|aarch64) _rtk_arch="aarch64" ;;
    *)
        echo "[错误] 不支持的 CPU 架构: $(uname -m)" >&2
        return 1
        ;;
esac

# 组合目标三元组（与 rtk 项目 release 命名一致）
case "${_rtk_os}-${_rtk_arch}" in
    linux-x86_64)  _rtk_target="x86_64-unknown-linux-musl" ;;
    linux-aarch64) _rtk_target="aarch64-unknown-linux-gnu" ;;
    darwin-*)      _rtk_target="${_rtk_arch}-apple-darwin" ;;
esac

# ---------------------------------------------------------------------------
# 2. 缓存路径 & 续传检测
# ---------------------------------------------------------------------------
_rtk_repo="rtk-ai/rtk"
_rtk_fallback_version="v0.42.3"
_rtk_install_dir="${RTK_INSTALL_DIR:-$HOME/bin}"
_rtk_cache_dir="$HOME/Downloads/installer/rtk"
mkdir -p "$_rtk_cache_dir"

_rtk_archive="rtk-${_rtk_target}.tar.gz"
_rtk_downloading="${_rtk_cache_dir}/${_rtk_archive}"   # 下载中临时文件
_rtk_version_file="${_rtk_cache_dir}/.version"          # 记录版本号

_rtk_resuming=false

# 检查是否有未完成的下载：临时文件存在 且 .version 可读
if [ -f "$_rtk_downloading" ] && [ -f "$_rtk_version_file" ]; then
    _rtk_resuming=true
    _rtk_version=$(cat "$_rtk_version_file")
    echo "发现未完成的下载（版本 ${_rtk_version}），将续传..."
    echo "  文件: ${_rtk_downloading}"
    echo "  已下载: $(du -h "$_rtk_downloading" | cut -f1)"
fi

# ---------------------------------------------------------------------------
# 3. 若非续传，则执行完整流程：已安装检查 → 版本确定 → 归档复用检查
# ---------------------------------------------------------------------------
if ! $_rtk_resuming; then
    # 3a. 已安装检查
    if command -v rtk &>/dev/null; then
        echo "rtk 已安装，当前版本："
        rtk --version
        read -r -p "是否强制重新安装？[y/N] " REPLY
        case "${REPLY:-N}" in
            [yY]|[yY][eE][sS]) ;;
            *) echo "已取消。"; return 0 ;;
        esac
    fi

    # 3b. 确定版本号
    #     优先 RTK_VERSION 环境变量（零请求）→ HEAD 重定向（1 次轻量请求）→ 回退默认版本
    if [ -n "$RTK_VERSION" ]; then
        _rtk_version="$RTK_VERSION"
        echo "使用指定版本: ${_rtk_version}"
    else
        echo "正在查询最新版本..."
        _rtk_location=$(wget -q --max-redirect=0 --server-response \
            "https://github.com/${_rtk_repo}/releases/latest" 2>&1 | \
            sed -n '/^  Location:/s/.*tag\/\([^[:space:]]*\).*/\1/p')

        if [ -n "$_rtk_location" ]; then
            _rtk_version="$_rtk_location"
            echo "最新版本: ${_rtk_version}"
        else
            _rtk_version="$_rtk_fallback_version"
            echo "无法连接 GitHub，回退到默认版本: ${_rtk_version}"
            echo "  （可设置 RTK_VERSION=vX.Y.Z 来指定其他版本）"
        fi
    fi

    _rtk_tag="${_rtk_version}"

    # 3c. 归档复用检查：同版本已下载过则直接复用，跳过下载
    _rtk_archived="${_rtk_cache_dir}/${_rtk_version}/${_rtk_archive}"
    if [ -f "$_rtk_archived" ]; then
        echo "复用已缓存的文件: ${_rtk_archived}"
        _rtk_use_archived=true
    else
        _rtk_use_archived=false
        # 将版本号写入 .version，以便中断后能续传
        echo "$_rtk_version" > "$_rtk_version_file"
    fi
fi

# ---------------------------------------------------------------------------
# 4. 下载
# ---------------------------------------------------------------------------
if $_rtk_resuming || ! ${_rtk_use_archived:-false}; then
    _rtk_download_url="https://github.com/${_rtk_repo}/releases/download/${_rtk_tag:-${_rtk_version}}/${_rtk_archive}"

    if $_rtk_resuming; then
        echo "继续下载: ${_rtk_download_url}"
    else
        echo "下载: ${_rtk_download_url}"
    fi

    # wget -c: 断点续传；--show-progress: 强制显示进度条；-O: 写入指定文件
    wget -c --show-progress -O "$_rtk_downloading" "$_rtk_download_url"

    # 下载完成，归档到版本子目录
    _rtk_archived="${_rtk_cache_dir}/${_rtk_version}/${_rtk_archive}"
    mkdir -p "$(dirname "$_rtk_archived")"
    mv "$_rtk_downloading" "$_rtk_archived"
    echo "已归档: ${_rtk_archived}"
else
    _rtk_archived="${_rtk_cache_dir}/${_rtk_version}/${_rtk_archive}"
fi

# ---------------------------------------------------------------------------
# 5. 安装
# ---------------------------------------------------------------------------
_rtk_tmpdir=$(mktemp -d)
trap 'rm -rf "$_rtk_tmpdir"' RETURN

# 安全检查：拒绝含绝对路径或路径穿越（..）的压缩包（CWE-22）
echo "校验压缩包安全性..."
if tar -tzf "$_rtk_archived" 2>/dev/null | grep -qE '^/|(^|/)\.\.(/|$)'; then
    echo "[错误] 压缩包包含不安全的路径，拒绝解压" >&2
    return 1
fi

# 解压 & 安装
echo "安装到 ${_rtk_install_dir}/"
mkdir -p "$_rtk_install_dir"
tar -xzf "$_rtk_archived" -C "$_rtk_tmpdir"
# 二进制文件名固定为 rtk，-f 支持从旧版本覆盖升级
mv -f "${_rtk_tmpdir}/rtk" "${_rtk_install_dir}/rtk"
chmod +x "${_rtk_install_dir}/rtk"

# ---------------------------------------------------------------------------
# 6. 验证安装
# ---------------------------------------------------------------------------
echo ""
echo "安装完成！"
"${_rtk_install_dir}/rtk" --version

# PATH 提示
if ! command -v rtk &>/dev/null; then
    echo "[提示] ~/bin 不在 PATH 中，请将以下行添加到 ~/.bashrc 或 ~/.zshrc："
    echo "       export PATH=\"\$HOME/bin:\$PATH\""
fi

# 清理临时变量
unset _rtk_os _rtk_arch _rtk_target _rtk_repo _rtk_version _rtk_tag
unset _rtk_install_dir _rtk_archive _rtk_downloading _rtk_download_url
unset _rtk_tmpdir _rtk_location _rtk_resuming _rtk_cache_dir _rtk_version_file
unset _rtk_archived _rtk_use_archived _rtk_fallback_version
