# CLAUDE.md — bashes

个人 shell 配置管理仓库，安装到 `~/.bash/`，同时兼容 bash 和 zsh。

## 项目结构

```
~/.bash/
├── bashrc              # 入口，由 ~/.bashrc 或 ~/.zshrc source
├── alias.bash          # 别名定义
├── function.bash       # 函数加载器 + myfunc 帮助函数
├── function/           # 独立函数模块（一个函数一个文件）
│   ├── confal.sh
│   └── ...
├── installer.sh        # installer 命令，按需安装 CLI 工具
├── installer/          # 安装脚本（一个 CLI 一个文件）
│   ├── _common.sh      # 公共函数库（_ 前缀，installer 列表不显示）
│   ├── glow.sh
│   └── ...
└── scripts/            # 辅助脚本
```

## Shell 兼容性

- 所有脚本均可能被 bash 或 zsh source，必须同时兼容两种 shell
- 如需区分行为，先检测 shell 再分支：

```bash
if [ -n "$BASH_VERSION" ]; then
    # bash 逻辑
elif [ -n "$ZSH_VERSION" ]; then
    # zsh 逻辑
fi
```

- 避免 bash 专属功能：`shopt`、`PROMPT_COMMAND` 等需放在 `$_is_bash` 守卫内
- `function` 关键字、`[[` 在两种 shell 中通用

## 通用约定

- 中文注释和提示信息
- 用 `check_source` 安全 source 可选文件（定义在 `function.bash`）
- PATH 追加用 `_prepend_to_path`（定义在 `bashrc`）
- 提交信息使用中文，格式为 `标题\n\n详细描述`

## Installer 约定

- 优先使用上游预编译二进制，安装到 `~/bin/`
- **全部二进制都安装**：压缩包内除 LICENSE、`.a`、`.so`、`.dylib` 外，所有文件均安装
- macOS 预编译不可用时 fallback 到 `brew install`，Linux 预编译不可用时打印源码编译指引
- 支持断点续传：`~/Downloads/installer/<name>/` 下缓存归档，`.version` 记录版本号
- 解压前做 CWE-22 安全检查（拒绝含 `/` 开头或 `..` 路径穿越的压缩包）
- 安装后用 `<主二进制> --version` 验证可用性

### 公共函数库 `_common.sh`

GitHub Release 类安装脚本 **必须** source `installer/_common.sh`，使用以下公共函数：

| 函数 | 用途 |
|------|------|
| `_i_detect_os <darwin> <linux>` | 检测 OS → `_I_OS` |
| `_i_detect_arch <amd64> <arm64>` | 检测架构 → `_I_ARCH` |
| `_i_setup <name> <repo> <fallback> [env]` | 初始化名称/仓库/回退版本/缓存目录 |
| `_i_set_install_dir <dir>` | 覆盖安装目录（默认 ~/bin） |
| `_i_check_installed <cmd> [ver_args]` | 已安装检查 + 重新安装交互 |
| `_i_github_download <name> <url_tmpl>` | 续传→版本检测→复用→下载→归档 |
| `_i_extract [strip]` | CWE-22 检查 + 解压到临时目录 |
| `_i_install_one <name>` | 安装单个二进制 |
| `_i_install_all [exclude...]` | 安装全部二进制（自动排除 LICENSE 等） |
| `_i_verify <path> [args]` | 验证安装，失败时自动清理 |
| `_i_path_warning <cmd>` | 若不在 PATH 中则提示 |
| `_i_cleanup` | 清理所有 `_I_*` 变量 |

URL 模板占位符：`<tag>` `<ver>` `<os>` `<arch>` `<target>`。
文件以 `_` 开头，installer 列表自动跳过。
