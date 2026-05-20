# cht: cheat.sh shell client wrapper {{{
cht() {
    local cht_bin="/tmp/bashes/cht.sh"
    if [[ ! -x "$cht_bin" ]]; then
        mkdir -p /tmp/bashes
        curl -sS "cht.sh/:cht.sh" -o "$cht_bin" && chmod +x "$cht_bin"
    fi
    "$cht_bin" "$@"
}
# }}}
