# `serve`：创建服务依赖

可以看到 , `main.go` 真正的作用是启动 `serve()` (或者`cli.Run()`) . 本篇按照 `serve()` 的执行顺序阅读。读完本篇后，读者应该知道：

```text
serve()
    ↓
创建退出通知
    ↓
读取并检查配置
    ↓
连接 PostgreSQL，执行 migration
    ↓
创建 HTTP client、Hydro client、Codeforces client 和 model client
    ↓
创建 platform.Server
    ↓
创建 http.Server
    ↓
开始监听端口
    ↓
调用 serveHTTP
```

`serveHTTP` 如何处理请求和关闭服务，会在 [04-http-startup.md](./04-http-startup.md) 中讲解。

## 1. 创建根 context 和取消函数

`serve()` 的开头是：

```go
ctx, cancel := signal.NotifyContext(
	context.Background(),
	syscall.SIGTERM,
	syscall.SIGINT,
)
defer cancel()
```

`signal.NotifyContext` 的返回值类型是：

```go
func NotifyContext(
	parent context.Context,
	signals ...os.Signal,
) (ctx context.Context, stop context.CancelFunc)
```

所以这两个变量的类型和用途是：

| 变量 | 类型 | 来源 | 用途 |
| --- | --- | --- | --- |
| `ctx` | `context.Context` | `NotifyContext` 的第一个返回值 | 把进程退出通知传给服务和请求 |
| `cancel` | `context.CancelFunc` | `NotifyContext` 的第二个返回值 | 取消这个 context，并解除 signal 订阅 |

`SIGTERM` 通常表示系统请求 process 正常结束，`SIGINT` 通常来自终端的 Ctrl+C。收到其中任意一个信号后，`ctx.Done()` 对应的 channel 会关闭。

`defer cancel()` 不会立即取消 `ctx`。它表示：`serve()` 返回时调用 `cancel()`，释放本次 signal 订阅相关的资源。

`context.Context`、`context.CancelFunc` 和 `NotifyContext` 已经在 [02/02](../02-standard-library/02-context.md) 和 [02/03](../02-standard-library/03-time-signal.md) 中讲过。本篇只说明它们在项目启动流程中的位置。

## 2. 检查必须的环境变量

程序随后检查 bridge secret：

```go
if len(os.Getenv("BRIDGE_SECRET")) < 32 {
	return errors.New("BRIDGE_SECRET must contain at least 32 characters")
}
```

`os.Getenv("BRIDGE_SECRET")` 的返回类型是 `string`。它读取当前 process 的环境变量。

Compose 对 platform service 的配置是：

```yaml
environment:
  BRIDGE_SECRET: ${BRIDGE_SECRET:?set BRIDGE_SECRET}
```

这个值用于平台和 Hydro 之间的身份验证。`serve()` 只检查它的长度，不把 secret 写进日志。

当长度不足 `32` 时，代码直接返回一个 `error`：

```text
环境变量不满足要求
    ↓
serve() 返回 error
    ↓
main 记录错误并以退出码 1 结束
```

程序在这个检查失败后不会连接数据库，也不会监听 HTTP 端口。

## 3. 读取环境变量和默认值

文件中还定义了一个辅助 function：

```go
func env(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
```

这个 function 接收两个 `string`，返回一个 `string`：

| 参数或变量 | 类型 | 用途 |
| --- | --- | --- |
| `key` | `string` | 要读取的环境变量名称 |
| `fallback` | `string` | 环境变量为空时使用的默认值 |
| `v` | `string` | `os.Getenv(key)` 读取到的值 |
| 返回值 | `string` | 实际交给调用者使用的配置值 |

例如：

```go
addr := env("LISTEN_ADDR", ":3000")
```

如果 `LISTEN_ADDR` 已设置，`addr` 保存环境变量的值；如果没有设置，`addr` 保存 `":3000"`。

这个 helper 与 `os.LookupEnv` 不同。`env` 不区分“变量不存在”和“变量存在但值为空”，因为两种情况都会使用 `fallback`。

