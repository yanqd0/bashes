#!/usr/bin/env bash
#
# confal bash — 配置 bash 环境

cat >> ~/.bashrc <<'EOF'

# vim: set shiftwidth=4 softtabstop=-1 expandtab foldmethod=marker:
# vim: set textwidth=80 colorcolumn=80:

# Personal config {{{
if [ -f ~/.bash/bashrc ]
then
    . ~/.bash/bashrc
fi
# }}}
EOF

echo "bash 配置已写入 ~/.bashrc"
