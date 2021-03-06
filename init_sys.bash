#!/usr/bin/env bash

### Initialize a system of Debian/Ubuntu or Darwin. ###

common=(
    git
    # Version Control System

    shellcheck
    # A static analysis tool for shell scripts.
    # See: https://github.com/koalaman/shellcheck

    jq
    # Command-line JSON processor
    # See: https://github.com/stedolan/jq

    cloc
    # Count Lines of Code
    # See: https://github.com/AlDanial/cloc

    autojump
    tree
    htop
    p7zip
)

debs=(
    build-essential
    exuberant-ctags

    silversearcher-ag
    # A code-searching tool similar to ack, but faster.
    # See: https://github.com/ggreer/the_silver_searcher
)

brews=(
    ag
    # Same as silversearcher-ag
    # See: https://github.com/ggreer/the_silver_searcher
)

name=$(uname)
case ${name} in
    'Linux')
        if [ "$(id -u)" == "0" ]
        then # root
            INSTALL="apt-get install"
        else # Not root
            INSTALL="sudo apt-get install"
        fi

        packages=("${common[@]}" "${debs[@]}");;
    'Darwin')
        INSTALL="brew install"
        packages=("${common[@]}" "${brews[@]}");;
    *)
        echo "Unsupported system: ${name}" 1>&2
        exit 1;;
esac
echo "Initialize ${name}..."

echo "$INSTALL" "${packages[@]}"
$INSTALL "${packages[@]}"

sudo pip3 install powerline-status psutil netifaces
