# HTTP 服务运行与关闭

打开 [cmd/acm/server.go](../../../acm-platform/cmd/acm/server.go) . `serveHTTP` 一边运行 HTTP server , 一边用另一个 goroutine 等待关闭通知 .

## 参数与通知

### 参数

四个参数都来自上一篇的 `serve()` :

1. `ctx` 的类型是 `context.Context` , 用于接收退出通知 .
2. `server` 的类型是 `*http.Server` , 已经配置了项目的 handler .
3. `listener` 的类型是 `net.Listener` , 已经监听了 TCP 端口 .
4. `drain` 的类型是 `func(context.Context) error` , 保存传入的 `platformServer.Tasks.Shutdown` . `drain(shutdown)` 就是对这个 `Tasks` 对象调用 `Shutdown(shutdown)` . `drain` 是参数名 , 不是 Go 关键字 .

### 通知 channel

1. `stopped := make(chan struct{})` 创建 `chan struct{}` . 调用 `Serve` 的 goroutine 在 `Serve` 返回后关闭它 , 通知关闭 goroutine . 当前代码不向它发送值 .
2. `shutdownDone := make(chan error, 1)` 创建容量为 1 的 `chan error` . 关闭 goroutine 向它发送一次结果 , 调用 `Serve` 的 goroutine 接收结果 .
3. 容量为 1 表示发送方可以先放入一个结果 , 不必等接收方同时执行接收 . 成功时发送的是 `nil` , 也占一个位置 .
4. `stopped` 表示 `Serve` 已返回 ; `shutdownDone` 中的结果表示 `Shutdown` 和 `drain` 都已返回 . 两个通知对应不同的完成状态 .

## 并发执行

### HTTP 服务与关闭 goroutine

1. `go func() { ... }()` 中 , 最后的 `()` 调用匿名 function , 前面的 `go` 让它在新的 goroutine 中执行关闭逻辑 .
2. 当前 goroutine 继续执行 `server.Serve(listener)` . `Serve` 接收 connection、读取 request , 再调用 `server.Handler` ; 直到 server 被关闭或监听发生不可继续的错误才返回 `error` .
3. 两个 goroutine 并发执行 , 源码排列顺序不表示关闭逻辑先完成、HTTP 服务后启动 .

### 关闭触发条件

关闭 goroutine 先执行 :

```go
select {
case <-ctx.Done():
case <-stopped:
}
```

1. `ctx.Done()` 关闭表示 context 已取消 ; `stopped` 关闭表示 `Serve` 已返回 . 任意一个发生后 , `select` 结束等待 .
2. 两个 `case` 都没有正文 , 因为后续使用同一段关闭代码 .
3. 信号退出时 , `ctx.Done()` 触发关闭 . `Serve` 异常返回时 , `stopped` 也能触发关闭 ; 此时根 `ctx` 未必已经取消 .

## 关闭流程

### 等待期限

1. `context.WithTimeout(context.Background(), 15*time.Second)` 返回 `context.Context` 和 `context.CancelFunc` , 分别保存为 `shutdown` 和 `cancel` .
2. `server.Shutdown` 和 `drain` 共用 `shutdown` 的截止时间 , 总共 15 秒 , 不是各自拥有 15 秒 . 如果前者已用完这段时间 , 后者不会重新获得 15 秒 .
3. parent 使用 `context.Background()` , 不使用 `ctx` . 信号退出时 `ctx` 已取消 , 从它创建的子 context 也会立即取消 , 无法给清理留下等待时间 .
4. `defer cancel()` 在关闭 goroutine 的 function 返回时释放资源 . 它与 `serve()` 中的 `cancel` 是不同的局部变量 .
5. 截止时间限制的是等待 , 不保证整个 process 在 15 秒内退出 .

### HTTP connection 清理

