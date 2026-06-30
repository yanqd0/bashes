#!/usr/bin/env bash
#
# eza 安装脚本
# ls 的现代化替代，支持图标、Git 状态、树形展示
# Rust 预编译二进制，安装到 ~/bin/
# macOS 无预编译二进制，需通过 Homebrew 安装
#
# 使用方式：
#   installer eza                       # 自动检测最新版本并安装
#   EZA_VERSION=v0.23.4 installer eza    # 指定版本安装
#
# 参考：https://github.com/eza-community/eza

# macOS：eza 未提供 macOS 预编译二进制，走 brew
case "$(uname -s)" in
Darwin)
    echo "macOS 检测到，将通过 Homebrew 安装 eza..."
    if command -v eza &>/dev/null; then
        echo "eza 已安装，当前版本："
        eza --version 2>/dev/null || true
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
        brew install eza || {
            echo "[错误] brew 安装失败" >&2
            return 1
        }
    else
        echo "[错误] 未找到 Homebrew，请先安装：installer brew" >&2
        return 1
    fi
    echo ""
    eza --version 2>/dev/null && echo "eza 安装完成！" || {
        echo "[错误] 安装后无法执行 eza" >&2
        return 1
    }
    return 0
    ;;
esac

source "$HOME/.bash/installer/_common.sh"

_i_rust_target || return 1
_i_setup "eza" "eza-community/eza" "v0.23.4" "EZA_VERSION"
[ -n "${EZA_INSTALL_DIR:-}" ] && _i_set_install_dir "$EZA_INSTALL_DIR"
[ -n "${EZA_VERSION:-}" ] && _I_VERSION="$EZA_VERSION"

_i_check_installed "eza" "--version" || return 0

# eza 资产不含版本号：eza_<target>.tar.gz
_i_github_download "eza-${_I_TARGET}.tar.gz" \
    "https://github.com/eza-community/eza/releases/download/<tag>/eza_<target>.tar.gz" ||
    return 1

_i_extract 0 || return 1
_i_install_one "eza" || return 1

_i_verify "${_I_INSTALL_DIR}/eza" "--version" || {
    echo "[错误] eza 安装后无法执行，请检查" >&2
    return 1
}
_i_path_warning "eza"
_i_cleanup
