#!/usr/bin/env bash
#
# confal git — 配置 git 别名和行为

git config --global core.editor vim
git config --global push.default simple
git config --global color.ui true
git config --global pull.rebase true
git config --global credential.helper store

git config --global alias.amend 'commit --amend --no-edit --reset-author'
git config --global alias.last 'log -1'
git config --global alias.unstage 'reset HEAD --'
git config --global alias.co checkout
git config --global alias.cp cherry-pick
git config --global alias.br branch
git config --global alias.cm commit
git config --global alias.f fetch
git config --global alias.ps push
git config --global alias.pl pull
git config --global alias.st status
git config --global alias.s 'status -sb'
git config --global alias.submadd 'submodule add'
git config --global alias.tags 'tag -ln'
git config --global alias.recursive-clone 'clone --recurse-submodules'
git config --global alias.l "log --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
git config --global alias.lg 'log --graph --full-history --all --color --pretty=format:"%x1b[31m%h%x09%x1b[32m%d%x1b[0m%x20%s"'

echo "git 配置已完成"
