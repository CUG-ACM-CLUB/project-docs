# fs 和 embed : 访问文件

上一篇介绍了 `io.Reader` 和 `io.Writer` . 本篇介绍 `io/fs` 和 `embed` .

`fs.FS` 描述 "可以按照文件名打开文件" 的能力 . 文件可以来自磁盘 , 也可以来自编译时嵌入程序的资源 .

## 1. 从磁盘目录中读取文件

假设当前目录中有下面的文件 :

```text
notes/
└── intro.txt
```

`notes/intro.txt` 的内容是 :

```text
hello from file
```

下面的完整程序读取这个文件 :

```go
package main

import (
	"fmt"
	"os"
)

func main() {
	body, err := os.ReadFile("notes/intro.txt")
	if err != nil {
		fmt.Println(err)
		return
	}

	fmt.Println(string(body))
}
```

`os.ReadFile` 的签名是 :

```go
func ReadFile(name string) ([]byte, error)
```

这个 function 接收文件路径 `string` , 返回文件内容 `[]byte` 和错误 `error` .

程序使用 `string(body)` 把字节切片转换成字符串 , 再输出文件内容 .

这个例子直接使用磁盘路径 . 下一节把同一个目录转换成 `fs.FS` , 再使用文件名读取文件 .

## 2. `fs.FS` 表示一个文件系统

`io/fs` 包的包名是 `fs` . `fs.FS` 是一个 interface :

```go
type FS interface {
	Open(name string) (File, error)
}
```

这个 interface 只规定一个能力 : 程序可以传入文件名 , 打开对应的文件 . (它从起始目录开始 )

`Open` 接收文件名 `string` , 返回 `fs.File` 和 `error` . `fs.File` 也是 interface , 表示一个已经打开、可以读取和关闭的文件 .

`fs.FS` 不要求文件一定来自磁盘 . 只要某个具体类型提供 `Open(string) (fs.File, error)` method , 这个具体类型就满足 `fs.FS` .

## 3. `os.DirFS` 把目录变成 `fs.FS`

`os.DirFS` 的签名是 :

```go
func DirFS(dir string) fs.FS
```

下面的完整程序把 `notes` 目录变成一个 `fs.FS` :

```go
package main

import (
	"fmt"
	"io/fs"
	"os"
)

func main() {
	root := os.DirFS("notes")
	body, err := fs.ReadFile(root, "intro.txt")
	if err != nil {
		fmt.Println(err)
		return
	}

	fmt.Println(string(body))
}
```

`root` 的类型是 `fs.FS` . 在这个 file system 中 , `"intro.txt"` 对应磁盘上的 `notes/intro.txt` .

`os.DirFS("notes")` 本身不返回 `error` , 也不会在创建时确认目录一定存在 . 程序调用 `fs.ReadFile` 时 , 真正打开文件 ; 如果目录或文件不存在 , `fs.ReadFile` 会返回 `error` .

`os.DirFS` 不是安全 sandbox . 目录中的 symbolic link 可能指向目录之外 . 本篇只使用它说明 "目录可以提供 `fs.FS` 能力" .

## 4. `fs.ReadFile` 读取 `fs.FS`

`fs.ReadFile` 的签名是 :

```go
func ReadFile(fsys FS, name string) ([]byte, error)
```

这个 function 接收两个参数 :

| 参数 | 类型 | 含义 |
| --- | --- | --- |
| `fsys` | `fs.FS` | 提供文件的 file system |
| `name` | `string` | file system 内的相对文件名 |

它返回 `[]byte` 和 `error` . 它会打开文件、读取内容并关闭文件 , 调用方不需要自己调用 `Close` .

第一节的程序可以按下面方式理解 :

```text
root = os.DirFS("notes")
    → root 提供 fs.FS
    → fs.ReadFile(root, "intro.txt")
    → 读取 notes/intro.txt
    → 返回 []byte 和 error
```

如果程序只需要按普通磁盘路径读取文件 , 可以使用 `os.ReadFile("notes/intro.txt")` . 如果程序希望让读取 function 接受不同来源的 file system , 可以使用 `fs.ReadFile(fsys, name)` .

## 5. `embed.FS` 把文件放进程序

有些程序需要把固定的文字、模板或网页文件一起放进 executable . `embed` 包可以在 build 时把文件嵌入 executable .

> [!NOTE]
>
> `executable` 的意思是**可执行文件** .
>
> 它是已经被编译完成、可以直接启动运行的文件 . 例如 :
>
> ```
> go build -o app main.go
> ```
>
> 这条命令会生成一个名为 `app` 的 executable . 程序可以这样启动 :
>
> ```
> . /app
> ```
>
> `main.go` 是源代码 , 不能直接作为程序运行 ; `app` 是编译后的 executable , 可以被操作系统直接启动 .
>
> 在 `embed.FS` 中 :
>
> ```
> //go : embed assets/*
> var files embed.FS
> ```
>
> `assets` 文件会在 build 时被放入 executable 中 .
>
> 所以 , 即使程序运行时没有旁边的 `assets` 目录 , 程序仍然可以读取已经嵌入 executable 的文件 .
>
> 但如果修改了磁盘上的 `assets/hello.txt` , 已经生成的 executable 不会自动更新 . 程序必须重新 build , 新的文件内容才会进入新的 executable .

