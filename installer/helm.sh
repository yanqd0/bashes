#!/usr/bin/env bash
#
# helm 安装脚本
# Kubernetes 包管理器，通过 get.helm.sh CDN 下载
# 不依赖 GitHub Releases，使用官方 CDN 分发
#
# 使用方式：
#   installer helm                       # 自动检测最新版本并安装
#   HELM_VERSION=v4.2.2 installer helm    # 指定版本安装
#
# 参考：https://helm.sh/docs/intro/install/

source "$HOME/.bash/installer/_common.sh"

# helm 使用 get.helm.sh CDN，非 GitHub Releases
# 因此不使用 _i_github_download，改用自定义下载逻辑

_i_detect_os "darwin" "linux" || return 1
_i_detect_arch "amd64" "arm64" || return 1
_i_setup "helm" "helm/helm" "v4.2.2" "HELM_VERSION"
[ -n "${HELM_INSTALL_DIR:-}" ] && _i_set_install_dir "$HELM_INSTALL_DIR"
[ -n "${HELM_VERSION:-}" ] && _I_VERSION="$HELM_VERSION"

_i_check_installed "helm" "version" || return 0

# 确定版本
_i_detect_version

# CDN 下载 URL：https://get.helm.sh/helm-<tag>-<os>-<arch>.tar.gz
_helm_url="https://get.helm.sh/helm-${_I_VERSION}-${_I_OS}-${_I_ARCH}.tar.gz"
_helm_archive="helm-${_I_OS}-${_I_ARCH}.tar.gz"
_helm_downloading="${_I_CACHE_DIR}/${_helm_archive}"
_helm_version_file="${_I_CACHE_DIR}/.version"
_helm_archived="${_I_CACHE_DIR}/${_I_VERSION}/${_helm_archive}"

# 续传检测：若临时文件与 .version 均存在，则进入续传模式
_helm_resuming=false
if [ -f "$_helm_downloading" ] && [ -f "$_helm_version_file" ]; then
    _helm_resuming=true
    echo "发现未完成的下载，将续传..."
    echo "  文件: ${_helm_downloading}"
    echo "  已下载: $(du -h "$_helm_downloading" | cut -f1)"
fi

if ! $_helm_resuming; then
    if [ -f "$_helm_archived" ] && _i_check_archive "$_helm_archived"; then
        echo "复用已缓存的文件: ${_helm_archived}"
    else
        [ -f "$_helm_archived" ] && echo "缓存文件已损坏，将重新下载"
        echo "$_I_VERSION" >"$_helm_version_file"
    fi
fi

# 仅在未复用归档时执行下载
if ! $_helm_resuming && [ -f "$_helm_archived" ] && _i_check_archive "$_helm_archived" 2>/dev/null; then
    : # 已复用归档，跳过下载
else
    if $_helm_resuming; then
        echo "继续下载: ${_helm_url}"
    else
        echo "下载: ${_helm_url}"
    fi
    wget -c --show-progress -O "$_helm_downloading" "$_helm_url" || {
        echo "[错误] 下载失败" >&2
        rm -f "$_helm_downloading"
        return 1
    }
    _helm_archived="${_I_CACHE_DIR}/${_I_VERSION}/${_helm_archive}"
    mkdir -p "$(dirname "$_helm_archived")"
    mv "$_helm_downloading" "$_helm_archived"
    echo "已归档: ${_helm_archived}"
fi

# CWE-22 安全检查：拒绝含绝对路径或路径穿越的压缩包
echo "校验压缩包安全性..."
if tar -tzf "$_helm_archived" 2>/dev/null | grep -qE '^/|(^|/)\.\.(/|$)'; then
    echo "[错误] 压缩包包含不安全的路径，拒绝解压" >&2
    return 1
fi

# 解压
_helm_tmpdir=$(mktemp -d)
echo "解压..."
tar -xzf "$_helm_archived" --strip-components=1 -C "$_helm_tmpdir" || {
    echo "[错误] 解压失败" >&2
    rm -rf "$_helm_tmpdir"
    return 1
}

# helm 压缩包内含 linux-amd64/helm，--strip-components=1 后 helm 在根目录
echo "安装到 ${_I_INSTALL_DIR}/"
mkdir -p "$_I_INSTALL_DIR"
cp -f "${_helm_tmpdir}/helm" "${_I_INSTALL_DIR}/helm"
chmod +x "${_I_INSTALL_DIR}/helm"
rm -rf "$_helm_tmpdir"
echo "  helm"

echo ""
if "${_I_INSTALL_DIR}/helm" version 2>/dev/null; then
    echo "helm 安装完成！"
else
    echo "[错误] helm 安装后无法执行，请检查" >&2
    return 1
fi

_i_path_warning "helm"
_i_cleanup
unset _helm_url _helm_archive _helm_downloading _helm_version_file _helm_resuming _helm_archived _helm_tmpdir
