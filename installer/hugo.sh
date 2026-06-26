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
# 1. 检测操作系统与架构（无网络请求，始终先行）
# ---------------------------------------------------------------------------

# 操作系统
_hugo_os="$(uname -s)"

case "$_hugo_os" in
Darwin) ;;
Linux) ;;
*)
    echo "[错误] 不支持的操作系统: $_hugo_os" >&2
    return 1
    ;;
esac

# CPU 架构：GoReleaser 命名 linux-amd64 / linux-arm64
_hugo_arch=""
case "$(uname -m)" in
x86_64 | amd64) _hugo_arch="amd64" ;;
arm64 | aarch64) _hugo_arch="arm64" ;;
*)
    echo "[错误] 不支持的 CPU 架构: $(uname -m)" >&2
    return 1
    ;;
esac

# ---------------------------------------------------------------------------
# 2. macOS 直接走 Homebrew（.pkg 格式不便提取）
# ---------------------------------------------------------------------------
if [ "$_hugo_os" = "Darwin" ]; then
    echo "macOS 检测到，将通过 Homebrew 安装 hugo..."

    # 已安装检查
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

    # 清理
    unset _hugo_os _hugo_arch
    return 0
fi

# ---------------------------------------------------------------------------
# 3. Linux: 从 GitHub Release 下载预编译二进制
# ---------------------------------------------------------------------------

# _check_archive: 校验压缩包完整性
_check_archive() {
    if declare -F check_compressed &>/dev/null; then
        check_compressed "$1"
    else
        tar -tzf "$1" >/dev/null 2>&1
    fi
}

_hugo_repo="gohugoio/hugo"
_hugo_fallback_version="v0.163.3"
_hugo_install_dir="${HUGO_INSTALL_DIR:-$HOME/bin}"
_hugo_cache_dir="$HOME/Downloads/installer/hugo"
mkdir -p "$_hugo_cache_dir"

_hugo_target="linux-${_hugo_arch}"
_hugo_archive="hugo-${_hugo_target}.tar.gz"
_hugo_downloading="${_hugo_cache_dir}/${_hugo_archive}" # 下载中临时文件
_hugo_version_file="${_hugo_cache_dir}/.version"        # 记录版本号

_hugo_resuming=false

# 检查是否有未完成的下载：临时文件存在 且 .version 可读
if [ -f "$_hugo_downloading" ] && [ -f "$_hugo_version_file" ]; then
    _hugo_resuming=true
    _hugo_version=$(cat "$_hugo_version_file")
    echo "发现未完成的下载（版本 ${_hugo_version}），将续传..."
    echo "  文件: ${_hugo_downloading}"
    echo "  已下载: $(du -h "$_hugo_downloading" | cut -f1)"
fi

# ---------------------------------------------------------------------------
# 4. 若非续传，则执行完整流程：已安装检查 → 版本确定 → 归档复用检查
# ---------------------------------------------------------------------------
if ! $_hugo_resuming; then
    # 4a. 已安装检查
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

    # 4b. 确定版本号
    #     优先 HUGO_VERSION 环境变量（零请求）→ HEAD 重定向（1 次轻量请求）→ 回退默认版本
    if [ -n "$HUGO_VERSION" ]; then
        _hugo_version="$HUGO_VERSION"
        echo "使用指定版本: ${_hugo_version}"
    else
        echo "正在查询最新版本..."
        _hugo_location=$(wget -q --max-redirect=0 --server-response \
            "https://github.com/${_hugo_repo}/releases/latest" 2>&1 |
            sed -n '/^  Location:/s/.*tag\/\([^[:space:]]*\).*/\1/p')

        if [ -n "$_hugo_location" ]; then
            _hugo_version="$_hugo_location"
            echo "最新版本: ${_hugo_version}"
        else
            _hugo_version="$_hugo_fallback_version"
            echo "无法连接 GitHub，回退到默认版本: ${_hugo_version}"
            echo "  （可设置 HUGO_VERSION=vX.Y.Z 来指定其他版本）"
        fi
    fi

    _hugo_tag="${_hugo_version}"
    # Release 资产中的版本号不含 v 前缀（如 0.163.3）
    _hugo_version_no_v="${_hugo_version#v}"

    # 4c. 归档复用检查：同版本已下载过且校验通过则直接复用
    _hugo_archived="${_hugo_cache_dir}/${_hugo_version}/${_hugo_archive}"
    if [ -f "$_hugo_archived" ] && _check_archive "$_hugo_archived"; then
        echo "复用已缓存的文件: ${_hugo_archived}"
        _hugo_use_archived=true
    else
        [ -f "$_hugo_archived" ] && echo "缓存文件已损坏，将重新下载: ${_hugo_archived}"
        _hugo_use_archived=false
        # 将版本号写入 .version，以便中断后能续传
        echo "$_hugo_version" >"$_hugo_version_file"
    fi
fi

# ---------------------------------------------------------------------------
# 5. 下载
# ---------------------------------------------------------------------------
if $_hugo_resuming || ! ${_hugo_use_archived:-false}; then
    # Release 资产命名：hugo_extended_<ver-no-v>_linux-<arch>.tar.gz
    _hugo_download_url="https://github.com/${_hugo_repo}/releases/download/${_hugo_tag:-${_hugo_version}}/hugo_extended_${_hugo_version_no_v}_${_hugo_target}.tar.gz"

    if $_hugo_resuming; then
        echo "继续下载: ${_hugo_download_url}"
    else
        echo "下载: ${_hugo_download_url}"
    fi

    # wget -c: 断点续传；--show-progress: 强制显示进度条；-O: 写入指定文件
    wget -c --show-progress -O "$_hugo_downloading" "$_hugo_download_url" || {
        echo "[错误] 下载失败" >&2
        return 1
    }

    # 下载完成，归档到版本子目录
    _hugo_archived="${_hugo_cache_dir}/${_hugo_version}/${_hugo_archive}"
    mkdir -p "$(dirname "$_hugo_archived")"
    mv "$_hugo_downloading" "$_hugo_archived"
    echo "已归档: ${_hugo_archived}"
else
    _hugo_archived="${_hugo_cache_dir}/${_hugo_version}/${_hugo_archive}"
fi

# ---------------------------------------------------------------------------
# 6. 解压 & 安装
# ---------------------------------------------------------------------------
_hugo_tmpdir=$(mktemp -d)
trap 'rm -rf "$_hugo_tmpdir"' RETURN

# 安全检查：拒绝含绝对路径或路径穿越（..）的压缩包（CWE-22）
echo "校验压缩包安全性..."
if tar -tzf "$_hugo_archived" 2>/dev/null | grep -qE '^/|(^|/)\.\.(/|$)'; then
    echo "[错误] 压缩包包含不安全的路径，拒绝解压" >&2
    return 1
fi

echo "安装到 ${_hugo_install_dir}/"
mkdir -p "$_hugo_install_dir"
tar -xzf "$_hugo_archived" -C "$_hugo_tmpdir"

# 安装全部二进制（排除 LICENSE、README 等非二进制文件）
_hugo_count=0
for f in "$_hugo_tmpdir"/*; do
    [ -f "$f" ] || continue
    name=$(basename "$f")
    case "$name" in
    LICENSE | README* | *.md) continue ;;
    esac
    # hugo 是 Go 静态编译的单一二进制，直接安装
    cp -f "$f" "${_hugo_install_dir}/"
    chmod +x "${_hugo_install_dir}/${name}"
    echo "  ${name}"
    _hugo_count=$((_hugo_count + 1))
done

echo "共安装 ${_hugo_count} 个二进制文件"

# ---------------------------------------------------------------------------
# 7. 验证安装
# ---------------------------------------------------------------------------
echo ""
if "${_hugo_install_dir}/hugo" version 2>/dev/null; then
    echo "hugo 安装完成！"
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

# PATH 提示
if ! command -v hugo &>/dev/null; then
    echo "[提示] ~/bin 不在 PATH 中，请将以下行添加到 ~/.bashrc 或 ~/.zshrc："
    echo "       export PATH=\"\$HOME/bin:\$PATH\""
fi

# 清理临时变量
unset _hugo_os _hugo_arch _hugo_repo _hugo_version _hugo_tag
unset _hugo_version_no_v _hugo_target _hugo_install_dir _hugo_archive
unset _hugo_downloading _hugo_download_url _hugo_tmpdir _hugo_location
unset _hugo_resuming _hugo_cache_dir _hugo_version_file _hugo_archived
unset _hugo_use_archived _hugo_fallback_version _hugo_count
