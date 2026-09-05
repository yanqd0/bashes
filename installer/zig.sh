#!/usr/bin/env bash
#
# zig 安装脚本
# Zig 语言编译器，官方预编译 .tar.xz，整树安装到 ~/bin/
#
# 注意：
#   - 官方预编译仅在 ziglang.org 发布（含社区镜像），GitHub Release 只有 bootstrap+源码且滞后
#   - 架构用 zig 自有三元组 <arch>-<os>（如 x86_64-linux / aarch64-macos）
#   - 非单二进制：zig 依赖随行的 lib/ 目录树，须用 _i_install_tree 整树安装
#   - 下载源测速缓存于 ~/Downloads/installer/.zig.csv（7 天）；首次/过期时交互选择，
#     期间静默用首项（默认最快，手动选择会被置顶）
#
# 使用方式：
#   installer zig                        # 首次/过期交互选镜像并装最新稳定版
#   ZIG_VERSION=0.16.0 installer zig     # 指定版本安装
#   ZIG_MIRROR=<base> installer zig      # 指定镜像 base（含 /download 层），跳过测速缓存
#
# 参考：https://ziglang.org/download/
# 镜像：https://ziglang.org/download/community-mirrors.txt

source "$HOME/.bash/installer/_common.sh"

# ---------------------------------------------------------------------------
# scheme "zig" 的候选镜像（base 需等价 ziglang.org/download，附
# <ver>/zig-<target>-<ver>.tar.xz），供 _net.sh 测速/缓存/选择
# ---------------------------------------------------------------------------
_zig_cand() {
    cat <<'EOF'
官方 ziglang.org|https://ziglang.org/download
vortan.dev|https://zig.vortan.dev/zig
karearl.com|https://zig.karearl.com/zig
linus.dev|https://zig.linus.dev/zig
fs.liujiacai.net|https://fs.liujiacai.net/zigbuilds
pkg.hexops.org|https://pkg.hexops.org/zig
mirror.mschae23.de|https://zig.mirror.mschae23.de/zig
EOF
}

# ---------------------------------------------------------------------------
# _zig_net_url <base>   由 base 拼出当前版本/目标的真实归档 URL
# ---------------------------------------------------------------------------
_zig_net_url() {
    echo "${1}/${_I_VERSION}/zig-${_I_TARGET}-${_I_VERSION}.tar.xz"
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
_i_check_installed "zig" "version" ||
    { unset -f _zig_latest_version _zig_cand _zig_net_url; return 0; }

# ---------------------------------------------------------------------------
# 5/6. 选择下载源并下载（scheme=zig，缓存 .zig.csv）
#    ZIG_MIRROR 强制指定单个镜像；否则按测速/缓存优先级逐个镜像尝试，
#    用户在选择菜单取消时输出哨兵 __abort__，此处中止安装。
# ---------------------------------------------------------------------------
_zig_ok=false
if [ -n "${ZIG_MIRROR:-}" ]; then
    echo "使用镜像（ZIG_MIRROR）: ${ZIG_MIRROR}"
    _i_github_download "zig-${_I_TARGET}-${_I_VERSION}.tar.xz" \
        "$(_zig_net_url "$ZIG_MIRROR")" && _zig_ok=true
else
    while IFS= read -r _zb; do
        if [ "$_zb" = "__abort__" ]; then
            echo "[已取消] 中止安装 zig。" >&2
            unset _zig_ok _zb
            unset -f _zig_latest_version _zig_cand _zig_net_url
            return 0
        fi
        [ -n "$_zb" ] || continue
        echo "尝试下载源: ${_zb}"
        if _i_github_download "zig-${_I_TARGET}-${_I_VERSION}.tar.xz" \
            "$(_zig_net_url "$_zb")"; then
            _zig_ok=true
            break
        fi
        echo "[提示] 该镜像下载失败，尝试下一镜像…" >&2
    done < <(_i_net_resolve zig _zig_cand _zig_net_url)

    if ! $_zig_ok; then
        # 测速无可用源或全部镜像失败：最后回退官方下载一次
        echo "[提示] 镜像均不可用，回退官方下载…" >&2
        _i_github_download "zig-${_I_TARGET}-${_I_VERSION}.tar.xz" \
            "$(_zig_net_url "https://ziglang.org/download")" && _zig_ok=true
    fi
fi
$_zig_ok || { echo "[错误] zig 下载失败" >&2; return 1; }

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
unset _zig_ok _zb
unset -f _zig_latest_version _zig_cand _zig_net_url
_i_cleanup
