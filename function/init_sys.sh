# init_sys: Initialize a system of openEuler/Fedora(RPM dnf/yum) or Darwin. {{{
#
# 与 Debian 版 init_sys 的差异说明:
#   - build-essential  -> dnf group install "Development Tools"(超集, 见下方注释)
#   - exuberant-ctags  -> ctags(本机 openEuler ctags 5.8 即 exuberant)
#   - silversearcher-ag-> the_silver_searcher(命令为 ag)
#   - shellcheck       -> 放弃: openEuler 各仓库(OS/EPOL/update)均无, 非 EPEL
#                         (TODO: 可自行从 github release 下载静态二进制到 ~/bin)
#   - autojump         -> 放弃: 不在 yum 也不在 PyPI, pipx install autojump 不可行
#                         (实测 pip3 index versions autojump 无该发行)
#                         (TODO: 官方源码方式 github release 的 install.py)
init_sys() {
    common=(
        git
        # Version Control System

        jq
        # Command-line JSON processor
        # See: https://github.com/jqlang/jq

        cloc
        # Count Lines of Code
        # See: https://github.com/AlDanial/cloc

        tree
        htop
        p7zip

        python3-pip
        # 脚本末尾 pip3 安装的前置(python 包管理器)
        python3-setuptools
        unzip zip xz
        # 常用压缩工具(与 p7zip 互补)
        vim-enhanced
        bash-completion
        # TODO: ripgrep/fd/bat/fzf/zoxide 在 openEuler 源中无, 故未列入
        #       需要时请自行源码安装或另配源
    )

    yums=(
        ctags
        # 等价于 Debian 的 exuberant-ctags
        # 本机 openEuler 上 ctags 5.8 即 exuberant 实现
        # See: http://ctags.sourceforge.net/

        the_silver_searcher
        # ag, 等价于 Debian 的 silversearcher-ag
        # See: https://github.com/ggreer/the_silver_searcher
    )

    brews=(
        ag
        # TODO: Darwin/brew 分支暂未实现, 仅作参考保留
        # Same as silversearcher-ag
    )

    name=$(uname)
    case ${name} in
        'Linux')
            # 自动选择包管理器: 优先 dnf, 回退 yum
            if command -v dnf >/dev/null 2>&1; then
                PM="dnf"
            elif command -v yum >/dev/null 2>&1; then
                PM="yum"
            else
                echo "Error: neither dnf nor yum found." 1>&2
                return 1
            fi

            if [ "$(id -u)" == "0" ]
            then # root
                INSTALL="$PM install"
                GROUPINSTALL="$PM group install"
            else # Not root
                INSTALL="sudo $PM install"
                GROUPINSTALL="sudo $PM group install"
            fi

            packages=("${common[@]}" "${yums[@]}");;
        'Darwin')
            # TODO: Darwin/brew 分支暂未实现
            echo "WARNING: init_sys: Darwin/brew 分支暂未实现," \
                 "请参考 Debian/apt 版或 yum 版手动安装。" 1>&2
            return 1;;
        *)
            echo "Unsupported system: ${name}" 1>&2
            return 1;;
    esac
    echo "Initialize ${name} (${PM})..."

    # build-essential 的 yum 等效: dnf 的 "Development Tools" 组
    # 该组 mandatory 包为 build-essential 的超集:
    #   覆盖 gcc gcc-c++ glibc-devel(=libc6-dev) make,
    #   另含 autoconf automake binutils gdb libtool patch pkgconf 等
    # 若嫌组过胖, 最小等效改为: $INSTALL gcc gcc-c++ make
    echo "$GROUPINSTALL \"Development Tools\""
    $GROUPINSTALL "Development Tools"

    echo "$INSTALL" "${packages[@]}"
    $INSTALL "${packages[@]}"

    sudo pip3 install powerline-status psutil netifaces
}
# }}}
