#!/usr/bin/env bash
#
# installer/_common.sh — GitHub Release 安装脚本的公共函数库
#
# 约定：
# - 所有公共函数以 _i_ 为前缀（installer internal）
# - 全局状态变量以 _I_ 为前缀（大写 I，Install 缩写）
# - 以 _ 开头的文件不会被 installer 列表展示
# - 同时兼容 bash 和 zsh
#
# 典型用法（以 glow 为例）：
#   source "$HOME/.bash/installer/_common.sh"
#   _i_detect_os "Darwin" "Linux"
#   _i_detect_arch "x86_64" "arm64"
#   _i_setup "glow" "charmbracelet/glow" "v2.1.2" "GLOW_VERSION"
#   _i_check_installed "glow" "--version"
#   _i_detect_version
#   _i_github_download "glow_<os>_<arch>.tar.gz" \
#       "https://github.com/charmbracelet/glow/releases/download/<tag>/glow_<ver>_<os>_<arch>.tar.gz"
#   _i_extract 1
#   _i_install_one "glow"
#   _i_verify "${_I_INSTALL_DIR}/glow" "--version"
#   _i_path_warning "glow"
#   _i_cleanup

# ============================================================================
# 全局状态变量
# ============================================================================
# _I_NAME         - 工具名称（_i_setup 设置）
# _I_REPO         - GitHub 仓库 owner/repo
# _I_FALLBACK     - 网络不可用时的回退版本
# _I_VERSION_ENV  - 版本环境变量名
# _I_VERSION      - 确定的版本号（含 v 前缀如适用）
# _I_TAG          - Release tag（通常与 _I_VERSION 相同）
# _I_OS           - 映射后的操作系统名（_i_detect_os 设置）
# _I_ARCH         - 映射后的 CPU 架构名（_i_detect_arch 设置）
# _I_INSTALL_DIR  - 安装目标目录（默认 ~/bin）
# _I_CACHE_DIR    - 下载缓存目录
# _I_ARCHIVED     - 归档文件完整路径（_i_github_download 设置）
# _I_TMPDIR       - 解压临时目录（_i_extract 设置，trap RETURN 自动清理）
# ============================================================================

# ---------------------------------------------------------------------------
# _i_check_archive <file>
# 校验压缩包完整性，优先使用 check_compressed，不可用时回退 tar -tzf
# ---------------------------------------------------------------------------
_i_check_archive() {
    if declare -F check_compressed &>/dev/null; then
        check_compressed "$1"
    else
        tar -tzf "$1" >/dev/null 2>&1
    fi
}

# ---------------------------------------------------------------------------
# _i_detect_os <darwin_label> <linux_label>
# 检测操作系统，映射到自定义标签，结果存入 _I_OS
# ---------------------------------------------------------------------------
_i_detect_os() {
    case "$(uname -s)" in
    Darwin) _I_OS="$1" ;;
    Linux) _I_OS="$2" ;;
    *)
        echo "[错误] 不支持的操作系统: $(uname -s)" >&2
        return 1
        ;;
    esac
}

# ---------------------------------------------------------------------------
# _i_detect_arch <amd64_label> <arm64_label>
# 检测 CPU 架构，映射到自定义标签，结果存入 _I_ARCH
# ---------------------------------------------------------------------------
_i_detect_arch() {
    case "$(uname -m)" in
    x86_64 | amd64) _I_ARCH="$1" ;;
    arm64 | aarch64) _I_ARCH="$2" ;;
    *)
        echo "[错误] 不支持的 CPU 架构: $(uname -m)" >&2
        return 1
        ;;
    esac
}

# ---------------------------------------------------------------------------
# _i_setup <tool_name> <repo> <fallback_version> [version_env_var]
# 初始化基本配置：名称、仓库、回退版本、安装/缓存目录
# ---------------------------------------------------------------------------
_i_setup() {
    _I_NAME="$1"
    _I_REPO="$2"
    _I_FALLBACK="$3"
    _I_VERSION_ENV="${4:-}"

    _I_INSTALL_DIR="${HOME}/bin"
    _I_CACHE_DIR="$HOME/Downloads/installer/${_I_NAME}"
    mkdir -p "$_I_CACHE_DIR"
}

# ---------------------------------------------------------------------------
# _i_set_install_dir <dir>
# 覆盖默认安装目录（需在 _i_setup 之前或之后调用）
# ---------------------------------------------------------------------------
_i_set_install_dir() {
    _I_INSTALL_DIR="$1"
}

# ---------------------------------------------------------------------------
# _i_check_installed <check_cmd> [version_args]
# 检查工具是否已安装，提示是否强制重新安装
# 用户取消时返回 1，调用方应 return 0
# ---------------------------------------------------------------------------
_i_check_installed() {
    local cmd="$1"
    local ver_args="${2:---version}"

    if command -v "$cmd" &>/dev/null; then
        echo "${_I_NAME} 已安装，当前版本："
        $cmd $ver_args 2>/dev/null || true
        read -r -p "是否强制重新安装？[y/N] " REPLY
        case "${REPLY:-N}" in
        [yY] | [yY][eE][sS]) ;;
        *)
            echo "已取消。"
            return 1
            ;;
        esac
    fi
    return 0
}

