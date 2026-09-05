#!/usr/bin/env bash
#
# installer/_net.sh — 下载源（镜像/代理）测速、缓存与交互选择库
#
# 背景：GitHub Release / 各官方站直连在国内偏慢，本库提供“测速 → 排序 →
# 缓存(默认 7 天) → 交互可选 → 之后静默用第一项”的通用机制。
#
# 缓存文件：$HOME/Downloads/installer/.<scheme>.csv
#   CSV 列：base,label,meanBps,devBps,lossPct,mtimeEpoch
#   注意：base/label 不得含逗号（当前候选均为 URL/域名，安全）。
#   行序 = 使用优先级（第一行即默认源）。手动选择某项后会被插入为第一行。
#   7 天内的后续运行直接读文件首行，不再重测速（TTL 见 _i_net_ttl_min）。
#
# 两个内置 scheme：github（代理前缀）/ zig（镜像站）。其余可由调用方扩展。
#   - .github.csv 是跨工具共享缓存：用“当前安装工具的资产 URL”测速，
#     结果对其它 GitHub 工具同样复用（启发式：它们走同一 github CDN）。
#   - 各 scheme 独立文件；测速/选择/缓存逻辑共用本库。
#
# 约定与注意：
#   - 测速必须串行：部分线路对并发境外连接限速，并行会让每条都接近 0。
#   - 测速依赖 curl（缺失时自动跳过测速，回退官方/直连）。
#   - 候选 base 以双下划线开头者视为“特殊源”（如 github 的 __direct__），
#     测速时对其附加 -L 跟随重定向（github 官方直连是 302）。
#   - 用户在选择菜单按 0/退出时，本库向 stdout 输出哨兵 __abort__ 并返回 1，
#     调用方应据此中止安装（不要当成“无可用源”继续尝试默认顺序）。
#
# 公共 API（本库仅依赖调用方提供的两个“策略函数名”，shell 无关）：
#   <cand_fn>  — 打印候选，每行 "label|base"
#   <url_fn>   — 给定 base 输出用于测速/下载的完整 URL
#
# 使用：
#   source _net.sh
#   _i_net_resolve <scheme> <cand_fn> <url_fn>   # 输出按优先级排序的 base（每行一个）
#   _i_net_reset  <scheme>                       # 删除缓存，强制重测（调试用）

# 缓存目录（与既有下载缓存一致）
_i_net_cache_dir() { echo "${HOME}/Downloads/installer"; }

# 缓存 TTL：7 天（分钟数，find -mmin 用）
_i_net_ttl_min() { echo 10080; }

# 缓存文件路径
_i_net_csv() { echo "$(_i_net_cache_dir)/.$1.csv"; }

# 是否有效：存在、非空、且修改时间在 TTL 内
_i_net_fresh() { [ -n "$(find "$1" -mmin "-$(_i_net_ttl_min)" -print -quit 2>/dev/null)" ]; }

# 人类可读速度
_i_net_fmt() {
    awk -v b="${1:-0}" 'BEGIN{
        if (b >= 1073741824) printf "%.2f GB/s", b/1073741824
        else if (b >= 1048576) printf "%.1f MB/s", b/1048576
        else if (b >= 1024) printf "%.0f KB/s", b/1024
        else printf "%.0f B/s", b
    }'
}

# 单候选测速：2 次采样（第 2 次失败则丢包 50%），返回 "meanBps,devBps,lossPct"
# 用法：_i_net_measure_one <base> <url_fn>
# 约定：特殊源（base 以 __ 开头，如 github 的 __direct__）测速时加 -L 跟随重定向；
#       github 官方直连是 302，不跟随会永远测到 0。代理/镜像源本身已返回内容，不需要。
_i_net_measure_one() {
    local base="$1" urlfn="$2"
    local curl_opt="" s1 s2 samples="" m d loss=0
    case "$base" in
    __*) curl_opt="-L" ;;
    esac
    url=$("$urlfn" "$base")

    s1=$(curl -s $curl_opt -r 0-2097151 --max-time 3 -o /dev/null \
        -w '%{speed_download}' "$url" 2>/dev/null)
    if [ -z "$s1" ] || ! awk -v x="$s1" 'BEGIN{exit !(x>0)}'; then
        printf '0,0,100'
        return
    fi
    samples="${s1}"$'\n'

    s2=$(curl -s $curl_opt -r 0-2097151 --max-time 3 -o /dev/null \
        -w '%{speed_download}' "$url" 2>/dev/null)
    if [ -n "$s2" ] && awk -v x="$s2" 'BEGIN{exit !(x>0)}'; then
        samples="${samples}${s2}"$'\n'
    else
        loss=50
    fi

    read -r m d <<< "$(printf '%s' "$samples" | awk '{a+=$1;b+=$1*$1}
        END{m=a/NR; printf "%d %d", m, sqrt(b/NR-m*m)}')"
    printf '%d,%d,%d' "${m:-0}" "${d:-0}" "$loss"
}

