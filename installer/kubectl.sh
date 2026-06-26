#!/usr/bin/env bash
#
# kubectl 安装脚本
# 从 Kubernetes 官方 CDN 下载预编译二进制，安装到 ~/bin/
# 全平台（Linux / macOS）统一策略，单一二进制直接下载
#
# 使用方式：
#   installer kubectl                           # 自动检测最新稳定版并安装
#   KUBECTL_VERSION=v1.36.0 installer kubectl    # 指定版本安装（跳过版本检测）
#
# 参考：https://kubernetes.io/docs/tasks/tools/

# ---------------------------------------------------------------------------
# 1. 检测操作系统与架构（无网络请求，始终先行）
# ---------------------------------------------------------------------------

# 操作系统：kubernetes CDN 命名 linux / darwin
_kubectl_os=""
case "$(uname -s)" in
Darwin) _kubectl_os="darwin" ;;
Linux) _kubectl_os="linux" ;;
*)
    echo "[错误] 不支持的操作系统: $(uname -s)" >&2
    return 1
    ;;
esac

# CPU 架构：kubernetes CDN 命名 amd64 / arm64
_kubectl_arch=""
case "$(uname -m)" in
x86_64 | amd64) _kubectl_arch="amd64" ;;
arm64 | aarch64) _kubectl_arch="arm64" ;;
*)
    echo "[错误] 不支持的 CPU 架构: $(uname -m)" >&2
    return 1
    ;;
esac

_kubectl_target="${_kubectl_os}/${_kubectl_arch}"

# ---------------------------------------------------------------------------
# 2. 缓存路径
#    kubectl 是单一二进制，缓存策略更简单：
#    ~/Downloads/installer/kubectl/<version>/kubectl —— 归档，同版本可复用
# ---------------------------------------------------------------------------
_kubectl_install_dir="${KUBECTL_INSTALL_DIR:-$HOME/bin}"
_kubectl_cache_dir="$HOME/Downloads/installer/kubectl"
mkdir -p "$_kubectl_cache_dir"

_kubectl_fallback_version="v1.36.0"

# ---------------------------------------------------------------------------
# 3. 已安装检查 → 版本确定 → 缓存复用
# ---------------------------------------------------------------------------

# 3a. 已安装检查
if command -v kubectl &>/dev/null; then
    echo "kubectl 已安装，当前版本："
    kubectl version --client 2>/dev/null || true
    read -r -p "是否强制重新安装？[y/N] " REPLY
    case "${REPLY:-N}" in
    [yY] | [yY][eE][sS]) ;;
    *)
        echo "已取消。"
        return 0
        ;;
    esac
fi

# 3b. 确定版本号
#     优先 KUBECTL_VERSION 环境变量（零请求）→ stable.txt（1 次轻量请求）→ 回退默认版本
if [ -n "$KUBECTL_VERSION" ]; then
    _kubectl_version="$KUBECTL_VERSION"
    echo "使用指定版本: ${_kubectl_version}"
else
    echo "正在查询最新稳定版本..."
    _kubectl_latest=$(wget -q -O - "https://dl.k8s.io/release/stable.txt" 2>/dev/null)

    if [ -n "$_kubectl_latest" ]; then
        _kubectl_version="$_kubectl_latest"
        echo "最新稳定版: ${_kubectl_version}"
    else
        _kubectl_version="$_kubectl_fallback_version"
        echo "无法查询 kubernetes CDN，回退到默认版本: ${_kubectl_version}"
        echo "  （可设置 KUBECTL_VERSION=vX.Y.Z 来指定其他版本）"
    fi
fi

_kubectl_tag="${_kubectl_version}"

# 3c. 缓存复用检查：同版本已下载过则直接复用
_kubectl_archived="${_kubectl_cache_dir}/${_kubectl_version}/kubectl"
if [ -f "$_kubectl_archived" ] && [ -s "$_kubectl_archived" ]; then
    echo "复用已缓存的文件: ${_kubectl_archived}"
    _kubectl_use_archived=true
else
    _kubectl_use_archived=false
fi

# ---------------------------------------------------------------------------
# 4. 下载（kubectl 是单一小文件，<50MB，无需断点续传）
# ---------------------------------------------------------------------------
if ! ${_kubectl_use_archived:-false}; then
    _kubectl_download_url="https://dl.k8s.io/release/${_kubectl_tag}/bin/${_kubectl_target}/kubectl"
    _kubectl_tmp="${_kubectl_cache_dir}/kubectl.downloading"

    echo "下载: ${_kubectl_download_url}"
    wget --show-progress -O "$_kubectl_tmp" "$_kubectl_download_url" || {
        echo "[错误] 下载失败" >&2
        rm -f "$_kubectl_tmp"
        return 1
    }

    # 归档到版本子目录
    _kubectl_archived="${_kubectl_cache_dir}/${_kubectl_version}/kubectl"
    mkdir -p "$(dirname "$_kubectl_archived")"
    mv "$_kubectl_tmp" "$_kubectl_archived"
    echo "已归档: ${_kubectl_archived}"
else
    _kubectl_archived="${_kubectl_cache_dir}/${_kubectl_version}/kubectl"
fi

# ---------------------------------------------------------------------------
# 5. 安装到 ~/bin/
# ---------------------------------------------------------------------------
echo "安装到 ${_kubectl_install_dir}/"
mkdir -p "$_kubectl_install_dir"
cp -f "$_kubectl_archived" "${_kubectl_install_dir}/kubectl"
chmod +x "${_kubectl_install_dir}/kubectl"

# ---------------------------------------------------------------------------
# 6. 验证安装
# ---------------------------------------------------------------------------
echo ""
if "${_kubectl_install_dir}/kubectl" version --client 2>/dev/null; then
    echo "kubectl 安装完成！"
else
    echo "预编译二进制不可用，清理已安装文件..."
    rm -f "${_kubectl_install_dir}/kubectl"

    if [ "$_kubectl_os" = "darwin" ]; then
        echo "macOS 可通过 Homebrew 安装："
        echo "  brew install kubectl"
    else
        echo "Linux 可通过包管理器安装："
        echo "  Ubuntu/Debian: sudo snap install kubectl --classic"
        echo "  或通过 apt："
        echo "  sudo apt-get update && sudo apt-get install -y apt-transport-https"
        echo "  curl -fsSL https://pkgs.k8s.io/core:/stable:/${_kubectl_version#v}/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg"
        echo "  echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${_kubectl_version#v}/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list"
        echo "  sudo apt-get update && sudo apt-get install -y kubectl"
    fi
    return 1
fi

# PATH 提示
if ! command -v kubectl &>/dev/null; then
    echo "[提示] ~/bin 不在 PATH 中，请将以下行添加到 ~/.bashrc 或 ~/.zshrc："
    echo "       export PATH=\"\$HOME/bin:\$PATH\""
fi

# 清理临时变量
unset _kubectl_os _kubectl_arch _kubectl_target _kubectl_version _kubectl_tag
unset _kubectl_install_dir _kubectl_cache_dir _kubectl_latest
unset _kubectl_download_url _kubectl_archived _kubectl_use_archived _kubectl_tmp
unset _kubectl_fallback_version
