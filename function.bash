#!/usr/bin/env bash


# check_source: Check if valid then source the file {{{
function check_source {
    if [ -f "$1" ]
    then
        source "$1"
    elif [ -f "$2" ]
    then
        source "$2"
    fi
}
# }}}

# mcd: mkdir and cd into it {{{
function mcd {
    mkdir -p "$1" && cd "$1"
}
# }}}

# myextract: Extract various condensed files {{{
function myextract {
    if [ -f "$1" ]
    then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar e "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.jar)       unzip "$1"       ;;
            *.aar)       unzip "$1"       ;;
            *.apk)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *)     echo "$1 cannot be extracted via myextract" ;;
        esac
    else
        echo "$1 is not a valid file"
    fi
}
# }}}

# tagsmgr0: Make and manage tags for Vim {{{
function tagsmgr0 {
    script=~/.bash/tags_manager.bash
    if [ -f $script ]
    then
        $script "$*"
    else
        echo $script not found!
    fi
}
# }}}

# printcolor: Print the supported color of current bash emulator. {{{
function printcolor {
    script=~/.bash/print_color.bash
    if [ -f $script ]
    then
        $script "$*"
    else
        echo $script not found!
    fi
}
# }}}

# cmd2sh: Save commands to a file {{{
function cmd2sh {
    if [[ -n $2 ]]
    then
        num=$2
    else
        num=1
    fi

    if [[ -n $1 ]]
    then
        file=$1.sh
        if [[ -e $file ]]
        then
            echo "$file exists. Abort!"
            return
        fi

        echo "#!/usr/bin/env bash" > "$file"
        echo "" >> "$file"
        fc -nl | tail -$num \
            | sed "s/	 //g" \
            | sed "s/  *$//g" >> "$file"
        chmod +x "$file"
    else
        echo "Usage: cmd2sh <FILE_file> [<CMD_NUM>]"
    fi
}
# }}}

# confal: Configurate all configurable commands. {{{
function confal {
    script=~/.bash/config_all.bash
    if [ -f $script ]
    then
        $script "$*"
    else
        echo $script not found!
    fi
}
# }}}

# ignore: Generate .gitignore file from gitignore.io API. {{{
# See: https://www.gitignore.io/docs
function gitignore {
    curl -L -s "https://www.gitignore.io/api/$*"
}
# }}}

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

# docker-clean: Clean docker containers, images and volumes. {{{
function docker-clean {
    docker rm $(docker ps -aq) 2> /dev/null
    docker rmi $(docker images -qf "dangling=true") 2> /dev/null
    # docker volume prune -f 2> /dev/null
}
# }}}

# vim: set shiftwidth=4 softtabstop=-1 expandtab foldmethod=marker:
# vim: set textwidth=80 colorcolumn=80:
