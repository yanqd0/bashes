# ctree: View a colorful tree with less {{{
ctree() {
    tree -C "$1" | less -R
}
# }}}
