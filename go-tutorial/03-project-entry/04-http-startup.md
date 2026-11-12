# HTTP 启动和关闭

`serve()` 已经创建了三个重要对象：

```text
ctx       context.Context
server    *http.Server
listener  net.Listener
```

`serve()` 把这三个对象交给：

```go
serveHTTP(ctx, server, listener, platformServer.Tasks.Shutdown)
```

真实文件是：

```text
acm-platform/cmd/acm/server.go
```

本篇解释 `serveHTTP` 如何做到两件事：

1. 调用 `server.Serve(listener)`，开始接收 HTTP request。
2. 收到退出通知后，停止接收新 request，等待已有工作和后台 task 结束。

`http.Server`、`net.Listener`、context 和 channel 的基础知识已经在 [02/02](../02-standard-library/02-context.md)、[02/04](../02-standard-library/04-net-http.md) 和 [02/05](../02-standard-library/05-io-fs-embed.md) 中讲过。本篇只分析项目中的关闭顺序。

## 1. `server.Serve(listener)` 开始工作

`serveHTTP` 的签名是：

```go
func serveHTTP(
	ctx context.Context,
	server *http.Server,
	listener net.Listener,
	drain func(context.Context) error,
) error
```

参数的含义是：

| 参数 | 类型 | 用途 |
| --- | --- | --- |
| `ctx` | `context.Context` | 表示整个 server process 是否应该停止 |
| `server` | `*http.Server` | 接收 connection 并调用 handler |
| `listener` | `net.Listener` | 提供 TCP connection |
| `drain` | `func(context.Context) error` | 等待后台 agent task 清理 |

`serveHTTP` 创建关闭流程需要的两个 channel：

```go
stopped := make(chan struct{})
shutdownDone := make(chan error, 1)
```

两个 channel 的类型分别是 `chan struct{}` 和 `chan error`。它们不传递业务数据，只传递“某件事已经发生”的通知或错误：

- `stopped`：`server.Serve(listener)` 已经返回。
- `shutdownDone`：关闭 goroutine 已经完成，并把关闭结果写入 channel。

第二个 channel 的容量是 `1`。关闭 goroutine 最多向它发送一次 error，因此发送时不会因为接收方尚未开始接收而永久阻塞。

## 2. 关闭 goroutine 等待两个事件

`serveHTTP` 启动一个 goroutine：

```go
go func() {
	select {
	case <-ctx.Done():
	case <-stopped:
	}

	shutdown, cancel := context.WithTimeout(
		context.Background(),
		15*time.Second,
	)
	defer cancel()

	err := server.Shutdown(shutdown)
	if err != nil {
		_ = server.Close()
	}
	shutdownDone <- errors.Join(err, drain(shutdown))
}()
```

这个 goroutine 的第一段是：

```go
select {
case <-ctx.Done():
case <-stopped:
}
```

它等待下面两个事件中的任意一个：

| 事件 | 含义 |
| --- | --- |
| `ctx.Done()` 关闭 | process 收到退出通知，或者上层主动取消 context |
| `stopped` 关闭 | `server.Serve(listener)` 已经返回 |

这个设计保证关闭逻辑不会只依赖操作系统信号。如果 `Serve` 因为 listener 出错而提前返回，关闭 goroutine 仍然会执行清理。

## 3. `stopped` 为什么使用 `close`

主 goroutine 后面会执行：

```go
err := server.Serve(listener)
close(stopped)
```

`close(stopped)` 向所有等待这个 channel 的 goroutine 广播“`Serve` 已经返回”。

这里没有发送具体值：

```go
stopped <- struct{}{}
```

因为程序只关心事件是否发生，不关心事件中的数据。关闭 channel 更适合“一次事件通知多个等待者”。

`close` channel、从 channel 接收和 `select` 的基础规则已经在 [01/08](../01-language/08-goroutine-channel.md) 和 [02/02](../02-standard-library/02-context.md) 中讲过。

## 4. 创建 15 秒的 shutdown context

收到任意一个关闭触发事件后，关闭 goroutine 创建：

```go
shutdown, cancel := context.WithTimeout(
	context.Background(),
	15*time.Second,
)
defer cancel()
```

返回值类型是：

| 变量 | 类型 | 用途 |
| --- | --- | --- |
| `shutdown` | `context.Context` | 给关闭操作设置最多 15 秒的时间 |
| `cancel` | `context.CancelFunc` | 关闭这个 shutdown context，并释放 timer |

这里使用 `context.Background()` 作为 parent，而不是使用已经取消的 `ctx`。原因是：`ctx` 表示“开始关闭”，`shutdown` 表示“关闭过程最多允许执行 15 秒”。如果直接把已经取消的 `ctx` 作为 parent，关闭操作可能一开始就被取消，无法完成排空工作。

`context.WithTimeout` 和 `CancelFunc` 已经在 [02/02](../02-standard-library/02-context.md) 中讲过。

## 5. `server.Shutdown` 停止接收新 request

关闭 goroutine 调用：

```go
err := server.Shutdown(shutdown)
```

`server.Shutdown` 的作用是：

1. 关闭 listener，不再接收新的 connection。
2. 等待已有 connection 上的 handler 返回。
3. 等待时间受 `shutdown` context 的 15 秒限制。

