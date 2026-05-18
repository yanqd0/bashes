# cmore: A colorful more {{{
cmore() {
    if [[ $2 ]]
    then
        pygmentize "$1" | more "$2"
    else
        pygmentize "$1" | more
    fi
}
# }}}
