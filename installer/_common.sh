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

# 网络加速层（下载源测速/缓存/交互选择），定义见 installer/_net.sh
source "$HOME/.bash/installer/_net.sh"

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
# _I_SYMLINK_DIR  - 软链接目录（默认 ~/bin，加入 PATH）
# _I_BACKING_DIR  - 按工具名的版本化存储根（$_I_SYMLINK_DIR/installer/$_I_NAME）
# _I_INSTALL_DIR  - 版本化安装目录（$_I_BACKING_DIR/$_I_VERSION，版本未知前为 $_I_BACKING_DIR）
# _I_SYMLINK_MODE - 软链接模式："auto"(默认) 或 "none"(用户自定义目录时退化为旧行为)
# _I_CACHE_DIR    - 下载缓存目录
# _I_ARCHIVED     - 归档文件完整路径（_i_github_download 设置）
# _I_TMPDIR       - 解压临时目录（_i_extract 设置，_i_cleanup 负责清理）
# ============================================================================

# ---------------------------------------------------------------------------
# _i_check_archive <file>
# 校验压缩包完整性：优先 check_compressed → 按扩展名选择 unzip -t / tar -tf
# ---------------------------------------------------------------------------
_i_check_archive() {
    if declare -F check_compressed &>/dev/null; then
        check_compressed "$1"
        return $?
    fi
    case "$1" in
    *.zip)
        if command -v unzip &>/dev/null; then
            unzip -t "$1" >/dev/null 2>&1
        else
            echo "[错误] 需要 unzip 命令来校验 zip 归档" >&2
            return 1
        fi
        ;;
    *)
        # tar -tf 自动检测压缩格式（gzip/xz/bzip2），兼容 .tar.gz 与 .tar.xz
        tar -tf "$1" >/dev/null 2>&1
        ;;
    esac
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
# _i_rust_target
# 将当前系统映射为 Rust 目标三元组，结果存入 _I_TARGET
# 例如 x86_64-unknown-linux-gnu、aarch64-apple-darwin 等
# ---------------------------------------------------------------------------
_i_rust_target() {
    case "$(uname -s)-$(uname -m)" in
    Linux-x86_64) _I_TARGET="x86_64-unknown-linux-gnu" ;;
    Linux-aarch64) _I_TARGET="aarch64-unknown-linux-gnu" ;;
    Linux-arm*) _I_TARGET="arm-unknown-linux-gnueabihf" ;;
    Darwin-x86_64) _I_TARGET="x86_64-apple-darwin" ;;
    Darwin-arm64) _I_TARGET="aarch64-apple-darwin" ;;
    *)
        echo "[错误] 不支持的 Rust 目标平台: $(uname -s)-$(uname -m)" >&2
        return 1
        ;;
    esac
}

# ---------------------------------------------------------------------------
# _i_setup <tool_name> <repo> <fallback_version> [version_env_var]
# 初始化基本配置：名称、仓库、回退版本、安装/缓存目录
# ---------------------------------------------------------------------------
_i_setup() {
    # 重置本安装流的全局状态：上次失败若未走到 _i_cleanup，_I_VERSION 等可能残留
    # 在交互 shell 中并污染本次安装（表现为“使用指定版本 xxx”而不重新检测）
    unset _I_VERSION _I_TAG _I_ARCHIVED _I_MAIN_SUB _I_TMPDIR _I_INSTALL_COUNT

    _I_NAME="$1"
    _I_REPO="$2"
    _I_FALLBACK="$3"
    _I_VERSION_ENV="${4:-}"

    _I_SYMLINK_DIR="${HOME}/bin"
    _I_SYMLINK_MODE="auto"
    _I_BACKING_DIR="${_I_SYMLINK_DIR}/installer/${_I_NAME}"
    _I_INSTALL_DIR="${_I_BACKING_DIR}" # 版本确定后重算为 $_I_BACKING_DIR/$_I_VERSION
    _I_CACHE_DIR="$HOME/Downloads/installer/${_I_NAME}"
    mkdir -p "$_I_CACHE_DIR"
}

