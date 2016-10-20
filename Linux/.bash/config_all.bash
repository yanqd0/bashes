#!/usr/bin/env bash


### Configurate all configurable commands ###

bash_config () {
    echo "
# vim: set shiftwidth=4 softtabstop=-1 expandtab foldmethod=marker:
# vim: set textwidth=80 colorcolumn=80:

# Personal config {{{
if [ -f ~/.bash/bashrc ]; then
    . ~/.bash/bashrc
fi
# }}}
" >> ~/.bashrc
}

git_config () {
    git config --global core.editor vim
    git config --global push.default simple
    git config --global color.ui true

    git config --global alias.amend 'commit --amend --no-edit'
    git config --global alias.s 'status -s'
    git config --global alias.l "log --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
    git config --global alias.lg 'log --graph --full-history --all --color --pretty=format:"%x1b[31m%h%x09%x1b[32m%d%x1b[0m%x20%s"'
}

main () {
    case $1 in
        bash)
            bash_config;;
        git)
            git_config;;
        "")
            echo 'A config name is needed:'
            echo '  bash'
            echo '  git'
            ;;
        *)
            echo $1 is not supported yet!
            echo You can write it in ~/.bash/config_all.bash;;
    esac
}

main $*

# vim: set shiftwidth=4 softtabstop=-1 expandtab:
# vim: set foldmethod=indent foldnestmax=1:
# vim: set textwidth=80 colorcolumn=80:
