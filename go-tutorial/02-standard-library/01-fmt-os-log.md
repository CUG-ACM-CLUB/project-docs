# fmt、os 和 slog

这篇介绍三个常见需求 : 输出文字、读取程序启动时的参数、记录运行情况 .

## 1. `fmt.Println` 输出一行文字

完整程序 :

```go
package main

import "fmt"

func main() {
	fmt.Println("hello")
	fmt.Println("分数", 90)
}
```

程序输出 :

```text
hello
分数 90
```

`fmt.Println` 可以接收多个值 . **它会在相邻参数之间添加空格 , 并在整行末尾添加换行 . **

签名 :

```go
func Println(a ...any) (n int, err error)
```

- `...any` 表示调用方可以传入任意数量、不同类型的参数 .
- 函数返回两个值 : `n` 的类型是 `int` , 表示写出的字节数 ; `err` 的类型是 `error` , 表示输出是否失败 .

- 上面的例子没有保存返回值 . Go 允许把函数调用单独写成一条语句 , 不使用它的返回值 .

## 2. `Printf` 按模板输出 , `Sprintf` 返回字符串

局部片段 , 放在 `main` 中并导入 `fmt` :

```go
name := "Lin"
score := 90
fmt.Printf("姓名: %s, 分数: %d\n", name, score)
```

`name` 的类型是 `string` , `score` 的类型是 `int` . 第一个参数是输出模板 , 后面的参数按顺序填入占位符 :

| 占位符 | 用途 | 本例对应的值 |
| --- | --- | --- |
| `%s` | 输出字符串 | `"Lin"` |
| `%d` | 按十进制输出整数 | `90` |
| `%v` | 自动推断 | 本例未使用 |
| `%T` | 输出值的类型 | 可以用来检查变量类型 |

程序输出 `姓名: Lin, 分数: 90` . 模板中的 `\n` 表示换行 ; `Printf` 不会自行添加换行 .

签名 :

```go
func Printf(format string, a ...any) (n int, err error)
func Sprintf(format string, a ...any) string
```

`Printf` 输出文字 , 返回字节数 `int` 和错误 `error` . `Sprintf` 返回一个 `string` , 不输出文字 :

```go
message := fmt.Sprintf("分数: %d", score)
fmt.Println(message)
fmt.Printf("%T\n", message) // string
```

## 3. `fmt.Fprintln`

程序有两个常见的输出位置 : 标准输出用于正常结果 , 标准错误用于错误说明 . 直接在终端运行程序时 , 终端通常会同时显示这两处的内容 ; 其他程序可以分别收集它们 .

`os` 包提供三个变量 :

| 变量 | 类型 | 用途 |
| --- | --- | --- |
| `os.Stdin` | `*os.File` | 标准输入 , 通常连接终端输入 |
| `os.Stdout` | `*os.File` | 标准输出 |
| `os.Stderr` | `*os.File` | 标准错误 |

`*os.File` 是文件指针类型 . 这里的输入输出也由文件对象表示 .

`fmt.Println` 默认向 `os.Stdout` 输出 . 程序可以用 `fmt.Fprintln` 指定另一个输出位置 :

```go
fmt.Fprintln(os.Stderr, "输入格式错误")
```

这个片段需要导入 `fmt` 和 `os` . `Fprintln` 的第一个参数接收一个 `io.Writer` 接口值 , 表示数据要写到哪里 ; 剩余参数是输出内容 . 它也返回 `(int, error)` .

`*os.File` 满足 `io.Writer` 接口 , 所以 `os.Stderr` 可以作为第一个参数 . 后面的 [io 篇](./05-io-fs-embed.md) 会解释这个接口 .

## 4. `os.Args` 保存命令行参数

完整程序 :

```go
package main

import (
	"fmt"
	"os"
)

func main() {
	fmt.Println(os.Args)
	if len(os.Args) > 1 {
		fmt.Println("第一个参数:", os.Args[1])
	}
}
```

假设这个程序的名字是 `hello` , 启动命令是 `./hello Lin` , 那么 `os.Args` 大致是 `[]string{"./hello", "Lin"}` .

`os.Args` 是 `[]string` 类型的变量 , 不是函数 . `os.Args[0]` 保存启动时使用的程序名或路径 , 后面的元素保存命令行参数 .

如果没有额外参数 , 切片就没有下标 1 . 例子先检查 `len(os.Args) > 1` , 再读取这个位置 .

## 5. `os.Getenv` 读取环境变量

环境变量是一组 `key` 和 `value` . 启动程序的终端或其他程序可以通过环境变量传入配置 . 签名 :

```go
func Getenv(key string) string
func LookupEnv(key string) (string, bool)
```

下面的片段放在函数中 , 需要导入 `os` :

```go
mode := os.Getenv("APP_MODE")
value, exists := os.LookupEnv("APP_MODE")
```

`mode` 和 `value` 都是 `string` . `exists` 是 `bool` , 表示这个环境变量是否存在 .

如果环境变量不存在 , `Getenv` 返回空字符串 `""` . 如果环境变量存在但值为空 , `Getenv` 也返回 `""` . `LookupEnv` 的第二个返回值可以区分这两种情况 .

这两个函数读取的是当前进程的环境变量 , 不会主动寻找或读取 `.env` 文件 .

## 6. `os.Exit` 结束整个进程

```go
func Exit(code int)
```

`os.Exit(1)` 传入一个 `int` , 没有返回值 , 并且会立即结束整个进程 . 启动这个程序的调用方可以读取退出码 : 通常 `0` 表示成功 , 非 `0` 表示失败 .

`return` 结束当前函数 , `os.Exit` 结束整个进程 . `os.Exit` 不执行已经登记的 `defer` , 因此调用方应该先完成需要的清理 .

## 7. `slog` 记录运行情况

完整程序 :

```go
package main

import "log/slog"

func main() {
	slog.Info("开始处理", "count", 3)
	slog.Warn("输入不完整", "field", "name")
	slog.Error("处理失败", "reason", "文件不存在")
}
```

导入路径是 `log/slog` , 使用时的包名是 `slog` .

这三个函数都接收一段字符串说明 , 以及可选的日志字段 ; 它们没有返回值 . 以 `Info` 为例 , 签名是 :

```go
func Info(msg string, args ...any)
```

在 `slog.Info("开始处理", "count", 3)` 中 , `"开始处理"` 是说明 , `"count"` 是字段名 , 整数 `3` 是字段值 . 程序把说明和具体数据分别记录 , 开发者就可以按字段查找日志 . 这种记录方式叫作结构化日志 .

| 函数 | 级别 | 常见用途 |
| --- | --- | --- |
| `slog.Debug` | 调试 | 开发时查看细节 , 默认级别设置下不会输出 |
| `slog.Info` | 信息 | 记录正常进度 |
| `slog.Warn` | 警告 | 记录需要注意的情况 |
| `slog.Error` | 错误 | 记录一次失败 |

这些函数只记录日志 , 不会自动退出程序 . 日志默认带有时间、级别和说明 , 具体格式可以配置 ; 结构化日志也不一定使用 JSON .

## 小练习

1. `fmt.Sprintf("分数: %d", 90)` 的返回类型是什么 ? 它会直接输出文字吗 ?
2. 一个环境变量存在但内容为空时 , `LookupEnv` 的两个返回值分别是什么 ?
3. 程序调用 `slog.Error` 后 , 下一行代码还会执行吗 ?

查阅签名时 , 可以在 Go 官方文档中搜索包名 `fmt`、`os` 和 `log/slog` .

下一篇 : [context](./02-context.md) .
