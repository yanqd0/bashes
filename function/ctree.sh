# ctree: View a colorful tree with less {{{
function ctree {
    tree -C "$1" | less -R
}
# }}}
