#!/usr/bin/env bash
#
# mold 安装脚本
# 极速链接器，GNU ld 的现代化替代
# Linux 预编译二进制，安装到 ~/bin/；macOS 走 Homebrew
#
# 使用方式：
#   installer mold                       # 自动检测最新版本并安装
#   MOLD_VERSION=v2.41.0 installer mold  # 指定版本安装
#
# 参考：https://github.com/rui314/mold
# 说明：mold 官方仅发布 Linux + Windows 预编译资产，未提供 macOS 预编译，
#       macOS 检测到后走 Homebrew fallback。
#       Linux 预编译二进制兼容 glibc 2.17+，老系统（如 Ubuntu 20）也能直接运行。

# macOS：mold 未提供 macOS 预编译二进制，走 brew
case "$(uname -s)" in
Darwin)
    echo "macOS 检测到，将通过 Homebrew 安装 mold..."
    if command -v mold &>/dev/null; then
        echo "mold 已安装，当前版本："
        mold --version 2>/dev/null || true
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
        brew install mold || {
            echo "[错误] brew 安装失败" >&2
            return 1
        }
    else
        echo "[错误] 未找到 Homebrew，请先安装：installer brew" >&2
        return 1
    fi
    echo ""
    mold --version 2>/dev/null && echo "mold 安装完成！" || {
        echo "[错误] 安装后无法执行 mold" >&2
        return 1
    }
    return 0
    ;;
esac

source "$HOME/.bash/installer/_common.sh"

# mold 资产文件名使用 x86_64/aarch64（与 _i_detect_arch 映射一致）
_i_detect_arch "x86_64" "aarch64" || return 1

_i_setup "mold" "rui314/mold" "v2.41.0" "MOLD_VERSION"
[ -n "${MOLD_INSTALL_DIR:-}" ] && _i_set_install_dir "$MOLD_INSTALL_DIR"
[ -n "${MOLD_VERSION:-}" ] && _I_VERSION="$MOLD_VERSION"

_i_check_installed "mold" "--version" || return 0

# 资产命名：mold-<ver>-<arch>-linux.tar.gz（文件名版本号不带 v 前缀，用 <ver>）
_i_github_download "mold-${_I_ARCH}-linux.tar.gz" \
    "https://github.com/rui314/mold/releases/download/<tag>/mold-<ver>-<arch>-linux.tar.gz" ||
    return 1

# 压缩包为嵌套结构（bin/libexec/lib/share），strip 一层后 bin/ 直接位于顶层
_i_extract 1 || return 1

# 自定义安装：只装 bin/ 下可执行文件（mold 自包含，ld.mold 为指向 mold 的软链接）
for _mold_bin in mold ld.mold; do
    if [ -f "$_I_TMPDIR/bin/$_mold_bin" ]; then
        echo "安装 ${_mold_bin} 到 ${_I_INSTALL_DIR}/"
        mkdir -p "$_I_INSTALL_DIR"
        cp -f "$_I_TMPDIR/bin/$_mold_bin" "${_I_INSTALL_DIR}/"
        chmod +x "${_I_INSTALL_DIR}/${_mold_bin}"
        _i_symlink_install "$_mold_bin"
    fi
done

_i_verify "${_I_INSTALL_DIR}/mold" "--version" || {
    echo "[错误] mold 安装后无法执行，请检查" >&2
    rm -f "${_I_INSTALL_DIR}/mold" "${_I_INSTALL_DIR}/ld.mold"
    rm -f "${_I_SYMLINK_DIR}/mold" "${_I_SYMLINK_DIR}/ld.mold"
    return 1
}
_i_path_warning "mold"
_i_cleanup
unset _mold_bin
