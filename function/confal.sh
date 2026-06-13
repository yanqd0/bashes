# confal: Configurate all configurable commands. {{{
confal() {
    case "${1:-}" in
        bash)
            echo "
# vim: set shiftwidth=4 softtabstop=-1 expandtab foldmethod=marker:
# vim: set textwidth=80 colorcolumn=80:

# Personal config {{{
if [ -f ~/.bash/bashrc ]
then
    . ~/.bash/bashrc
fi
# }}}
" >> ~/.bashrc
            ;;
        zsh)
            echo "
# vim: set shiftwidth=4 softtabstop=-1 expandtab foldmethod=marker:
# vim: set textwidth=80 colorcolumn=80:

# Personal config {{{
if [ -f ~/.bash/bashrc ]
then
    . ~/.bash/bashrc
fi
# }}}
" >> ~/.zshrc
            ;;
        brew)
            # Git HTTP/1.1 — 国内镜像 HTTP/2 兼容性问题会导致卡住
            git config --global http.version HTTP/1.1
            echo "Git HTTP version 已设为 HTTP/1.1（国内镜像兼容）"

            # 写入 Homebrew 国内镜像环境变量
            if [ "$(uname)" = "Darwin" ]; then
                _confal_brew_rc="$HOME/.zprofile"
            else
                _confal_brew_rc="$HOME/.bashrc"
            fi

            if grep -q 'HOMEBREW_BOTTLE_DOMAIN' "$_confal_brew_rc" 2>/dev/null; then
                echo "Homebrew 环境变量已存在于 $_confal_brew_rc，跳过写入"
            else
                cat >> "$_confal_brew_rc" <<'EOF'

# Homebrew 国内镜像配置（阿里云）— 可用 brew_switch 切换 {{{
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.aliyun.com/homebrew/homebrew-bottles"
export HOMEBREW_API_DOMAIN="https://mirrors.aliyun.com/homebrew/homebrew-bottles/api"
export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.aliyun.com/homebrew/homebrew-core.git"
export HOMEBREW_PIP_INDEX_URL="https://mirrors.aliyun.com/pypi/simple/"
export HOMEBREW_NO_AUTO_UPDATE=1
# }}}
EOF
                echo "Homebrew 国内镜像环境变量已写入 $_confal_brew_rc"
            fi
            unset _confal_brew_rc
            ;;
        git)
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
            ;;
        rustup)
            export RUSTUP_DIST_SERVER=https://mirrors.aliyun.com/rustup
            export RUSTUP_UPDATE_ROOT=https://mirrors.aliyun.com/rustup/rustup
            echo "Rustup mirrors set to Aliyun"
            ;;
        "")
            echo 'A config name is needed:'
            echo '  bash'
            echo '  brew'
            echo '  git'
            echo '  rustup'
            echo '  zsh'
            ;;
        *)
            echo "$1 is not supported yet!"
            echo You can write it in ~/.bash/config_all.bash
            ;;
    esac
}
# }}}
