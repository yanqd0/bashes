#!/usr/bin/env bash
#
# llama.cpp 安装脚本
# 通过 wget 下载 GitHub Release 预编译二进制，全部安装到 ~/bin/
# macOS 预编译不可用时 fallback 到 brew install llama.cpp
# Linux 预编译不可用时打印源码编译指引
#
# 使用方式：
#   installer llama.cpp                           # 自动检测最新版本并安装
#   LLAMACPP_VERSION=b9769 installer llama.cpp     # 指定版本安装（跳过版本检测）
#
# 参考：https://github.com/ggerganov/llama.cpp

source "$HOME/.bash/installer/_common.sh"

# ---------------------------------------------------------------------------
# 1. 检测操作系统与架构
# ---------------------------------------------------------------------------
_i_detect_os "macos" "ubuntu" || return 1
_i_detect_arch "x64" "arm64" || return 1

# ---------------------------------------------------------------------------
# 2. 配置
# ---------------------------------------------------------------------------
_i_setup "llama.cpp" "ggerganov/llama.cpp" "b9769" "LLAMACPP_VERSION"
[ -n "${LLAMACPP_INSTALL_DIR:-}" ] && _i_set_install_dir "$LLAMACPP_INSTALL_DIR"
[ -n "${LLAMACPP_VERSION:-}" ] && _I_VERSION="$LLAMACPP_VERSION"

# ---------------------------------------------------------------------------
# 3. 已安装检查
# ---------------------------------------------------------------------------
_i_check_installed "llama-cli" "--version" || return 0

# ---------------------------------------------------------------------------
# 4. 下载
# ---------------------------------------------------------------------------
_i_github_download "llama-${_I_OS}-${_I_ARCH}.tar.gz" \
    "https://github.com/ggerganov/llama.cpp/releases/download/<tag>/llama-<tag>-bin-<os>-<arch>.tar.gz" ||
    return 1

# ---------------------------------------------------------------------------
# 5. 解压 & 安装全部二进制
#    （压缩包顶层为 llama-<tag>/ 目录，--strip-components=1 去除）
# ---------------------------------------------------------------------------
_i_extract 1 || return 1
_i_install_all || return 1

# ---------------------------------------------------------------------------
# 6. 验证安装 & fallback
# ---------------------------------------------------------------------------
if _i_verify "${_I_INSTALL_DIR}/llama-cli" "--version"; then
    _i_path_warning "llama-cli"
else
    if [ "$_I_OS" = "macos" ]; then
        echo "尝试通过 Homebrew 安装..."
        if command -v brew &>/dev/null; then
            brew install llama.cpp || {
                echo "[错误] brew 安装失败" >&2
                return 1
            }
            echo ""
            if llama-cli --version 2>/dev/null; then
                echo "llama.cpp 通过 Homebrew 安装完成！"
            else
                echo "[错误] 安装后仍无法执行 llama-cli" >&2
                return 1
            fi
        else
            echo "[错误] 未找到 Homebrew，请先安装：installer brew" >&2
            return 1
        fi
        return 0
    else
        echo "预编译二进制不兼容当前系统（通常因为 glibc 版本过低）"
        echo ""
        echo "请从源码编译安装："
        echo "  git clone https://github.com/ggerganov/llama.cpp"
        echo "  cd llama.cpp"
        echo "  cmake -B build"
        echo "  cmake --build build --config Release -j"
        echo "  cp build/bin/* ~/bin/"
        echo ""
        echo "依赖：git cmake gcc g++"
        echo "Ubuntu/Debian: sudo apt install git cmake build-essential"
        return 1
    fi
fi

_i_cleanup