## 4. 连接 PostgreSQL

`serve()` 接着创建数据库 store：

```go
store, err := platform.Open(ctx, os.Getenv("DATABASE_URL"))
if err != nil {
	return errors.New("database connection failed")
}
defer store.DB.Close()
```

`os.Getenv("DATABASE_URL")` 返回 PostgreSQL connection string。Compose 为 platform service 设置的值类似于：

```text
postgres://acm:<password>@postgres:5432/acm?sslmode=disable
```

`platform.Open` 的返回类型是：

```go
func Open(ctx context.Context, url string) (*Store, error)
```

因此：

| 变量 | 类型 | 来源 | 用途 |
| --- | --- | --- | --- |
| `store` | `*platform.Store` | `platform.Open` 的第一个返回值 | 保存 PostgreSQL connection pool |
| `err` | `error` | `platform.Open` 的第二个返回值 | 表示配置或连接是否失败 |

`*platform.Store` 中的 `DB` field 类型是 `*pgxpool.Pool`。`platform.Open` 会解析 connection string、创建 connection pool，并执行 `Ping` 检查数据库是否可用。

创建成功后，`defer store.DB.Close()` 登记关闭 connection pool。`serve()` 返回时，程序会执行这个 `defer`。

这里的 `defer` 和多个返回值已经在 [01/03](../01-language/03-return-and-error.md) 和 [01/06](../01-language/06-defer-and-function-value.md) 中讲过。

## 5. 执行 database migration

数据库连接成功后，程序执行：

```go
if err = store.Migrate(ctx); err != nil {
	return fmt.Errorf("database migration failed: %w", err)
}
```

`store.Migrate(ctx)` 的返回类型是 `error`。这个 method 会执行 PostgreSQL schema，并完成已有数据的必要整理。

`Migrate` 使用的 schema 来自：

```go
//go:embed schema.sql
var schema string
```

`schema` 的类型是 `string`，内容是编译时嵌入 executable 的 SQL 文本。`Migrate` 把这个 SQL 文本传给 `DB.Exec`。

`fmt.Errorf` 创建一个带上下文的 `error`：

```go
fmt.Errorf("database migration failed: %w", err)
```

`%w` 会保留原始 `err`，因此上层仍然可以继续检查原始错误。

本篇只需要知道 migration 会在服务开始接收 request 之前执行。PostgreSQL store 的具体 SQL 操作属于项目分层内容，会在 [04/05](../04-project-architecture/05-postgres-layer.md) 中展开。

## 6. 处理中断的 agent task

服务重启后，数据库中可能还保留上一次 process 的 `running` task。程序执行：

```go
_, err = store.DB.Exec(ctx, `
	UPDATE agent_runs
	SET status='interrupted',
	    error='server restarted',
	    finished_at=now()
	WHERE status='running'
`)
if err != nil {
	return err
}
```

`store.DB.Exec` 返回：

```go
(pgconn.CommandTag, error)
```

代码使用空白标识符 `_` 丢弃第一项，只保留 `error`：

```go
_, err = store.DB.Exec(...)
```

这条 SQL 把旧的 `running` 记录标记为 `interrupted`。程序不会把上一次 process 中断时正在执行的 task 假设为仍然运行。

SQL 内容使用反引号包围的 raw string。raw string 的基础语法已经在 [01/02](../01-language/02-function.md) 和项目代码阅读中遇到，本篇重点是这条操作发生在启动阶段。

## 7. 创建通用 `http.Client`

程序创建一个通用 HTTP client：

```go
client := &http.Client{
	Timeout: 30 * time.Second,
	CheckRedirect: func(
		*http.Request,
		[]*http.Request,
	) error {
		return http.ErrUseLastResponse
	},
}
```

`client` 的类型是 `*http.Client`。`&http.Client{...}` 创建一个 `http.Client` struct 值，并返回指向它的 pointer。

这个 client 有两个重要配置：

