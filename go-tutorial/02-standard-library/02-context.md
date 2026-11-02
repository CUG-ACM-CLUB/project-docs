# context : 通知任务停止

假设一个函数正在处理任务 , 调用方已经不再需要结果 . 调用方需要一种方式通知这个函数 : "可以停止了 . "

`context` 包提供这样的通知方式 . 程序还可以用它传递截止时间 . context 不会自动创建 goroutine , 也不会强行终止正在执行的代码 .

本篇的必要前置是 `01/` 中的函数值、`defer` 和 channel .

## 1. `context.Context` 是接口类型

下面是这个接口的方法 :

```go
type Context interface {
	Deadline() (deadline time.Time, ok bool)
	Done() <-chan struct{}
	Err() error
	Value(key any) any
}
```

一个值满足这个接口后 , 程序就可以通过这些方法查询任务的取消状态和截止时间 .

| 方法 | 返回值类型 | 含义 |
| --- | --- | --- |
| `Deadline()` | `time.Time, bool` | 截止时间 , 以及是否设定了截止时间 |
| `Done()` | `<-chan struct{}` | 只读 channel , 取消时会关闭 |
| `Err()` | `error` | 尚未取消时返回 `nil` , 取消后返回原因 |
| `Value(key)` | `any` | 查询附加在 context 上的值 , 本篇不展开 |

`time.Time` 表示时间点 , 下一篇会讲 . `<-chan struct{}` 表示程序只能从这个 channel 接收通知 , 不能通过这个值发送数据或关闭 channel .

> [!NOTE]
>
> # 拆解 `<-chan struct{}`
>
> 你的困惑很正常 , 这是两个语法点叠在一起了 . 我们一层层拆开 .
>
> ## 第一部分 : `chan struct{}` 是什么 ?
>
> ```go
> chan struct{}   // 一个 channel , 里面流动的元素类型是 struct{}
> ```
>
> channel 在 Go 里就是 "管道" , **管道里流动的东西有类型** :
>
> ```go
> chan int        // 里面流动 int
> chan string     // 里面流动 string
> chan struct{}   // 里面流动空结构体
> ```
>
> 所以 `chan struct{}` 读作 : "一个元素类型为 `struct{}` 的 channel" .
>
> ## 第二部分 : `<-chan` 和 `chan<-` 是什么 ?
>
> Go 允许**限制 channel 的方向** . `chan` 前面的箭头表示**你能对它做什么操作** :
>
> | 写法       | 名称             | 含义             | 你能做的操作   |
> | ---------- | ---------------- | ---------------- | -------------- |
> | `chan T`   | 双向             | 既能发也能收     | 发和收         |
> | `<-chan T` | **只读（接收）** | 只能从里面**取** | 只能 `<-ch`    |
> | `chan<- T` | **只写（发送）** | 只能往里面**放** | 只能 `ch <- v` |
>
> ### 关键 : 箭头指向哪里
>
> 箭头 `<-` 就像 "数据流动的箭头" :
>
> ```go
> <-chan T     // 箭头从 channel 指出 → 数据只能流出 → 你只能接收（读）
> chan<- T     // 箭头指向 channel → 数据只能流入 → 你只能发送（写）
> ```
>
> 记忆口诀 : **箭头离开 channel = 数据流出 = 你只读 ; 箭头指向 channel = 数据流入 = 你只写 . **
>
> ```go
> // 返回一个能读能写的 channel
> func A() chan int { . . . }
> 
> // 返回一个只能读的 channel（对调用者而言）
> func B() <-chan int { . . . }
> 
> // 返回一个只能写的 channel
> func C() chan<- int { . . . }
> ```
>
> 调用者拿到 `B()` 的返回值后 :
>
> ```go
> ch : = B()
> v : = <-ch     // ✅ 可以读
> ch <- 1       // ❌ 编译错误 : cannot send to receive-only channel
> ```
>
> ## 为什么要限制成只读 ?
>
> 设计者返回 `<-chan struct{}`（而不是 `chan struct{}`）是**故意的保护** :
>
> - `Done()` 的 channel 应该**只由内部关闭**（表示完成） , 外部只应该 "等待它关闭" .
> - 如果返回双向 `chan` , 外部就能 `close()` 或往里塞数据 , 破坏语义 .
> - 返回只读后 , 外部**只能 `<-ch` 等待** , 从类型层面就杜绝了误用 .
>
> ## 一句话总结
>
> - `chan struct{}` : 一个元素是空结构体的 channel .
> - `<-chan` : **只读方向的 channel 类型**（箭头指出 = 数据流出 = 你只能接收） .
> - 合起来 `<-chan struct{}` : **一个只读的、元素为 `struct{}` 的 channel** .
> - 在 `Done()` 里 , 它表示 "你只能等这个 channel 关闭来获知完成信号 , 不能对它做别的事" .

取消通知通过 channel 的关闭传递 , 不需要发送一个具体的 `struct{}` 值 .

## 2. `Background` 提供起点

签名 :

```go
func Background() Context {
	return backgroundCtx{}
}

// backgroundCtx{}
type backgroundCtx struct{ emptyCtx }

type emptyCtx struct{}

// Context , 前文也有解释
type Context interface {
	Deadline() (deadline time.Time, ok bool)
	Done() <-chan struct{}
	Err() error
	Value(key any) any
}
```

调用时写包名 :

```go
parent := context.Background()
```

变量 `parent` 的声明类型是 `context.Context` . 它没有截止时间 , 不会自行取消 , 常用作创建其他 context 的起点 .

`parent.Done()` 返回的是 nil channel . 程序直接等待这个 channel 会一直阻塞 , 因此程序通常从它创建一个可取消的子 context .

## 3. `WithCancel` 返回 context 和函数

签名 :

```go
func WithCancel(parent Context) (ctx Context, cancel CancelFunc)
type CancelFunc func()
```

完整程序 :

```go
package main

import (
	"context"
	"fmt"
)

func main() {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	fmt.Println(ctx.Err()) // <nil>
	cancel() // 再调用一次是为了安全的 , cancel 是幂等的 , 调多次没关系
	<-ctx.Done()
	fmt.Println(ctx.Err()) // context canceled
}
```

先按返回类型分析变量 :

| 变量 | 类型 | 用途 |
| --- | --- | --- |
| `ctx` | `context.Context` | 交给任务 , 用来接收取消通知 |
| `cancel` | `context.CancelFunc` | 交给控制方 , 用来发出取消通知 |

`CancelFunc` 定义为 `func()` , 所以变量 `cancel` 保存的是一个不接收参数、不返回值的函数 . `cancel()` 是调用这个函数 .

`cancel` 在用途上有些像 C 的函数指针 , 但 Go 这里使用的是函数值 . 返回的函数已经关联了这次创建的子 context , 调用时不需要再传入 `ctx` .

`defer cancel()` 表示 : `main` 返回时 , 再调用这个函数 . 登记 `defer` 不会立即取消 context .

例子中间的 `cancel()` 则会立即发出取消通知 . `ctx.Done()` 返回的 channel 关闭后 , `<-ctx.Done()` 就可以继续执行 ; `ctx.Err()` 随后返回 `context.Canceled` , 它的类型是 `error` .

同一个取消函数可以调用多次 , 第一次之后的调用不会再次取消 . 因此 , 例子中的显式调用和延后调用可以同时存在 

## 4. 任务要主动响应通知

上一节只是演示状态变化 . 下面的完整程序让一个 goroutine 等待取消通知 :

```go
package main

import (
	"context"
	"fmt"
)

func wait(ctx context.Context, finished chan<- struct{}) {
	<-ctx.Done()
	fmt.Println("任务收到取消通知")
	close(finished)
}

func main() {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	finished := make(chan struct{})

	go wait(ctx, finished)
	cancel()
	<-finished // 阻塞式接收。它阻塞到 channel 有值可读（或已关闭）为止。
}
```

`finished` 的类型是 `chan struct{}` . 参数 `finished chan<- struct{}` 把函数内可用的操作限制为发送和关闭 , 不允许接收 .

> [!NOTE]
>
> `<-chan int`、`chan<- int`、`chan int` 是**三个不同的类型** . 区别只是 Go 允许 **双向 → 单向** 的**隐式赋值**（单向能力是双向的子集 , 安全） , 但**不允许单向 → 双向**（会丢失编译期约束） .

这里有两种不同的通知 :

- `cancel()` 通知任务停止 .
- `close(finished)` 通知调用方 : 任务已经执行完清理并结束 .

`cancel()` 不等待任务结束 . 如果 `main` 需要确认任务已经结束 , 它就要像例子这样单独等待 .

如果一个循环完全不检查 `ctx.Done()` 或 `ctx.Err()` , 这个循环就不会因为 context 取消而自动停止 .

## 5. `WithTimeout` 设置等待上限

签名 :

```go
func WithTimeout(parent Context, timeout time.Duration) (Context, CancelFunc)
```

`time.Duration` 表示时间段 . `2 * time.Second` 的类型是 `time.Duration` , 表示两秒 ; 下一篇会展开时间单位 .

完整程序 :

```go
package main

import (
	"context"
	"fmt"
	"time"
)

func main() {
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()

	<-ctx.Done()
	fmt.Println(ctx.Err()) // context deadline exceeded
}
```

