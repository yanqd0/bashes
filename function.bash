#!/usr/bin/env bash


# check_source: Check if valid then source the file {{{
function check_source {
    if [ -f "$1" ]
    then
        source "$1"
    elif [ -f "$2" ]
    then
        source "$2"
    fi
}
# }}}

# Source all function modules from function/ directory {{{
_func_dir=$HOME/.bash/function
if [ -d "$_func_dir" ]; then
    for _f in "$_func_dir"/*.sh; do
        [ -f "$_f" ] || continue
        source "$_f"
    done
fi
unset _func_dir _f
# }}}

# mcd: mkdir and cd into it {{{
function mcd {
    mkdir -p "$1" && cd "$1" || exit
}
# }}}

# confal: Configurate all configurable commands. {{{
function confal {
    script=~/.bash/config_all.bash
    if [ -f $script ]
    then
        $script "$*"
    else
        echo $script not found!
    fi
}
# }}}

# myip: Get public IP info from various services {{{
function myip {
    if [[ "$1" == "-h" || "$1" == "--help" ]]
    then
        echo "Usage: myip [N]" 1>&2
        echo "  0  myip.ipip.net   (default, geo+ISP)" 1>&2
        echo "  1  ipinfo.io       (JSON, rich detail)" 1>&2
        echo "  2  icanhazip.com   (IP only, stable)" 1>&2
        echo "  3  ifconfig.me     (IP only, classic)" 1>&2
        echo "  4  ip.sb           (IP only, minimal)" 1>&2
        echo "  5  cip.cc          (geo+ISP, fast)" 1>&2
        return
    fi

    case "${1:-0}" in
        1) curl ipinfo.io ;;
        2) curl icanhazip.com ;;
        3) curl ifconfig.me ;;
        4) curl ip.sb ;;
        5) curl cip.cc ;;
        *) curl myip.ipip.net ;;
    esac
}
# }}}

# myfunc: Print all managed functions with descriptions {{{
function myfunc {
    declare -A desc
    desc=(
        [check_source]="检查文件是否存在并 source"
        [mcd]="创建目录并进入"
        [myextract]="解压各种压缩文件"
        [tagsmgr0]="Vim 标签管理"
        [printcolor]="打印终端支持的色彩"
        [cmd2sh]="将历史命令保存为脚本"
        [confal]="配置所有可配置命令"
        [gitignore]="调用 gitignore.io API 生成模板"
        [mkdatedir]="按日期创建目录"
        [init_sys]="初始化 Linux 系统"
        [docker-clean]="清理 Docker 容器和镜像"
        [ctree]="彩色树状目录显示"
        [cless]="彩色 less 分页器"
        [myip]="查询本机公网 IP"
        [cmore]="彩色 more 分页器"
    )

    local func_dir="$HOME/.bash/function"
    local name f

    echo "=== function/ modules ==="
    if [ -d "$func_dir" ]; then
        for f in "$func_dir"/*.sh; do
            [ -f "$f" ] || continue
            name=$(basename "$f" .sh)
            printf "  %-20s %s\n" "$name" "${desc[$name]:-}"
        done | sort
    fi

    echo "=== inline functions ==="
    for name in check_source mcd confal myip; do
        printf "  %-20s %s\n" "$name" "${desc[$name]:-}"
    done
}
# }}}

# vim: set shiftwidth=4 softtabstop=-1 expandtab foldmethod=marker:
# vim: set textwidth=80 colorcolumn=80:
