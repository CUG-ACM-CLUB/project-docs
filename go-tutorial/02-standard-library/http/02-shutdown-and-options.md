# 服务关闭、timeout 和 callback

本篇先给 `02/04` 中的 server 增加关闭流程 , 再介绍 `http.Server` 和 `http.Client` 的几个常见配置 .

`listener`、handler conversion 和 `Serve` 的基础用法见 [02/04](../04-net-http.md) . 本篇不重复解释这些基础概念 .

## 1. 一个带关闭流程的 server

下面的程序启动一个 server , 并等待 Unix 系统发送退出 signal . 程序收到 signal 后 , 会先等待正在处理的 request 结束 , 再退出 .

```go
package main

import (
	"context"
	"errors"
	"fmt"
	"net"
	"net/http"
	"os/signal"
	"syscall"
	"time"
)

func hello(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintln(w, "hello")
}

func run() error {
	ctx, stop := signal.NotifyContext(
		context.Background(),
		syscall.SIGINT,
		syscall.SIGTERM,
	)
	defer stop()

	listener, err := net.Listen("tcp", "127.0.0.1:8080")
	if err != nil {
		return err
	}

	server := &http.Server{
		Handler: http.HandlerFunc(hello),
	}
	serveDone := make(chan error, 1)
	go func() {
		serveDone <- server.Serve(listener)
	}()

	select {
	case <-ctx.Done():
	case err := <-serveDone:
		return err
	}

	shutdownCtx, cancel := context.WithTimeout(
		context.Background(),
		3*time.Second,
	)
	defer cancel()

	shutdownErr := server.Shutdown(shutdownCtx)
	if shutdownErr != nil {
		_ = server.Close()
	}

	serveErr := <-serveDone
	if errors.Is(serveErr, http.ErrServerClosed) {
		serveErr = nil
	}
	return errors.Join(serveErr, shutdownErr)
}

func main() {
	if err := run(); err != nil {
		fmt.Println(err)
	}
}
```

这个例子面向 Unix 系统 . 程序运行后 , 在终端按下 `Ctrl+C` , 系统会发送 `SIGINT` . `NotifyContext` 和 `stop()` 的作用见 [time 和 signal 篇第六节](../03-time-signal.md#6-notifycontext-把信号转换成取消通知) .

程序启动后 , 有两个执行过程 :

- 新的 goroutine 调用 `server.Serve(listener)` . 这个调用结束后 , goroutine 把返回的 `error` 发送到 `serveDone` .
- `run` 等待 signal 或 `Serve` 先结束 . 收到 signal 后 , `run` 调用 `Shutdown` ; `Shutdown` 结束后 , `run` 再读取 `serveDone` .

`serveDone` 的类型是 `chan error` , 容量是 `1` . 这个 channel 用来传递 `Serve` 的结果 ; 即使 `run` 还没有接收 , 发送方也可以先保存一条结果 . channel 和 `select` 的语法见 [01/08](../../01-language/08-goroutine-channel.md) .

`select` 的第二个 branch 接收 `serveDone` . 如果 `Serve` 在 signal 到达前就结束 , `run` 会直接返回这个 error , 不会一直等待 signal .

## 2. `Shutdown` 和 `Close`

关闭 server 的代码是 :

```go
shutdownCtx, cancel := context.WithTimeout(
	context.Background(),
	3*time.Second,
)
defer cancel()

shutdownErr := server.Shutdown(shutdownCtx)
if shutdownErr != nil {
	_ = server.Close()
}
```

这段代码中 , 变量的类型是 :

| 变量 | 类型 | 含义 |
| --- | --- | --- |
| `shutdownCtx` | `context.Context` | 限制关闭操作的等待时间 |
| `cancel` | `context.CancelFunc` | 取消这个 timeout 的 function |
| `shutdownErr` | `error` | `Shutdown` 返回的结果 |

`cancel()` 为什么可以调用 , 以及 `defer cancel()` 何时执行 , 见 [context 篇第三、五节](../02-context.md#3-withcancel-返回-context-和函数) .

两个 method 的签名是 :

```go
func (s *Server) Shutdown(ctx context.Context) error
func (s *Server) Close() error
```

- `Shutdown` 关闭 listener , 停止接收新的 connection , 并等待正在处理的普通 request 结束 . `Shutdown` 接收 `context.Context` , 返回 `error` .
- `Close` 不等待这些 request 正常结束 , 而是关闭相关 connection . `Close` 不接收参数 , 返回 `error` .

本例给 `Shutdown` 最多三秒的等待时间 . 如果 `Shutdown` 返回 error , 程序再调用 `Close` . `_ = server.Close()` 表示程序执行 `Close` , 但不保存它返回的 error ; 本例保留的是 `shutdownErr` .

程序使用新的 `context.Background()` 创建 `shutdownCtx` . 收到 signal 后 , 原来的 `ctx` 已经取消 ; 如果程序继续使用原来的 `ctx` , 关闭操作就没有三秒等待时间 .

这些 method 针对普通 HTTP connection . WebSocket 等被其他代码接管的 connection , 需要程序另外管理 .

## 3. 为什么还要等待 `Serve` 的结果

关闭代码的最后一部分是 :

```go
serveErr := <-serveDone
if errors.Is(serveErr, http.ErrServerClosed) {
	serveErr = nil
}
return errors.Join(serveErr, shutdownErr)
```

`serveErr` 的类型是 `error` , 它来自第一节 goroutine 中的 `server.Serve(listener)` .

调用 `Shutdown` 后 , `Serve` 会返回 `http.ErrServerClosed` . 这是标准库提供的 `error` , 表示 server 按照预期关闭 . 程序使用 `errors.Is` 检查这个 error ; 如果匹配 , 程序把 `serveErr` 改成 `nil` .

`errors.Is` 返回 `bool` , `errors.Join` 返回 `error` . `errors.Join` 把 `Serve` 和 `Shutdown` 的 error 合成一个 error ; 如果所有 error 都是 `nil` , 它返回 `nil` . 具体用法见 [errors 篇第四、六节](../06-errors.md#4-errorsis-检查错误值) .

`Serve` 返回和全部 request 处理结束不是同一个事件 :

```text
Shutdown 关闭 listener
    → Serve 可以返回 ErrServerClosed
    → Shutdown 可能仍在等待活动 request 结束
```

因此 , 程序不能只看到 `Serve` 返回就结束整个 process . 第一节先等待 `Shutdown` 返回 , 再读取 `Serve` 的结果 ; 两个调用都有结果后 , `run` 才返回 .

`Shutdown` 也不负责停止程序自己创建的所有后台 goroutine . 那些任务仍然需要程序通过 context、channel 等方式管理 .

## 4. `http.Server` 的 timeout field

下面是一个完整程序 . 这个程序只展示 `http.Server` 的配置 , 不启动 server :

```go
package main

import (
	"fmt"
	"net/http"
	"time"
)

func main() {
	server := &http.Server{
		Addr:              "127.0.0.1:8080",
		ReadHeaderTimeout: 2 * time.Second,
		ReadTimeout:       5 * time.Second,
		WriteTimeout:      10 * time.Second,
		IdleTimeout:       30 * time.Second,
	}

	fmt.Printf("%T\n", server)
}
```

`server` 的类型是 `*http.Server` . `Addr` 的类型是 `string` , 四个 timeout field 的类型都是 `time.Duration` .

| field | 限制的阶段 |
| --- | --- |
| `ReadHeaderTimeout` | 读取 request header |
| `ReadTimeout` | 读取整个 request , 包括 request body |
| `WriteTimeout` | 写 response |
| `IdleTimeout` | 一条 connection 等待下一个 request |

一条 connection 可以被后续 request 继续使用 . `IdleTimeout` 限制的是这段没有新 request 的等待时间 .

这些限制不是依次相加的总时间 , 也不能保证正在执行的 handler 到点后自行停止 . handler 中的 operation 仍然需要按要求处理取消通知 .

`Addr` 的使用取决于程序怎样启动 server :

- `server.ListenAndServe()` 按 `Addr` 创建 listener , 再开始 service . 这个 method 不接收参数 , 返回 `error` .
- `server.Serve(listener)` 使用已经传入的 listener , 不会再按 `Addr` 打开另一个 port . 第一节使用的是这种方式 .

## 5. `CheckRedirect` : 由 client 调用的 function

假设 client 请求 `/old` , server 返回 redirect response , 要求 client 改为访问 `/new` . client 可以通过 `CheckRedirect` 决定是否继续 redirect .

下面是一个完整程序 . 它创建一个带 `CheckRedirect` 的 client , 但不发送 request :

```go
package main

import (
	"fmt"
	"net/http"
)

func main() {
	client := &http.Client{
		CheckRedirect: func(
			req *http.Request,
			via []*http.Request,
		) error {
			return http.ErrUseLastResponse
		},
	}

	fmt.Printf("%T\n", client)
}
```

`client` 的类型是 `*http.Client` . `CheckRedirect` field 保存一个 function , 它的类型是 :

```go
func(req *http.Request, via []*http.Request) error
```

| 参数或返回值 | 类型 | 含义 |
| --- | --- | --- |
| `req` | `*http.Request` | client 准备发送的下一次 request |
| `via` | `[]*http.Request` | 这次 redirect 之前已经发送的 request 列表 |
| 返回值 | `error` | 决定 client 是否继续 redirect |

创建 `client` 时 , 匿名 function 不执行 . client 在 `Do` 处理 redirect、准备继续发送 request 时 , 才调用这个 function , 并传入 `req` 和 `via` . 程序员不需要自己填写这两个参数 .

这种先交给 library 保存 , 之后由 library 在指定时机调用的 function , 称为 callback .

- callback 返回 `nil` : 允许 client 继续 redirect .
- callback 返回 `http.ErrUseLastResponse` : client 不跟随 redirect , 把当前 response 交给 `Do` 的调用方 . 这个特殊返回值不会单独使 `Do` 返回非 nil error , 调用方仍然负责关闭 response body .

`Do` 的返回值和 body 的关闭要求见 [上一篇第四节](./01-client.md#4-发送-request并得到-response) .

## 6. `BaseContext` : 由 server 调用的 function

下面是一个完整程序 . 这个程序只展示 `BaseContext` 的配置 , 不创建 listener , 也不调用 `Serve` :

```go
package main

import (
	"context"
	"fmt"
	"net"
	"net/http"
)

func main() {
	root, cancel := context.WithCancel(context.Background())
	defer cancel()

	server := &http.Server{
		BaseContext: func(listener net.Listener) context.Context {
			return root
		},
	}

	fmt.Printf("%T\n", server)
}
```

`root` 的类型是 `context.Context` , `cancel` 的类型是 `context.CancelFunc` , `server` 的类型是 `*http.Server` .

`BaseContext` field 保存一个 callback , 它的类型是 :

```go
func(net.Listener) context.Context
```

server 调用这个 function 时 , 会把自己使用的 listener 作为 `net.Listener` 参数传入 . 这个 function 返回一个 `context.Context` , 作为 server 处理 connection 时的基础 context .

本例的 callback 没有使用参数 `listener` , 而是返回外层变量 `root` . Go 允许 function 不使用已经声明的参数 .

配置 `BaseContext` 时 , callback 不会执行 ; server 开始 service 时才会调用它 . 这与第五节 "先保存 function , 之后由 library 调用" 的方式相同 .

> [!NOTE]
>
> ## callback 回调函数
>
> ```go
> // 这段例子的输出是
> // 	开始工作
> // 	工作完成
> // 	收到完成通知
> 
> package main
> 
> import "fmt"
> 
> func work(done func()) {
> 	fmt.Println( "开始工作" )
> 	fmt.Println( "工作完成" )
> 	done()
> }
> 
> func main() {
> 	work(func() {
> 		fmt.Println( "收到完成通知" )
> 	})
> }
> ```
>
> - `main` 把匿名 function 传给 `work` , 这个 function 就是 callback .
> - `work` 用参数 `done` 保存它 . `done` 的类型是 `func()` .
> - `work` 执行到 `done()` 时 , 才调用这个 callback , 输出 "收到完成通知" .
>
> **callback 不一定在后台执行 , 也不一定异步 . 上面的调用全部按顺序执行 . **

server 的 request context 会由基础 context 派生 . 因此 , 程序调用 `cancel()` 取消 `root` 后 , 取消通知可以传给这些 request . parent-child context 的关系见 [context 篇第六节](../02-context.md#6-父子-context-怎样关联) .

## 小练习

1. 第一节为什么不能只等待 `Serve` 返回 , 就直接结束 process ?
2. `Shutdown` 的参数和返回值分别是什么类型 ?
3. `CheckRedirect` 的 `req` 和 `via` 由谁传入 ? 创建 client 时会执行这个 callback 吗 ?
4. `BaseContext` 返回 `root` , 为什么调用 `cancel()` 能通知 request ?

下一篇 : [io：读取和写入字节](../05-io-fs-embed.md) .
