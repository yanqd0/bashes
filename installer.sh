#!/usr/bin/env bash

# installer: Manage CLI tool installations {{{
function installer {
    local installer_dir="$HOME/.bash/installer"

    declare -A desc
    desc=(
        [bat]="cat 的现代化替代，支持语法高亮与 Git 标记"
        [brew]="macOS / Linux 包管理器，使用阿里云镜像安装"
        [glow]="终端 Markdown 预览工具"
        [hugo]="Go 语言静态网站生成器，构建速度极快"
        [kubectl]="Kubernetes 集群管理命令行工具"
        [llama.cpp]="高性能 LLM 推理引擎，支持 CPU/GPU 混合推理"
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
            # 跳过 _ 开头的内部文件
            case "$name" in _*) continue ;; esac
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
