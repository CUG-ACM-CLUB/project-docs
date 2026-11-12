# 服务初始化与启动

对照 [cmd/acm/main.go](../../../acm-platform/cmd/acm/main.go) 中的 `func serve() error` 阅读 . 以下按初始化顺序说明各个对象的类型和用途 .

## 退出通知与配置

### 根 context

1. `signal.NotifyContext(...)` 返回 `context.Context` 和 `context.CancelFunc` , 分别保存为 `ctx` 和 `cancel` .
2. process 收到 `SIGTERM` 或 `SIGINT` 后 , `ctx` 被取消 . 后面的 HTTP request 和后台任务使用这个 context 或它的子 context .
3. `defer cancel()` 在 `serve()` 返回时取消 context 并解除本次信号订阅 . 取消是通知 , 不会强行停止代码 , 也不等于等待任务结束 .

基础规则见 [context](../02-standard-library/02-context.md) 和 [time、signal](../02-standard-library/03-time-signal.md) .

### 环境变量

1. `os.Getenv("BRIDGE_SECRET")` 返回 `string` . `BRIDGE_SECRET` 是平台与 Hydro 通信时使用的 secret ; 当前检查要求长度至少为 32 字节 . Go 的 `len(string)` 计算字节数 , 不是中文字数 .
2. `DATABASE_URL` 保存 PostgreSQL 连接地址和账号配置 . [compose.yaml](../../../acm-platform/compose.yaml) 通过 `environment` 把配置传给 container 内的程序 .
3. `env(key, fallback string) string` 是同文件中定义的辅助 function . 环境变量不存在或值为空时 , 它返回 `fallback` ; 否则返回环境变量的值 . 例如 `env("LISTEN_ADDR", ":3000")` 的默认结果是 `":3000"` .

## 数据库初始化

### 连接池

1. `platform.Open(ctx, os.Getenv("DATABASE_URL"))` 返回 `*platform.Store` 和 `error` , 分别保存为 `store` 和 `err` .
2. `platform.Store` 是 `postgres.Store` 的别名 , `platform.Open` 转调 `postgres.Open` . 两者关系见 [platform/store.go](../../../acm-platform/internal/platform/store.go) 和 [postgres/store.go](../../../acm-platform/internal/infrastructure/postgres/store.go) .
3. `store.DB` 的类型是 `*pgxpool.Pool` . connection pool 管理并复用数据库连接 , 不要求每次 SQL 操作重新建立连接 . `Open` 创建 pool 后调用 `Ping` 检查数据库是否能连接 .
4. `defer store.DB.Close()` 在 `serve()` 返回时关闭 pool . 如果 `Open` 已失败 , 程序会提前返回 , 不会执行这条 `defer` 声明 .

### 数据迁移与任务状态

1. `store.Migrate(ctx)` 返回 `error` . 它执行 `schema.sql` 中的建表和结构更新 SQL , 并整理已有题面数据 . migration 在这里指让数据库结构和数据适配当前程序 , 不是搬迁数据库服务器 .
2. `schema.sql` 位于 `internal/infrastructure/postgres/` . `//go:embed schema.sql` 把文件内容保存为 `string` , 编译后运行不需要再从源码目录读取它 .
3. migration 失败时 , `fmt.Errorf("database migration failed: %w", err)` 添加说明并保留原错误 . `%w` 的规则见 [errors](../02-standard-library/06-errors.md) .
4. 随后的 `store.DB.Exec(ctx, SQL)` 把 `agent_runs` 表中的 `running` 记录改成 `interrupted` , 写入原因和结束时间 . 这一步标记上次 process 留下的任务 , 不重新执行任务 .
5. `Exec` 返回 `pgconn.CommandTag` 和 `error` . 前者可以查询受影响的行数 ; 当前代码用 `_` 忽略它 , 只检查错误 . 反引号包围的内容是交给数据库执行的 SQL 字符串 .

## 外部服务 client

### HTTP client

1. `client` 的类型是 `*http.Client` , 供 Hydro 和 Codeforces 发送 request . `Timeout` 为 30 秒 , 包括连接、redirect 和读取 response body 的时间 ; request 自身的 context 可能让操作更早结束 .
2. `CheckRedirect` 保存 `func(*http.Request, []*http.Request) error` 类型的 callback . client 准备跟随 redirect 时才调用它 .
3. callback 返回 `http.ErrUseLastResponse` , 表示不继续访问新地址 , 把当前 redirect response 留给调用者处理 . 两个参数没有名字 , 因为 callback 不读取它们 .

基础用法见 [http.Client](../02-standard-library/http/01-client.md) ; redirect callback 见 [服务关闭、timeout 和 callback](../02-standard-library/http/02-shutdown-and-options.md) 第五节 .

### 模型配置

1. `model` 的类型是 `*platform.ResponsesModel` . `URL`、`Key`、`Name` 都是 `string` , 分别保存 API 地址、认证 key 和模型名称 .
2. `model.Client` 是另一个 `*http.Client` , timeout 为 80 秒 . `CheckRedirect: client.CheckRedirect` 只复用 callback , 两个 client 仍是不同对象 .
3. `configID := model.ConfigID()` 得到 `string` . `ConfigID` 根据 URL、名称和 key 计算 hash , 即从这些内容算出的标识字符串 . 数据库用它区分模型配置的调用状态 , 不把 key 本身作为配置标识保存 .
4. 此处只创建配置对象 , 没有调用模型或验证 key 是否可用 .

### 调用状态 callback

