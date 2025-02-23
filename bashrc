#!/usr/bin/env bash

### The local bashrc ###

# Previous configs {{{
if [ -f ~/.bash/function.bash ]
then
    . ~/.bash/function.bash
fi

check_source ~/.bash/alias.bash
# }}}

# export {{{
export PATH=$HOME/.local/bin:$PATH

# Golang {{{
# export GOROOT=$HOME/.golang/go
# export GOPATH=$HOME/.golang/path
# The bootstrap should be the branch release-branch.go1.4 of go
# export GOROOT_BOOTSTRAP=$HOME/.golang/bootstrap
# export GOROOT_FINAL=${GOROOT_FINAL:-$GOROOT}
# export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
# }}}

export HISTCONTROL=ignoredups:ignorespace
export HISTSIZE=1000
export HISTFILESIZE=2000
export TERM=xterm-256color

export CLICOLOR=1                   # Colorize `ls`
# Disable this because of `make` completion error
# export CLICOLOR_FORCE=1             # Always
export LSCOLORS=gxfxaxdxcxegedabagacad

# export GREP_COLOR='1;43'
# }}}

# shopt {{{
shopt -s checkwinsize               # Check the window size and update if necessary,
shopt -s histappend                 # Append to the history file
shopt -s cdspell                    # Auto amend directory error
shopt -s extglob                    # Several extended pattern matching operators are recognized
# }}}

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# PS1 {{{
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
# }}}

# Bash completion {{{
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
# }}}

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

check_source ~/.fzf.bash
check_source /usr/share/autojump/autojump.bash

if [ -d ~/.yarn/bin ]
then
    export PATH=$HOME/.yarn/bin:$PATH
fi
if [ -d "$HOME/.cargo/bin" ]
then
    export PATH="$HOME/.cargo/bin:$PATH"
fi

# vim: set shiftwidth=4 softtabstop=-1 expandtab foldmethod=marker:
# vim: set textwidth=100 colorcolumn=100:
