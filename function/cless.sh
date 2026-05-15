# cless: A colorful less {{{
function cless {
    pygmentize "$1" | less -NR
}
# }}}