`server.Shutdown` 返回一个 `error`。如果所有已有 request 都在 15 秒内结束，返回值通常是 `nil`。如果等待超时或关闭失败，返回非 `nil` 的 `error`。

`server.Serve(listener)` 和 `server.Shutdown(shutdown)` 是两个不同的调用：

```text
Serve(listener)
    └─ 持续接收 connection，并处理 request

Shutdown(shutdown)
    └─ 请求 Serve 停止接收新 connection，并等待已有 request
```

## 6. 超时后调用 `server.Close`

代码继续执行：

```go
if err != nil {
	_ = server.Close()
}
```

如果 `Shutdown` 没有在规定时间内完成，`server.Close()` 会强制关闭仍然打开的 connection。

`server.Close` 返回 `error`，但这里使用 `_` 丢弃它。程序已经拥有 `Shutdown` 返回的主要错误，关闭失败不会覆盖这个错误。

这段代码体现了两层关闭策略：

```text
先尝试优雅关闭
    ↓ 15 秒内完成
结束

15 秒后仍未完成
    ↓
强制关闭 connection
```

## 7. 等待后台 agent task

关闭 HTTP server 后，代码调用：

```go
shutdownDone <- errors.Join(err, drain(shutdown))
```

`drain` 是 `serve()` 传入的：

```go
platformServer.Tasks.Shutdown
```

它的 function type 是：

```go
func(context.Context) error
```

因此，`drain(shutdown)` 会等待 agent service 中仍然 active 的 task。`drain` 返回一个 `error`，表示后台 task 是否在 shutdown context 的时间限制内完成。

`errors.Join` 的签名是：

```go
func Join(errs ...error) error
```

它把多个可能的错误合并为一个 `error`：

```go
errors.Join(err, drain(shutdown))
```

如果两个错误都是 `nil`，结果是 `nil`。如果其中一个或两个不是 `nil`，结果保留这些错误，供调用方继续检查。

`errors.Join` 和 `error` 包已经在 [02/06](../02-standard-library/06-errors.md) 中讲过。

## 8. 主 goroutine 等待 `Serve` 和关闭流程

主 goroutine 在启动关闭 goroutine 后，执行：

```go
err := server.Serve(listener)
close(stopped)
shutdownErr := <-shutdownDone
```

执行顺序是：

1. `server.Serve(listener)` 阻塞，直到 listener 关闭或 server 发生错误。
2. `Serve` 返回后，主 goroutine 关闭 `stopped`。
3. 关闭 goroutine 收到 `stopped`，执行 `Shutdown` 和 `drain`。
4. 关闭 goroutine 把最终错误写入 `shutdownDone`。
5. 主 goroutine 从 `shutdownDone` 接收 `shutdownErr`。

`Serve` 返回后，关闭流程可能还没有完成。特别是已有 handler 可能仍在运行，因此程序不能在 `Serve` 返回后立即结束 `serveHTTP`。

这就是 `shutdownDone` 存在的原因：

```text
Serve 返回
    ↓
关闭 listener
    ↓
等待 active request
    ↓
等待 active agent task
    ↓
serveHTTP 才能返回
```

## 9. 处理 `http.ErrServerClosed`

HTTP server 在正常调用 `Shutdown` 或 `Close` 后，`Serve` 通常返回：

```go
http.ErrServerClosed
```

这不是程序启动失败，而是标准库用来表示“server 已经被要求关闭”的 sentinel error。

代码把这个正常关闭结果转换为 `nil`：

```go
if errors.Is(err, http.ErrServerClosed) {
	err = nil
}
```

这里使用 `errors.Is`，而不是直接比较 `err == http.ErrServerClosed`，因为错误可能被其他 error 包装。

正常退出时，最终结果是：

```go
return errors.Join(err, shutdownErr)
```

如果 `Serve` 返回的是正常关闭错误，并且 `Shutdown` 与 `drain` 都成功，`serveHTTP` 返回 `nil`。随后 `serve()` 返回 `nil`，`main` 正常结束，不会记录“server stopped”错误。

## 10. 完整关闭时序

当 process 收到 `SIGTERM` 时，完整流程如下：

```text
操作系统发送 SIGTERM
        ↓
NotifyContext 关闭 ctx.Done()
        ↓
关闭 goroutine 开始执行
        ↓
server.Shutdown(shutdown)
        ↓
停止接收新的 connection
        ↓
等待已有 HTTP handler 返回
        ↓
platformServer.Tasks.Shutdown(shutdown)
        ↓
等待 active agent task 结束
        ↓
关闭 goroutine 写入 shutdownDone
        ↓
serveHTTP 返回
        ↓
serve() 返回
        ↓
main 正常结束
```

如果 HTTP request 没有在 15 秒内结束，程序会调用 `server.Close()`。如果 agent task 也没有在同一个 shutdown context 的截止时间前结束，`drain` 会返回 timeout error，`serveHTTP` 会把它交给 `main`。

## 小结

`serveHTTP` 的核心不是“启动一个 function”，而是同时管理两个生命周期：

- HTTP server 的 connection 和 request 生命周期。
- agent task 的后台执行生命周期。

它先让 `Serve` 工作，再通过 `ctx.Done()`、`Shutdown`、`Close` 和 `drain` 按顺序完成关闭。

下一篇：[Docker 构建和运行](./05-docker-build.md)。