# 测速全部候选并写入 csv（按 meanBps 降序）；完全失败(mean=0)的行被剔除。
# 串行执行：避免并发触发线路限速。用法：_i_net_measure_write <csv> <cand_fn> <url_fn>
_i_net_measure_write() {
    local csv="$1" cand="$2" urlfn="$3"
    local tmp="${csv}.m.$$" line label base stat m

    : >"$tmp"
    while IFS= read -r line; do
        [ -n "$line" ] || continue
        label="${line%%|*}"
        base="${line#*|}"
        stat=$(_i_net_measure_one "$base" "$urlfn")
        m="${stat%%,*}"
        # 丢包=100（全部失败）视为不可用，不入缓存
        if [ "$m" -gt 0 ] 2>/dev/null; then
            printf '%s\n' "$base,$label,$stat" >>"$tmp"
        fi
    done < <("$cand")

    if [ -s "$tmp" ]; then
        sort -t, -k3,3nr "$tmp" | awk -F, -v now="$(date +%s)" \
            '{printf "%s,%s,%s,%s,%s,%s\n",$1,$2,$3,$4,$5,now}' >"$csv"
    fi
    rm -f "$tmp"
    [ -s "$csv" ]
}

# 交互选源：列出 csv（已按速度降序），把用户选择项移到第一行。
_i_net_pick() {
    local csv="$1" max sel
    max=$(wc -l <"$csv" | tr -d ' ')
    [ "$max" -ge 1 ] || return 1

    echo "" >&2
    echo "请选择下载源（已按测速从快到慢排序，回车用默认）：" >&2
    awk -F, '{
        m=$3; loss=$5;
        spd=(m>=1048576)?sprintf("%.1f MB/s",m/1048576):sprintf("%.0f KB/s",m/1024);
        printf "  %2d) %-26s %-10s%s\n", NR, $2, spd, (loss>0?sprintf(" 丢包%d%%",loss):"");
    }' "$csv" >&2
    echo "  0) 退出" >&2
    printf '  请输入选项 [1-%d]（回车=1）: ' "$max" >&2
    read -r sel
    sel="${sel:-1}"
    case "$sel" in
    0 | q | Q) return 1 ;;
    esac
    if [ "$sel" -ge 1 ] 2>/dev/null && [ "$sel" -le "$max" ] 2>/dev/null; then
        if [ "$sel" -ne 1 ]; then
            local chosen
            chosen=$(sed -n "${sel}p" "$csv")
            { echo "$chosen"; sed "${sel}d" "$csv"; } >"${csv}.$$" &&
                mv "${csv}.$$" "$csv"
        fi
        return 0
    fi
    echo "无效选项，使用默认。" >&2
    return 0
}

# 主入口：解析 scheme 的下载源优先级（每行一个 base），返回 0。
#   - 缓存有效 → 按缓存行序输出（首行=默认）
#   - 缓存缺失/过期 → 重新测速写缓存；若为交互 TTY 则弹菜单让用户选择
#   - 用户取消（选 0/退出）→ 输出哨兵 __abort__ 并返回 1，调用方应中止安装
# 说明：测速全失败时不视为致命错误，返回空列表（由调用方回退官方/直连）。
_i_net_resolve() {
    local scheme="$1" cand_fn="$2" url_fn="$3"
    local dir csv
    dir="$(_i_net_cache_dir)"
    mkdir -p "$dir"
    csv="$dir/.${scheme}.csv"

    if [ -s "$csv" ] && _i_net_fresh "$csv"; then
        awk -F, 'NF { print $1 }' "$csv"
        return 0
    fi

    echo "下载源缓存缺失或已过期（7 天），正在测速…（限时测速，可能需要数秒到十余秒）" >&2
    # 测速依赖 curl；缺失则跳过测速，直接回退官方/直连，避免误报 0 列表
    if ! command -v curl >/dev/null 2>&1; then
        echo "[提示] 未安装 curl，无法测速，将使用官方/直连下载" >&2
        return 0
    fi
    if _i_net_measure_write "$csv" "$cand_fn" "$url_fn"; then
        if [ -t 0 ]; then
            _i_net_pick "$csv" || { echo "__abort__"; return 1; }
        fi
    else
        echo "[提示] 所有下载源测速均失败，将使用官方/直连兜底。" >&2
        rm -f "$csv"
    fi

    awk -F, 'NF { print $1 }' "$csv"
    return 0
}

# 运行时剔除失效源：某 base 下载失败后，从缓存移除该行，避免近期重复尝试死链。
_i_net_drop() {
    local csv base tmp
    csv="$(_i_net_csv "$1")"
    base="$2"
    [ -s "$csv" ] || return 0
    tmp="${csv}.d.$$"
    awk -F, -v b="$base" '$1!=b { print }' "$csv" >"$tmp" && mv "$tmp" "$csv"
}

# 强制重测（删除缓存文件）
_i_net_reset() {
    rm -f "$(_i_net_csv "$1")"
}