1. `model.Observe` 的类型是 `func(context.Context, int, bool, string)` , 没有返回值 . 赋值时只保存 function , 不执行其中的数据库操作 .
2. 后续 [ResponsesModel.Respond](../../../acm-platform/internal/infrastructure/model/client.go) 结束模型请求处理时 , 通过 `defer` 调用 `Observe` . 配置缺失导致 `Respond` 提前返回时 , 还没有登记这次调用 .
3. 四个参数依次是保存记录使用的 `context.Context`、HTTP status code `int`、协议处理是否成功 `bool`、错误说明 `string` . 没有收到 HTTP response 时 , status code 为 `0` .
4. callback 的参数 `ctx` 由 `Respond` 传入 , 不是直接引用 `serve()` 的 `ctx` . 当前 `Respond` 为保存状态单独创建了 2 秒的 context .
5. callback 使用外层的 `store` 和 `configID` , 因此也是 closure . 它调用 `store.RecordModelCall` 保存状态 ; 保存失败时只写 warning , 不覆盖模型请求的返回结果 .

## 前端资源

1. `internal/web/web.go` 中的 `//go:embed assets/*` 从这个 Go 文件所在目录找文件 . 本地对应的绝对目录是 `/Users/zelong/Desktop/acm-oj-new/acm-platform/internal/web/assets/` , 不是 `main.go` 所在目录 .
2. `web.Files` 的类型是 `embed.FS` . `fs.Sub(web.Files, "assets")` 返回 `fs.FS` 和 `error` , 分别保存为 `assets` 和 `err` .
3. 在 `web.Files` 中读取首页使用 `assets/index.html` ; 在 `assets` 中读取同一个文件使用 `index.html` . `fs.Sub` 只改变文件访问的起点 , 不改变 process 的工作目录 .

具体用法见 [fs 和 embed](../02-standard-library/files/01-fs-embed.md) .

## 服务对象

### 业务对象 `platformServer`

1. `platformServer` 的类型是 `*platform.Server` . `Store: store`、`Web: assets` 等写法把前面准备的值保存到对应 field 中 .
2. `Hydro` 是 `*platform.Hydro` . `URL` 供 Go 程序访问 Hydro , 默认是 Compose network 中的 `http://hydro:8888` ; `PublicURL` 用来生成交给浏览器的题目链接 .
3. `CF` 是 `*platform.CF` , 保存 Codeforces API 地址 . `Hydro.Client` 和 `CF.Client` 共用前面创建的 `client` .
4. `Agent` 是 `*platform.Agent` , 保存 `store`、`model` 和 `configID` , 供之后执行分析任务使用 .
5. `questionnaireapp.New(store)` 返回 `*questionnaireapp.Service` ; `practiceapp.New(store)` 返回 `*practiceapp.Service` . 两者都保存 `store` , 之后通过它读写数据 . `questionnaireapp` 和 `practiceapp` 是文件顶部指定的 import 别名 .
6. `ModelReady` 是 `bool` , 只检查 key 和模型名称是否非空 , 不代表模型已成功调用 . `SecureCookie` 也是 `bool` , 决定 cookie 是否带 `Secure` 标记 . `Revision` 是记录程序版本的 `string` .

### HTTP server

1. `server` 的类型是 `*http.Server` , 负责接收 HTTP request . 它与提供业务处理代码的 `platformServer` 是不同对象 .
2. `platformServer.Handler(ctx)` 返回 `http.Handler` , 保存到 `server.Handler` . 收到 request 后 , `http.Server` 才调用这个 handler .
3. 调用 `Handler(ctx)` 时已经会执行 `App(ctx)` : 创建 Fiber application、登记路由、初始化 `platformServer.Tasks` . 因此后面能够使用 `Tasks.Shutdown` . 实现见 [platform/http.go](../../../acm-platform/internal/platform/http.go) .
4. 四个 timeout field 分别限制读取 header、读取整个 request、写 response 和等待下一次 request 的时间 , 值依次为 5、30、120、60 秒 . 具体规则见 [服务关闭、timeout 和 callback](../02-standard-library/http/02-shutdown-and-options.md) 第四节 .
5. `BaseContext` 保存 `func(net.Listener) context.Context` 类型的 callback . `Serve` 开始使用 listener 时调用它 , 得到建立 connection context 的起点 . 当前 callback 返回 `serve()` 开头创建的 `ctx` ; 取消它也会通知 request , 但不强制让 handler 返回 .

## 服务启动与资源清理

### 后台循环与端口监听

1. `go platformServer.RefreshLoop(ctx)` 在新的 goroutine 中运行刷新循环 . 该循环每分钟检查待生成的报告和待更新的画像 ; 模型未配置时跳过调度 , context 取消后停止循环 . 实现见 [agent/service.go](../../../acm-platform/internal/application/agent/service.go) .
2. `net.Listen("tcp", server.Addr)` 返回 `net.Listener` 和 `error` . `listener` 默认监听 `:3000` ; 在 container 中运行时 , 这是 container 内的端口 , 不是 host 的 `13000` 端口 .
3. listener 创建成功后 , `slog.Info` 记录地址、revision 和模型是否配置 . 监听失败时 , `serve()` 返回错误 .

### `serveHTTP` 调用与返回

1. `serveHTTP(ctx, server, listener, platformServer.Tasks.Shutdown)` 管理 HTTP 服务的运行和关闭 , 返回 `error` . `serve()` 把这个结果返回给 `main()` .
2. 最后一个参数没有 `()` , 因此这里没有调用 `Tasks.Shutdown` . 传入的是已绑定 `Tasks` 对象的 method value , 类型为 `func(context.Context) error` ; 接收方之后可以调用它 .
3. `serveHTTP` 返回后 , `serve()` 执行已登记的 `defer` : 先关闭数据库 pool , 再调用 `cancel()` . 这是正常返回路径的清理顺序 , 不表示所有后台代码都已被强制结束 .

下一篇 : [HTTP 运行和关闭 review](./04-http-startup-review.md) .
