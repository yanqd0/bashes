#!/usr/bin/env bash

# brew_switch: 一键切换 Homebrew 镜像源 {{{
function brew_switch {
    # ---------- 颜色输出 ----------
    _brew_switch_red='\033[0;31m'
    _brew_switch_green='\033[0;32m'
    _brew_switch_yellow='\033[1;33m'
    _brew_switch_nc='\033[0m'
    _brew_switch_info()  { echo -e "${_brew_switch_green}[INFO]${_brew_switch_nc} $1"; }
    _brew_switch_warn()  { echo -e "${_brew_switch_yellow}[WARN]${_brew_switch_nc} $1"; }
    _brew_switch_error() { echo -e "${_brew_switch_red}[ERROR]${_brew_switch_nc} $1" >&2; return 1; }

    # ---------- 命令行参数 ----------
    _brew_switch_do_update=false
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -u|--update) _brew_switch_do_update=true; shift ;;
            *) _brew_switch_error "未知参数: $1。用法: brew_switch [-u|--update]" || return ;;
        esac
    done

    # ---------- 检查 Homebrew ----------
    if ! command -v brew &>/dev/null; then
        _brew_switch_error "Homebrew 未安装" || return
    fi
    _brew_switch_info "Homebrew 已安装: $(brew --version | head -1)"

    # ---------- 根据 prefix 获取 URL ----------
    _brew_switch_get_urls() {
        case "$1" in
            ustc)
                _brew_switch_brew_url="https://mirrors.ustc.edu.cn/brew.git"
                _brew_switch_core_url="https://mirrors.ustc.edu.cn/homebrew-core.git"
                _brew_switch_cask_url="https://mirrors.ustc.edu.cn/homebrew-cask.git"
                _brew_switch_bottle_url="https://mirrors.ustc.edu.cn/homebrew-bottles"
                _brew_switch_api_url="https://mirrors.ustc.edu.cn/homebrew-bottles/api"
                _brew_switch_pip_url="https://mirrors.ustc.edu.cn/pypi/web/simple"
                ;;
            tuna)
                _brew_switch_brew_url="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"
                _brew_switch_core_url="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git"
                _brew_switch_cask_url="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-cask.git"
                _brew_switch_bottle_url="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"
                _brew_switch_api_url="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api"
                _brew_switch_pip_url="https://pypi.tuna.tsinghua.edu.cn/simple"
                ;;
            tencent)
                _brew_switch_brew_url="https://mirrors.cloud.tencent.com/homebrew/brew.git"
                _brew_switch_core_url="https://mirrors.cloud.tencent.com/homebrew/homebrew-core.git"
                _brew_switch_cask_url="https://mirrors.cloud.tencent.com/homebrew/homebrew-cask.git"
                _brew_switch_bottle_url="https://mirrors.cloud.tencent.com/homebrew-bottles"
                _brew_switch_api_url="https://mirrors.cloud.tencent.com/homebrew-bottles/api"
                _brew_switch_pip_url="https://mirrors.cloud.tencent.com/pypi/simple"
                ;;
            ali)
                _brew_switch_brew_url="https://mirrors.aliyun.com/homebrew/brew.git"
                _brew_switch_core_url="https://mirrors.aliyun.com/homebrew/homebrew-core.git"
                _brew_switch_cask_url="https://mirrors.aliyun.com/homebrew/homebrew-cask.git"
                _brew_switch_bottle_url="https://mirrors.aliyun.com/homebrew/homebrew-bottles"
                _brew_switch_api_url="https://mirrors.aliyun.com/homebrew/homebrew-bottles/api"
                _brew_switch_pip_url="https://mirrors.aliyun.com/pypi/simple/"
                ;;
            huawei)
                _brew_switch_brew_url="https://mirrors.huaweicloud.com/homebrew/brew.git"
                _brew_switch_core_url="https://mirrors.huaweicloud.com/homebrew/homebrew-core.git"
                _brew_switch_cask_url="https://mirrors.huaweicloud.com/homebrew/homebrew-cask.git"
                _brew_switch_bottle_url="https://mirrors.huaweicloud.com/homebrew-bottles"
                _brew_switch_api_url="https://mirrors.huaweicloud.com/homebrew-bottles/api"
                _brew_switch_pip_url="https://mirrors.huaweicloud.com/repository/pypi/simple"
                ;;
            netease)
                _brew_switch_brew_url="https://mirrors.163.com/homebrew/brew.git"
                _brew_switch_core_url="https://mirrors.163.com/homebrew/homebrew-core.git"
                _brew_switch_cask_url="https://mirrors.163.com/homebrew/homebrew-cask.git"
                _brew_switch_bottle_url="https://mirrors.163.com/homebrew-bottles"
                _brew_switch_api_url="https://mirrors.163.com/homebrew-bottles/api"
                _brew_switch_pip_url="https://mirrors.163.com/pypi/simple/"
                ;;
            sjtu)
                _brew_switch_brew_url="https://mirrors.sjtug.sjtu.edu.cn/git/homebrew/brew.git"
                _brew_switch_core_url="https://mirrors.sjtug.sjtu.edu.cn/git/homebrew/homebrew-core.git"
                _brew_switch_cask_url="https://mirrors.sjtug.sjtu.edu.cn/git/homebrew/homebrew-cask.git"
                _brew_switch_bottle_url=""
                _brew_switch_api_url=""
                _brew_switch_pip_url="https://mirrors.sjtug.sjtu.edu.cn/pypi/web/simple"
                ;;
            bfsu)
                _brew_switch_brew_url="https://mirrors.bfsu.edu.cn/git/homebrew/brew.git"
                _brew_switch_core_url="https://mirrors.bfsu.edu.cn/git/homebrew/homebrew-core.git"
                _brew_switch_cask_url="https://mirrors.bfsu.edu.cn/git/homebrew/homebrew-cask.git"
                _brew_switch_bottle_url="https://mirrors.bfsu.edu.cn/homebrew-bottles"
                _brew_switch_api_url="https://mirrors.bfsu.edu.cn/homebrew-bottles/api"
                _brew_switch_pip_url="https://mirrors.bfsu.edu.cn/pypi/web/simple"
                ;;
            official)
                _brew_switch_brew_url="https://github.com/Homebrew/brew.git"
                _brew_switch_core_url="https://github.com/Homebrew/homebrew-core.git"
                _brew_switch_cask_url="https://github.com/Homebrew/homebrew-cask.git"
                _brew_switch_bottle_url=""
                _brew_switch_api_url=""
                _brew_switch_pip_url=""
                ;;
            *)
                _brew_switch_error "未知的镜像源前缀: $1" || return
                ;;
        esac
    }

    # ---------- 探测当前使用的镜像源 ----------
    _brew_switch_detect() {
        local brew_repo current_url detected
        brew_repo="$(brew --repo)"
        current_url=$(git -C "$brew_repo" config --get remote.origin.url 2>/dev/null || echo "")

        if [ -z "$current_url" ]; then
            _brew_switch_warn "无法探测当前 brew 仓库的 remote 地址"
            return
        fi

        case "$current_url" in
            *mirrors.ustc.edu.cn*)         detected="中科大 (ustc)" ;;
            *mirrors.tuna.tsinghua.edu.cn*) detected="清华大学 (tuna)" ;;
            *mirrors.cloud.tencent.com*)    detected="腾讯云 (tencent)" ;;
            *mirrors.aliyun.com*)           detected="阿里云 (ali)" ;;
            *mirrors.huaweicloud.com*)      detected="华为云 (huawei)" ;;
            *mirrors.163.com*)              detected="网易 (netease)" ;;
            *mirrors.sjtug.sjtu.edu.cn*)    detected="上海交大 (sjtu)" ;;
            *mirrors.bfsu.edu.cn*)          detected="北京外国语大学 (bfsu)" ;;
            *github.com/Homebrew*)          detected="官方源 (official)" ;;
            *)                              detected="未知镜像源" ;;
        esac

        echo ""
        echo -e "${_brew_switch_green}[INFO]${_brew_switch_nc} 当前 brew 使用的镜像源: ${_brew_switch_yellow}${detected}${_brew_switch_nc}"
        echo -e "       remote: ${current_url}"
        echo ""
    }

    _brew_switch_detect

    # ---------- 选择镜像 ----------
    echo "=========================================="
    echo "请选择要切换的 Homebrew 镜像源："
    echo "  1) 中科大 (ustc)          5) 华为云 (huawei)"
    echo "  2) 清华大学 (tuna)        6) 网易 (netease)"
    echo "  3) 腾讯云 (tencent)       7) 上海交大 (sjtu)"
    echo "  4) 阿里云 (aliyun/ali)    8) 北京外国语大学 (bfsu)"
    echo "  9) 官方源 (official)"
    echo "  0) 退出 (quit/exit)"
    echo "=========================================="
    read -r -p "请输入数字或简称: " _brew_switch_choice

    _brew_switch_choice_lower=$(echo "$_brew_switch_choice" | tr '[:upper:]' '[:lower:]')
    case "$_brew_switch_choice_lower" in
        0|quit|exit) _brew_switch_info "已取消。"; return 0 ;;
        1|ustc)    _brew_switch_prefix="ustc";    _brew_switch_mirror_name="中科大" ;;
        2|tuna)    _brew_switch_prefix="tuna";    _brew_switch_mirror_name="清华大学" ;;
        3|tencent) _brew_switch_prefix="tencent"; _brew_switch_mirror_name="腾讯云" ;;
        4|aliyun|ali) _brew_switch_prefix="ali";  _brew_switch_mirror_name="阿里云" ;;
        5|huawei)  _brew_switch_prefix="huawei";  _brew_switch_mirror_name="华为云" ;;
        6|netease) _brew_switch_prefix="netease"; _brew_switch_mirror_name="网易" ;;
        7|sjtu)    _brew_switch_prefix="sjtu";    _brew_switch_mirror_name="上海交大" ;;
        8|bfsu)    _brew_switch_prefix="bfsu";    _brew_switch_mirror_name="北京外国语大学" ;;
        9|official) _brew_switch_prefix="official"; _brew_switch_mirror_name="官方源" ;;
        *) _brew_switch_error "无效选择，请输入数字或简称（如 aliyun, huawei）" || return ;;
    esac

    _brew_switch_get_urls "$_brew_switch_prefix" || return

    _brew_switch_info "已选择镜像源: $_brew_switch_mirror_name"

    # ---------- 切换 Git 仓库地址 ----------
    _brew_switch_git_remote() {
        local repo_name="$1" remote_url="$2" repo_path current_url

        if [ -z "$remote_url" ]; then
            _brew_switch_warn "仓库 ${repo_name} 的镜像地址为空，跳过设置"
            return
        fi

        case $repo_name in
            brew) repo_path="$(brew --repo)" ;;
            core)
                repo_path="$(brew --repo homebrew/core)" 2>/dev/null || true
                if [ ! -d "$repo_path" ]; then
                    _brew_switch_warn "homebrew-core 仓库不存在，跳过"
                    return
                fi
                ;;
            cask)
                repo_path="$(brew --repo homebrew/cask)" 2>/dev/null || true
                if [ ! -d "$repo_path" ]; then
                    _brew_switch_warn "homebrew-cask 仓库不存在，跳过"
                    return
                fi
                ;;
            *) _brew_switch_error "未知仓库名: ${repo_name}" || return ;;
        esac

        current_url=$(git -C "$repo_path" config --get remote.origin.url 2>/dev/null || echo "")
        if [ -n "$current_url" ]; then
            _brew_switch_info "仓库 ${repo_name} 当前地址: ${current_url}"
        fi

        git -C "$repo_path" remote set-url origin "$remote_url"
        _brew_switch_info "仓库 ${repo_name} 已切换到: ${remote_url}"
    }

    _brew_switch_git_remote "brew" "$_brew_switch_brew_url"
    _brew_switch_git_remote "core" "$_brew_switch_core_url"
    _brew_switch_git_remote "cask" "$_brew_switch_cask_url"

    # ---------- 更新环境变量（核心：主动添加缺失的变量）----------
    _brew_switch_update_vars() {
        local pip_url="$1" api_url="$2" bottle_url="$3" brew_git="$4" core_git="$5"
        local config_files rcfile bak

        # 要管理的变量名 → 对应值
        _brew_switch_set_var() {
            local rcfile="$1" var_name="$2" var_value="$3"
            local pattern="^[[:space:]]*export ${var_name}="

            if [ -z "$var_value" ]; then
                # 目标源不支持该变量，删除已有行
                if grep -q -E "$pattern" "$rcfile" 2>/dev/null; then
                    sed -i '' -E "/${pattern}/d" "$rcfile"
                    _brew_switch_info "  - 已删除 ${var_name}"
                fi
            else
                local escaped_val
                escaped_val=$(echo "$var_value" | sed -e 's/[|&\\]/\\&/g')
                if grep -q -E "$pattern" "$rcfile" 2>/dev/null; then
                    # 变量已存在，更新值
                    sed -i '' -E "s|^([[:space:]]*export ${var_name}=).*|\1\"${escaped_val}\"|" "$rcfile"
                    _brew_switch_info "  - 已更新 ${var_name} = \"${var_value}\""
                else
                    # 变量不存在，主动添加
                    echo "export ${var_name}=\"${var_value}\"" >> "$rcfile"
                    _brew_switch_info "  - 已添加 ${var_name} = \"${var_value}\""
                fi
            fi
        }

        config_files=(
            "$HOME/.zprofile"
            "$HOME/.zshrc"
            "$HOME/.bashrc"
            "$HOME/.profile"
            "$HOME/.bash_profile"
        )

        for rcfile in "${config_files[@]}"; do
            [ -f "$rcfile" ] || continue
            _brew_switch_info "正在处理 $rcfile"

            _brew_switch_set_var "$rcfile" "HOMEBREW_PIP_INDEX_URL" "$pip_url"
            _brew_switch_set_var "$rcfile" "HOMEBREW_API_DOMAIN" "$api_url"
            _brew_switch_set_var "$rcfile" "HOMEBREW_BOTTLE_DOMAIN" "$bottle_url"
            _brew_switch_set_var "$rcfile" "HOMEBREW_BREW_GIT_REMOTE" "$brew_git"
            _brew_switch_set_var "$rcfile" "HOMEBREW_CORE_GIT_REMOTE" "$core_git"
        done
    }

    _brew_switch_update_vars \
        "$_brew_switch_pip_url" \
        "$_brew_switch_api_url" \
        "$_brew_switch_bottle_url" \
        "$_brew_switch_brew_url" \
        "$_brew_switch_core_url"

    # ---------- 可选 brew update ----------
    if [ "$_brew_switch_do_update" = true ]; then
        _brew_switch_info "正在执行 'brew update' 测试连接..."
        if brew update; then
            _brew_switch_info "brew update 成功"
        else
            _brew_switch_warn "brew update 出现异常，请检查网络或手动执行 'brew update'"
        fi
    else
        _brew_switch_info "跳过 brew update (如需测试，请添加 -u 或 --update 参数)"
    fi

    _brew_switch_info "环境变量已更新。请重启终端或执行 'source ~/.zprofile' 使其生效"

    # 清理内部变量
    unset _brew_switch_red _brew_switch_green _brew_switch_yellow _brew_switch_nc
    unset _brew_switch_do_update _brew_switch_choice _brew_switch_choice_lower
    unset _brew_switch_prefix _brew_switch_mirror_name
    unset _brew_switch_brew_url _brew_switch_core_url _brew_switch_cask_url
    unset _brew_switch_bottle_url _brew_switch_api_url _brew_switch_pip_url
}
# }}}

# vim: set shiftwidth=4 softtabstop=-1 expandtab foldmethod=marker:
# vim: set textwidth=80 colorcolumn=80:
