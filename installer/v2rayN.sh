#!/usr/bin/env bash
#
# v2rayN 安装脚本
# V2Ray/Xray 代理客户端，基于 Avalonia 跨平台 GUI
# 多文件 GUI 应用，使用 _i_github_download + _i_extract 公共流水线，
# 安装阶段自定义递归复制，~/bin/v2rayN 为软链接
#
# 使用方式：
#   installer v2rayN                       # 自动检测最新版本并安装
#   V2RAYN_VERSION=7.22.7 installer v2rayN  # 指定版本安装
#
# 参考：https://github.com/2dust/v2rayN

source "$HOME/.bash/installer/_common.sh"

# ---------------------------------------------------------------------------
# 1. 检测操作系统与架构
# ---------------------------------------------------------------------------
_i_detect_os "macos" "linux" || return 1
# v2rayN x86_64 用 '64' 命名（非 x86_64）
_i_detect_arch "64" "arm64" || return 1

# ---------------------------------------------------------------------------
# 2. 配置（v2rayN 是多文件 GUI 应用，安装到子目录）
# ---------------------------------------------------------------------------
_i_setup "v2rayN" "2dust/v2rayN" "7.22.7" "V2RAYN_VERSION"
[ -n "${V2RAYN_INSTALL_DIR:-}" ] && _i_set_install_dir "$V2RAYN_INSTALL_DIR"
[ -n "${V2RAYN_VERSION:-}" ] && _I_VERSION="$V2RAYN_VERSION"

# ---------------------------------------------------------------------------
# 3. 已安装检查（使用公共函数，自动显示版本）
# ---------------------------------------------------------------------------
_i_check_installed "v2rayN" "--version" || return 0

# ---------------------------------------------------------------------------
# 4. 下载（使用公共流水线，获得续传恢复 + 版本化归档 + 归档完整性校验）
# ---------------------------------------------------------------------------
_i_github_download "v2rayN-${_I_OS}-${_I_ARCH}.zip" \
    "https://github.com/2dust/v2rayN/releases/download/<tag>/v2rayN-<os>-<arch>.zip" ||
    return 1

# ---------------------------------------------------------------------------
# 5. 解压（使用公共函数，含 CWE-22 安全检查 + zip auto-strip 单顶层目录）
# ---------------------------------------------------------------------------
_i_extract 1 || return 1

# ---------------------------------------------------------------------------
# 6. 安装到版本目录（多文件 GUI 应用，递归复制全部内容）
# ---------------------------------------------------------------------------
rm -rf "${_I_INSTALL_DIR:?}"
mkdir -p "$_I_INSTALL_DIR"

_v2rayN_count=0
for _v2rayN_f in "$_I_TMPDIR"/*; do
    [ -e "$_v2rayN_f" ] || continue
    _v2rayN_name=$(basename "$_v2rayN_f")
    cp -rf "$_v2rayN_f" "${_I_INSTALL_DIR}/"
    if [ -f "$_v2rayN_f" ]; then
        chmod +x "${_I_INSTALL_DIR}/${_v2rayN_name}" 2>/dev/null || true
        echo "  ${_v2rayN_name}"
    elif [ -d "$_v2rayN_f" ]; then
        echo "  ${_v2rayN_name}/"
    fi
    _v2rayN_count=$((_v2rayN_count + 1))
done
echo "共安装 ${_v2rayN_count} 项"

# ---------------------------------------------------------------------------
# 7. 创建 ~/bin/v2rayN 软链接指向主程序
# ---------------------------------------------------------------------------
_i_symlink_install "v2rayN"

# ---------------------------------------------------------------------------
# 8. 验证安装
# ---------------------------------------------------------------------------
echo ""
if [ -f "${_I_INSTALL_DIR}/v2rayN" ]; then
    # 尝试打印版本（GUI 应用可能无 --version，用 timeout 防护）
    timeout 5 "${_I_INSTALL_DIR}/v2rayN" --version 2>/dev/null || true
    echo "v2rayN 安装完成！"
    echo "启动: v2rayN"
else
    echo "[警告] 未找到 v2rayN 主程序，请检查压缩包内容" >&2
    echo "已安装内容："
    ls -la "$_I_INSTALL_DIR/" 2>/dev/null
fi
_i_path_warning "v2rayN"
_i_cleanup
unset _v2rayN_f _v2rayN_name _v2rayN_count