- `Timeout: 30 * time.Second`：一个 request 最多等待 30 秒。
- `CheckRedirect`：收到 HTTP redirect 时调用的 callback。

`CheckRedirect` field 的类型是：

```go
func(req *http.Request, via []*http.Request) error
```

当前 callback 返回 `http.ErrUseLastResponse`，表示 client 不自动跟随 redirect，而是把 redirect response 直接交给调用者。

`http.Client`、`http.Request` 和 callback 已经在 [02/04](../02-standard-library/04-net-http.md) 中讲过。本篇只说明平台为什么创建它，以及后面的 Hydro 和 Codeforces client 为什么复用它。

## 8. 创建 model client

程序创建模型 client：

```go
model := &platform.ResponsesModel{
	URL:  env("OPENAI_BASE_URL", "https://api.openai.com/v1"),
	Key:  os.Getenv("OPENAI_API_KEY"),
	Name: os.Getenv("OPENAI_MODEL"),
	Client: &http.Client{
		Timeout:       80 * time.Second,
		CheckRedirect: client.CheckRedirect,
	},
}
```

`model` 的类型是 `*platform.ResponsesModel`。这个 struct 保存模型服务需要的配置：

| field | 类型 | 来源 | 用途 |
| --- | --- | --- | --- |
| `URL` | `string` | 环境变量或默认值 | 模型 API 的 base URL |
| `Key` | `string` | `OPENAI_API_KEY` | 模型 API 的认证 key |
| `Name` | `string` | `OPENAI_MODEL` | 要调用的模型名称 |
| `Client` | `*http.Client` | 新创建的 client | 发送模型 HTTP request |

模型 client 的 timeout 是 `80` 秒，比通用 client 的 `30` 秒更长，因为模型 response 可能需要更久。

程序随后计算 model 配置的标识：

```go
configID := model.ConfigID()
```

`ConfigID()` 返回 `string`。它根据模型 URL、模型名称和 key 计算 hash，用于记录“这次模型调用使用了哪一组配置”。数据库只保存 hash，不保存 key。

## 9. 设置 model 的观察 callback

程序把一个 function value 赋给 `model.Observe`：

```go
model.Observe = func(
	ctx context.Context,
	httpStatus int,
	protocolOK bool,
	message string,
) {
	if err := store.RecordModelCall(
		ctx,
		configID,
		httpStatus,
		protocolOK,
		message,
	); err != nil {
		slog.Warn("model status could not be saved")
	}
}
```

`Observe` field 的类型是：

```go
func(context.Context, int, bool, string)
```

这个 callback 不返回值。模型 client 每次完成一次请求后，`ResponsesModel.Respond` 会调用它，并传入：

| 参数 | 类型 | 内容 |
| --- | --- | --- |
| `ctx` | `context.Context` | 保存观察记录时使用的 context |
| `httpStatus` | `int` | HTTP response status code，连接失败时可能为 `0` |
| `protocolOK` | `bool` | 模型 response 是否通过协议处理 |
| `message` | `string` | 限制后的错误说明，成功时通常为空 |

这个匿名 function 访问了外部的 `store` 和 `configID`，所以它也是一个 closure。closure 的基础概念已经在 [01/06](../01-language/06-defer-and-function-value.md) 中讲过。

`store.RecordModelCall` 返回 `error`。如果写入观察记录失败，callback 只记录 warning，不把模型主流程已经得到的结果改成失败。

## 10. 准备嵌入的前端资源

前端资源在：

```text
acm-platform/internal/web/assets/
```

`internal/web/web.go` 中写着：

```go
package web

import (
	"embed"
)

//go:embed assets/*
var Files embed.FS
```

`Files` 的类型是 `embed.FS`，它保存编译时嵌入 executable 的文件树。

`serve()` 执行：

```go
assets, err := fs.Sub(web.Files, "assets")
if err != nil {
	return err
}
```

`fs.Sub` 的返回类型是：

```go
(fs.FS, error)
```

`assets` 的类型是 `fs.FS` interface。它把 `web.Files` 中的 `assets` 目录作为新的根目录，因此后续静态文件代码可以使用：

