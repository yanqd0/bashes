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
│   ├── rtk.sh
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
