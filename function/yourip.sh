# yourip: Query geo/IP info of a given domain or IP {{{
yourip() {
    if [[ "$1" == "-h" || "$1" == "--help" || -z "$1" ]]
    then
        echo "Usage: yourip <domain|IP> [N]" 1>&2
        echo "  0  cip.cc          (default, geo+ISP)" 1>&2
        echo "  1  ipinfo.io       (JSON, rich detail)" 1>&2
        echo "  2  ip-api.com      (JSON, free)" 1>&2
        return
    fi

    local target="$1"
    local mode="${2:-0}"

    # cip.cc and ipinfo.io need IP, not domain; resolve if needed
    local ip="$target"
    if [[ "$mode" != 2 && "$target" =~ [^0-9.] ]]; then
        ip=$(dig +short "$target" 2>/dev/null | head -1)
        if [[ -z "$ip" ]]; then
            ip=$(getent hosts "$target" 2>/dev/null | awk '{print $1; exit}')
        fi
        if [[ -z "$ip" ]]; then
            echo "ERROR: Cannot resolve $target" >&2
            return 1
        fi
        echo "Resolved $target → $ip" >&2
    fi

    case "$mode" in
        1) curl -sS "ipinfo.io/$ip" | jq '.' ;;
        2) curl -sS "ip-api.com/json/$target" | jq '.' ;;
        *) curl -sS "cip.cc/$ip" ;;
    esac
}
# }}}
