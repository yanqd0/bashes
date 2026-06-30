#!/usr/bin/env bash
#
# k9s 安装脚本
# Kubernetes 终端管理面板，实时监控集群资源
# Go 预编译二进制，安装到 ~/bin/
#
# 使用方式：
#   installer k9s                       # 自动检测最新版本并安装
#   K9S_VERSION=v0.51.0 installer k9s    # 指定版本安装
#
# 参考：https://github.com/derailed/k9s

source "$HOME/.bash/installer/_common.sh"

_i_detect_os "Darwin" "Linux" || return 1
_i_detect_arch "amd64" "arm64" || return 1
_i_setup "k9s" "derailed/k9s" "v0.51.0" "K9S_VERSION"
[ -n "${K9S_INSTALL_DIR:-}" ] && _i_set_install_dir "$K9S_INSTALL_DIR"
[ -n "${K9S_VERSION:-}" ] && _I_VERSION="$K9S_VERSION"

_i_check_installed "k9s" "version" || return 0

# GoReleaser 命名：k9s_<OS>_<arch>.tar.gz（不含版本号）
_i_github_download "k9s-${_I_OS}_${_I_ARCH}.tar.gz" \
    "https://github.com/derailed/k9s/releases/download/<tag>/k9s_<os>_<arch>.tar.gz" ||
    return 1

_i_extract 0 || return 1
_i_install_one "k9s" || return 1

_i_verify "${_I_INSTALL_DIR}/k9s" "version" || {
    echo "[错误] k9s 安装后无法执行，请检查" >&2
    return 1
}
_i_path_warning "k9s"
_i_cleanup
