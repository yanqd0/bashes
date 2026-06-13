#!/usr/bin/env bash
#
# confal zsh — 配置 zsh 环境

cat >> ~/.zshrc <<'EOF'

# vim: set shiftwidth=4 softtabstop=-1 expandtab foldmethod=marker:
# vim: set textwidth=80 colorcolumn=80:

# Personal config {{{
if [ -f ~/.bash/bashrc ]
then
    . ~/.bash/bashrc
fi
# }}}
EOF

echo "zsh 配置已写入 ~/.zshrc"
