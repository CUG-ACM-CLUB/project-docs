# io : 读取和写入数据

程序经常需要读取和写入数据 . 数据可能来自字符串、文件或 HTTP response .

`io` 包用 `Reader` 和 `Writer` 两个 interface 描述这种能力 . 调用方只需要关心 "怎样读取”和“怎样写入" , 不需要先知道数据来自哪里 .

## 1. 一个完整程序

下面的程序从内存中的字符串读取数据 , 再把数据输出到终端 :

```go
package main

import (
	"fmt"
	"io"
	"strings"
)

func main() {
	reader := strings.NewReader("hello")

	body, err := io.ReadAll(reader)
	if err != nil {
		fmt.Println(err)
		return
	}

	fmt.Println(string(body))
}
```

程序输出 :

```text
hello
```

这段程序的执行过程是 :

1. `strings.NewReader("hello")` 创建一个数据来源 .
2. `io.ReadAll(reader)` 从这个数据来源读取全部内容 .
3. `io.ReadAll` 返回 `[]byte` 和 `error` .
4. `string(body)` 把字节切片转换成字符串 .
5. `fmt.Println` 把字符串输出到终端 .

本篇会解释 `reader` 为什么可以传给 `io.ReadAll` , 以及 `body` 为什么是 `[]byte` .

## 2. `io.Reader` 表示"可以读取"

`io.Reader` 是一个 interface :

```go
type Reader interface {
	Read(p []byte) (n int, err error)
}
```

这个 interface 只规定一个要求 : 具体类型必须提供 `Read` method .

`Read` 的参数和返回值如下 :

| 名字 | 类型 | 含义 |
| --- | --- | --- |
| `p` | `[]byte` | 调用方提供的接收空间 |
| `n` | `int` | 本次实际读取的字节数 |
| `err` | `error` | 本次读取的状态 |

`Read` 会把读取到的数据写入 `p` , 然后返回实际读取的字节数 `n` . 如果调用方提供了长度为 100 的 `p` , `Read` 也不保证一定读入 100 个字节 .

调用方只能使用 `p[:n]` 中的内容 :

```go
package main

import (
	"fmt"
	"strings"
)

func main() {
	reader := strings.NewReader("hello")
	buffer := make([]byte, 2)

	n, err := reader.Read(buffer)
	if err != nil {
		fmt.Println(err)
		return
	}

	fmt.Println(string(buffer[:n]))
}
```

程序输出 :

```text
he
```

`buffer` 的类型是 `[]byte` , 长度是 `2` . `reader.Read(buffer)` 返回的 `n` 是 `2` , 所以程序只把 `buffer[:2]` 转换成字符串 .

`buffer[:n]` 的意思是 : 取出从下标 `0` 到下标 `n` 之前的部分 . 切片规则见 [01/07](../01-language/07-collections.md) .

当数据来源已经没有内容时 , `Read` 可能返回 `io.EOF` . `io.EOF` 是一个 `error` 值 , 表示已经到达内容末尾 . 它不一定表示业务操作失败 .

一次 `Read` 也可能同时返回有效数据和 `io.EOF` . 调用方应该先处理本次已经读取到的 `n` 个字节 , 再根据 `err` 判断后续是否还有数据 .

## 3. `strings.Reader` 为什么可以传给 `io.ReadAll`

第一节中有这行代码 :

```go
reader := strings.NewReader("hello")
```

`strings.NewReader` 的签名是 :

```go
func NewReader(s string) *strings.Reader
```

这个 function 接收一个 `string` , 返回一个 `*strings.Reader` . 因此 , 变量 `reader` 的类型是 `*strings.Reader` .

`*strings.Reader` 是一个具体类型 . 它内部保存字符串内容和当前读取位置 , 并且提供 `Read` method .

因为 `*strings.Reader` 提供了 `Read([]byte) (int, error)` , 所以它满足 `io.Reader` interface . 需要 `io.Reader` 的 function 可以接收它 :

```go
func ReadAll(r Reader) ([]byte, error)
```

`io.ReadAll` 的参数类型是 `io.Reader` , 返回 `[]byte` 和 `error` . `reader` 虽然声明为 `*strings.Reader` , 但它满足这个 interface , 因此可以传入 :

```go
body, err := io.ReadAll(reader)
```

这里发生的是 interface 赋值和参数传递 , 不是把 `*strings.Reader` 转换成另一种具体结构体 .

## 4. `io.ReadAll` 返回全部剩余内容

下面的完整程序展示 `io.ReadAll` 的返回值 :

```go
package main

import (
	"fmt"
	"io"
	"strings"
)

func main() {
	reader := strings.NewReader("hello")

	body, err := io.ReadAll(reader)
	if err != nil {
		fmt.Println(err)
		return
	}

	fmt.Println(body)
	fmt.Println(string(body))
}
```

程序输出大致是 :

```text
[104 101 108 108 111]
hello
```

