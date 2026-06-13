---
paths:
  - confal/*
  - confal.sh
---

# 配置脚本规则

**confal 只做配置，不做安装，不提供通用工具函数。**

## 职责边界

- **confal**：配置已有工具的行为（git alias、环境变量、镜像源等）。特征是写 `~/.gitconfig`、`~/.zprofile`、`~/.bashrc` 等配置文件，或设置全局 `git config`。
- **installer**：安装新工具到系统（下载、编译、包管理）。
- **function**：提供可复用的通用 shell 函数，不属于安装和配置的默认放这里。

## 文件组织

- 配置脚本放在 `confal/<name>.sh`，命名为小写命令名
- 调度器 `confal.sh` 定义 `confal()` 函数，按 `$1` 分发，由 `bashrc` 加载
- `confal()` 内置 `desc` 关联数组，添加 `[<name>]="中文简介"`，按字典序排列

## 脚本编写

- 脚本由 `confal()` 以 `source` 方式执行，直接运行配置命令
- 退出用 `return`，不要用 `exit`
- 写入配置文件前 `grep -q` 检查避免重复追加
- 中文提示信息

## 系统兼容

- macOS（`uname = Darwin`）与 Linux 的 shell 配置文件路径可能不同
- macOS 默认写 `~/.zprofile`（Homebrew 环境变量）或 `~/.zshrc`（shell 配置）
- Linux 默认写 `~/.bashrc`

## 示例：最小可用的配置脚本

```bash
#!/usr/bin/env bash
#
# confal <name> — 一句话中文描述

echo "正在配置 <name>..."
# 配置逻辑
echo "<name> 配置完成"
```