# ---------------------------------------------------------------------------
# _i_set_install_dir <dir>
# 覆盖默认安装目录（需在 _i_setup 之后调用）
# 用户自定义目录时禁用版本化存储，退化为扁平安装（旧行为）
# ---------------------------------------------------------------------------
_i_set_install_dir() {
    _I_SYMLINK_DIR="$1"
    _I_SYMLINK_MODE="none"
    _I_BACKING_DIR="$1"
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
        echo -n "是否强制重新安装？[y/N] " >&2
        read -r REPLY
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
        if [ "$_I_SYMLINK_MODE" != "none" ]; then
            _I_INSTALL_DIR="${_I_BACKING_DIR}/${_I_VERSION}"
        fi
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
    if [ "$_I_SYMLINK_MODE" != "none" ]; then
        _I_INSTALL_DIR="${_I_BACKING_DIR}/${_I_VERSION}"
    fi
}

# ---------------------------------------------------------------------------
# GitHub 下载源候选与 URL 构造（供 _net.sh 的 scheme "github" 使用）
# 候选含“直连 GitHub”（sentinel __direct__）与各代理前缀，官方与代理同场测速；
# 测速/下载 URL = 前缀 + 完整 github URL；__direct__ 则直接使用完整 github URL。
# ---------------------------------------------------------------------------
_gh_cand() {
    cat <<'EOF'
直连 GitHub|__direct__
gh-proxy.com|https://gh-proxy.com/
ghfast.top|https://ghfast.top/
gh.ddlc.top|https://gh.ddlc.top/
ghproxy.net|https://ghproxy.net/
EOF
}
_gh_probe() {
    if [ "$1" = "__direct__" ]; then
        echo "${_GH_URL}"
    else
        echo "${1}${_GH_URL}"
    fi
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

    # 续传检测：存在非空(已下载部分内容)的临时文件 且 .version 可读
    # 0 字节残留（如因 404/死链失败留下的空壳）不续传，避免被旧版本号卡死，应重新检测版本
    if [ -s "$downloading" ] && [ -f "$version_file" ]; then
        local _resume_version
        _resume_version=$(cat "$version_file")
        if [ -n "${_I_VERSION:-}" ] && [ "$_I_VERSION" != "$_resume_version" ]; then
            echo "版本请求 (${_I_VERSION}) 与未完成下载 (${_resume_version}) 不一致，丢弃旧文件"
            rm -f "$downloading" "$version_file"
        else
            resuming=true
            _I_VERSION="$_resume_version"
            _I_TAG="${_I_VERSION}"
            if [ "$_I_SYMLINK_MODE" != "none" ]; then
                _I_INSTALL_DIR="${_I_BACKING_DIR}/${_I_VERSION}"
            fi
            echo "发现未完成的下载（版本 ${_I_VERSION}），将续传..."
            echo "  文件: ${downloading}"
            echo "  已下载: $(du -h "$downloading" | cut -f1)"
        fi
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

    # GitHub 资产走加速层（仅对 github.com 下载 URL 生效）
    case "$download_url" in
    https://github.com/* | http://github.com/*)
        local -a _gh_src=()
        local _gh_mirror="${INSTALLER_MIRROR:-}"
        local _gh_b _gh_eff _gh_ok=false

        if [ "$_gh_mirror" = "none" ]; then
            _gh_src+=("__direct__")
        elif [ -n "$_gh_mirror" ]; then
            # 显式指定代理前缀（逗号分隔）：按给定顺序，末尾追加直连
            local _gh_ifs=$IFS _gh_m
            IFS=','
            for _gh_m in $_gh_mirror; do
                [ -n "$_gh_m" ] && _gh_src+=("$_gh_m")
            done
            IFS=$_gh_ifs
        else
            # 使用测速缓存/交互选择（scheme=github）；用户取消时 resolve 输出哨兵 __abort__
            _GH_URL="$download_url"
            while IFS= read -r _gh_b; do
                if [ "$_gh_b" = "__abort__" ]; then
                    unset _GH_URL
                    echo "[已取消] 中止安装 ${_I_NAME:-}。" >&2
                    return 1
                fi
                [ -n "$_gh_b" ] && _gh_src+=("$_gh_b")
            done < <(_i_net_resolve github _gh_cand _gh_probe)
            unset _GH_URL
            # 测速无任何可用源（如被限速/临时故障）：退而求其次，按默认顺序试代理再直连
            if [ "${#_gh_src[@]}" -eq 0 ]; then
                echo "[提示] 测速暂无可用源，将按默认顺序尝试代理（最后直连）…" >&2
                while IFS= read -r _gh_line; do
                    _gh_b="${_gh_line#*|}"
                    [ -n "$_gh_b" ] && [ "$_gh_b" != "__direct__" ] && _gh_src+=("$_gh_b")
                done < <(_gh_cand)
            fi
        fi

        # 兜底直连恒在末位（若已作为候选出现则不重复添加）
        local _gh_has=false _gh_x
        for _gh_x in "${_gh_src[@]}"; do
            [ "$_gh_x" = "__direct__" ] && _gh_has=true
        done
        $_gh_has || _gh_src+=("__direct__")

        for _gh_b in "${_gh_src[@]}"; do
            if [ "$_gh_b" = "__direct__" ]; then
                _gh_eff="$download_url"
            else
                _gh_eff="${_gh_b}${download_url}"
            fi
            if $resuming; then echo "继续下载: ${_gh_eff}"; else echo "下载: ${_gh_eff}"; fi
            if wget -c --show-progress -O "$downloading" "$_gh_eff"; then
                _gh_ok=true
                break
            fi
            echo "[提示] 下载源失败，尝试下一源…" >&2
            # 标记该源失效（从缓存剔除），避免近期反复试死链
            [ "$_gh_b" != "__direct__" ] && _i_net_drop github "$_gh_b"
        done
        $_gh_ok || {
            echo "[错误] 下载失败" >&2
            return 1
        }
        ;;
    *)
        # 非 github.com 源：沿用直连单次下载
        if $resuming; then echo "继续下载: ${download_url}"; else echo "下载: ${download_url}"; fi
        wget -c --show-progress -O "$downloading" "$download_url" || {
            echo "[错误] 下载失败" >&2
            return 1
        }
        ;;
    esac

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
# 支持 .tar.gz / .tar.xz / .zip 格式，由 _I_ARCHIVED 扩展名自动判断
# 结果存入 _I_TMPDIR（_i_cleanup 负责清理）
# ---------------------------------------------------------------------------
_i_extract() {
    local strip="${1:-0}"

    echo "校验压缩包安全性..."
    case "$_I_ARCHIVED" in
    *.zip)
        if ! command -v unzip &>/dev/null; then
            echo "[错误] 需要 unzip 命令" >&2
            return 1
        fi
        if [ "$strip" -gt 1 ]; then
            echo "[错误] zip 归档仅支持 --strip-components=1" >&2
            return 1
        fi
        # CWE-22：提取 unzip -l 输出的文件名列进行校验
        # 使用 sed 提取文件名（跳过表头和表尾），避免 awk $NF 因文件名含空格而截断
        if unzip -l "$_I_ARCHIVED" 2>/dev/null |
            sed -n '1,/^---/d; /^---/q; s/^.\{1,\}[0-9]\{2\}:[0-9]\{2\}[[:space:]]\{1,\}//p' |
            grep -qE '^/|(^|/)\.\.(/|$)'; then
            echo "[错误] 压缩包包含不安全的路径，拒绝解压" >&2
            return 1
        fi
        _I_TMPDIR=$(mktemp -d)
        echo "解压..."
        mkdir -p "$_I_INSTALL_DIR"
        unzip -o "$_I_ARCHIVED" -d "$_I_TMPDIR" >/dev/null || {
            echo "[错误] 解压失败" >&2
            rm -rf "$_I_TMPDIR"
            return 1
        }

        # zip 不支持原生 --strip-components，解压后模拟：自动检测单顶层目录
        if [ "$strip" -gt 0 ]; then
            local _items=("$_I_TMPDIR"/*)
            if [ ${#_items[@]} -eq 1 ] && [ -d "${_items[0]}" ]; then
                local _wrapper="${_items[0]}"
                mv "$_wrapper"/* "$_I_TMPDIR/" 2>/dev/null
                rmdir "$_wrapper" 2>/dev/null
            else
                echo "[错误] zip 归档不包含单一顶层目录，无法剥离" >&2
                rm -rf "$_I_TMPDIR"
                return 1
            fi
        fi
        ;;
    *)
        # CWE-22 安全检查：拒绝含绝对路径或路径穿越的压缩包
        if tar -tf "$_I_ARCHIVED" 2>/dev/null | grep -qE '^/|(^|/)\.\.(/|$)'; then
            echo "[错误] 压缩包包含不安全的路径，拒绝解压" >&2
            return 1
        fi
        _I_TMPDIR=$(mktemp -d)
        echo "解压..."
        mkdir -p "$_I_INSTALL_DIR"
        tar -xf "$_I_ARCHIVED" --strip-components="$strip" -C "$_I_TMPDIR" || {
            echo "[错误] 解压失败" >&2
            rm -rf "$_I_TMPDIR"
            return 1
        }
        ;;
    esac
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
    mkdir -p "$_I_INSTALL_DIR"
    cp -f "$src" "${_I_INSTALL_DIR}/"
    chmod +x "${_I_INSTALL_DIR}/${name}"
    echo "  ${name}"

    _i_symlink_install "$name"
}

# ---------------------------------------------------------------------------
# _i_install_all [exclude_patterns...]
# 从临时目录安装全部二进制文件到 _I_INSTALL_DIR
# 默认排除 LICENSE、.a、.so、.so.*、.dylib、README*、*.md
# 额外排除项通过参数传入（shell case 模式）
# ---------------------------------------------------------------------------
_i_install_all() {
    local count=0
    local _names=""

    echo "安装到 ${_I_INSTALL_DIR}/"
    mkdir -p "$_I_INSTALL_DIR"
    for f in "$_I_TMPDIR"/*; do
        [ -f "$f" ] || continue
        local name
        name=$(basename "$f")

        # 内置排除
        _i_is_excluded "$name" && continue

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
        _names="${_names} ${name}"
        count=$((count + 1))
    done

    # 为每个已安装的二进制创建软链接
    for name in $_names; do
        [ -n "$name" ] && _i_symlink_install "$name"
    done

    echo "共安装 ${count} 个二进制文件"
    _I_INSTALL_COUNT="$count"
}

# ---------------------------------------------------------------------------
# _i_install_tree <main_binary>
# 整树安装：将解压目录中的全部内容（含随行子目录与点文件）拷贝到 _I_INSTALL_DIR，
# 再为主二进制建立 ~/bin 软链。用于非单二进制、需随行资源目录的工具（如 zig 的 lib/）。
# 主二进制在解压树中的相对路径存入 _I_MAIN_SUB（可能嵌于 bin/ 等子目录，自动定位）。
# ---------------------------------------------------------------------------
_i_install_tree() {
    local main_bin="$1"

    # 在解压树中定位可执行主程序（可能嵌在 bin/ 等子目录）
    local rel
    rel=$( (cd "$_I_TMPDIR" && find . -type f -name "$main_bin" -perm -u+x -print 2>/dev/null | head -1) )
    rel="${rel#./}"
    if [ -z "$rel" ] || [ ! -f "$_I_TMPDIR/$rel" ]; then
        echo "[错误] 解压目录中未找到可执行主程序 ${main_bin}" >&2
        return 1
    fi
    _I_MAIN_SUB="$rel"

    echo "整树安装到 ${_I_INSTALL_DIR}/"
    mkdir -p "$_I_INSTALL_DIR"
    cp -a "$_I_TMPDIR"/. "$_I_INSTALL_DIR"/ || {
        echo "[错误] 拷贝整树失败" >&2
        return 1
    }
    chmod +x "${_I_INSTALL_DIR}/${_I_MAIN_SUB}"
    echo "  主程序: ${_I_INSTALL_DIR}/${_I_MAIN_SUB}"
    echo "  随行内容:"
    (cd "$_I_TMPDIR" && ls -1) | sed 's/^/    /'

    # 建立软链 ~/bin/<main_binary> -> <install_dir>/<sub>
    if [ "$_I_SYMLINK_MODE" != "none" ]; then
        mkdir -p "$_I_SYMLINK_DIR"
        rm -f "${_I_SYMLINK_DIR}/${main_bin}"
        ln -sf "${_I_INSTALL_DIR}/${_I_MAIN_SUB}" "${_I_SYMLINK_DIR}/${main_bin}"
        echo "  ${_I_SYMLINK_DIR}/${main_bin} -> ${_I_INSTALL_DIR}/${_I_MAIN_SUB}"
    fi
}

# ---------------------------------------------------------------------------
# _i_symlink_install <binary_name>
# 创建软链接：_I_SYMLINK_DIR/<name> → _I_INSTALL_DIR/<name>
# 若 _I_SYMLINK_MODE 为 "none"（用户自定义安装目录），则跳过
# ---------------------------------------------------------------------------
_i_symlink_install() {
    [ "${_I_SYMLINK_MODE}" = "none" ] && return 0

    local name="$1"
    local link_path="${_I_SYMLINK_DIR}/${name}"
    local target_path="${_I_INSTALL_DIR}/${name}"

    # 清理旧文件或链接（支持原地替换）
    if [ -e "$link_path" ] || [ -L "$link_path" ]; then
        rm -f "$link_path"
    fi

    mkdir -p "$_I_SYMLINK_DIR"
    ln -sf "$target_path" "$link_path"
    echo "  ${link_path} -> ${target_path}"
}

# ---------------------------------------------------------------------------
# _i_is_excluded <name>
# 判断文件名是否应被排除（LICENSE、README、库文件、文档等）
# 排除规则同时用于 _i_install_all 和 _i_verify 的清理逻辑
# ---------------------------------------------------------------------------
_i_is_excluded() {
    case "$1" in
    LICENSE | README* | *.md | *.a | *.dylib | *.so | *.so.*) return 0 ;;
    esac
    return 1
}

# ---------------------------------------------------------------------------
# _i_verify <binary_path> [test_args]
# 验证安装的二进制是否可用
# 成功返回 0，失败时自动清理 _I_TMPDIR 中对应的已安装文件及软链接
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

        # 清理：遍历 _I_TMPDIR 中的文件，从安装目录和链接目录删除对应文件
        for f in "$_I_TMPDIR"/*; do
            [ -f "$f" ] || continue
            local name
            name=$(basename "$f")
            _i_is_excluded "$name" && continue
            rm -f "${_I_INSTALL_DIR}/${name}"
            rm -f "${_I_SYMLINK_DIR}/${name}"
        done

        # 尝试清理空的版本目录
        rmdir "$_I_INSTALL_DIR" 2>/dev/null || true

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
# _i_migrate_detect_version <binary_path>
# 尝试检测已安装二进制文件的版本号
# 依次尝试 --version → version 子命令 → 正则提取 → "unknown"
# ---------------------------------------------------------------------------
_i_migrate_detect_version() {
    local _md_binary="$1"
    local _md_output=""
    local _md_ok=false

    # 超时包装：macOS 默认无 timeout 命令，检测后降级为直接执行
    local _md_timeout="timeout 5"
    if ! command -v timeout &>/dev/null; then
        _md_timeout=""
    fi

    # 策略 1: --version（超时 5 秒，避免 GUI 应用挂起）
    _md_output=$($_md_timeout "$_md_binary" --version 2>/dev/null) && _md_ok=true || true
    if ! $_md_ok; then
        # 策略 2: version 子命令（如 hugo version、k9s version）
        _md_output=$($_md_timeout "$_md_binary" version 2>/dev/null) && _md_ok=true || true
    fi

    if ! $_md_ok || [ -z "$_md_output" ]; then
        echo "unknown"
        return
    fi

    # 提取版本号：优先 semver (vX.Y.Z 或 X.Y.Z)
    local _md_ver
    _md_ver=$(echo "$_md_output" | grep -oE 'v?[0-9]+\.[0-9]+\.[0-9]+' | head -1)

    # 回退：X.Y 格式
    if [ -z "$_md_ver" ]; then
        _md_ver=$(echo "$_md_output" | grep -oE 'v?[0-9]+\.[0-9]+' | head -1)
    fi

    # 回退：纯数字版本号（如 b9769）
    if [ -z "$_md_ver" ]; then
        _md_ver=$(echo "$_md_output" | grep -oE '[0-9]{4,}' | head -1)
    fi

    echo "${_md_ver:-unknown}"
}

# ---------------------------------------------------------------------------
# _i_migrate_current_install [symlink_dir] [backing_root]
# 将 ~/bin/ 下的扁平二进制文件迁移到版本化存储结构
# 扫描指定目录中的可执行文件，检测版本后移到 backing store，创建软链接
# ---------------------------------------------------------------------------
_i_migrate_current_install() {
    local _mi_symlink_dir="${1:-$HOME/bin}"
    local _mi_backing_root="${2:-$HOME/bin/installer}"

    # 已知的 binary 名 → tool 名映射（binary 与工具名不同的情况）
    local _mi_difft_tool _mi_llama_tool _mi_warp_tool
    _mi_difft_tool="difftastic"
    _mi_llama_tool="llama.cpp"
    _mi_warp_tool="warp"

    echo "=== 迁移已安装的工具到版本化存储 ==="
    echo "扫描: ${_mi_symlink_dir}"
    echo "存储: ${_mi_backing_root}"
    echo ""

    local _mi_migrated=0
    local _mi_skipped=0

    for _mi_entry in "$_mi_symlink_dir"/*; do
        [ -f "$_mi_entry" ] || continue
        local _mi_name
        _mi_name=$(basename "$_mi_entry")

        # 跳过已知非二进制文件
        case "$_mi_name" in
        installer | .version | *.app | *.md | *.txt | lm-studio) continue ;;
        esac

        # 跳过软链接（需由各自的安装脚本管理）
        if [ -L "$_mi_entry" ]; then
            echo "  [跳过] ${_mi_name} (软链接)"
            _mi_skipped=$((_mi_skipped + 1))
            continue
        fi

        # 确定工具名（处理 binary ≠ tool 的特殊情况）
        local _mi_tool="$_mi_name"
        case "$_mi_name" in
        difft) _mi_tool="$_mi_difft_tool" ;;
        llama-cli | llama-server | llama-*)
            _mi_tool="$_mi_llama_tool"
            ;;
        warp-terminal) _mi_tool="$_mi_warp_tool" ;;
        esac

        # 检测版本
        echo "  [迁移] ${_mi_name} (工具: ${_mi_tool})"
        local _mi_vers
        _mi_vers=$(_i_migrate_detect_version "$_mi_entry")

        # 创建版本化目录并移动
        local _mi_ver_dir="${_mi_backing_root}/${_mi_tool}/${_mi_vers}"
        mkdir -p "$_mi_ver_dir"
        mv "$_mi_entry" "${_mi_ver_dir}/${_mi_name}"
        chmod +x "${_mi_ver_dir}/${_mi_name}"

        # 创建软链接替换原文件
        ln -sf "${_mi_ver_dir}/${_mi_name}" "$_mi_entry"

        echo "    ${_mi_entry} -> ${_mi_ver_dir}/${_mi_name}"
        _mi_migrated=$((_mi_migrated + 1))
    done

    echo ""
    echo "迁移完成: ${_mi_migrated} 个已迁移, ${_mi_skipped} 个跳过"
}

# ---------------------------------------------------------------------------
# _i_cleanup
# 清理所有 _I_ 前缀的全局变量
# ---------------------------------------------------------------------------
_i_cleanup() {
    [ -n "${_I_TMPDIR:-}" ] && rm -rf "$_I_TMPDIR"
    unset _I_NAME _I_REPO _I_FALLBACK _I_VERSION_ENV
    unset _I_VERSION _I_TAG _I_OS _I_ARCH _I_TARGET
    unset _I_SYMLINK_DIR _I_BACKING_DIR _I_INSTALL_DIR _I_SYMLINK_MODE
    unset _I_CACHE_DIR _I_ARCHIVED _I_TMPDIR
    unset _I_INSTALL_COUNT _I_MAIN_SUB
}
