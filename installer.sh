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
        [rclone]="命令行云存储同步工具，支持 40+ 存储后端"
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
    # 分类表：cat=工具名→分类 key；cat_name=分类 key→中文名；cat_order=展示顺序
    # 新增工具时需同步在 cat 中登记分类（含连字符的 key 用引号包裹）
    # -----------------------------------------------------------------------
    declare -A cat_name cat
    cat_name=(
        [terminal]="终端增强"
        [k8s]="Kubernetes"
        [runtime]="运行时与包管理"
        [network]="网络与代理"
        [code]="代码工具"
        [build]="性能与构建"
        [ai]="AI 与效率"
    )
    local -a cat_order=(terminal k8s runtime network code build ai)
    cat=(
        [bat]="terminal" [eza]="terminal" [fd]="terminal"
        [glow]="terminal" [hexyl]="terminal" [warp]="terminal"
        [yazi]="terminal" [zoxide]="terminal"
        [helm]="k8s" [k9s]="k8s" [kubectl]="k8s"
        [brew]="runtime" [deno]="runtime" [nvm]="runtime"
        [rustup]="runtime" [uv]="runtime"
        [rclone]="network" [v2rayN]="network"
        [delta]="code" [difftastic]="code" [mint]="code" [stylua]="code"
        [hugo]="build" [hyperfine]="build" [mold]="build"
        ["codebase-memory-mcp"]="ai" ["llama.cpp"]="ai" [rtk]="ai"
    )

    # -----------------------------------------------------------------------
    # 命令行解析
    # -----------------------------------------------------------------------
    local opt_help=false
    local opt_list=false
    local opt_pick=true
    local opt_migrate=false
    local tool_name=""

    while [ $# -gt 0 ]; do
        case "$1" in
        -h | --help)
            opt_help=true
            opt_list=false
            opt_pick=false
            shift
            ;;
        -l | --list)
            opt_list=true
            opt_pick=false
            shift
            ;;
        -f | --pick)
            opt_pick=true
            opt_list=false
            shift
            ;;
        -m | --migrate)
            opt_migrate=true
            opt_list=false
            opt_pick=false
            shift
            ;;
        --)
            shift
            [ $# -gt 0 ] && tool_name="$1"
            opt_list=false
            opt_pick=false
            break
            ;;
        -*)
            opt_list=false
            opt_pick=false
            echo "installer: 未知选项 '$1'，使用 -h 查看帮助" >&2
            return 1
            ;;
        *)
            tool_name="$1"
            opt_list=false
            opt_pick=false
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
  -l, --list      分组列出可安装的工具（已安装标 ✓，过长时分屏）
  -f, --pick      用 fzf 交互选择器挑选工具安装
  -m, --migrate   将 ~/bin/ 下的扁平二进制迁移到版本化存储

