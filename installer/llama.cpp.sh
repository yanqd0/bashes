#!/usr/bin/env bash
#
# llama.cpp 安装脚本
# 通过 wget 下载 GitHub Release 预编译二进制，全部安装到 ~/bin/
# macOS 预编译不可用时 fallback 到 brew install llama.cpp
# Linux 预编译不可用时打印源码编译指引
#
# 使用方式：
#   installer llamacpp                           # 自动检测最新版本并安装
#   LLAMACPP_VERSION=b9769 installer llamacpp     # 指定版本安装（跳过版本检测）
#
# 参考：https://github.com/ggerganov/llama.cpp

# _check_archive: 校验压缩包完整性，优先使用 check_compressed，不可用时回退 tar -tzf
_check_archive() {
    if declare -F check_compressed &>/dev/null; then
        check_compressed "$1"
    else
        tar -tzf "$1" >/dev/null 2>&1
    fi
}

# ---------------------------------------------------------------------------
# 1. 检测操作系统与架构（无网络请求，始终先行）
# ---------------------------------------------------------------------------

# 操作系统：Release 命名 macos / ubuntu
_llamacpp_os=""
case "$(uname -s)" in
Darwin) _llamacpp_os="macos" ;;
Linux) _llamacpp_os="ubuntu" ;;
*)
    echo "[错误] 不支持的操作系统: $(uname -s)" >&2
    return 1
    ;;
esac

# CPU 架构：Release 命名 x64 / arm64
_llamacpp_arch=""
case "$(uname -m)" in
x86_64 | amd64) _llamacpp_arch="x64" ;;
arm64 | aarch64) _llamacpp_arch="arm64" ;;
*)
    echo "[错误] 不支持的 CPU 架构: $(uname -m)" >&2
    return 1
    ;;
esac

# ---------------------------------------------------------------------------
# 2. 缓存路径 & 续传检测
# ---------------------------------------------------------------------------
_llamacpp_repo="ggerganov/llama.cpp"
_llamacpp_fallback_version="b9769"
_llamacpp_install_dir="${LLAMACPP_INSTALL_DIR:-$HOME/bin}"
_llamacpp_cache_dir="$HOME/Downloads/installer/llamacpp"
mkdir -p "$_llamacpp_cache_dir"

_llamacpp_archive="llama-${_llamacpp_os}-${_llamacpp_arch}.tar.gz"
_llamacpp_downloading="${_llamacpp_cache_dir}/${_llamacpp_archive}" # 下载中临时文件
_llamacpp_version_file="${_llamacpp_cache_dir}/.version"            # 记录版本号

_llamacpp_resuming=false

# 检查是否有未完成的下载：临时文件存在 且 .version 可读
if [ -f "$_llamacpp_downloading" ] && [ -f "$_llamacpp_version_file" ]; then
    _llamacpp_resuming=true
    _llamacpp_version=$(cat "$_llamacpp_version_file")
    echo "发现未完成的下载（版本 ${_llamacpp_version}），将续传..."
    echo "  文件: ${_llamacpp_downloading}"
    echo "  已下载: $(du -h "$_llamacpp_downloading" | cut -f1)"
fi

# ---------------------------------------------------------------------------
# 3. 若非续传，则执行完整流程：已安装检查 → 版本确定 → 归档复用检查
# ---------------------------------------------------------------------------
if ! $_llamacpp_resuming; then
    # 3a. 已安装检查
    if command -v llama-cli &>/dev/null; then
        echo "llama.cpp 已安装，当前版本："
        llama-cli --version 2>/dev/null || true
        read -r -p "是否强制重新安装？[y/N] " REPLY
        case "${REPLY:-N}" in
        [yY] | [yY][eE][sS]) ;;
        *)
            echo "已取消。"
            return 0
            ;;
        esac
    fi

    # 3b. 确定版本号
    #     优先 LLAMACPP_VERSION 环境变量（零请求）→ HEAD 重定向（1 次轻量请求）→ 回退默认版本
    if [ -n "$LLAMACPP_VERSION" ]; then
        _llamacpp_version="$LLAMACPP_VERSION"
        echo "使用指定版本: ${_llamacpp_version}"
    else
        echo "正在查询最新版本..."
        _llamacpp_location=$(wget -q --max-redirect=0 --server-response \
            "https://github.com/${_llamacpp_repo}/releases/latest" 2>&1 |
            sed -n '/^  Location:/s/.*tag\/\([^[:space:]]*\).*/\1/p')

        if [ -n "$_llamacpp_location" ]; then
            _llamacpp_version="$_llamacpp_location"
            echo "最新版本: ${_llamacpp_version}"
        else
            _llamacpp_version="$_llamacpp_fallback_version"
            echo "无法连接 GitHub，回退到默认版本: ${_llamacpp_version}"
            echo "  （可设置 LLAMACPP_VERSION=bXXXX 来指定其他版本）"
        fi
    fi

    _llamacpp_tag="${_llamacpp_version}"

    # 3c. 归档复用检查：同版本已下载过且校验通过则直接复用，跳过下载
    _llamacpp_archived="${_llamacpp_cache_dir}/${_llamacpp_version}/${_llamacpp_archive}"
    if [ -f "$_llamacpp_archived" ] && _check_archive "$_llamacpp_archived"; then
        echo "复用已缓存的文件: ${_llamacpp_archived}"
        _llamacpp_use_archived=true
    else
        [ -f "$_llamacpp_archived" ] && echo "缓存文件已损坏，将重新下载: ${_llamacpp_archived}"
        _llamacpp_use_archived=false
        # 将版本号写入 .version，以便中断后能续传
        echo "$_llamacpp_version" >"$_llamacpp_version_file"
    fi
fi

# ---------------------------------------------------------------------------
# 4. 下载
# ---------------------------------------------------------------------------
if $_llamacpp_resuming || ! ${_llamacpp_use_archived:-false}; then
    # Release 资产命名：llama-{tag}-bin-{os}-{arch}.tar.gz
    _llamacpp_download_url="https://github.com/${_llamacpp_repo}/releases/download/${_llamacpp_tag:-${_llamacpp_version}}/llama-${_llamacpp_tag:-${_llamacpp_version}}-bin-${_llamacpp_os}-${_llamacpp_arch}.tar.gz"

    if $_llamacpp_resuming; then
        echo "继续下载: ${_llamacpp_download_url}"
    else
        echo "下载: ${_llamacpp_download_url}"
    fi

    # wget -c: 断点续传；--show-progress: 强制显示进度条；-O: 写入指定文件
    wget -c --show-progress -O "$_llamacpp_downloading" "$_llamacpp_download_url" || {
        echo "[错误] 下载失败" >&2
        return 1
    }

    # 下载完成，归档到版本子目录
    _llamacpp_archived="${_llamacpp_cache_dir}/${_llamacpp_version}/${_llamacpp_archive}"
    mkdir -p "$(dirname "$_llamacpp_archived")"
    mv "$_llamacpp_downloading" "$_llamacpp_archived"
    echo "已归档: ${_llamacpp_archived}"
else
    _llamacpp_archived="${_llamacpp_cache_dir}/${_llamacpp_version}/${_llamacpp_archive}"
fi

# ---------------------------------------------------------------------------
# 5. 解压 & 安装全部二进制到 ~/bin/
#    压缩包结构：llama-{tag}/ 顶层目录，--strip-components=1 去除
#    使用 cp 而非 mv：保留 tmpdir 中的文件列表用于验证失败时的清理
# ---------------------------------------------------------------------------
_llamacpp_tmpdir=$(mktemp -d)
trap 'rm -rf "$_llamacpp_tmpdir"' RETURN

# 安全检查：拒绝含绝对路径或路径穿越（..）的压缩包（CWE-22）
echo "校验压缩包安全性..."
if tar -tzf "$_llamacpp_archived" 2>/dev/null | grep -qE '^/|(^|/)\.\.(/|$)'; then
    echo "[错误] 压缩包包含不安全的路径，拒绝解压" >&2
    return 1
fi

echo "解压到 ${_llamacpp_install_dir}/"
mkdir -p "$_llamacpp_install_dir"
tar -xzf "$_llamacpp_archived" --strip-components=1 -C "$_llamacpp_tmpdir"

# 安装全部二进制文件（排除 LICENSE、静态库、动态库）
_llamacpp_count=0
for f in "$_llamacpp_tmpdir"/*; do
    [ -f "$f" ] || continue
    name=$(basename "$f")
    case "$name" in
    LICENSE | *.a | *.dylib) continue ;;
    *.so | *.so.*) continue ;;
    esac
    cp -f "$f" "${_llamacpp_install_dir}/"
    chmod +x "${_llamacpp_install_dir}/${name}"
    echo "  ${name}"
    _llamacpp_count=$((_llamacpp_count + 1))
done

echo "共安装 ${_llamacpp_count} 个二进制文件"

# ---------------------------------------------------------------------------
# 6. 验证安装 & fallback
# ---------------------------------------------------------------------------
echo ""
if "${_llamacpp_install_dir}/llama-cli" --version 2>/dev/null; then
    echo "llama.cpp 安装完成！"
else
    # 清理已安装的不可用文件
    echo "预编译二进制不可用，清理已安装文件..."
    for f in "$_llamacpp_tmpdir"/*; do
        [ -f "$f" ] || continue
        name=$(basename "$f")
        [ "$name" = "LICENSE" ] && continue
        rm -f "${_llamacpp_install_dir}/${name}"
    done

    if [ "$_llamacpp_os" = "macos" ]; then
        # -------------------------------------------------------------------
        # macOS fallback: Homebrew
        # -------------------------------------------------------------------
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
        # -------------------------------------------------------------------
        # Linux fallback: 源码编译指引
        # -------------------------------------------------------------------
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

# PATH 提示
if ! command -v llama-cli &>/dev/null; then
    echo "[提示] ~/bin 不在 PATH 中，请将以下行添加到 ~/.bashrc 或 ~/.zshrc："
    echo "       export PATH=\"\$HOME/bin:\$PATH\""
fi

# 清理临时变量
unset _llamacpp_os _llamacpp_arch _llamacpp_repo _llamacpp_version _llamacpp_tag
unset _llamacpp_install_dir _llamacpp_archive _llamacpp_downloading
unset _llamacpp_download_url _llamacpp_tmpdir _llamacpp_location _llamacpp_resuming
unset _llamacpp_cache_dir _llamacpp_version_file _llamacpp_archived _llamacpp_use_archived
unset _llamacpp_fallback_version _llamacpp_count
