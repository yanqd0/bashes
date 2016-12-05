#!/usr/bin/env bash


if [[ `uname` = 'Darwin' ]]
then
    alias macvim='open -a MacVim'   # open MacVim app quickly
elif [[ `uname` = 'Linux' ]]
then
    alias xopen='xdg-open'          # Open files in a terminal
    alias ls='ls --color=auto'      # Colorize `ls`
fi

# ls {{{
alias ll='ls -AhlF'                 # List files and directories with human readable infomation
alias la='ls -A'                    # Show All files
alias l.='ls -d .*'                 # Show hidden files only
alias lsf='ls -hl | grep ^d'        # Show files only
alias lsd='ls -hl | grep -v ^d'     # Show directories only
# Recursive directory listing
alias lr='ls -R | grep ":$" | sed -e '\''s/:$//'\'' -e '\''s/[^-][^\/]*\//--/g'\'' -e '\''s/^/   /'\'' -e '\''s/-/|/'\'''
# Recursive directory listing including hidden files
alias lra='ls -AR | grep ":$" | sed -e '\''s/:$//'\'' -e '\''s/[^-][^\/]*\//--/g'\'' -e '\''s/^/   /'\'' -e '\''s/-/|/'\'''
# }}}

# grep {{{
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
# }}}

# Jump back n directories at a time {{{
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'
alias .......='cd ../../../../../..'
# }}}

# git {{{
# Compact, colorized git log
alias gl="git log --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
# Visualise git log (like gitk, in the terminal)
alias glg='git log --graph --full-history --all --color --pretty=format:"%x1b[31m%h%x09%x1b[32m%d%x1b[0m%x20%s"'
# }}}

# Other {{{
alias pipinst='pip install --user'  # Install pip only for the current user.
alias df='df -h'                    # Human readable df
alias rm='rm -i'                    # rm will be more safe by reminding
alias tm='ps -ef | grep'            # Search for process
alias vi='vim --noplugin'           # Set vi as vim
# Show which commands you use the most
alias freq='cut -f1 -d" " ~/.bash_history | sort | uniq -c | sort -nr | head -n 30'
# }}}


# vim: set shiftwidth=4 softtabstop=-1 expandtab foldmethod=marker:
# vim: set textwidth=100 colorcolumn=100:
