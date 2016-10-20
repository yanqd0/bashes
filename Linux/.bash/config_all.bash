#!/usr/bin/env bash


### Configurate all configurable commands ###

git_config () {
    git config --global core.editor vim
    git config --global push.default simple
    git config --global color.ui true

    git config --global alias.amend 'commit --amend --no-edit'
    git config --global alias.s 'status -s'
    git config --global alias.l "log --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
    git config --global alias.lg 'log --graph --full-history --all --color --pretty=format:"%x1b[31m%h%x09%x1b[32m%d%x1b[0m%x20%s"'
}

case $1 in
    git)
        git_config;;
    *)
        echo $1 is not supported yet!
        echo You can write it in ~/.bash/config_all.bash;;
esac


# vim: set shiftwidth=4 softtabstop=-1 expandtab:
# vim: set foldmethod=indent foldnestmax=1:
# vim: set textwidth=80 colorcolumn=80:
