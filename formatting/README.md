# 文档格式化

本目录保存 `project-docs` 使用的 Markdown 文档格式约定和格式化脚本 .

## 安装 Perl

脚本直接运行在宿主机上 , 不需要 Docker , 也不需要先编译项目 . 先检查是否已经安装 :

```bash
perl --version
```

macOS 通常已经提供 Perl . 如果系统没有 Perl , 可以使用 Homebrew :

```bash
brew install perl
perl --version
```

Debian 或 Ubuntu 可以使用系统包管理器 :

```bash
sudo apt update
sudo apt install perl
perl --version
```

脚本使用的 `File::Find`、`File::Spec` 和 `Getopt::Long` 都是常见 Perl 标准库模块 , 不需要单独从 CPAN 安装 .

脚本按 UTF-8 读取和写回 Markdown 文件 . 仓库中的中文文档应保存为 UTF-8 ; 如果文件使用其他编码 , 先转换为 UTF-8 再处理 . 脚本会在处理每个文件时验证 UTF-8 ; 验证失败时会报告文件并停止 .

格式化脚本不会猜测文件的编码 . 如果文件不是合法的 UTF-8 , 脚本应报告错误并停止处理 . 格式化脚本也不会负责把其他编码转换成 UTF-8.

如果已有文件使用 GBK 等其他编码 , 请先使用 `convert-to-utf8.pl` 生成 UTF-8 文件 , 再使用格式化脚本 . 转换工具要求使用者明确指定原始编码 , 不会自动猜测 .

## 目前的格式与最佳实践

普通正文中的中文标点使用英文字符 , 并在标点两侧保留一个空格 :

```text
这是一个例子 . 下一句继续 .
答案是 : "hello world" .
```

当前规则包括 :

| 原写法   | 目标写法             |
| -------- | -------------------- |
| `。`     | `.`                  |
| `，`     | `,`                  |
| `：`     | `:`                  |
| `；`     | `;` , 规则与句号相同 |
| `！`     | `!`                  |
| `？`     | `?`                  |
| `“内容”` | `"内容"`             |
| `‘内容’` | `'内容'`             |

行首和行尾不添加多余空格 . 小数点、英文单词中的句点和 URL 不按句号处理 , 推荐将英文单词整体设置为行内代码块 .

脚本只整理已经存在的标点 , 不根据句意猜测或补全缺失的句号、逗号、分号等标点 . 原文一行末尾没有标点时 , 脚本会保留原样 .

句尾标点只保留左侧的一个空格 , 不添加右侧空格 :

```text
这是句子 .
```

句中标点才在两侧保留空格 :

```text
这是第一句 . 这是第二句 .
```

这套规则是本仓库的内部文档风格 , 不是中文标点的国家标准 . 国家标准规定的是中文标点的通常形式和用法 , 本目录约定的是项目成员选择的书写方式 .

## 保护范围

脚本只处理普通 Markdown 正文 , 以下内容保持原样 :

- 围栏代码块 .
- 行内代码 .
- Markdown 链接和图片链接 .
- GitHub Alert 标记 , 例如 `> [!NOTE]` 和 `> [!TIP]` .
- `http://` 和 `https://` URL.
- HTML 标签 .

## Usage

建议从 `project-docs` 仓库根目录执行 . 若当前不在仓库根目录 , 先进入仓库 :

```bash
cd /path/to/project-docs
```

例如 :

```bash
cd /Users/zelong/Desktop/acm-oj-new/project-docs
```

检查一个 Markdown 文件 :

```bash
perl formatting/md-format.pl --check README.md
```

检查整个教程 :

```bash
perl formatting/md-format.pl --check go-tutorial/
```

传入目录时 , 脚本会递归查找其中所有 `.md` 文件 , 不处理其他格式的文件 .

`--check` 只显示 unified diff , 不修改文件 . 如果发现需要修改的内容 , 命令会以非零状态退出 ; 没有发现问题时以零状态退出 .

确认 diff 没有问题后 , 再写回文件 :

```bash
perl formatting/md-format.pl --write go-tutorial/
```

`--write` 会直接修改传入范围内发生变化的 Markdown 文件 . 程序会先读取并验证传入范围内的全部 Markdown 文件 , 全部文件通过 UTF-8 检查后才开始写回 , 避免目录处理中途出现编码错误时只修改一部分文件 . **建议**先执行 `--check` , 确认差异后再使用 `--write` .

脚本默认不会自动处理仓库中的所有 Markdown 文件 . 需要格式化哪个文件或目录 , 就把哪个路径作为参数传入 .

例如 , 格式化整个 `go-tutorial` 的完整流程是 :

```bash
# cd /Users/zelong/Desktop/acm-oj-new/project-docs
perl formatting/md-format.pl --check go-tutorial/
# 人工查看输出的 diff
perl formatting/md-format.pl --write go-tutorial/
git diff -- go-tutorial/
```

## 转换为 UTF-8

`convert-to-utf8.pl` 用于把一个明确知道原始编码的文件转换为 UTF-8.工具默认不会覆盖原文件 , 使用者需要指定新的输出文件 :

```bash
perl formatting/convert-to-utf8.pl \
  --from GBK \
  --input old-notes.md \
  --output old-notes-utf8.md
```

`--from` 必须填写输入文件实际使用的编码 , 例如 `GBK` 或 `UTF-8` . 工具不会根据文件内容猜测编码 .

转换工具会执行以下检查 :

- 输入文件必须存在 .
- 输入文件必须能够按照 `--from` 指定的编码解码 .
- 输出文件默认不能已经存在 .
- 转换失败时不会写出不完整的结果 .
- 输出文件使用 UTF-8 , 并且不写入 BOM.

如果使用者确认可以覆盖已有输出文件 , 可以加上 `--force` :

```bash
perl formatting/convert-to-utf8.pl \
  --from GBK \
  --input old-notes.md \
  --output old-notes-utf8.md \
  --force
```

转换完成后 , 使用者仍然应运行格式化脚本的 `--check` , 确认文件内容和格式符合预期 .

## 处理原则

1. 先保护 Markdown 中不能改动的区域 .
2. 只对普通正文应用标点规则 .
3. 保留原文件的其他结构和内容 .
4. 默认先查看 diff , 再决定是否写回 .
5. 脚本重复运行时 , 结果应保持不变 .

## 后续扩展

如果以后需要统一标题、列表、表格或连续空行 , 应增加独立规则 , 并为容易误改的情况补充示例 .

不要直接把所有 Markdown 交给解析器重新渲染 . 重新渲染可能改变原有换行、列表写法和局部空格 , 局部格式化应优先保留原文结构 .
