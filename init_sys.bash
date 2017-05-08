#!/usr/bin/env bash

### Initialize in a Debian/Ubuntu system ###

packages=(
    build-essential

    git
    # Version Control System

    silversearcher-ag
    # A code-searching tool similar to ack, but faster.
    # See: https://github.com/ggreer/the_silver_searcher

    shellcheck
    # A static analysis tool for shell scripts.
    # See: https://github.com/koalaman/shellcheck

    jq
    # Command-line JSON processor
    # See: https://github.com/stedolan/jq

    cloc
    # Count Lines of Code
    # See: https://github.com/AlDanial/cloc
)

if [ "$(id -u)" != "0" ]
then # Not root
   INSTALL="sudo aptitude install"
else # root
   INSTALL="aptitude install"
fi

$INSTALL "${packages[@]}"