```text
index.html
assets 中的其他相对路径
```

而不必重复写 `assets/` 前缀。`embed.FS` 和 `fs.FS` 已经在 [02/05](../02-standard-library/05-io-fs-embed.md) 中讲过。

## 11. 组装 `platform.Server`

程序把已经创建的依赖放入一个 `platform.Server` struct：

```go
platformServer := &platform.Server{
	Store: store,
	Hydro: &platform.Hydro{
		URL:       env("HYDRO_URL", "http://hydro:8888"),
		PublicURL: env("HYDRO_PUBLIC_URL", "http://127.0.0.1:13888"),
		Secret:    os.Getenv("BRIDGE_SECRET"),
		Client:    client,
	},
	CF: &platform.CF{
		URL:    "https://codeforces.com/api",
		Client: client,
	},
	Agent: &platform.Agent{
		Store:    store,
		Model:    model,
		ConfigID: configID,
	},
	ModelReady:    model.Key != "" && model.Name != "",
	Questionnaire: questionnaireapp.New(store),
	Practice:      practiceapp.New(store),
	SecureCookie:  os.Getenv("COOKIE_SECURE") == "true",
	Revision:      revision,
	Web:           assets,
}
```

这段代码没有开始监听端口。它只创建一个对象，并把已经创建的依赖交给这个对象保存。

主要 field 的关系是：

| field | 类型 | 作用 |
| --- | --- | --- |
| `Store` | `*platform.Store` | 访问 PostgreSQL |
| `Hydro` | `*platform.Hydro` | 调用 Hydro |
| `CF` | `*platform.CF` | 调用 Codeforces API |
| `Agent` | `*platform.Agent` | 运行 agent task |
| `ModelReady` | `bool` | 表示模型 key 和名称是否都已配置 |
| `Questionnaire` | `*questionnaire.Service` | 处理问卷业务 |
| `Practice` | `*practice.Service` | 处理练习业务 |
| `SecureCookie` | `bool` | 是否把 cookie 标记为 secure |
| `Revision` | `string` | 当前程序版本 |
| `Web` | `fs.FS` | 提供嵌入的前端文件 |

`questionnaireapp.New(store)` 和 `practiceapp.New(store)` 都返回指向 application service 的 pointer。application layer 会在 [04/03](../04-project-architecture/03-application-layer.md) 中讲解。

`platform.Server` 的 `Handler` method 会根据这些依赖创建 HTTP request handler：

```go
Handler(ctx context.Context) http.Handler
```

`Handler` 的具体路由和 Fiber adapter 会在 [04/01](../04-project-architecture/01-platform-server.md) 和 [04/02](../04-project-architecture/02-fiber-route.md) 中讲解。

## 12. 创建 `http.Server`

程序继续创建标准库的 HTTP server：

```go
server := &http.Server{
	Addr:              env("LISTEN_ADDR", ":3000"),
	Handler:           platformServer.Handler(ctx),
	ReadHeaderTimeout: 5 * time.Second,
	ReadTimeout:       30 * time.Second,
	WriteTimeout:      120 * time.Second,
	IdleTimeout:       60 * time.Second,
	BaseContext: func(net.Listener) context.Context {
		return ctx
	},
}
```

`server` 的类型是 `*http.Server`。

`platformServer.Handler(ctx)` 的返回类型是 `http.Handler`。这个返回值被保存到 `server.Handler` field。`http.Server` 收到 HTTP request 后，会把 request 交给这个 handler。

各个 timeout 的意义是：

| field | 时间 | 限制的阶段 |
| --- | --- | --- |
| `ReadHeaderTimeout` | 5 秒 | 等待 request header |
| `ReadTimeout` | 30 秒 | 读取 request |
| `WriteTimeout` | 120 秒 | 写出 response |
| `IdleTimeout` | 60 秒 | keep-alive connection 空闲时间 |

`BaseContext` 的类型是：

```go
func(net.Listener) context.Context
```

