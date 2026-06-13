#!/usr/bin/env bash
#
# brew 安装脚本
# Homebrew — macOS / Linux 包管理器，默认使用阿里云镜像
#
# 核心思路：从清华镜像 clone Homebrew 官方 install.git，替换其中所有
# GitHub 地址为阿里云镜像地址，注入 HOMEBREW_BOTTLE_DOMAIN 后执行。
# install.sh 本身由 Homebrew 官方维护，本脚本只做镜像适配，不去依赖
# 第三方安装脚本。
#
# 使用方式：
#   installer brew
#
# 参考：https://github.com/Homebrew/install

# ---------------------------------------------------------------------------
# 1. 检测操作系统与架构
# ---------------------------------------------------------------------------
_brew_os="$(uname -s)"
_brew_arch="$(uname -m)"

case "$_brew_os" in
    Darwin) ;;
    Linux) ;;
    *)
        echo "[错误] 不支持的操作系统: $_brew_os" >&2
        return 1
        ;;
esac

# 确定安装路径
if [ "$_brew_os" = "Darwin" ]; then
    if [ "$_brew_arch" = "arm64" ]; then
        _brew_prefix="/opt/homebrew"
    else
        _brew_prefix="/usr/local"
    fi
    _brew_repository="$_brew_prefix"
else
    _brew_prefix="/home/linuxbrew/.linuxbrew"
    _brew_repository="$_brew_prefix/Homebrew"
fi

# ---------------------------------------------------------------------------
# 2. 镜像源 URL（阿里云为主，清华用于 install.git clone）
# ---------------------------------------------------------------------------
_brew_mirror_brew="https://mirrors.aliyun.com/homebrew/brew.git"
_brew_mirror_core="https://mirrors.aliyun.com/homebrew/homebrew-core.git"
_brew_mirror_cask="https://mirrors.aliyun.com/homebrew/homebrew-cask.git"
_brew_mirror_bottle="https://mirrors.aliyun.com/homebrew/homebrew-bottles"
_brew_mirror_api="https://mirrors.aliyun.com/homebrew/homebrew-bottles/api"
_brew_mirror_pip="https://mirrors.aliyun.com/pypi/simple/"
# install.git 清华有镜像，阿里云可能没有，用于一次性 clone 官方安装脚本
_brew_install_git="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/install.git"

# ---------------------------------------------------------------------------
# 3. 已安装检查
# ---------------------------------------------------------------------------
if command -v brew &>/dev/null; then
    echo "Homebrew 已安装，当前版本："
    brew --version 2>/dev/null || true
    echo "安装路径: $(brew --prefix 2>/dev/null || echo "未知")"
    read -r -p "是否强制重新安装？[y/N] " REPLY
    case "${REPLY:-N}" in
        [yY]|[yY][eE][sS]) ;;
        *) echo "已取消。"; return 0 ;;
    esac
fi

# ---------------------------------------------------------------------------
# 4. 确保 git 可用
# ---------------------------------------------------------------------------
if ! command -v git &>/dev/null; then
    echo "需要 git 才能继续安装..."
    if [ "$_brew_os" = "Darwin" ]; then
        echo "正在触发 Xcode Command Line Tools 安装..."
        xcode-select --install 2>/dev/null || true
        echo "请完成上述安装后重新运行 installer brew"
        return 1
    else
        sudo apt update && sudo apt install -y git || {
            echo "[错误] git 安装失败" >&2
            return 1
        }
    fi
fi

# ---------------------------------------------------------------------------
# 5. 安装
# ---------------------------------------------------------------------------
echo "将安装 Homebrew 到: $_brew_prefix"
echo "镜像源: 阿里云"

# 获取 sudo 权限
sudo echo -n "" || { echo "[错误] 需要 sudo 权限"; return 1; }

# 如有旧安装，提示备份后删除
if [ -d "$_brew_prefix" ]; then
    read -r -p "检测到已有 $_brew_prefix，是否删除后重新安装？[y/N] " REPLY
    case "${REPLY:-N}" in
        [yY]|[yY][eE][sS])
            _brew_backup="$HOME/Desktop/Old_Homebrew_$(date +%Y%m%d_%H%M%S)"
            mkdir -p "$_brew_backup" 2>/dev/null
            cp -rf "$_brew_prefix" "$_brew_backup/" 2>/dev/null && echo "已备份到: $_brew_backup"
            sudo rm -rf "$_brew_prefix"
            ;;
        *) echo "已取消。"; return 0 ;;
    esac
