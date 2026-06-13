#!/usr/bin/env bash
#
# warp 安装脚本
# Warp — 现代终端仿真器，支持 AI 辅助
# macOS 通过 Homebrew Cask 安装，Linux 通过 deb 包安装
#
# 使用方式：
#   installer warp
#   WARP_VERSION=0.2026.06.10.09.27.stable.01 installer warp   # 指定版本安装
#
# 缓存策略：
#   ~/Downloads/installer/warp/.version               — 记录下载中/已完成的版本
#   ~/Downloads/installer/warp/warp-<arch>.deb         — 下载中临时文件（中断后用于续传）
#   ~/Downloads/installer/warp/<version>/warp-<arch>.deb — 下载完成后的归档，同版本可复用
#
# 参考：https://www.warp.dev/

# ---------------------------------------------------------------------------
# 1. 操作系统检测
# ---------------------------------------------------------------------------
_warp_os="$(uname -s)"
case "$_warp_os" in
    Darwin|Linux) ;;
    *)
        echo "[错误] 不支持的操作系统: $_warp_os" >&2
        return 1
        ;;
esac

# ---------------------------------------------------------------------------
# macOS → Homebrew Cask（流程简单，单独处理）
# ---------------------------------------------------------------------------
if [ "$_warp_os" = "Darwin" ]; then
    if [ -d "/Applications/Warp.app" ]; then
        echo "Warp 已安装: /Applications/Warp.app"
        read -r -p "是否强制重新安装？[y/N] " REPLY
        case "${REPLY:-N}" in
            [yY]|[yY][eE][sS]) ;;
            *) echo "已取消。"; return 0 ;;
        esac
    fi
    if ! command -v brew &>/dev/null; then
        echo "[错误] 未找到 Homebrew，请先安装 Homebrew: https://brew.sh/" >&2
        return 1
    fi
    brew install --cask warp || {
        echo "[错误] 安装失败" >&2
        return 1
    }
    if [ -d "/Applications/Warp.app" ]; then
        echo "Warp 安装完成！可通过 Launchpad 或 /Applications/Warp.app 启动"
    else
        echo "[错误] Warp 安装后未找到，请检查" >&2
        return 1
    fi
    unset _warp_os
    return 0
fi

# ---------------------------------------------------------------------------
# 以下为 Linux deb 安装流程
# 检测 CPU 架构（Warpp 的 deb repo 使用 amd64/arm64）
# ---------------------------------------------------------------------------
_warp_arch="amd64"
case "$(uname -m)" in
    arm64|aarch64) _warp_arch="arm64" ;;
esac

# ---------------------------------------------------------------------------
# 2. 缓存路径 & 续传检测
# ---------------------------------------------------------------------------
_warp_cache_dir="$HOME/Downloads/installer/warp"
mkdir -p "$_warp_cache_dir"

_warp_archive="warp-${_warp_arch}.deb"
_warp_downloading="${_warp_cache_dir}/${_warp_archive}"
_warp_version_file="${_warp_cache_dir}/.version"

_warp_resuming=false
if [ -f "$_warp_downloading" ] && [ -f "$_warp_version_file" ]; then
    _warp_resuming=true
    _warp_version=$(cat "$_warp_version_file")
    echo "发现未完成的下载（版本 ${_warp_version}），将续传..."
    echo "  文件: ${_warp_downloading}"
    echo "  已下载: $(du -h "$_warp_downloading" | cut -f1)"
fi

