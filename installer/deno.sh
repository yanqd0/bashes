#!/usr/bin/env bash
#
# deno 安装脚本
# JavaScript/TypeScript 运行时，Rust 预编译，单一二进制
# 支持 GitHub 官方下载和国内镜像（dl.deno.js.cn），交互模式下提示选择
#
# 使用方式：
#   installer deno                       # 自动检测最新版本，交互选择下载源
#   DENO_VERSION=v2.9.2 installer deno    # 指定版本安装（跳过版本检测）
#   DENO_MIRROR=1 installer deno          # 强制使用国内镜像（非交互模式也生效）
#
# 参考：https://github.com/denoland/deno
# 镜像：https://x.deno.js.cn/

source "$HOME/.bash/installer/_common.sh"

# ---------------------------------------------------------------------------
# 1. 检测操作系统与架构（Deno 使用标准 Rust 目标三元组）
# ---------------------------------------------------------------------------
_i_rust_target || return 1

# ---------------------------------------------------------------------------
# 2. 配置
# ---------------------------------------------------------------------------
_i_setup "deno" "denoland/deno" "v2.9.2" "DENO_VERSION"
[ -n "${DENO_INSTALL_DIR:-}" ] && _i_set_install_dir "$DENO_INSTALL_DIR"
[ -n "${DENO_VERSION:-}" ] && _I_VERSION="$DENO_VERSION"

# ---------------------------------------------------------------------------
# 3. 已安装检查
# ---------------------------------------------------------------------------
_i_check_installed "deno" "--version" || return 0

# ---------------------------------------------------------------------------
# 4. 选择下载源
#    交互模式：提示用户选择 GitHub 官方或国内镜像
#    非交互模式（管道/定时任务）：默认 GitHub，可通过 DENO_MIRROR 环境变量切换
#
#    注意：此函数通过 $() 命令替换调用，stdout 用于返回 URL 值，
#    所有用户界面输出必须重定向到 stderr（>&2）
# ---------------------------------------------------------------------------
_deno_select_url() {
    local github_url="https://github.com/denoland/deno/releases/download/<tag>/deno-<target>.zip"
    local mirror_url="https://dl.deno.js.cn/release/<tag>/deno-<target>.zip"

    # 环境变量直接指定（最高优先级，非交互模式也生效）
    if [ -n "${DENO_MIRROR:-}" ]; then
        echo "使用国内镜像（DENO_MIRROR 环境变量）" >&2
        echo "$mirror_url"
        return
    fi

    # 非交互模式：默认使用 GitHub 官方地址
    if [ ! -t 0 ]; then
        echo "非交互模式，使用 GitHub 官方下载" >&2
        echo "$github_url"
        return
    fi

    # 交互模式：提示用户选择（提示信息输出到 stderr，URL 输出到 stdout）
    echo "" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "  请选择 deno 下载源" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "  1) GitHub 官方（默认）" >&2
    echo "  2) 国内镜像 dl.deno.js.cn" >&2
    echo "" >&2
    read -r -p "  请输入选项 [1/2]（默认 1）: " _deno_choice

    case "${_deno_choice:-1}" in
    2)
        echo "  使用国内镜像下载" >&2
        echo "$mirror_url"
        ;;
    *)
        echo "  使用 GitHub 官方下载" >&2
        echo "$github_url"
        ;;
    esac
}

_deno_download_url=$(_deno_select_url)

# ---------------------------------------------------------------------------
# 5. 下载（续传检测 → 版本检测 → 归档复用 → 下载）
# ---------------------------------------------------------------------------
_i_github_download "deno-${_I_TARGET}.zip" "$_deno_download_url" || {
    unset _deno_download_url
    return 1
}
unset _deno_download_url

# ---------------------------------------------------------------------------
# 6. 解压 & 安装
# ---------------------------------------------------------------------------
_i_extract 0 || return 1
_i_install_one "deno" || return 1

# ---------------------------------------------------------------------------
# 7. 验证安装
# ---------------------------------------------------------------------------
_i_verify "${_I_INSTALL_DIR}/deno" "--version" || {
    echo "[错误] deno 安装后无法执行，请检查" >&2
    return 1
}
_i_path_warning "deno"
_i_cleanup
