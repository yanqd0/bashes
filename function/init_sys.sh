# init_sys: Initialize a Linux system. {{{
init_sys() {
    script=$HOME/.bash/init_sys.bash
    if [ -f "$script" ]
    then
        $script "$*"
    else
        echo "$script not found!"
    fi
}
# }}}