`body` 的类型是 `[]byte` . 程序直接输出 `body` 时 , `fmt` 会显示每个字节的整数值 ; 程序使用 `string(body)` 后 , 才会看到字符串内容 .

`err` 的类型是 `error` . `io.ReadAll` 正常读到末尾时会返回 `nil` , 不会把正常的 `io.EOF` 当作失败返回 .

`io.ReadAll` 从当前读取位置开始读取 , 不会自动回到数据开头 . 它也不会自动限制读取内容的大小 , 因此程序读取来源不可信的数据时 , 需要另外设置大小限制 .

## 5. `io.Writer` 表示"可以写入"

`io.Writer` 是另一个 interface :

```go
type Writer interface {
	Write(p []byte) (n int, err error)
}
```

`Write` 接收一段 `[]byte` , 返回实际写入的字节数 `int` 和错误 `error` .

下面的完整程序把同一段文字写到两个不同的 `Writer` :

```go
package main

import (
	"fmt"
	"os"
	"strings"
)

func main() {
	message := []byte("hello\n")

	_, err := os.Stdout.Write(message)
	if err != nil {
		fmt.Println(err)
		return
	}

	var builder strings.Builder
	_, err = builder.Write(message)
	if err != nil {
		fmt.Println(err)
		return
	}

	fmt.Print(builder.String())
}
```

`os.Stdout` 的类型是 `*os.File` , `builder` 的类型是 `strings.Builder` . 这两个具体类型都提供 `Write` method , 因此都满足 `io.Writer` interface .

`os.Stdout.Write(message)` 把字节写到终端 . `builder.Write(message)` 把字节保存到内存中 . 两个数据来源不同 , 但调用方使用的都是 `Write` .

这就是 interface 的作用 : 调用方只要求 "这个值可以写入" , 不需要为终端和内存分别设计不同的 function .

`fmt.Fprintln` 的第一个参数也是 `io.Writer` . 因此 , 标准输出、文件和 HTTP response 都可以作为它的第一个参数 . `fmt` 的输出方法见 [02/01](./01-fmt-os-log.md) .

## 6. 文件也是 `io.Reader`

`os.Open` 的签名是 :

```go
func Open(name string) (*File, error)
```

下面的完整程序读取当前目录中的 `hello.txt` :

```go
package main

import (
	"fmt"
	"io"
	"os"
)

func main() {
	file, err := os.Open("hello.txt")
	if err != nil {
		fmt.Println(err)
		return
	}
	defer file.Close()

	body, err := io.ReadAll(file)
	if err != nil {
		fmt.Println(err)
		return
	}

	fmt.Println(string(body))
}
```

`file` 的类型是 `*os.File` . `*os.File` 提供 `Read` method , 因此它满足 `io.Reader` interface , 可以作为 `io.ReadAll` 的参数 .

`file.Close()` 的签名是 :

```go
func (f *File) Close() error
```

`Close` 返回 `error` . 程序在成功打开文件后使用 `defer file.Close()` , 保证 `main` 返回时关闭文件 . 本例没有保存关闭时的错误 .

`io.ReadAll` 只负责读取 , 不负责关闭 `file` . 关闭文件是调用方的责任 .

## 7. HTTP response body 也是 `io.Reader`

在 [http.Client 篇](./http/01-client.md) 中 , `client.Do` 返回 `*http.Response` . `resp.Body` 的类型是 `io.ReadCloser` :

```go
type ReadCloser interface {
	Reader
	Closer
}

type Closer interface {
	Close() error
}
```

`ReadCloser` 同时要求 `Read` 和 `Close` method . 因此 , `resp.Body` 既可以读取 , 也必须关闭 .

下面的完整程序向本机 server 发送 `GET` request , 并读取 response body :

```go
package main

import (
	"fmt"
	"io"
	"net/http"
)

func main() {
	resp, err := http.Get("http://127.0.0.1:8080/")
	if err != nil {
		fmt.Println(err)
		return
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		fmt.Println(err)
		return
	}

	fmt.Println(string(body))
}
```

`http.Get` 返回 `*http.Response` 和 `error` . `resp.Body` 满足 `io.Reader` , 所以可以传给 `io.ReadAll` ; `resp.Body` 也满足 `io.Closer` , 所以调用方必须关闭它 .

读取和关闭 response body 有助于 HTTP client 复用 connection . 对于大小不受信任的 response body , 程序还应该先限制读取量 .

## 小练习

1. `*strings.Reader` 和 `io.Reader` 是同一种类型吗 ? 它们是什么关系 ?
2. `io.ReadAll` 返回什么类型 ? 它会替调用方关闭文件吗 ?
3. 为什么 `os.Stdout` 和 `strings.Builder` 都可以作为 `io.Writer` 使用 ?
4. 为什么 `resp.Body` 既可以传给 `io.ReadAll` , 又可以调用 `Close` ?

查阅签名时 , 可以在 Go 官方文档中搜索 `io`、`strings`、`os` 和 `net/http` .

下一篇 : [fs 和 embed](./files/01-fs-embed.md) .