HTTP server 为 connection 创建基础 context 时调用这个 callback。当前 callback 忽略 `net.Listener` 参数，始终返回 `serve()` 创建的 `ctx`。因此，进程收到 `SIGTERM` 或 `SIGINT` 后，请求 context 也能收到取消通知。

`http.Server`、`http.Handler` 和 timeout 的基础知识已经在 [02/04](../02-standard-library/04-net-http.md) 中讲过。本篇只解释这些对象在真实项目中的组装关系。

## 13. 启动后台刷新循环

程序启动 agent task 的后台刷新循环：

```go
go platformServer.RefreshLoop(ctx)
```

`go` 关键字会创建一个 goroutine，异步调用 `RefreshLoop`。这个 function 不会阻塞当前的 `serve()`，所以 `serve()` 可以继续创建 listener。

`RefreshLoop` 内部每分钟检查一次 context 和 ticker：

```go
func (s *Server) RefreshLoop(ctx context.Context) {
	s.Tasks.RefreshLoop(ctx)
}
```

具体的 agent task 调度会在后续 application layer 章节讲解。当前只需要记住：这个 goroutine 使用同一个 `ctx`，context 取消后，它会停止循环。

goroutine、channel 和 `go` 关键字已经在 [01/08](../01-language/08-goroutine-channel.md) 中讲过。

## 14. 创建 listener

程序调用：

```go
listener, err := net.Listen("tcp", server.Addr)
if err != nil {
	return err
}
```

`net.Listen` 的返回类型是：

```go
(net.Listener, error)
```

因此：

| 变量 | 类型 | 来源 | 用途 |
| --- | --- | --- | --- |
| `listener` | `net.Listener` interface | `net.Listen` 的第一个返回值 | 接收 TCP connection |
| `err` | `error` | `net.Listen` 的第二个返回值 | 表示监听端口是否失败 |

`server.Addr` 的类型是 `string`，默认值是 `":3000"`。`":3000"` 表示监听本机所有可用 network interface 的 TCP `3000` 端口。

listener 创建成功后，程序写入启动日志：

```go
slog.Info(
	"platform listening",
	"address", server.Addr,
	"revision", revision,
	"model_configured", platformServer.ModelReady,
)
```

日志只记录地址、revision 和模型是否配置，不记录 API key。

## 15. 进入 `serveHTTP`

`serve()` 最后执行：

```go
return serveHTTP(
	ctx,
	server,
	listener,
	platformServer.Tasks.Shutdown,
)
```

`serveHTTP` 的签名是：

```go
func serveHTTP(
	ctx context.Context,
	server *http.Server,
	listener net.Listener,
	drain func(context.Context) error,
) error
```

传入的四个值分别是：

| 参数 | 类型 | 实际值 | 用途 |
| --- | --- | --- | --- |
| `ctx` | `context.Context` | 根 context | 通知 HTTP server 开始关闭 |
| `server` | `*http.Server` | 刚创建的 HTTP server | 接收和处理 request |
| `listener` | `net.Listener` | `net.Listen` 创建的 listener | 接收 TCP connection |
| `drain` | `func(context.Context) error` | `platformServer.Tasks.Shutdown` method value | 等待 agent task 清理 |

`platformServer.Tasks.Shutdown` 是一个 method value。它保存了 receiver `platformServer.Tasks`，所以传给 `serveHTTP` 后，`serveHTTP` 可以直接调用：

```go
drain(shutdownContext)
```

`serveHTTP` 会调用 `server.Serve(listener)`，并负责优雅关闭。具体过程见下一篇。

## 小结

`serve()` 的工作不是处理某个具体的 HTTP request。`serve()` 负责把运行 HTTP server 所需的对象创建出来并连接起来：

```text
环境变量
    ↓
PostgreSQL store、外部 client、model client
    ↓
platform.Server
    ↓
http.Server
    ↓
net.Listener
    ↓
serveHTTP
```

下一篇：[HTTP 启动和关闭](./04-http-startup.md)。