fi

# Clone 官方 install 脚本（从清华镜像），替换为阿里云地址后执行
_brew_tmp=$(mktemp -d)
trap 'rm -rf "$_brew_tmp"' RETURN

echo "正在获取 Homebrew 安装脚本..."
git clone --depth=1 "$_brew_install_git" "$_brew_tmp/install" 2>/dev/null || {
    echo "[错误] 无法获取安装脚本，请检查网络连接" >&2
    return 1
}

_brew_install_script="$_brew_tmp/install/install.sh"

# 替换 install.sh 中所有 GitHub 地址为阿里云镜像
sed -i '' -e "s|https://github.com/Homebrew|https://mirrors.aliyun.com/homebrew|g" \
          -e 's|"update"|"update-reset"|g' \
          "$_brew_install_script" 2>/dev/null || \
sed -i -e "s|https://github.com/Homebrew|https://mirrors.aliyun.com/homebrew|g" \
         -e 's|"update"|"update-reset"|g' \
         "$_brew_install_script"

# 注入 HOMEBREW_BOTTLE_DOMAIN，使安装过程中下载 bottle 也走镜像
sed -i '' "1a\\
export HOMEBREW_BOTTLE_DOMAIN=${_brew_mirror_bottle}\\
export HOMEBREW_API_DOMAIN=${_brew_mirror_api}\\
export HOMEBREW_CORE_GIT_REMOTE=${_brew_mirror_core}\\
" "$_brew_install_script" 2>/dev/null || \
sed -i "1a\\
export HOMEBREW_BOTTLE_DOMAIN=${_brew_mirror_bottle}\\
export HOMEBREW_API_DOMAIN=${_brew_mirror_api}\\
export HOMEBREW_CORE_GIT_REMOTE=${_brew_mirror_core}\\
" "$_brew_install_script"

echo "正在安装 Homebrew..."
NONINTERACTIVE=1 /bin/bash "$_brew_install_script" || {
    echo "[错误] Homebrew 安装失败" >&2
    return 1
}

# ---------------------------------------------------------------------------
# 6. 写入环境变量到 shell 配置文件
# ---------------------------------------------------------------------------
if [ "$_brew_os" = "Darwin" ]; then
    _brew_rc="$HOME/.zprofile"
else
    _brew_rc="$HOME/.bashrc"
fi

echo "写入环境变量到 $_brew_rc ..."

# 先移除旧的 #ckbrew 标记的配置
if [ -f "$_brew_rc" ]; then
    sed -i '' '/#ckbrew/d' "$_brew_rc" 2>/dev/null || sed -i '/#ckbrew/d' "$_brew_rc"
fi

cat >> "$_brew_rc" << EOF

# Homebrew mirror (aliyun) — 可用 brew_switch 切换 {{{
export HOMEBREW_PIP_INDEX_URL="${_brew_mirror_pip}"
export HOMEBREW_API_DOMAIN="${_brew_mirror_api}"
export HOMEBREW_BOTTLE_DOMAIN="${_brew_mirror_bottle}"
export HOMEBREW_CORE_GIT_REMOTE="${_brew_mirror_core}"
eval \$(${_brew_prefix}/bin/brew shellenv) #ckbrew
# }}}
EOF

# ---------------------------------------------------------------------------
# 7. 验证安装
# ---------------------------------------------------------------------------
# 在当前 shell 中生效
eval "$($_brew_prefix/bin/brew shellenv 2>/dev/null)" 2>/dev/null || true

echo ""
if brew --version &>/dev/null; then
    echo "Homebrew 安装完成！"
    brew config 2>/dev/null || true
else
    echo "[错误] Homebrew 安装后无法执行，请检查" >&2
    return 1
fi

echo ""
echo "提示: 执行 'source $_brew_rc' 使环境变量在当前终端生效"
echo "提示: 使用 brew_switch 命令可切换其他镜像源（中科大、清华、腾讯云等）"

# 清理临时变量
unset _brew_os _brew_arch _brew_prefix _brew_repository
unset _brew_mirror_brew _brew_mirror_core _brew_mirror_cask
unset _brew_mirror_bottle _brew_mirror_api _brew_mirror_pip
unset _brew_install_git _brew_tmp _brew_install_script _brew_rc _brew_backup
