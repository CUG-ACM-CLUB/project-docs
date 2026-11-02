# time 和 signal

`time` 包处理时间 . `os/signal` 包接收操作系统信号 , 例如终端发出的退出通知 .

本篇先讲时间值 , 再把操作系统信号和上一篇的 context 联系起来 .

## 1. 时间点和时间段

签名 :

```go
func Now() Time
func Since(t Time) Duration
```

完整程序 :

```go
package main

import (
	"fmt"
	"time"
)

func main() {
	started := time.Now()
	time.Sleep(20 * time.Millisecond)
	elapsed := time.Since(started)
	fmt.Println(elapsed)
}
```

| 变量或表达式 | 类型 | 含义 |
| --- | --- | --- |
| `started` | `time.Time` | 调用 `Now` 时的时间点 |
| `20 * time.Millisecond` | `time.Duration` | 20 毫秒的时间段 |
| `elapsed` | `time.Duration` | 从 `started` 到现在经过的时间 |

`time.Sleep` 的签名是 `func Sleep(d Duration)` . 它接收时间段 , 没有返回值 .

运行环境和调度会影响等待时间 , 所以例子的输出不保证恰好是 `20ms` .

## 2. 为什么不能直接用整数表示秒

`time` 包定义了 :

```go
type Duration int64
```

`time.Duration` 是以 `int64` 为底层类型的有名类型 , 使用纳秒作为计数单位 :

```go
var short time.Duration = 30
var long time.Duration = 30 * time.Second
```

两个变量的类型都是 `time.Duration` . `short` 表示 30 纳秒 , `long` 表示 30 秒 .

因此 , 程序调用 `time.Sleep(30)` 时 , 传入的是 30 纳秒 . 程序需要等待 30 秒时 , 应该写 `time.Sleep(30 * time.Second)` .

| 常量 | 表示的时间 |
| --- | --- |
| `time.Nanosecond` | 1 纳秒 |
| `time.Microsecond` | 1 微秒 |
| `time.Millisecond` | 1 毫秒 |
| `time.Second` | 1 秒 |
| `time.Minute` | 1 分钟 |

## 3. `Sleep` 等待时间 , `After` 提供通知

`time.Sleep` 会暂停当前 goroutine . 其他 goroutine 仍然可以运行 , 但当前 goroutine 不会因为另一个 context 被取消而自动提前结束等待 .

如果程序需要同时等待 "时间到达”和“任务取消" , 程序可以使用 `time.After` :

```go
func After(d Duration) <-chan Time
```

它接收一个 `time.Duration` , 返回 `<-chan time.Time` . 这是只读 channel , 到指定时间后可以从中接收一个时间值 .

下面是函数片段 , 需要导入 `context` 和 `time` :

```go
func wait(ctx context.Context) error {
	select {
	case <-time.After(time.Second):
		return nil
	case <-ctx.Done():
		return ctx.Err()
	}
}
```

`wait` 接收 `context.Context` , 返回 `error` . 一秒先到就返回 `nil` ; 取消通知先到就返回取消原因 .

`case <-time.After(...)` 没有保存收到的 `time.Time` , 因为这个函数只关心时间是否到达 .

## 4. ticker 定期通知

签名 :

```go
func NewTicker(d Duration) *Ticker
func (t *Ticker) Stop()
```

完整程序 :

```go
package main

import (
	"fmt"
	"time"
)

func main() {
	ticker := time.NewTicker(time.Second)
	defer ticker.Stop()

	for i := 0; i < 3; i++ {
		now := <-ticker.C
		fmt.Println(now)
	}
}
```

`ticker` 的类型是 `*time.Ticker` . 它的字段 `C` 的类型是 `<-chan time.Time` , 程序可以从这个 channel 接收定时通知 .

每次接收得到的 `now` 都是 `time.Time` . 例子接收三次后结束 .

`ticker.Stop()` 没有返回值 , 它会停止后续定时通知 , 但不会关闭 `ticker.C` . 因此 , 程序不能依靠 `Stop` 让正在等待这个 channel 的 goroutine 自动结束 .

如果接收方处理得太慢 , ticker 可能丢弃部分通知 . 它不保证程序逐一处理每个周期 . 传给 `NewTicker` 的时间段必须大于零 .

## 5. 操作系统信号是什么

信号是操作系统通知进程发生某种事件的方式 . 在 Linux、macOS 等 Unix 系统中 , 常见信号包括 :

| 信号 | 常见来源或含义 |
| --- | --- |
| `SIGINT` | 终端按下 Ctrl+C |
| `SIGTERM` | 请求进程结束 , 让程序有机会清理资源 |
| `SIGKILL` | 强制结束 , 程序不能捕获它来执行清理 |

程序可以用 `os/signal` 订阅信号 . `syscall` 包提供这些信号常量 ; 下面的例子面向 Unix 系统 .

## 6. `NotifyContext` 把信号转换成取消通知

签名 :

```go
func NotifyContext(parent context.Context, signals ...os.Signal) (
	ctx context.Context,
	stop context.CancelFunc,
)
```

第一个参数是父 context . 后面的 `...os.Signal` 表示程序可以传入多个信号值 . `os.Signal` 是接口 , `syscall.SIGINT` 和 `syscall.SIGTERM` 满足这个接口 .

完整程序 :

```go
package main

import (
	"context"
	"fmt"
	"os/signal"
	"syscall"
)

func main() {
	ctx, cancel := signal.NotifyContext(
		context.Background(),
		syscall.SIGTERM,
		syscall.SIGINT,
	)
	defer cancel()

	fmt.Println("等待退出信号")
	<-ctx.Done()
	fmt.Println("收到通知，结束程序")
}
```

这两个返回值的类型分别是 :

| 变量 | 类型 | 用途 |
| --- | --- | --- |
| `ctx` | `context.Context` | 接收取消通知 |
| `cancel` | `context.CancelFunc` | 取消 context , 并解除本次信号订阅 |

官方签名把第二个返回值命名为 `stop` . 例子把它保存到变量 `cancel` 中 , 类型和作用都没有变化 .

`context.CancelFunc` 的定义是 `type CancelFunc func()` . 所以 `cancel` 保存的是函数值 , `cancel()` 就是调用它 . `defer cancel()` 则是在 `main` 返回时调用 .

程序收到订阅的信号后 , `ctx.Done()` 返回的 channel 会关闭 , 等待语句继续执行 . 程序随后输出说明 , `main` 返回 , 最后执行已经登记的 `cancel()` .

如果父 context 被取消 , 或者程序主动调用 `cancel()` , 这个 `ctx` 也会被取消 . 因此 , 取消通知不一定意味着收到了操作系统信号 .

## 小练习

1. `time.Duration(5)` 和 `5 * time.Second` 分别表示多长时间 ?
2. `ticker` 和 `ticker.C` 的类型分别是什么 ?
3. 为什么 `cancel` 后面可以加 `()` ? 如果把变量名改成 `stop` , 应该怎样调用 ?

查阅签名时 , 可以在 Go 官方文档中搜索 `time` 和 `os/signal` .

下一篇 : [net 和 net/http](./04-net-http.md) .
