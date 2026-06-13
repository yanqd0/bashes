#!/usr/bin/env bash

# installer: Manage CLI tool installations {{{
function installer {
    local installer_dir="$HOME/.bash/installer"

    declare -A desc
    desc=(
        [brew]="macOS / Linux 包管理器，使用阿里云镜像安装"
        [glow]="终端 Markdown 预览工具"
        [rtk]="CLI 代理工具，减少 LLM token 消耗 60-90%"
        [rustup]="Rust 工具链管理器（使用阿里云镜像安装）"
        [uv]="Python 包与项目管理器（国内镜像安装）"
        [warp]="现代终端仿真器，支持 AI 辅助"
    )

    if [ $# -eq 0 ]; then
        echo "可安装内容："
        local f name
        for f in "$installer_dir"/*.sh; do
            [ -f "$f" ] || continue
            name=$(basename "$f" .sh)
            printf "  %-16s %s\n" "$name" "${desc[$name]:-}"
        done
        return 0
    fi

    local script="$installer_dir/$1.sh"
    if [ -f "$script" ]; then
        source "$script"
    else
        echo "installer: 未找到 '$1' 的安装脚本" >&2
        return 1
    fi
}
# }}}
