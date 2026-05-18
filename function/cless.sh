# cless: A colorful less {{{
cless() {
    pygmentize "$1" | less -NR
}
# }}}
