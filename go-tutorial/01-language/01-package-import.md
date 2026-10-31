# 包、导入和文件

## 1. 包是什么

Go 用包（package）组织代码。一个包可以包含多个文件，供其他包调用。

```go
package main

import "fmt"

func main() {
	fmt.Println("hello")
}
```

`package main` 声明当前文件属于 `main` 包。`import "fmt"` 引入标准库的 `fmt` 包。`fmt.Println` 调用这个包中的函数。

`main` 包比较特殊：它是可执行程序的入口包，入口函数是 `func main()`。其他包通常提供可复用的功能。

## 2. 文件与包是什么关系

在当前项目中：

```text
cmd/acm/
├── main.go          package main
├── server.go        package main
└── server_test.go   package main
```

`main.go` 可以直接调用 `server.go` 的 `serveHTTP`，不需要导入 `server.go`。它们属于同一个包。

构建项目时使用的是包路径：

```bash
go build ./cmd/acm
```

不是只处理 `main.go`。普通构建不包含 `*_test.go`；测试命令才会编译测试文件。带构建条件的文件也可能被排除。

同名包不一定是同一个包。不同目录中的两个 `package practice`，仍然是两个包，要通过导入路径区分。

## 3. 导入路径从哪里来

项目的 `go.mod` 写着：

```go
module github.com/CUG-ACM-CLUB/acm-platform
```

所以项目内的目录 `internal/cli` 对应导入路径：

```go
import "github.com/CUG-ACM-CLUB/acm-platform/internal/cli"
```

这不表示每次都去 GitHub 下载它。Go 会根据当前 module 找到本地源码。

## 4. 三类包

| 类别 | 项目中的例子 | 来源 |
| --- | --- | --- |
| 标准库 | `fmt`、`os`、`net/http` | Go 提供 |
| 第三方包 | `github.com/gofiber/fiber/v2` | 项目的依赖 |
| 项目内部包 | `.../internal/cli` | 当前仓库 |

`import` 只对当前文件有效。即使 `server.go` 已导入 `context`，`main.go` 使用时仍要自己导入。

导入普通包后不使用，会报编译错误。

## 5. 别名与大写名字

项目中有：

```go
import practiceapp "github.com/CUG-ACM-CLUB/acm-platform/internal/application/practice"
```

`practiceapp` 是这个文件给包起的别名，因此使用 `practiceapp.New(...)`。别名没有修改被导入包的名字。

Go 通过名字的首字母判断成员是否向其他包公开：

```go
func Open() {} // 其他包可以调用
func open() {} // 只能在本包使用
```

同样的规则也用于类型、变量和结构体字段。`platform.Open` 公开，而 `main.go` 的 `env` 只在 `main` 包内使用。

`internal` 目录还限制导入范围。当前项目的 `internal` 包可供本项目代码使用，不是供任意外部项目导入的公共库。

## 对照项目

先打开 [main.go](../../../acm-platform/cmd/acm/main.go)，只看 `package` 和 `import`，暂不读 `serve()`。

找出标准库、项目包和导入别名。然后在同目录的 `server.go` 中找到 `serveHTTP`，确认它也属于 `package main`。

## 小练习

为什么 `main.go` 调用 `serveHTTP` 不用导入 `server.go`，调用 `cli.Run` 却需要导入 `cli`？

参考：[Go 语言规范：包](https://go.dev/ref/spec#Packages)。