无选项时，installer <名称> 安装指定工具。
不带任何参数则进入 fzf 选择器；无 fzf 或非终端时回退为分组列表。
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

    # 无参默认 fzf，但无 fzf 或非交互 TTY：退化为分组列表
    if $opt_pick && { [ ! -t 1 ] || ! command -v fzf >/dev/null 2>&1; }; then
        if [ ! -t 1 ]; then
            echo "installer: 非终端环境，退化为分组列表显示" >&2
        else
            echo "installer: 未安装 fzf，退化为分组列表显示" >&2
        fi
        opt_pick=false
        opt_list=true
    fi

    # -----------------------------------------------------------------------
    # --list / -l：分组 + 已安装标记 + 分屏
    # -----------------------------------------------------------------------
    if $opt_list; then
        local -a lines=() names=()
        lines+=("可安装内容：")
        local name mark c
        while IFS= read -r name; do names+=("$name"); done < <(_installer_collect_tools)

        for c in "${cat_order[@]}"; do
            lines+=("")
            lines+=("  ${cat_name[$c]}")
            for name in "${names[@]}"; do
                [ "${cat[$name]:-}" = "$c" ] || continue
                mark="  "
                _installer_is_installed "$name" && mark="✓ "
                if [ ${#name} -gt 16 ]; then
                    lines+=("    ${name} ${mark}")
                    lines+=("                      ${desc[$name]:-}")
                else
                    lines+=("    $(printf '%-16s' "$name")${mark}${desc[$name]:-}")
                fi
            done
        done

        # 未登记分类的工具兜底到"未分类"组，避免在列表中静默消失（与 fzf 一致）
        local has_unclassified=false
        for name in "${names[@]}"; do
            [ -z "${cat[$name]:-}" ] && has_unclassified=true
        done
        if $has_unclassified; then
            lines+=("")
            lines+=("  未分类")
            for name in "${names[@]}"; do
                [ -n "${cat[$name]:-}" ] && continue
                mark="  "
                _installer_is_installed "$name" && mark="✓ "
                if [ ${#name} -gt 16 ]; then
                    lines+=("    ${name} ${mark}")
                    lines+=("                      ${desc[$name]:-}")
                else
                    lines+=("    $(printf '%-16s' "$name")${mark}${desc[$name]:-}")
                fi
            done
        fi

        _installer_pager "${lines[@]}"
        return 0
    fi

    # -----------------------------------------------------------------------
    # fzf 选择器（无参默认）：过滤选工具并安装
    # -----------------------------------------------------------------------
    if $opt_pick; then
        local -a choices=() names=()
        local name mark
        while IFS= read -r name; do names+=("$name"); done < <(_installer_collect_tools)
        for name in "${names[@]}"; do
            mark="  "
            _installer_is_installed "$name" && mark="✓ "
            # 工具名用 tab 分隔，选择结果用 cut -f1 提取，工具名含空格也不受影响
            choices+=("$(printf '%s\t%s%s  [%s]' "$name" "$mark" \
                "${desc[$name]:-}" "${cat_name[${cat[$name]:-code}]}")")
        done
        local sel chosen
        sel=$(printf '%s\n' "${choices[@]}" | fzf --reverse --height=60% \
            --delimiter=$'\t' \
            --header='输入过滤（含分类名），回车安装，ESC 取消' 2>/dev/null)
        [ -n "$sel" ] || return 0
        chosen=$(printf '%s' "$sel" | cut -d$'\t' -f1)
        installer "$chosen"
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

# ---------------------------------------------------------------------------
# _installer_collect_tools
# 输出所有安装脚本的工具名（跳过 _* 前缀），每行一个，供列表与 fzf 复用
# ---------------------------------------------------------------------------
function _installer_collect_tools {
    local f name
    for f in "$HOME/.bash/installer"/*.sh; do
        [ -f "$f" ] || continue
        name=$(basename "$f" .sh)
        case "$name" in _*) continue ;; esac
        printf '%s\n' "$name"
    done
}

# ---------------------------------------------------------------------------
# _installer_is_installed <tool>
# 判断工具是否已安装：默认 command -v，特判命令名≠工具名的情况
# ---------------------------------------------------------------------------
function _installer_is_installed {
    local tool="$1"
    case "$tool" in
    warp)
        # Linux 命令名 warp-terminal；macOS 为 GUI 应用
        command -v warp-terminal >/dev/null 2>&1 && return 0
        [ -d "/Applications/Warp.app" ] && return 0
        return 1
        ;;
    difftastic)
        # 二进制名 difft，与工具名不同
        command -v difft >/dev/null 2>&1
        ;;
    llama.cpp)
        # 多二进制，任一存在即视为已装
        command -v llama-cli >/dev/null 2>&1 || command -v llama-server >/dev/null 2>&1
        ;;
    nvm)
        # nvm 是 shell 函数，非交互 shell 中 command -v 不可靠，改用文件检查
        [ -s "${NVM_DIR:-$HOME/.nvm}/nvm.sh" ]
        ;;
    *)
        command -v "$tool" >/dev/null 2>&1
        ;;
    esac
}

# ---------------------------------------------------------------------------
# _installer_pager <lines...>
# 分屏显示：非 TTY 全量输出 → less -FXR → 无 less 时手写翻页兜底
# ---------------------------------------------------------------------------
function _installer_pager {
    local -a content=("$@")

    # 非 TTY：直接全量输出（保持管道行为，如 installer | grep）
    if [ ! -t 1 ]; then
        printf '%s\n' "${content[@]}"
        return 0
    fi

    # 首选 less：-F 不足一屏自动退出；-X 退出不刷屏；-R 原样透传
    if command -v less >/dev/null 2>&1; then
        printf '%s\n' "${content[@]}" | less -FXR
        return 0
    fi

    # 无 less 兜底：按终端高度手写翻页
    local height=24 t
    t=$(tput lines 2>/dev/null) && [ -n "$t" ] && [ "$t" -gt 0 ] && height="$t"

    if [ "${#content[@]}" -le "$height" ]; then
        printf '%s\n' "${content[@]}"
        return 0
    fi

    local i=0 key
    while [ "$i" -lt "${#content[@]}" ]; do
        local end=$((i + height - 1))
        if [ "$end" -ge "${#content[@]}" ]; then
            printf '%s\n' "${content[@]:i}"
            break
        fi
        printf '%s\n' "${content[@]:i:height}"
        printf -- "-- 更多 --（回车翻页 / q 退出）"
        local _rc=0
        if [ -n "$ZSH_VERSION" ]; then
            IFS= read -rk1 key || _rc=$?
        else
            IFS= read -rn1 key || _rc=$?
        fi
        # 无论 read 成功还是 EOF，都补换行，避免下一页首行或 shell 提示符粘连
        printf '\n'
        [ "$_rc" -ne 0 ] && return 0
        case "$key" in
        q | Q) return 0 ;;
        esac
        i=$((i + height))
    done
}
