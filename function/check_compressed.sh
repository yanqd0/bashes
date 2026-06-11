# check_compressed: 校验压缩文件完整性，支持 tar/tar.gz/tgz/zip/7z {{{
function check_compressed {
    local file="$1"

    if [ ! -f "$file" ]; then
        echo "[错误] 文件不存在: ${file}" >&2
        return 1
    fi

    case "$file" in
        *.tar)
            tar -tf "$file" >/dev/null 2>&1
            ;;
        *.tar.gz|*.tgz)
            tar -tzf "$file" >/dev/null 2>&1
            ;;
        *.zip)
            if command -v unzip &>/dev/null; then
                unzip -t "$file" >/dev/null 2>&1
            else
                echo "[错误] 缺少 unzip 命令，无法校验 zip 文件" >&2
                return 1
            fi
            ;;
        *.7z)
            if command -v 7z &>/dev/null; then
                7z t "$file" >/dev/null 2>&1
            else
                echo "[错误] 缺少 7z 命令，无法校验 7z 文件" >&2
                return 1
            fi
            ;;
        *)
            # 未知格式，保守处理，视为有效
            return 0
            ;;
    esac
}
# }}}
