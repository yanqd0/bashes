### The local bashrc ###

# Previous configs {{{
if [ -f ~/.bash/function.bash ]
then
    . ~/.bash/function.bash
fi

check_source ~/.bash/alias.bash
# }}}

# export {{{
export PATH=$PATH:$HOME/.local/bin

# Golang {{{
export GOROOT=$HOME/.golang/go
export GOPATH=$HOME/.golang/path
export GOROOT_BOOTSTRAP=$HOME/.golang/go1.7
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
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
export GREP_OPTIONS='--color=auto'
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
PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
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

# vim: set shiftwidth=4 softtabstop=-1 expandtab foldmethod=marker:
# vim: set textwidth=100 colorcolumn=100:
