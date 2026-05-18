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
    case "${2:-0}" in
        1) curl "ipinfo.io/$target" ;;
        2) curl "ip-api.com/json/$target" ;;
        *) curl "cip.cc/$target" ;;
    esac
}
# }}}
