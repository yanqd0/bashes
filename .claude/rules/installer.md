---
paths:
  - installer/*
  - installer.sh
---

# 安装脚本规则

## 文件组织

- 安装脚本放在 `installer/<name>.sh`，命名为小写命令名
- 在 `installer.sh` 的 `desc` 关联数组中同步添加一行 `[<name>]="中文简介"`
- 脚本通过 `installer <name>` 调用，`installer.sh` 会 `source` 执行它

## 脚本编写

- 脚本中可直接调用 shell 函数（如 `confal`），因为 `installer.sh` 以 `source` 方式执行
- 退出用 `return`，不要用 `exit`（source 模式下 `exit` 会关闭终端）
- 安装前检查命令是否已存在：已存在则打印版本并提示，不要静默覆盖
- 中文提示信息

## 系统兼容

- macOS（`uname = Darwin`）与 Linux 可能走不同安装方式
- brew 安装后环境变量写 `~/.zshrc`，curl 等安装后写 `~/.bashrc`
- 写入前 `grep -q` 检查避免重复
