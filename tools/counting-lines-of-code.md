# Motivation

想统计一下一个项目到底有多少行代码 有两个工具 `cloc` 和 `tokei` . 运行环境是 `macos` .

## cloc

cloc 会分别统计文件数、代码行、注释行和空行。(cloc.sourceforge.net)

- https://cloc.sourceforge.net/
- https://github.com/AlDanial/cloc

### install

```bash
brew install cloc
cloc --version
```

### Usage

```bash
cd /path/to/your-project

# 统计整个项目：
cloc .

# 统计 Git 已跟踪文件：
cloc --vcs=git .

# 只统计 Go 文件：
cloc --include-lang=Go .

# 排除目录：
cloc --exclude-dir=node_modules,vendor,dist,build .

# 输出 JSON：
cloc --vcs=git --json . > cloc.json
```

### Example

```bash
cloc --vcs=git .
```

```text
      96 text files.
      90 unique files.                              
       6 files ignored.

github.com/AlDanial/cloc v 2.10  T=0.60 s (151.1 files/s, 16569.1 lines/s)
-------------------------------------------------------------------------------
Language                     files          blank        comment           code
-------------------------------------------------------------------------------
Go                              56            400             23           6121
JavaScript                      13             18             15           1368
Markdown                         8            320              0            966
CSS                              1              0              0            173
YAML                             2              8              0            170
SQL                              1              0              0            124
Bourne Shell                     4              2              0            100
Dockerfile                       1              3              0             25
HTML                             1              0              0             17
C++                              2              0              0             12
JSON                             1              0              0              7
-------------------------------------------------------------------------------
SUM:                            90            751             38           9083
-------------------------------------------------------------------------------
```

## tokei

- https://github.com/XAMPPRocky/tokei

### install

```bash
brew install tokei
tokei --version
```

### Usage

```bash
#  统计整个项目：
tokei .

# 统计当前 Git 项目：
tokei

# 只统计 Go：
tokei --type Go

# 排除目录：
tokei . --exclude node_modules --exclude vendor

# 输出 JSON：
tokei . --output json > tokei.json
```

`tokei` 通常会遵守 `.gitignore` 和 `.ignore`，也可以用 `--exclude` 添加额外排除规则。

### Example

```bash
tokei .
```

```text
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Language              Files        Lines         Code     Comments       Blanks
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 C++                       2           12           12            0            0
 CSS                       1          173          173            0            0
 Dockerfile                1           28           25            0            3
 Go                       56         6544         6121           23          400
 HTML                      1           17           17            0            0
 JavaScript               13         1401         1368           15           18
 JSON                      1            7            7            0            0
 Shell                     4          102           96            4            2
 SQL                       1          124          124            0            0
 YAML                      2          178          170            0            8
─────────────────────────────────────────────────────────────────────────────────
 Markdown                  8         1181            0          861          320
 |- BASH                   2          105          102            3            0
 (Total)                             1286          102          864          320
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Total                    90         9872         8215          906          751
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Practice

日常快速查看：

```bash
tokei
```

需要更详细、可导出的报告：

```bash
cloc --vcs=git .
```