1. `server.Shutdown(shutdown)` 关闭 listener 和空闲 connection , 等待正在处理 request 的 handler 返回 . 这通常称为 graceful shutdown : 停止接收新工作 , 等待已有工作结束 .
2. listener 关闭后 , `Serve` 可以返回 `http.ErrServerClosed` . 此时 `Shutdown` 可能还在等待 handler , 所以 `Serve` 返回不代表已有 request 都已处理完 .
3. `Shutdown` 返回 `error` . 正常完成时为 `nil` ; 等待超时或其他关闭错误会产生非 `nil` 结果 .
4. 非 `nil` 时 , `_ = server.Close()` 直接关闭剩余的普通 HTTP connection . 程序不保留 `Close` 的错误 , 但仍保留 `Shutdown` 的错误 .
5. 关闭 connection 不等于强制终止 handler . 例如不检查 context 的无限循环 , 不会因为 `Close` 自动停止 .
6. `Shutdown` 和 `Close` 不管理已交给应用自行处理的 connection , 例如某些 WebSocket connection . 本项目这段代码没有额外处理它们 .

### Agent 任务清理

1. `drain(shutdown)` 对应 [agent.Service.Shutdown](../../../acm-platform/internal/application/agent/service.go) . 它先把 `closing` 设为 `true` , 不再接收新任务 , 再等待已登记的任务结束 .
2. 任务计数归零时 , method 返回 `nil` ; 等待的 context 到期时 , 它返回 `ctx.Err()` . 它不强行结束任务 , 也不取消任务原来的 context .
3. 信号退出时 , 任务使用的根 context 已取消 , `RefreshLoop` 也收到停止通知 . `drain` 等待的是任务计数 , 不包含对 `RefreshLoop` goroutine 的单独等待 .
4. `Serve` 异常返回时 , 则不能假设所有后台任务都已收到取消通知 , 原因见[关闭触发条件](#关闭触发条件) .
5. `errors.Join(err, drain(shutdown))` 先执行 `drain` , 再把其返回值与 HTTP 关闭错误合并 . `shutdownDone <- ...` 把结果发给调用 `Serve` 的 goroutine . `errors.Join` 忽略 `nil` ; 全部成功时结果为 `nil` .

## 结果汇总

### 关闭结果接收

以下三行在调用 `Serve` 的 goroutine 中顺序执行 :

```go
err := server.Serve(listener)
close(stopped)
shutdownErr := <-shutdownDone
```

1. `close(stopped)` 通知关闭 goroutine : `Serve` 已返回 . 等待 `<-stopped` 的代码可以继续 , 不需要发送一个 `struct{}{}` 值 .
2. `shutdownErr` 的类型是 `error` . `<-shutdownDone` 等待关闭结果 ; 结果已经放入 channel 时 , 直接取出 .
3. 信号退出时 , 关闭 goroutine 已通过 `ctx.Done()` 开始执行 `Shutdown` . 后续关闭 `stopped` 不会再次执行 `Shutdown` , 因为 `select` 只执行一次 .

### 错误返回

1. `errors.Is(err, http.ErrServerClosed)` 检查 `Serve` 是否因关闭而返回 . 这种结果是预期行为 , 程序把 `err` 改成 `nil` . `errors.Is` 也能识别被其他错误包装的值 .
2. `return errors.Join(err, shutdownErr)` 同时保留监听错误和关闭错误 . 正常关闭且清理成功时 , 两者都是 `nil` , `serveHTTP` 返回 `nil` .
3. `serve()` 接收结果 , 执行自己的 `defer` 后返回给 `main()` . 非 `nil` 结果会让 `main()` 记录错误并调用 `os.Exit(1)` .

## 基础知识索引

基础规则指路 : [goroutine 和 channel](../01-language/08-goroutine-channel.md)、[context](../02-standard-library/02-context.md)、[HTTP 关闭](../02-standard-library/http/02-shutdown-and-options.md)、[errors](../02-standard-library/06-errors.md) .

下一篇 : [Docker 构建和运行](./05-docker-build.md) .
