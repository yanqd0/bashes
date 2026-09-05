#!/usr/bin/env bash
#
# zig 安装脚本
# Zig 语言编译器，官方预编译 .tar.xz，整树安装到 ~/bin/
#
# 注意：
#   - 官方预编译仅在 ziglang.org 发布（含社区镜像），GitHub Release 只有 bootstrap+源码且滞后
#   - 架构用 zig 自有三元组 <arch>-<os>（如 x86_64-linux / aarch64-macos）
#   - 非单二进制：zig 依赖随行的 lib/ 目录树，须用 _i_install_tree 整树安装
#   - 官方社区镜像无大陆内网节点，故不做地区硬编码；交互模式下对各镜像实时测速排序后由用户挑选
#
# 使用方式：
#   installer zig                        # 交互选择下载源并自动探测最新稳定版
#   ZIG_VERSION=0.16.0 installer zig     # 指定版本安装
#   ZIG_MIRROR=<base> installer zig      # 指定镜像 base（含 /download 层），跳过交互
#
# 参考：https://ziglang.org/download/
# 镜像：https://ziglang.org/download/community-mirrors.txt

source "$HOME/.bash/installer/_common.sh"

# ---------------------------------------------------------------------------
# 候选镜像（base 需等价于 ziglang.org/download 一层，附 <ver>/zig-<target>-<ver>.tar.xz）
# 均来自官方 community-mirrors.txt，此处仅保留实测可正常返回归档路径的节点
# ---------------------------------------------------------------------------
_zig_mirror_candidates=(
    "官方 ziglang.org|https://ziglang.org/download"
    "vortan.dev|https://zig.vortan.dev/zig"
    "karearl.com|https://zig.karearl.com/zig"
    "linus.dev|https://zig.linus.dev/zig"
    "fs.liujiacai.net|https://fs.liujiacai.net/zigbuilds"
    "pkg.hexops.org|https://pkg.hexops.org/zig"
    "mirror.mschae23.de|https://zig.mirror.mschae23.de/zig"
)

# ---------------------------------------------------------------------------
# _zig_artifact_url <base>  拼出某个 base 对应的真实归档 URL
# ---------------------------------------------------------------------------
_zig_artifact_url() {
    echo "${1}/${_I_VERSION}/zig-${_I_TARGET}-${_I_VERSION}.tar.xz"
}

# ---------------------------------------------------------------------------
# _zig_speed_test <base>   对某个 base 做限流测速，输出字节/秒
# 只拉前 ~512KB 用于估算，max-time 2s 兜底避免交互卡顿
# ---------------------------------------------------------------------------
_zig_speed_test() {
    local b
    b=$(curl -s -r 0-524287 --max-time 2 -o /dev/null \
        -w '%{speed_download}' "$(_zig_artifact_url "$1")" 2>/dev/null)
    LC_ALL=C printf '%.0f' "${b:-0}"
}

# ---------------------------------------------------------------------------
# _zig_speed_rank   测速全部候选，按速度降序输出 "bytes|label|base"
# ---------------------------------------------------------------------------
_zig_speed_rank() {
    local entry label base kb
    for entry in "${_zig_mirror_candidates[@]}"; do
        label="${entry%%|*}"; base="${entry#*|}"
        kb=$(_zig_speed_test "$base")
        printf '%s|%s|%s\n' "$kb" "$label" "$base"
    done | sort -rn
}

# ---------------------------------------------------------------------------
# _zig_fmt_speed <bytes/s>   人类可读速度
# ---------------------------------------------------------------------------
_zig_fmt_speed() {
    awk -v b="${1:-0}" 'BEGIN{
        if (b >= 1048576) printf "%.1f MB/s", b/1048576
        else printf "%.0f KB/s", b/1024
    }'
}

# ---------------------------------------------------------------------------
# _zig_select_mirror   交互测速 → 排序 → 挑选，选中 base 输出到 stdout
# 所有 UI 输出重定向 stderr；选 0 或非交互取消返回 1
# ---------------------------------------------------------------------------
_zig_select_mirror() {
    local -a labels=() bases=() kbs=()
    local line kb label base i n fastest

    echo "" >&2
    echo "正在对各镜像测速（限流小样本，约数秒）..." >&2
    while IFS='|' read -r kb label base; do
        [ -n "$base" ] || continue
        kbs+=("$kb"); labels+=("$label"); bases+=("$base")
    done < <(_zig_speed_rank)

    n=${#bases[@]}
    if [ "$n" -eq 0 ]; then
        echo "[错误] 全部镜像测速失败" >&2
        return 1
    fi

    echo "" >&2
    echo "请选择 zig 下载源（已按实时测速从快到慢排序）：" >&2
    for ((i = 0; i < n; i++)); do
        printf '  %2d) %-26s %s%s\n' "$((i + 1))" "${labels[$i]}" \
            "$(_zig_fmt_speed "${kbs[$i]}")" "$([ "$i" -eq 0 ] && echo "  (最快)")" >&2
    done
    echo "  0) 退出" >&2
    echo -n "  请输入选项 [1-${n}]（回车选最快的 1）: " >&2

    read -r REPLY
    local choice="${REPLY:-1}"
    case "$choice" in
    0 | q | Q) return 1 ;;
    *)
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "$n" ]; then
            i=$((choice - 1))
            echo "已选择：${labels[$i]}" >&2
            echo "${bases[$i]}"
            return 0
        else
            echo "无效选项，已取消。" >&2
            return 1
        fi
        ;;
    esac
}