`ctx` 的类型仍然是 `context.Context` , `cancel` 的类型仍然是 `context.CancelFunc` .

两秒到达后 , `ctx.Done()` 返回的 channel 会关闭 , `ctx.Err()` 返回 `context.DeadlineExceeded` . 这个值的类型也是 `error` .

如果操作在两秒之前完成 , 程序仍然应该调用 `cancel()` , 释放计时等相关资源 . `defer cancel()` 可以保证函数提前返回时也会执行这个动作 .

如果程序已经有一个确定的截止时间 , 可以使用 `context.WithDeadline` . 它的第二个参数是 `time.Time` , 返回值仍然是 `(context.Context, context.CancelFunc)` .

## 6. 父子 context 怎样关联

局部片段 , 放在函数中 , 导入 `context` 和 `time` :

```go
parent, stopParent := context.WithCancel(context.Background())
defer stopParent()

child, stopChild := context.WithTimeout(parent, 5*time.Second)
defer stopChild()
```

`parent` 和 `child` 都是 `context.Context` ; `stopParent` 和 `stopChild` 都是 `context.CancelFunc` .

程序调用 `stopParent()` 时 , 父 context 及其子 context 都会被取消 . 程序只调用 `stopChild()` 时 , 父 context 不受影响 .

如果父 context 先到达截止时间 , 子 context 也会随之取消 . 子 context 的五秒上限不会延长父 context 的期限 .

> [!NOTE]
>
> ### 从源码层面展示级联取消
>
> 摘自`context.go` 
>
> ```go
> // create child context
> func WithCancel(parent Context) (ctx Context , cancel CancelFunc) {
> 	c : = withCancel(parent)
> 	return c , func() { c.cancel(true , Canceled , nil) }
> }
> 
> // withCancel
> func withCancel(parent Context) *cancelCtx {
> 	if parent == nil {
> 		panic( "cannot create context from nil parent" )
> 	}
> 	c : = &cancelCtx{}
> 	c.propagateCancel(parent , c)
> 	return c
> }
> 
> // 传播取消信号
> func (c *cancelCtx) propagateCancel(parent Context , child canceler) {
>   	c.Context = parent
> 
> 	done : = parent.Done()
> 	if done == nil {
> 		return // parent is never canceled
> 	}
> 
> 	select {
> 	case <-done :
> 		// parent is already canceled
> 		child.cancel(false , parent.Err() , Cause(parent))
> 		return
> 	default :
> 	}
>   
>   if a , ok : = parent.(afterFuncer) ; ok {
> 		// parent implements an AfterFunc method.
> 		c.mu.Lock()
> 		stop : = a.AfterFunc(func() {
> 			child.cancel(false , parent.Err() , Cause(parent))
> 		})
> 		c.Context = stopCtx{
> 			Context : parent ,
> 			stop : stop ,
> 		}
> 		c.mu.Unlock()
> 		return
> 	}
> 
> 	goroutines.Add(1)
> 	go func() {
> 		select {
> 		case <-parent.Done() :
> 			child.cancel(false , parent.Err() , Cause(parent))
> 		case <-child.Done() :
> 		}
> 	}()
> }
> 
> // call cancel
> func (c *cancelCtx) cancel(removeFromParent bool , err , cause error) {
>   // . . .
>   
>   for child : = range c.children {
> 		// NOTE : acquiring the child's lock while holding parent's lock.
> 		child.cancel(false , err , cause)
> 	}
>   
>   // . . .
>   
>   if removeFromParent {
>     removeChild(c.Context , c)
> 	}
>   
>   // . . .
> }
> ```

## 7. 把 context 继续传给执行任务的函数

Go 函数通常把 context 放在第一个参数 :

```go
func read(ctx context.Context) error {
	if err := ctx.Err(); err != nil {
		return err
	}
	return nil
}
```

这段示意函数接收 `context.Context` , 返回 `error` . 它只检查一次当前是否已取消 , 不代表真实读取操作 .

程序调用另一个支持 context 的 API 时 , 还应该把 `ctx` 继续传入 . 下一篇之后的 HTTP 章节会介绍这种调用 .

## 小练习

1. `ctx, cancel := context.WithCancel(...)` 中 , 两个变量的类型分别是什么 ?
2. `cancel()` 和 `<-finished` 分别在做什么 ? 为什么前者不能替代后者 ?
3. 父 context 在第一秒取消 , 子 context 设置了五秒超时 , 子 context 还要等满五秒吗 ?

查阅签名时 , 可以在 Go 官方文档中搜索 `context` .

下一篇 : [time 和 signal](./03-time-signal.md) .
