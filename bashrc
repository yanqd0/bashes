#!/usr/bin/env bash

### The local bashrc ###

# Shell detection {{{
_is_bash=false
_is_zsh=false
[ -n "$BASH_VERSION" ] && _is_bash=true
[ -n "$ZSH_VERSION" ] && _is_zsh=true
# }}}

# Previous configs {{{
if [ -f ~/.bash/function.bash ]
then
    . ~/.bash/function.bash
fi

check_source ~/.bash/alias.bash
check_source ~/.bash/installer.sh
check_source ~/.bash/confal.sh
# }}}

# export {{{
# prepend_to_path: Prepend dir to PATH if it exists and not already there {{{
_prepend_to_path() {
    if [ -d "$1" ]; then
        case ":$PATH:" in
            *:"$1":*) ;;
            *) export PATH="$1:$PATH" ;;
        esac
    fi
}
# }}}

_prepend_to_path "$HOME/.yarn/bin"
_prepend_to_path "$HOME/.cargo/bin"
_prepend_to_path "$HOME/.local/bin"
_prepend_to_path "$HOME/bin"

# Golang {{{
# export GOROOT=$HOME/.golang/go
# export GOPATH=$HOME/.golang/path
# The bootstrap should be the branch release-branch.go1.4 of go
# export GOROOT_BOOTSTRAP=$HOME/.golang/bootstrap
# export GOROOT_FINAL=${GOROOT_FINAL:-$GOROOT}
# export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
# }}}

if $_is_bash; then
    export HISTCONTROL=ignoredups:ignorespace
fi
export HISTSIZE=1000
export HISTFILESIZE=2000
export TERM=xterm-256color

export CLICOLOR=1                   # Colorize `ls`
# Disable this because of `make` completion error
# export CLICOLOR_FORCE=1             # Always
export LSCOLORS=gxfxaxdxcxegedabagacad

# export GREP_COLOR='1;43'
# }}}

# Shell options {{{
if $_is_bash; then
    shopt -s checkwinsize               # Check the window size and update if necessary,
    shopt -s histappend                 # Append to the history file
    shopt -s cdspell                    # Auto amend directory error
    shopt -s extglob                    # Several extended pattern matching operators are recognized
elif $_is_zsh; then
    setopt append_history               # Append to the history file
    setopt correct                      # Auto amend directory error
    setopt extended_glob                # Several extended pattern matching operators are recognized
    setopt hist_ignore_dups             # Don't record duplicate commands
    setopt hist_ignore_space            # Don't record commands starting with space
fi
# }}}

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# Prompt {{{
if $_is_bash; then
    POWERLINE_HOME=$(/usr/bin/python3 -c "
from importlib import metadata

try:
    dist = metadata.distribution('powerline-status')
    print(dist.locate_file(''))
except metadata.PackageNotFoundError:
    raise SystemExit(1)
")
    if [ -d "$POWERLINE_HOME" ]
    then
        source "$POWERLINE_HOME/powerline/bindings/bash/powerline.sh"
        export POWERLINE_HOME
        powerline-daemon -q
        alias pdb='python3 -m powerline.bindings.pdb'
    else
        PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\] $(date -Iseconds)\n\$ '
    fi
fi
# }}}

# Completion {{{
if $_is_bash; then
    if ! shopt -oq posix
    then
        if [ -f /usr/share/bash-completion/bash_completion ]
        then
            . /usr/share/bash-completion/bash_completion
        elif [ -f /etc/bash_completion ]
        then
            . /etc/bash_completion
        fi
    fi
elif $_is_zsh; then
    autoload -Uz compinit && compinit
fi
# }}}

# fzf & autojump {{{
if $_is_bash; then
    check_source ~/.fzf.bash
fi

if $_is_zsh; then
    check_source /usr/share/autojump/autojump.zsh /usr/share/autojump/autojump.bash
else
    check_source /usr/share/autojump/autojump.bash
fi
# }}}

# vim: set shiftwidth=4 softtabstop=-1 expandtab foldmethod=marker:
# vim: set textwidth=100 colorcolumn=100:
