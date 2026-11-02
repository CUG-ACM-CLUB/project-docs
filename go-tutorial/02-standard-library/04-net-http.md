# net 和 net/http

浏览器打开网页时 , 会向 server 发送 HTTP request . server 处理 request , 再返回 HTTP response .

`net` 包提供 connection 和监听能力 , `net/http` 包在这些能力之上处理 HTTP . 本篇先写一个返回文字的小服务 , 再解释其中的代码 .

## 1. 一个完整程序

下面的程序监听本机 `8080` 端口 . 浏览器访问这个地址后 , 会收到 `hello` .

```go
package main

import (
	"fmt"
	"net"
	"net/http"
)

func hello(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintln(w, "hello")
}

func main() {
	// 创建 listener。
	listener, err := net.Listen("tcp", "127.0.0.1:8080")
	if err != nil {
		fmt.Println(err)
		return
	}

	// 将 hello 转换为满足 http.Handler interface 的值。
	handler := http.HandlerFunc(hello)

	// 创建 server，并指定 handler。
	server := &http.Server{
		Handler: handler,
	}

	// server 通过 listener 接收 connection，并处理 HTTP request。
	err = server.Serve(listener)
	if err != nil {
		fmt.Println(err)
	}
}
```

先按启动顺序阅读 : 第二节解释 `listener` , 第三节解释 `handler` 的 conversion 和 server 配置 , 第四节解释 `Serve` 的执行过程 . 第五、六节再分别讲解 handler 怎样读取 request、写回 response .

## 2. `net.Listen` 创建 listener

程序首先调用 :

```go
listener, err := net.Listen("tcp", "127.0.0.1:8080")
```

`listener` 的类型是 `net.Listener` , 供 server 接收 connection .

`net.Listen` 的定义是 :

```go
func Listen(network, address string) (Listener, error) {
	var lc ListenConfig
	return lc.Listen(context.Background(), network, address)
}
```

`Listen` 接收两个 `string` 参数 , 返回 `net.Listener` 和 `error` . 如果端口已经被其他程序占用 , 监听可能失败 . 程序必须先检查 `err` , 再使用 `listener` .

程序也可以用 `defer` 安排关闭 listener :

```go
listener, err := net.Listen("tcp", "127.0.0.1:8080")
if err != nil {
	return err
}
defer listener.Close()
```

`listener.Close()` 用来停止监听 , 返回类型是 `error` . 这个片段没有保存关闭时返回的错误 .

## 3. 把 `hello` 交给 server

第一节的 `hello` 是处理 request 的 function . 本节只解释怎样把它交给 server ; 参数 `w`、`r` 的类型和用途见第五、六节 .

程序不能直接写 `Handler: hello` . `http.Server` 的 `Handler` field 类型是 `http.Handler` interface , 要求传入的值提供 `ServeHTTP` method :

```go
type Handler interface {
	ServeHTTP(ResponseWriter, *Request)
}
```

普通 function `hello` 没有这个 method . 程序需要先执行 :

```go
handler := http.HandlerFunc(hello)
```

标准库定义的 `http.HandlerFunc` 是一个 function type :

```go
type HandlerFunc func(ResponseWriter, *Request)
```

标准库还为这个类型提供了 `ServeHTTP` method , 因此 `http.HandlerFunc` 满足 `http.Handler` interface .

`http.HandlerFunc(hello)` 是 type conversion : 它把 `hello` 转换为 `http.HandlerFunc` 类型的值 , 再保存到变量 `handler` . conversion 不会执行 `hello` .

因此 , 程序可以把 `handler` 赋给 server 的 `Handler` field . server 何时调用它 , 见第四节 .

```go
server := &http.Server{
	Handler: handler,
}
```

## 4. `Serve` 接收 connection 并调用 handler

程序创建 server 后 , 调用 :

```go
err = server.Serve(listener)
```

`Serve` 的签名是 :

```go
func (s *Server) Serve(l net.Listener) error
```

`Serve` 接收已经创建的 listener , 返回一个 `error` . 服务正常运行期间 , `Serve` 会持续接收和处理 connection , 不会立即返回 ; 外层 function 也不会越过这个调用提前返回(即使 `return` 也会运行) .

server 收到 HTTP request 后 , 会调用 `handler.ServeHTTP(w, r)` . 这个 method 内部再调用 `hello(w, r)` .

多个 request 可以并发处理 . 因此 , 如果 handler 修改共享变量 , 程序还需要考虑同步问题 .

## 5. handler 怎样读取 request

第三节中 `ServeHTTP(ResponseWriter, *Request)` 签名中有两个参数 , 没有返回值 . 两个参数的作用如下 :

| 参数类型 | 含义 |
| --- | --- |
| `http.ResponseWriter` | interface , handler 通过它写回 response , 具体操作见第六节 |
| `*http.Request` | request 指针 , 保存 method、URL、header 等信息 |

示例中的 `hello` 用变量 `r` 接收 `*http.Request` . handler 可以通过下面的 field 和 method 读取 request :

| 写法 | 类型 | 含义 |
| --- | --- | --- |
| `r.Method` | `string` | request method , 例如 `"GET"` |
| `r.URL` | `*url.URL` | URL struct 指针 |
| `r.URL.Path` | `string` | 路径 , 例如 `"/hello"` |
| `r.Header` | `http.Header` | request header , 底层类型是 `map[string][]string` |
| `r.Context()` | `context.Context` | 与这次 request 关联的 context |

`url.URL` 来自 `net/url` 包 , 它保存 URL 的组成部分 . 本篇不展开 URL 解析 .

handler 可以根据 request 的 method 和路径决定如何写回 response , 不必为每个路径建立一个新的 server .

> [!NOTE]
>
> 浏览器访问 : `http://127.0.0.1:8080/hello?name=Lin`
>
> server 收到 request 后 , 会把 request 信息传给 `hello` 的参数 `r` . 你可以把第一节的 `hello` 换成 :
>
> ```
> func hello(w http.ResponseWriter , r *http.Request) {
> 	fmt.Println(r.Method)
> 	fmt.Println(r.URL.Path)
> 	fmt.Println(r.URL.RawQuery)
> 
> 	fmt.Fprintln(w , "hello" )
> }
> ```
>
> - `r.Method` 的类型是 `string` , 保存 request method .
> - `r.URL.Path` 的类型是 `string` , 保存 URL 中的路径 .
> - `r.URL.RawQuery` 的类型是 `string` , 保存 URL 中 `?` 后面的内容 .
>
> 这次访问会让 **Go 程序的终端**输出 :
>
> ```
> GET
> /hello
> name=Lin
> ```

## 6. handler 怎样写回 response

handler 不通过返回字符串来回答浏览器 , 而是通过 `http.ResponseWriter` 写出内容 .

第一节的 `hello` 使用 :

```go
fmt.Fprintln(w, "hello")
```

这条语句把文字 `hello` 写入 response body .

handler 还可以设置 response header 和 status code . 下面的片段需要导入 `fmt` 和 `net/http` :

```go
handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "text/plain; charset=utf-8")
	w.WriteHeader(http.StatusOK)
	fmt.Fprintln(w, "hello")
})
```

这个例子把第一节的具名 function `hello` 换成了匿名 function . conversion 的作用和 `handler` 的类型与第三节相同 , 调用时机见第四节 .

参数类型沿用第五节的说明 . 三条语句分别执行以下操作 :

- `w.Header()` 返回 `http.Header` . `Set` 接收两个 `string` , 没有返回值 ; 这里设置 response 的内容类型 .
- `w.WriteHeader(...)` 接收一个 `int` status code , 没有返回值 . `http.StatusOK` 的值是 `200` .
- `fmt.Fprintln(w, "hello")` 的作用见本节开头 . 这里能够把 `w` 传给 `Fprintln` , 是因为 `http.ResponseWriter` 满足 `io.Writer` interface ; `io.Writer` 的定义会在 [io 篇第四节](./05-io-fs-embed.md#4-iowriter-接口) 讲解 .

handler 应先设置 response header , 再写 status code 或 body . 如果 handler 没有显式写 status code , 第一次写 body 时通常会使用 `200` .

## 接下来阅读

请按顺序读完下面两篇 , 再进入文件读写章节 :

1. [http.Client：发送请求](./http/01-client.md)
2. [服务关闭、超时和回调](./http/02-shutdown-and-options.md)

## 小练习

1. `net.Listen` 的两个返回值分别是什么类型 ?
2. `http.HandlerFunc(func(...) {...})` 为什么不是立即执行匿名 function ?
3. handler 通过哪个参数把 `hello` 写回浏览器 ?

查阅签名时 , 可以在 Go 官方文档中搜索 `net` 和 `net/http` .
