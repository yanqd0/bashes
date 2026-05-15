# mkdatedir: Make a directory by date. {{{
function mkdatedir {
    dir=$(date +%Y)/$(date +%m)/$(date +%d)
    mkdir -p "$dir"
    if [[ -n $1 ]]
    then
        touch "$dir/$1"
    fi
}
# }}}