# ---------------------------------------------------------------------------
# 1. 检测操作系统与架构，映射为 zig 目标三元组 <arch>-<os>
# ---------------------------------------------------------------------------
_i_detect_os "macos" "linux" || return 1
_i_detect_arch "x86_64" "aarch64" || return 1
_I_TARGET="${_I_ARCH}-${_I_OS}" # 如 x86_64-linux / aarch64-macos

# ---------------------------------------------------------------------------
# 2. 配置
# ---------------------------------------------------------------------------
_i_setup "zig" "ziglang/zig" "0.16.0" "ZIG_VERSION"
[ -n "${ZIG_INSTALL_DIR:-}" ] && _i_set_install_dir "$ZIG_INSTALL_DIR"

# ---------------------------------------------------------------------------
# 3. 探测最新稳定版：解析 index.json 顶层 key（跳过 master/dev），取最大 semver
# ---------------------------------------------------------------------------
_zig_latest_version() {
    wget -qO- "https://ziglang.org/download/index.json" 2>/dev/null |
        sed -n 's/^[[:space:]]*"\([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\)".*/\1/p' |
        sort -V | tail -1
}
if [ -n "${ZIG_VERSION:-}" ]; then
    _I_VERSION="$ZIG_VERSION"
    echo "使用指定版本: ${_I_VERSION}"
elif [ -z "${_I_VERSION:-}" ]; then
    echo "正在查询最新稳定版..."
    _I_VERSION=$(_zig_latest_version)
    if [ -z "$_I_VERSION" ]; then
        _I_VERSION="$_I_FALLBACK"
        echo "无法连接 ziglang.org，回退到默认版本: ${_I_VERSION}"
        echo "  （可设置 ZIG_VERSION=... 指定其他版本）"
    else
        echo "最新稳定版: ${_I_VERSION}"
    fi
fi
_I_TAG="$_I_VERSION"

# ---------------------------------------------------------------------------
# 4. 已安装检查（zig 用 version 子命令，非 --version）
# ---------------------------------------------------------------------------
_i_check_installed "zig" "version" || { unset -f _zig_latest_version _zig_select_mirror; return 0; }

# ---------------------------------------------------------------------------
# 5. 选择下载源：
#    ZIG_MIRROR 环境变量 > 交互测速挑选 > （非交互）官方
# ---------------------------------------------------------------------------
_ZIG_BASE="https://ziglang.org/download"
if [ -n "${ZIG_MIRROR:-}" ]; then
    _ZIG_BASE="$ZIG_MIRROR"
    echo "使用镜像（ZIG_MIRROR）: ${_ZIG_BASE}"
elif [ -t 0 ]; then
    if ! _ZIG_BASE=$(_zig_select_mirror); then
        unset _ZIG_BASE _zig_mirror_candidates
        unset -f _zig_latest_version _zig_select_mirror _zig_speed_rank \
            _zig_speed_test _zig_artifact_url _zig_fmt_speed
        return 0
    fi
else
    echo "非交互模式，使用官方下载" >&2
fi

# ---------------------------------------------------------------------------
# 6. 下载：_I_VERSION 已定，复用公共下载管线（续传/缓存复用）
# ---------------------------------------------------------------------------
_i_github_download "zig-${_I_TARGET}-${_I_VERSION}.tar.xz" \
    "$(_zig_artifact_url "$_ZIG_BASE")" || return 1

# ---------------------------------------------------------------------------
# 7. 解压并整树安装（zig 需随行 lib/，单二进制拷贝会缺库）
# ---------------------------------------------------------------------------
_i_extract 1 || return 1
_i_install_tree "zig" || return 1

# ---------------------------------------------------------------------------
# 8. 验证安装（_I_MAIN_SUB 由 _i_install_tree 记录主程序相对路径）
# ---------------------------------------------------------------------------
if ! _i_verify "${_I_INSTALL_DIR}/${_I_MAIN_SUB}" "version"; then
    echo "[错误] zig 安装后无法执行，请检查" >&2
    rm -rf "$_I_INSTALL_DIR"
    rm -f "${_I_SYMLINK_DIR}/zig"
    [ -n "$_I_TMPDIR" ] && rm -rf "$_I_TMPDIR"
    return 1
fi
_i_path_warning "zig"

# 清理临时函数与变量
unset _ZIG_BASE _zig_mirror_candidates
unset -f _zig_latest_version _zig_select_mirror _zig_speed_rank \
    _zig_speed_test _zig_artifact_url _zig_fmt_speed
_i_cleanup