# ---------------------------------------------------------------------------
# 3. 若非续传，则执行完整流程：已安装检查 → 版本确定 → 归档复用检查
# ---------------------------------------------------------------------------
if ! $_warp_resuming; then
    # 3a. 已安装检查
    if command -v warp-terminal &>/dev/null; then
        echo "Warp 已安装，当前版本："
        warp-terminal --version 2>/dev/null || true
        read -r -p "是否强制重新安装？[y/N] " REPLY
        case "${REPLY:-N}" in
            [yY]|[yY][eE][sS]) ;;
            *) echo "已取消。"; return 0 ;;
        esac
    fi

    # 3b. 确定版本号
    #     WARP_VERSION 环境变量（零请求）→ HEAD 重定向（1 次请求）→ 报错退出
    if [ -n "$WARP_VERSION" ]; then
        _warp_version="$WARP_VERSION"
        echo "使用指定版本: ${_warp_version}"
    else
        echo "正在查询最新版本..."
        _warp_location=$(wget -4 -q --max-redirect=0 --server-response \
            "https://app.warp.dev/download?package=deb&arch=${_warp_arch}" 2>&1 | \
            sed -n '/^  [Ll]ocation:/s|.*/stable/v\([^/]*\)/.*|\1|p')

        if [ -n "$_warp_location" ]; then
            _warp_version="$_warp_location"
            echo "最新版本: ${_warp_version}"
        else
            echo "[错误] 无法获取 Warp 最新版本，请检查网络连接" >&2
            echo "  可设置 WARP_VERSION=0.YYYY.MM.DD.xx.xx.stable.xx 来指定版本" >&2
            return 1
        fi
    fi

    # 3c. 归档复用检查：同版本已下载且校验通过则跳过下载
    _warp_archived="${_warp_cache_dir}/${_warp_version}/${_warp_archive}"
    if [ -f "$_warp_archived" ] && dpkg-deb --info "$_warp_archived" >/dev/null 2>&1; then
        echo "复用已缓存的文件: ${_warp_archived}"
        _warp_use_archived=true
    else
        [ -f "$_warp_archived" ] && echo "缓存文件已损坏，将重新下载"
        _warp_use_archived=false
        echo "$_warp_version" > "$_warp_version_file"
    fi
fi

# ---------------------------------------------------------------------------
# 4. 下载（续传或新下载）
# ---------------------------------------------------------------------------
if $_warp_resuming || ! ${_warp_use_archived:-false}; then
    _warp_download_url="https://app.warp.dev/download?package=deb&arch=${_warp_arch}"

    if $_warp_resuming; then
        echo "继续下载: ${_warp_download_url}"
    else
        echo "下载: ${_warp_download_url}"
    fi

    wget -4 -c --show-progress -O "$_warp_downloading" "$_warp_download_url" || {
        echo "[错误] 下载失败" >&2
        return 1
    }

    # 下载完成，归档到版本子目录
    _warp_archived="${_warp_cache_dir}/${_warp_version}/${_warp_archive}"
    mkdir -p "$(dirname "$_warp_archived")"
    mv "$_warp_downloading" "$_warp_archived"
    echo "已归档: ${_warp_archived}"
else
    _warp_archived="${_warp_cache_dir}/${_warp_version}/${_warp_archive}"
fi

# ---------------------------------------------------------------------------
# 5. 安装 deb 包
# ---------------------------------------------------------------------------
# 校验 deb 包完整性
echo "校验 deb 包完整性..."
dpkg-deb --info "$_warp_archived" >/dev/null 2>&1 || {
    echo "[错误] deb 包损坏或无效" >&2
    return 1
}

echo "安装 deb 包（将自动配置 apt 仓库，后续可通过 apt upgrade 更新）..."
if sudo dpkg -i "$_warp_archived"; then
    :  # dpkg 直接成功
elif sudo apt install -f -y; then
    echo "apt 自动修复依赖完成"
else
    echo "[错误] 安装失败" >&2
    return 1
fi

# ---------------------------------------------------------------------------
# 6. 验证安装
# ---------------------------------------------------------------------------
echo ""
if command -v warp-terminal &>/dev/null; then
    warp-terminal --version 2>/dev/null || true
    echo "Warp 安装完成！"
else
    echo "[错误] Warp 安装后无法执行，请检查" >&2
    return 1
fi

# 清理临时变量
unset _warp_os _warp_arch _warp_version _warp_cache_dir _warp_archive
unset _warp_downloading _warp_download_url _warp_version_file _warp_resuming
unset _warp_archived _warp_use_archived _warp_location