示例目录 :

```text
example/
├── main.go
└── assets/
    └── hello.txt
```

`assets/hello.txt` 的内容是 :

```text
hello from embedded file
```

`main.go` 是 :

```go
package main

import (
	"embed"
	"fmt"
)

//go:embed assets/*
var files embed.FS

func main() {
	body, err := files.ReadFile("assets/hello.txt")
	if err != nil {
		fmt.Println(err)
		return
	}

	fmt.Println(string(body))
}
```

`files` 的类型是 `embed.FS` . `embed.FS` 是一个具体类型 , 提供只读 file system 能力 .

`//go:embed assets/*` 是 Go 编译器识别的 directive , 不是普通注释 . 这个 directive 必须紧挨着包级 variable `files` , 路径相对于 `main.go` 所在的目录 .

> [!NOTE]
>
> "包级 variable `files`" 指的是 : **`files` 这个 variable 写在所有 function 的外面 , 属于当前 package . **相对的 , 写在函数中的就是 function-local variable .

> [!NOTE]
>
> 真正决定嵌入哪些文件的是 `//go:embed assets/*` 中的 `assets/*` .
>
> ```
> //go : embed assets/*
> var files embed.FS
> ```
>
> - `//go:embed` : 告诉 Go , 下一行的 variable 要保存嵌入的文件 .
> - `assets/*` : 指定要嵌入的文件路径 . 前面的绝对路径是 : **写有 `//go:embed` 的那个 `.go` 文件所在的文件夹 . **
> - `var files embed.FS` : 声明一个名为 `files` 的 variable , 用来保存这些嵌入的文件 .
>

`files.ReadFile("assets/hello.txt")` 返回 `[]byte` 和 `error` .

## 6. `embed.FS` 为什么可以传给 `fs.ReadFile`

`embed.FS` 不是 `fs.FS` interface 本身 , 它是一个具体类型 . 但是 , `embed.FS` 提供了 `Open` method , 所以它满足 `fs.FS` :

```text
embed.FS
    → 提供 Open(name string) (fs.File, error)
    → 满足 fs.FS
    → 可以传给 fs.ReadFile
```

下面的完整程序用 `fs.ReadFile` 读取嵌入资源 :

```go
package main

import (
	"embed"
	"fmt"
	"io/fs"
)

//go:embed assets/*
var files embed.FS

func main() {
  // 第五节中的是 
  // 		var files embed.FS
  // 		body, err := files.ReadFile("assets/hello.txt")
	body, err := fs.ReadFile(files, "assets/hello.txt")
	if err != nil {
		fmt.Println(err)
		return
	}

	fmt.Println(string(body))
}
```

这里的 `files` 变量类型是 `embed.FS` , 但 `fs.ReadFile` 的第一个参数类型是 `fs.FS` . Go 检查到 `embed.FS` 满足 `fs.FS` , 所以允许传入 .

## 7. `fs.Sub` 改变访问起点

`fs.Sub` 的签名是 :

```go
func Sub(fsys FS, dir string) (FS, error)
```

下面的完整程序先把 `assets` 变成新的访问起点 , 再读取 `hello.txt` :

```go
package main

import (
	"embed"
	"fmt"
	"io/fs"
)

//go:embed assets/*
var files embed.FS

func main() {
	assets, err := fs.Sub(files, "assets")
	if err != nil {
		fmt.Println(err)
		return
	}

	body, err := fs.ReadFile(assets, "hello.txt")
	if err != nil {
		fmt.Println(err)
		return
	}

	fmt.Println(string(body))
}
```

`assets` 的类型是 `fs.FS` , `body` 的类型是 `[]byte` , `err` 的类型是 `error` .

原来的 `files` 需要使用 `"assets/hello.txt"` . `fs.Sub(files, "assets")` 返回一个新的 `fs.FS` , 这个 file system 把原来的 `assets` 目录作为访问起点 , 因此后续只需要使用 `"hello.txt"` .

`fs.Sub` 不会复制文件 , 也不会新建磁盘目录 . 它只返回一个使用不同相对路径起点的 file system .

## 小练习

1. `embed.FS` 和 `fs.FS` 哪个是具体类型 , 哪个是 interface ?
2. 修改磁盘上的 `assets/hello.txt` 后 , 已经 build 的 executable 会自动读到新内容吗 ?
3. `fs.Sub(files, "assets")` 返回的两个值分别是什么类型 ?

查阅签名时 , 可以在 Go 官方文档中搜索 `io/fs` 和 `embed` .

下一篇 : [errors](../06-errors.md) .
