---
paths:
  - function/*
  - function.bash
---

# 函数模块规则

**function 是默认推荐位置。** 不属于安装（installer）和配置（confal）的新功能默认放这里。提供可复用的通用 shell 函数，一个文件一个公开函数，由 `function.bash` 自动加载。

## 文件组织

- 新增函数放在 `function/<name>.sh`，一个文件只定义一个公开函数
- 文件名与函数名一致
- 在 `function.bash` 的 `myfunc` 函数中，向 `desc` 数组添加 `[<name>]="中文简介"`，按名称字典序排列，不以添加时间为序
- `function.bash` 启动时自动 glob `function/*.sh` 并逐一 source，新增文件无需额外注册即可被加载

## 函数编写

- 函数体用 `function <name> { ... }` 语法（bash/zsh 通用）
- 文件头尾保留 vim fold marker 注释 `# {{{` / `# }}}`
- 中文注释和帮助信息
- vim modeline 末尾保留（参考现有文件）

## 示例：最小可用的函数文件

```bash
# mycmd: 一句话中文描述 {{{
function mycmd {
    # 逻辑
}
# }}}
```
