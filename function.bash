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

# myfunc: Print all managed functions with descriptions {{{
function myfunc {
    declare -A desc
    desc=(
        [confal]="配置调度器，分发到 confal/ 目录"
        [installer]="安装调度器，分发到 installer/ 目录"
        [brew_switch]="一键切换 Homebrew 镜像源"
        [check_compressed]="校验压缩文件完整性"
        [check_source]="检查文件是否存在并 source"
        [cht]="cheat.sh 命令行速查表客户端"
        [cless]="彩色 less 分页器"
        [cmd2sh]="将历史命令保存为脚本"
        [cmore]="彩色 more 分页器"
        [ctree]="彩色树状目录显示"
        [docker-clean]="清理 Docker 容器和镜像"
        [gitignore]="调用 gitignore.io API 生成模板"
        [init_sys]="初始化 Linux 系统"
        [mcd]="创建目录并进入"
        [mkdatedir]="按日期创建目录"
        [myextract]="解压各种压缩文件"
        [myip]="查询本机公网 IP"
        [printcolor]="打印终端支持的色彩"
        [tagsmgr0]="Vim 标签管理"
        [yourip]="查询指定域名或IP的归属地"
    )

    local func_dir="$HOME/.bash/function"
    local name f

    echo "=== dispatchers ==="
    for name in confal installer; do
        printf "  %-20s %s\n" "$name" "${desc[$name]:-}"
    done

    echo "=== function/ modules ==="
    if [ -d "$func_dir" ]; then
        for f in "$func_dir"/*.sh; do
            [ -f "$f" ] || continue
            name=$(basename "$f" .sh)
            printf "  %-20s %s\n" "$name" "${desc[$name]:-}"
        done | sort
    fi

    echo "=== inline functions ==="
    for name in check_source; do
        printf "  %-20s %s\n" "$name" "${desc[$name]:-}"
    done
}
# }}}

# vim: set shiftwidth=4 softtabstop=-1 expandtab foldmethod=marker:
# vim: set textwidth=80 colorcolumn=80:
