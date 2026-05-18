# printcolor: Print the supported color of current bash emulator. {{{
printcolor() {
    script=~/.bash/print_color.bash
    if [ -f $script ]
    then
        $script "$*"
    else
        echo $script not found!
    fi
}
# }}}
