# init_sys: Initialize a Linux system. {{{
function init_sys {
    script=$HOME/.bash/init_sys.bash
    if [ -f "$script" ]
    then
        $script "$*"
    else
        echo "$script not found!"
    fi
}
# }}}
