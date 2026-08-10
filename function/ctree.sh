# ctree: View a colorful tree with less {{{
ctree() {
    tree -C "$@" | less -R
}
# }}}
