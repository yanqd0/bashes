#!/usr/bin/env bash
#
# warp 安装脚本
# Warp — 现代终端仿真器，支持 AI 辅助
# macOS 通过 Homebrew Cask 安装，Linux 通过 deb 包安装（deb 会自动配置 apt 仓库）
#
# 使用方式：
#   installer warp
#
# 参考：https://www.warp.dev/

# ---------------------------------------------------------------------------
# 1. 检测操作系统
# ---------------------------------------------------------------------------
_warp_os="$(uname -s)"

case "$_warp_os" in
    Darwin) ;;
    Linux) ;;
    *)
        echo "[错误] 不支持的操作系统: $_warp_os" >&2
        return 1
        ;;
esac

# ---------------------------------------------------------------------------
# 2. 已安装检查
# ---------------------------------------------------------------------------
_warp_installed=false
if [ "$_warp_os" = "Darwin" ]; then
    if [ -d "/Applications/Warp.app" ]; then
        _warp_installed=true
        echo "Warp 已安装: /Applications/Warp.app"
    fi
elif [ "$_warp_os" = "Linux" ]; then
    if command -v warp-terminal &>/dev/null; then
        _warp_installed=true
        echo "Warp 已安装，当前版本："
        warp-terminal --version 2>/dev/null || true
    fi
fi

if $_warp_installed; then
    read -r -p "是否强制重新安装？[y/N] " REPLY
    case "${REPLY:-N}" in
        [yY]|[yY][eE][sS]) ;;
        *) echo "已取消。"; return 0 ;;
    esac
fi

# ---------------------------------------------------------------------------
# 3. 安装
# ---------------------------------------------------------------------------
if [ "$_warp_os" = "Darwin" ]; then
    echo "通过 Homebrew Cask 安装 Warp..."
    if ! command -v brew &>/dev/null; then
        echo "[错误] 未找到 Homebrew，请先安装 Homebrew: https://brew.sh/" >&2
        return 1
    fi
    brew install --cask warp || {
        echo "[错误] 安装失败" >&2
        return 1
    }
elif [ "$_warp_os" = "Linux" ]; then
    # 检测 CPU 架构，选择对应的 deb 包
    _warp_arch="amd64"
    case "$(uname -m)" in
        arm64|aarch64) _warp_arch="arm64" ;;
    esac

    _warp_deb_url="https://releases.warp.dev/linux/deb/stable/pool/main/w/warp-terminal/warp-terminal_latest_${_warp_arch}.deb"
    _warp_tmp_deb=$(mktemp /tmp/warp.XXXXXX.deb)
    trap 'rm -f "$_warp_tmp_deb"' RETURN

    echo "下载 Warp deb 包..."
    wget -c --show-progress -O "$_warp_tmp_deb" "$_warp_deb_url" || {
        echo "[错误] 下载失败" >&2
        return 1
    }

    echo "安装 deb 包（将自动配置 apt 仓库，后续可通过 apt upgrade 更新）..."
    sudo apt install -y "$_warp_tmp_deb" || {
        echo "[错误] 安装失败" >&2
        return 1
    }
fi

# ---------------------------------------------------------------------------
# 4. 验证安装
# ---------------------------------------------------------------------------
echo ""
if [ "$_warp_os" = "Darwin" ]; then
    if [ -d "/Applications/Warp.app" ]; then
        echo "Warp 安装完成！可通过 Launchpad 或 /Applications/Warp.app 启动"
    else
        echo "[错误] Warp 安装后未找到，请检查" >&2
        return 1
    fi
elif [ "$_warp_os" = "Linux" ]; then
    if command -v warp-terminal &>/dev/null; then
        warp-terminal --version 2>/dev/null || true
        echo "Warp 安装完成！"
    else
        echo "[错误] Warp 安装后无法执行，请检查" >&2
        return 1
    fi
fi

# 清理临时变量
unset _warp_os _warp_arch _warp_installed _warp_deb_url _warp_tmp_deb
