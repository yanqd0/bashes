#!/usr/bin/env bash
#
# hugo 安装脚本
# 通过 wget 下载 GitHub Release 预编译二进制，安装到 ~/bin/
# macOS 预编译为 .pkg 格式不便提取，直接通过 Homebrew 安装
# Linux 预编译不可用时打印源码编译指引
#
# 使用方式：
#   installer hugo                           # 自动检测最新版本并安装
#   HUGO_VERSION=v0.163.3 installer hugo      # 指定版本安装（跳过版本检测）
#
# 参考：https://github.com/gohugoio/hugo

# ---------------------------------------------------------------------------
# macOS：.pkg 格式不便提取，直接走 Homebrew
# ---------------------------------------------------------------------------
case "$(uname -s)" in
Darwin)
    echo "macOS 检测到，将通过 Homebrew 安装 hugo..."

    if command -v hugo &>/dev/null; then
        echo "hugo 已安装，当前版本："
        hugo version 2>/dev/null || true
        read -r -p "是否强制重新安装？[y/N] " REPLY
        case "${REPLY:-N}" in
        [yY] | [yY][eE][sS]) ;;
        *)
            echo "已取消。"
            return 0
            ;;
        esac
    fi

    if command -v brew &>/dev/null; then
        brew install hugo || {
            echo "[错误] brew 安装失败" >&2
            return 1
        }
    else
        echo "[错误] 未找到 Homebrew，请先安装：installer brew" >&2
        return 1
    fi

    echo ""
    if hugo version 2>/dev/null; then
        echo "hugo 安装完成！"
    else
        echo "[错误] 安装后仍无法执行 hugo" >&2
        return 1
    fi
    return 0
    ;;
esac

# ---------------------------------------------------------------------------
# Linux：GitHub Release 预编译二进制
# ---------------------------------------------------------------------------
source "$HOME/.bash/installer/_common.sh"

_i_detect_os "not-used" "linux" || return 1
_i_detect_arch "amd64" "arm64" || return 1
_i_setup "hugo" "gohugoio/hugo" "v0.163.3" "HUGO_VERSION"
[ -n "${HUGO_INSTALL_DIR:-}" ] && _i_set_install_dir "$HUGO_INSTALL_DIR"
[ -n "${HUGO_VERSION:-}" ] && _I_VERSION="$HUGO_VERSION"

_i_check_installed "hugo" "version" || return 0

_i_github_download "hugo-${_I_OS}-${_I_ARCH}.tar.gz" \
    "https://github.com/gohugoio/hugo/releases/download/<tag>/hugo_extended_<ver>_linux-<arch>.tar.gz" ||
    return 1

_i_extract 0 || return 1
_i_install_all || return 1

if _i_verify "${_I_INSTALL_DIR}/hugo" "version"; then
    _i_path_warning "hugo"
else
    echo "预编译二进制不可用（可能 glibc 版本不兼容）"
    echo ""
    echo "请从源码编译安装（需要 Go 1.19+）："
    echo "  git clone https://github.com/gohugoio/hugo"
    echo "  cd hugo"
    echo "  go build -o ~/bin/hugo"
    echo ""
    echo "或通过 Homebrew 安装：brew install hugo"
    return 1
fi

_i_cleanup
