#!/usr/bin/env bash

# confal: 配置调度器，分发到 confal/ 目录下的独立脚本 {{{
function confal {
    local confal_dir="$HOME/.bash/confal"

    declare -A desc
    desc=(
        [bash]="配置 bash 环境"
        [brew]="配置 Homebrew 国内镜像"
        [git]="配置 git 别名和行为"
        [rustup]="配置 Rust 工具链镜像"
        [zsh]="配置 zsh 环境"
    )

    if [ $# -eq 0 ]; then
        echo "可配置内容："
        local f name
        for f in "$confal_dir"/*.sh; do
            [ -f "$f" ] || continue
            name=$(basename "$f" .sh)
            printf "  %-16s %s\n" "$name" "${desc[$name]:-}"
        done | sort
        return 0
    fi

    local script="$confal_dir/$1.sh"
    if [ -f "$script" ]; then
        source "$script"
    else
        echo "confal: 未找到 '$1' 的配置脚本" >&2
        return 1
    fi
}
# }}}

# vim: set shiftwidth=4 softtabstop=-1 expandtab foldmethod=marker:
# vim: set textwidth=80 colorcolumn=80:
