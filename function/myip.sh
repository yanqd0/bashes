# myip: Get public IP info from various services {{{
myip() {
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
