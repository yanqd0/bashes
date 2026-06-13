---
paths:
  - installer/*
  - installer.sh
---

# 安装脚本规则

**installer 只管安装。** 将新工具安装到系统（下载、编译、包管理）。配置已有工具的行为（git alias、环境变量、镜像源等）应放在 `confal/`。通用工具函数应放在 `function/`。

## 文件组织

- 安装脚本放在 `installer/<name>.sh`，命名为小写命令名
- 在 `installer.sh` 的 `desc` 关联数组中同步添加一行 `[<name>]="中文简介"`
- `desc` 中的条目按名称字典序排列，不以添加时间为序
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

## 通用安装策略

适用于从 GitHub Release、或其它类似平台，下载预编译二进制的脚本。

所有需要"自行拼装下载 URL → 下载 → 安装"的脚本，默认遵循以下策略（参考 `rtk.sh`）：

### 执行流程

```
检测 OS/架构 → 缓存续传检查
  ├── 有未完成下载 → 读 .version → wget -c 续传 → 归档 → 安装 → 验证
  └── 无缓存       → 已安装检查 → 版本确定 → 归档复用检查
                       ├── 同版本已归档 → 跳过下载 → 安装 → 验证
                       └── 新版本       → 写 .version → wget 下载 → 归档 → 安装 → 验证
```

### 缓存目录结构

```
~/Downloads/installer/<name>/
├── .version                          ← 记录版本号及文件名中缺失的关键信息
├── <name>-<target>.tar.gz            ← 下载中临时文件（用于续传）
└── <version>/
    └── <name>-<target>.tar.gz        ← 下载完成后的归档，同版本可复用
```

### 下载

- 使用 `wget -c --show-progress -O <缓存文件> <URL>`：`-c` 断点续传，`--show-progress` 显示进度条
- 下载到 `~/Downloads/installer/<name>/` 固定路径（非 mktemp 临时目录），确保进程中断后文件保留
- 下载完成后 `mv` 到 `<version>/` 子目录归档

### 版本确定

按优先级依次尝试，每种方式都只发起 1 次或更少的网络请求：

1. **环境变量**（零请求）：如 `${NAME}_VERSION`，用户显式指定则跳过所有检测
2. **HEAD 重定向**（1 次轻量请求）：`wget --max-redirect=0 --server-response` 跟随 GitHub `/releases/latest`
3. **硬编码回退**（零请求）：前两步均失败时使用固定的默认版本号，并给出提示

### 续传判断

- 启动时先于版本检测和已安装检查：若 `~/Downloads/installer/<name>/` 下存在临时文件且 `.version` 可读，直接进入续传模式
- 续传模式下跳过已安装检查、版本查询、归档复用检查
- `.version` 文件记录版本等文件名中无法体现的关键信息

### 已安装检查

- `command -v <name>` 检测，已安装则打印 `--version` 并询问"是否强制重新安装？[y/N]"
- 默认 N 取消，y/yes 继续
- 强制安装时仍遵循归档复用逻辑

### 安全校验（压缩包）

- 解压前 `tar -tzf | grep -qE '^/|(^|/)\.\.(/|$)'` 检查路径安全（CWE-22）
- 拒绝含绝对路径或 `..` 路径穿越的压缩包

### 安装 & 验证

- 默认安装到 `~/bin/`，可通过 `${NAME}_INSTALL_DIR` 环境变量覆盖
- `mkdir -p` 确保目录存在，`mv -f` 覆盖旧版本
- `chmod +x` 确保可执行
- 安装后调用 `--version` 验证，若安装路径不在 `PATH` 中则打印提示

### 变量命名

- 脚本内局部变量统一以 `_<name>_` 为前缀（如 `_rtk_os`、`_rtk_version`）
- 脚本末尾 `unset` 清理全部临时变量，避免污染 shell 环境
