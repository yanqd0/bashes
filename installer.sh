#!/usr/bin/env bash

# installer: Manage CLI tool installations {{{
function installer {
    local installer_dir="$HOME/.bash/installer"

    declare -A desc
    desc=(
        [bat]="cat 的现代化替代，支持语法高亮与 Git 标记"
        [brew]="macOS / Linux 包管理器，使用阿里云镜像安装"
        ["codebase-memory-mcp"]="MCP 服务器：为 AI 编码助手提供代码库长期记忆"
        [delta]="git diff 美化工具，支持语法高亮与并排对比"
        [deno]="JavaScript/TypeScript 运行时，Rust 预编译，单一二进制"
        [difftastic]="语义化 diff 工具，理解代码结构而非逐行对比"
        [eza]="ls 的现代化替代，支持图标与 Git 状态"
        [fd]="find 的现代化替代，语法简洁搜索极快"
        [glow]="终端 Markdown 预览工具"
        [helm]="Kubernetes 包管理器，通过 get.helm.sh CDN 安装"
        [hexyl]="十六进制查看器，语法着色，比 xxd/od 更直观"
        [hugo]="Go 语言静态网站生成器，构建速度极快"
        [hyperfine]="命令行基准测试工具，精确统计执行时间"
        [k9s]="Kubernetes 终端管理面板，实时监控集群资源"
        [kubectl]="Kubernetes 集群管理命令行工具"
        [llama.cpp]="高性能 LLM 推理引擎，支持 CPU/GPU 混合推理"
        [mint]="本地 issue 跟踪系统，Rust 编写、SQLite 存储"
        [mold]="极速链接器，GNU ld 的现代化替代"
        [nvm]="Node 版本管理器，官方脚本安装到 ~/.nvm"
        [rtk]="CLI 代理工具，减少 LLM token 消耗 60-90%"
        [rustup]="Rust 工具链管理器（使用阿里云镜像安装）"
        [stylua]="Lua 代码格式化工具，Rust 预编译"
        [uv]="Python 包与项目管理器（国内镜像安装）"
        [v2rayN]="V2Ray/Xray 代理客户端，跨平台 GUI"
        [warp]="现代终端仿真器，支持 AI 辅助"
        [yazi]="终端文件管理器，支持预览与多面板"
        [zoxide]="智能 cd 替代，根据访问频率自动跳转"
    )

    # -----------------------------------------------------------------------
    # 命令行解析
    # -----------------------------------------------------------------------
    local opt_help=false
    local opt_list=true
    local opt_migrate=false
    local tool_name=""

    while [ $# -gt 0 ]; do
        case "$1" in
        -h | --help)
            opt_help=true
            opt_list=false
            shift
            ;;
        -l | --list)
            opt_list=true
            shift
            ;;
        -m | --migrate)
            opt_migrate=true
            opt_list=false
            shift
            ;;
        --)
            shift
            [ $# -gt 0 ] && tool_name="$1"
            opt_list=false
            break
            ;;
        -*)
            opt_list=false
            echo "installer: 未知选项 '$1'，使用 -h 查看帮助" >&2
            return 1
            ;;
        *)
            tool_name="$1"
            opt_list=false
            shift
            break
            ;;
        esac
    done

    # 不接受选项后还拼一个工具名（除了 --list 和 --help 互相兼容）
    if [ -n "$tool_name" ] && $opt_migrate; then
        echo "installer: --migrate 不接受工具名参数" >&2
        return 1
    fi

    # -----------------------------------------------------------------------
    # --help / -h
    # -----------------------------------------------------------------------
    if $opt_help; then
        cat <<'EOF'
用法: installer [选项] [名称]

选项:
  -h, --help      打印此帮助信息
  -l, --list      列出可安装的工具
  -m, --migrate   将 ~/bin/ 下的扁平二进制迁移到版本化存储

无选项时，installer <名称> 安装指定工具。
不带任何参数则等同于 --list。
EOF
        return 0
    fi

    # -----------------------------------------------------------------------
    # --migrate / -m
    # -----------------------------------------------------------------------
    if $opt_migrate; then
        source "$HOME/.bash/installer/_common.sh"
        _i_migrate_current_install
        return $?
    fi

    # -----------------------------------------------------------------------
    # --list / -l 或无参数（默认行为）
    # -----------------------------------------------------------------------
    if $opt_list; then
        echo "可安装内容："
        local f name
        for f in "$installer_dir"/*.sh; do
            [ -f "$f" ] || continue
            name=$(basename "$f" .sh)
            case "$name" in _*) continue ;; esac
            if [ ${#name} -gt 16 ]; then
                printf "  %s\n                   %s\n" "$name" "${desc[$name]:-}"
            else
                printf "  %-16s %s\n" "$name" "${desc[$name]:-}"
            fi
        done
        return 0
    fi

    # -----------------------------------------------------------------------
    # 安装指定工具
    # -----------------------------------------------------------------------
    local script="$installer_dir/$tool_name.sh"
    if [ -f "$script" ]; then
        source "$script"
    else
        echo "installer: 未找到 '$tool_name' 的安装脚本" >&2
        return 1
    fi
}
# }}}