# ---------------------------------------------------------------------------
# _i_detect_version
# 确定版本号：环境变量（零请求）→ GitHub HEAD 重定向（1 次轻量请求）→ 回退
# 结果存入 _I_VERSION 和 _I_TAG
# 若调用前已设置 _I_VERSION（如通过环境变量），则跳过检测
# ---------------------------------------------------------------------------
_i_detect_version() {
    # 若调用方已通过环境变量等方式设置了 _I_VERSION，直接使用
    if [ -n "${_I_VERSION:-}" ]; then
        echo "使用指定版本: ${_I_VERSION}"
        _I_TAG="${_I_VERSION}"
        return 0
    fi

    echo "正在查询最新版本..."
    local location
    location=$(wget -q --max-redirect=0 --server-response \
        "https://github.com/${_I_REPO}/releases/latest" 2>&1 |
        sed -n '/^  Location:/s/.*tag\/\([^[:space:]]*\).*/\1/p')

    if [ -n "$location" ]; then
        _I_VERSION="$location"
        echo "最新版本: ${_I_VERSION}"
    else
        _I_VERSION="$_I_FALLBACK"
        echo "无法连接 GitHub，回退到默认版本: ${_I_VERSION}"
        if [ -n "$_I_VERSION_ENV" ]; then
            echo "  （可设置 ${_I_VERSION_ENV}=... 来指定其他版本）"
        fi
    fi

    _I_TAG="${_I_VERSION}"
}

# ---------------------------------------------------------------------------
# _i_github_download <archive_name> <download_url_template>
#
# 下载管线：续传检测 → 版本检测 → 归档复用 → 下载 → 归档
# 结果存入 _I_ARCHIVED
#
# <archive_name>        归档文件名（如 "glow_Darwin_x86_64.tar.gz"）
# <download_url_template> 下载 URL 模板，支持以下占位符：
#   <tag>    → Release tag（_I_TAG）
#   <ver>    → 版本号去除 v 前缀（如 2.1.2）
#   <os>     → 操作系统名（_I_OS）
#   <arch>   → CPU 架构名（_I_ARCH）
#   <target> → 目标三元组（_I_TARGET，需调用方预先设置）
# ---------------------------------------------------------------------------
_i_github_download() {
    local archive_name="$1"
    local url_template="$2"

    local downloading="${_I_CACHE_DIR}/${archive_name}"
    local version_file="${_I_CACHE_DIR}/.version"
    local resuming=false

    # 续传检测：临时文件存在 且 .version 可读
    if [ -f "$downloading" ] && [ -f "$version_file" ]; then
        resuming=true
        _I_VERSION=$(cat "$version_file")
        _I_TAG="${_I_VERSION}"
        echo "发现未完成的下载（版本 ${_I_VERSION}），将续传..."
        echo "  文件: ${downloading}"
        echo "  已下载: $(du -h "$downloading" | cut -f1)"
    fi

    # 若非续传：检测版本 → 归档复用检查
    if ! $resuming; then
        _i_detect_version

        local archived="${_I_CACHE_DIR}/${_I_VERSION}/${archive_name}"
        if [ -f "$archived" ] && _i_check_archive "$archived"; then
            echo "复用已缓存的文件: ${archived}"
            _I_ARCHIVED="$archived"
            return 0
        else
            [ -f "$archived" ] && echo "缓存文件已损坏，将重新下载: ${archived}"
            # 写入 .version，以便中断后能续传
            echo "$_I_VERSION" >"$version_file"
        fi
    fi

    # 若已通过复用获得 _I_ARCHIVED，跳过下载
    if [ -n "${_I_ARCHIVED:-}" ]; then
        return 0
    fi

    # 构建下载 URL（替换占位符）
    local ver_no_v="${_I_VERSION#v}"
    local download_url
    download_url=$(echo "$url_template" | sed \
        -e "s|<tag>|${_I_TAG}|g" \
        -e "s|<ver>|${ver_no_v}|g" \
        -e "s|<os>|${_I_OS}|g" \
        -e "s|<arch>|${_I_ARCH}|g" \
        -e "s|<target>|${_I_TARGET:-}|g")

    if $resuming; then
        echo "继续下载: ${download_url}"
    else
        echo "下载: ${download_url}"
    fi

    wget -c --show-progress -O "$downloading" "$download_url" || {
        echo "[错误] 下载失败" >&2
        return 1
    }

    # 归档到版本子目录
    local archived="${_I_CACHE_DIR}/${_I_VERSION}/${archive_name}"
    mkdir -p "$(dirname "$archived")"
    mv "$downloading" "$archived"
    echo "已归档: ${archived}"
    _I_ARCHIVED="$archived"
}

# ---------------------------------------------------------------------------
# _i_extract [strip_components]
# 解压压缩包到临时目录，自动做 CWE-22 安全检查
# 结果存入 _I_TMPDIR，trap RETURN 自动清理
# ---------------------------------------------------------------------------
_i_extract() {
    local strip="${1:-0}"

    # CWE-22 安全检查：拒绝含绝对路径或路径穿越的压缩包
    echo "校验压缩包安全性..."
    if tar -tzf "$_I_ARCHIVED" 2>/dev/null | grep -qE '^/|(^|/)\.\.(/|$)'; then
        echo "[错误] 压缩包包含不安全的路径，拒绝解压" >&2
        return 1
    fi

    _I_TMPDIR=$(mktemp -d)
    trap 'rm -rf "$_I_TMPDIR"' RETURN

    echo "解压..."
    mkdir -p "$_I_INSTALL_DIR"
    tar -xzf "$_I_ARCHIVED" --strip-components="$strip" -C "$_I_TMPDIR"
}

# ---------------------------------------------------------------------------
# _i_install_one <binary_name>
# 从临时目录安装单个二进制文件到 _I_INSTALL_DIR
# ---------------------------------------------------------------------------
_i_install_one() {
    local name="$1"
    local src="${_I_TMPDIR}/${name}"

    if [ ! -f "$src" ]; then
        echo "[错误] 压缩包中未找到 ${name} 文件" >&2
        return 1
    fi

    echo "安装 ${name} 到 ${_I_INSTALL_DIR}/"
    cp -f "$src" "${_I_INSTALL_DIR}/"
    chmod +x "${_I_INSTALL_DIR}/${name}"
    echo "  ${name}"
}

# ---------------------------------------------------------------------------
# _i_install_all [exclude_patterns...]
# 从临时目录安装全部二进制文件到 _I_INSTALL_DIR
# 默认排除 LICENSE、.a、.so、.so.*、.dylib、README*、*.md
# 额外排除项通过参数传入（shell case 模式）
# ---------------------------------------------------------------------------
_i_install_all() {
    local count=0

    echo "安装到 ${_I_INSTALL_DIR}/"
    for f in "$_I_TMPDIR"/*; do
        [ -f "$f" ] || continue
        local name
        name=$(basename "$f")

        # 内置排除
        case "$name" in
        LICENSE | README* | *.md | *.a | *.dylib | *.so | *.so.*) continue ;;
        esac

        # 额外排除
        local skip=false
        for pat in "$@"; do
            case "$name" in
            $pat)
                skip=true
                break
                ;;
            esac
        done
        $skip && continue

        cp -f "$f" "${_I_INSTALL_DIR}/"
        chmod +x "${_I_INSTALL_DIR}/${name}"
        echo "  ${name}"
        count=$((count + 1))
    done

    echo "共安装 ${count} 个二进制文件"
    _I_INSTALL_COUNT="$count"
}

# ---------------------------------------------------------------------------
# _i_verify <binary_path> [test_args]
# 验证安装的二进制是否可用
# 成功返回 0，失败时自动清理 _I_TMPDIR 中对应的已安装文件
# ---------------------------------------------------------------------------
_i_verify() {
    local bin_path="$1"
    local test_args="${2:---version}"

    echo ""
    if "$bin_path" $test_args 2>/dev/null; then
        echo "${_I_NAME} 安装完成！"
        return 0
    else
        echo "预编译二进制不可用，清理已安装文件..."

        # 清理：遍历 _I_TMPDIR 中的文件，从安装目录删除对应文件
        for f in "$_I_TMPDIR"/*; do
            [ -f "$f" ] || continue
            local name
            name=$(basename "$f")
            case "$name" in
            LICENSE | README* | *.md) continue ;;
            esac
            rm -f "${_I_INSTALL_DIR}/${name}"
        done

        return 1
    fi
}

# ---------------------------------------------------------------------------
# _i_path_warning <cmd>
# 如果指定命令不在 PATH 中，打印添加 ~/bin 到 PATH 的提示
# ---------------------------------------------------------------------------
_i_path_warning() {
    local cmd="$1"
    if ! command -v "$cmd" &>/dev/null; then
        echo "[提示] ~/bin 不在 PATH 中，请将以下行添加到 ~/.bashrc 或 ~/.zshrc："
        echo "       export PATH=\"\$HOME/bin:\$PATH\""
    fi
}

# ---------------------------------------------------------------------------
# _i_cleanup
# 清理所有 _I_ 前缀的全局变量
# ---------------------------------------------------------------------------
_i_cleanup() {
    unset _I_NAME _I_REPO _I_FALLBACK _I_VERSION_ENV
    unset _I_VERSION _I_TAG _I_OS _I_ARCH _I_TARGET
    unset _I_INSTALL_DIR _I_CACHE_DIR _I_ARCHIVED _I_TMPDIR
    unset _I_INSTALL_COUNT
}
