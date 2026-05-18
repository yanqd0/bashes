# tagsmgr0: Make and manage tags for Vim {{{
tagsmgr0() {
    script=~/.bash/tags_manager.bash
    if [ -f $script ]
    then
        $script "$*"
    else
        echo $script not found!
    fi
}
# }}}
