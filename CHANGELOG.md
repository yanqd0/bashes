# Change Log

## 0.2.0

### Features

- 新增 `myip` 函数，查询本机公网 IP（支持多个服务商）。
- 新增 `yourip` 函数，查询域名或 IP 归属地（支持 cip.cc、ipinfo.io、ip-api.com）。
- 新增 `init_sys` 系统初始化脚本，支持 Debian/Ubuntu 和 Darwin (Homebrew)。
- 新增 `cless`、`cmore` 彩色分页器函数，基于 `less`/`more` 的高亮管道分页。
- 新增 `ctree` 彩色树形目录函数。
- 新增 `docker-clean` 函数，清理未使用的 Docker 容器和镜像。
- 新增 `install-android.sh`，一键安装 Android 命令行工具并配置环境变量。
- 新增 git 别名 `cp` (cherry-pick)、`tags` (tag -ln)，配置 `credential.helper store`。
- 新增 fzf 模糊搜索和 rust/cargo 工具链的路径配置。
- 增强 PS1 提示符，新增 `pdb` 别名集成 powerline 调试工具。

### Bug Fixes

- 修复 `POWERLINE_HOME` 路径错误。
- 修复 `cd` 在未创建目录时的 SC2164 警告。
- 修复 `config_all.bash` 中的 shell 静态分析警告。
- 修复 `docker-clean` 误传参数导致不清理 volumes 的问题。

### Others

- `function.bash` 拆分为 `function/` 目录下 16 个独立模块，启动时自动加载。
- 新增 `myfunc` 函数，分模块区和内联区列出所有受管函数及中文说明。
- 外部独立脚本（`print_color.bash`、`tags_manager.bash`、`init_sys.bash`、`config_all.bash`）全部内联到对应 function 模块并删除原文件。
- 函数定义语法统一为 `func()` 格式。
- `mcd` 移入 `function/mcd.sh` 独立模块。
- 废弃 `GREP_OPTION` 环境变量。
- 重构 `init_sys` 使用 bash 数组管理包列表。
- `$()` 替代反引号，Python 替代 awk 获取 powerline 路径。
- Python 3 替代 Python 2 运行 powerline。
