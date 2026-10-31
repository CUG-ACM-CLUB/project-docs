# goroutine、channel 和 select

本篇只介绍阅读当前项目所需要的并发基础 .

本篇会先解释为什么需要 channel , 再介绍 goroutine、发送、接收、阻塞、缓冲和 `select` . 本篇暂不展开复杂的并发设计 .

## 1. 为什么需要 channel

假设程序启动了两个 goroutine :

```go
go work()
go report()
```

这两个任务可以同时运行 , 但它们之间没有直接的通信方式 .

如果 `work` 执行结束后需要通知 `report` , 程序可以使用 channel :

```text
work goroutine
      |
      | 发送“完成”
      v
   channel
      |
      | 接收“完成”
      v
report goroutine
```

因此 , channel 可以先理解为 :

> channel 是 Go 提供的一条带类型的通信通道 . 一个 goroutine 把数据放进去 , 另一个 goroutine 从里面取出来 .

## 2. `go` 会启动一个 goroutine

```go
go work()
continueWork()
```

`go work()` 会启动一个 goroutine 执行 `work` . 当前 goroutine 不会等待 `work` 执行结束 , 而是继续执行 `continueWork` .

goroutine 是由 Go 运行时调度的执行单元 . goroutine 不等于每次都新建一个操作系统线程 .

启动 goroutine 不代表任务已经完成 , 也不保证两个任务的执行顺序 . `main()` 返回后 , 程序不会为了等待 goroutine 完成而自动运行 .

当前项目中 :

```go
go platformServer.RefreshLoop(ctx)
```

这条语句让后台刷新循环与 HTTP 服务同时运行 .

## 3. 创建 channel

程序可以使用 `make` 创建 channel :

```go
numbers := make(chan int)
```

这条语句创建了一个 channel :

```text
变量名：numbers
传输的数据类型：int
```

这个 channel 只能传输整数 :

```go
numbers <- 42
```

下面的代码会产生类型错误 :

```go
numbers <- "完成" // 编译错误
```

程序也可以创建传输字符串的 channel :

```go
messages := make(chan string)
```

## 4. 发送和接收

发送数据使用下面的语法 :

```go
channel <- value
```

例如 :

```go
numbers <- 42
```

这条语句表示 : 程序把整数 `42` 发送到 `numbers` channel.

接收数据使用下面的语法 :

```go
value := <-channel
```

例如 :

```go
number := <-numbers
```

这条语句表示 : 程序从 `numbers` channel 接收一个整数 , 并把整数保存到 `number` .

## 5. 一个完整的发送和接收例子

程序启动后 , Go 会让 `main` 函数运行在一个特殊的 goroutine 中 . 这个 goroutine 通常叫作 `main goroutine` . 现在按执行顺序阅读这段代码 .

```go
package main

import "fmt"

func main() {
	numbers := make(chan int)

	go func() {
		numbers <- 42
	}()

	number := <-numbers
	fmt.Println(number)
}
```

第一步 , `main` 创建一个传输整数的无缓冲 channel :

```go
numbers := make(chan int)
```

此时 channel 还没有整数 . 这个 channel 等待一个发送方和一个接收方完成交接 .

第二步 , `main` 通过创建一个匿名函数启动一个新的 goroutine :

```go
go func() {
	numbers <- 42
}()
```

第三步 , `main` 执行接收 :

```go
number := <-numbers
```

因为 `numbers` 是无缓冲 channel , 如果发送方还没有准备好 , `main goroutine` 会在这一行等待 . 如果发送方已经执行到 `numbers <- 42` , `main goroutine` 和发送方 goroutine 就在 channel 这里完成交接 .

交接完成后 , 发送方完成这次发送动作 , `main goroutine` 从 `channel` 取得 `42` 并保存到 `number` 中 .

第四步 , `main` 打印接收到的整数 :

```go
fmt.Println(number)
```

因此 , 这个程序的完整流程是 :

```text
main goroutine 创建通道 numbers
        ↓
main goroutine 启动发送方 goroutine
        ↓
发送方 goroutine 准备发送 42
        ↓
main goroutine 准备接收 42
        ↓
main goroutine 和发送方 goroutine 通过 channel 完成数据交接
        ↓
main goroutine 把 42 保存到 number
        ↓
main goroutine 打印 42
```

这个例子中 , 发送语句正好是发送方 goroutine 的最后一条语句 . `number := <-numbers` 等待的是数据交接 , 不是专门等待发送方 goroutine 完整结束 . 这个区别会在第 7 节单独说明 .

## 6. 为什么发送和接收会等待

例子中的 channel 是无缓冲 channel . 

无缓冲 channel 没有可以暂时保存数据的空间 . 发送方执行发送任务时 , 发送方需要等待接收方准备好 ; 接收方准备接收时 也需要发送方准备好 , 所以 `<-` 无论是在发送方中还是在接收方中 , 都会阻塞当前协程 , 直到对方准备好 , 才会开始传输同步信息(也就是例子中的`42`) . 因此 , 无缓冲 channel 更像一次 ** "当面交接" ** : 发送方和接收方必须在同一时刻完成交接 .

如果程序按照下面的顺序执行 :

```go
numbers := make(chan int)
numbers <- 42
number := <-numbers
```

这三行代码全部运行在同一个 `main goroutine` 中 . `numbers <- 42` 时 , `main goroutine` 就会阻塞等待 , 所以后续的接收方准备永远也执行不到(因为在同一个协程中) , 所以这段代码会直接卡死 . 正确的写法是像例子中一样使用另一个协程 .

## 7. WaitGroup

第六节的例子中 , 发送方 goroutine 发送 `42` 之后就没有其他代码了 . 因此 , 主 goroutine 完成接收后 , 发送方 goroutine 没有其他可观察的工作了 . 接收动作本身仍然不负责等待发送方 goroutine 完整结束 . 但是 , 接收数据不等于等待发送方 goroutine 执行结束 . 下面的例子在发送操作之后还有一条打印语句 :

```go
numbers := make(chan int)

go func() {
	numbers <- 42
	fmt.Println("发送之后的代码")
}()

number := <-numbers
fmt.Println(number)
```

执行过程如下 :

1. 发送方 goroutine 执行 `numbers <- 42` .
2. 主 goroutine 的 `number := <-numbers` 接收 `42` .
3. 发送方 goroutine 完成发送后 , 继续执行 `fmt.Println("发送之后的代码")` . 主 goroutine 打印 `number` .

主 goroutine 接收到 `42` , 只能说明发送操作已经完成 . 这个结果不能说明发送方 goroutine 后面的代码已经执行完 .

如果 `main()` 在发送方 goroutine 执行完之前返回 , 整个程序就会结束 . 发送方 goroutine 可能还没有机会执行后面的代码 .

因此 , 程序需要区分 "协程信息交换完毕" 和 "协程本身执行完毕" 这两件事 . 于是 , 我们需要 **sync.WaitGroup** . `sync.WaitGroup` 可以帮助程序等待一组 goroutine 执行结束 . 使用 `WaitGroup` 时 , 程序需要完成三步 :

1. 使用 `Add(1)` 登记一个需要等待的 goroutine.
2. 在这个 goroutine 执行结束时调用 `Done()` .
3. 在主 goroutine 中调用 `Wait()` , 等待已经登记的 goroutine 全部调用 `Done()` .

```go
import "sync"

var group sync.WaitGroup
numbers := make(chan int)

group.Add(1)

go func() {
	defer group.Done()

	numbers <- 42
	fmt.Println("发送之后的代码")
}()

number := <-numbers
fmt.Println(number)

group.Wait()
```

在这个例子中 :

- `number := <-numbers` 等待发送方把 `42` 交给主 goroutine.
- `group.Wait()` 等待发送方 goroutine 执行完打印语句 .
- `defer group.Done()` 保证这个 goroutine 返回时通知 `WaitGroup` .

因此 , channel 负责在两个 goroutine 之间交接数据 , `WaitGroup` 负责等待 goroutine 完整结束 .

## 8. 有缓冲 channel

程序可以在创建 channel 时指定缓冲容量 :

```go
numbers := make(chan int, 2)
```

这表示 `numbers` 最多可以暂时保存两个整数 .

因此 , 下面两次发送可以先把数据放入缓冲区 :

```go
numbers <- 10
numbers <- 20
```

第三次发送会等待 :

```go
numbers <- 30
```

除非另一个 goroutine 先接收并取走一个数据 .

两种 channel 可以这样比较 :

- 无缓冲 channel : 发送必须等待接收
- 有缓冲 channel : 缓冲区没有满时 , 发送可以先保存数据

当前项目中的 `shutdownDone` 是一个容量为 1 的 channel :

```go
shutdownDone := make(chan error, 1)
```

关闭 goroutine 会把关闭结果放入这个 channel :

```go
shutdownDone <- errors.Join(err, drain(shutdown))
```

主流程稍后会从这个 channel 取出结果 :

```go
shutdownErr := <-shutdownDone
```

容量为 1 可以让关闭 goroutine 先保存一个结果 , 不必等待主流程恰好同时执行接收 .

## 9. `close` 表示不会再发送

`close(channel)` 表示发送方已经不会再向这个 channel 发送新的数据 .

```go
numbers := make(chan int, 2)

numbers <- 10
numbers <- 20
close(numbers)
```

关闭 channel 不会删除已经发送的数据 . 接收方仍然可以读取缓冲区里的 `10` 和 `20` :

```go
fmt.Println(<-numbers) // 10
fmt.Println(<-numbers) // 20
```

如果接收方使用 `range` :

```go
for number := range numbers {
	fmt.Println(number)
}
```

这个循环会持续读取数据 , 直到 channel 已经关闭并且其中的数据已经全部读完 .

程序不应该重复关闭同一个 channel , 也不应该向已经关闭的 channel 发送数据 . 这两种操作都会触发 `panic` .

## 10. 使用 `chan struct{}` 发送完成通知

有些场景不需要传输数据 , 只需要通知另一个 goroutine : "某件事已经发生" .

这时程序可以使用 `struct{}` :

```go
done := make(chan struct{})
```

`struct{}` 是一个没有字段的结构体 . 这个 channel 不需要传输业务数据 , 因此使用空结构体表达 "只有通知 , 没有数据" .

发送方可以关闭 channel :

```go
close(done)
```

等待方可以接收通知 :

```go
<-done
```

如果 `done` 还没有关闭 , 等待方会继续等待 . 如果 `done` 已经关闭 , `<-done` 会立即继续执行 .

关闭 channel 会通知所有正在等待这个 channel 的接收方 . 因此 , 一个完成通知可以同时唤醒多个等待方 .

## 11. `select` 等待多个事件

程序可以使用 `select` 同时等待多个 channel 操作 :

```go
select {
case <-done:
	fmt.Println("工作结束")
case <-ctx.Done():
	fmt.Println("收到取消信号")
}
```

上面的代码会等待两个事件 : `done 被关闭` 和 `ctx 被取消` . 哪个事件先发生 , 程序就执行哪个 `case` . 如果没有任何事件发生 , `select` 会继续等待 .

程序加入 `default` 后 , `select` 就不会继续等待 :

```go
select {
case value := <-numbers:
	fmt.Println(value)
default:
	fmt.Println("当前没有数据")
}
```

如果 `numbers` 当前没有可以接收的数据 , 程序会立即执行 `default` .

## 12. 回到当前项目

`cmd/acm/server.go` 中有两个重要的 channel :

```go
stopped := make(chan struct{})
shutdownDone := make(chan error, 1)
```

这两个 channel 的用途不同 :

- `stopped` : 通知关闭 goroutine , HTTP 服务已经停止监听 .
- `shutdownDone` : 把关闭过程产生的 error 传回主流程 .

关闭流程可以简化为 :

```text
serveHTTP 启动关闭 goroutine
        ↓
关闭 goroutine 等待 ctx.Done() 或 stopped
        ↓
关闭 goroutine 执行 server.Shutdown
        ↓
关闭 goroutine 等待 HTTP 请求和 Agent 任务清理
        ↓
关闭 goroutine 把 error 放入 shutdownDone
        ↓
主流程从 shutdownDone 取出 error
```

## 13. channel 不会自动保护共享数据

channel 可以帮助 goroutine 传递数据或发送通知 , 但 channel 不会自动解决所有并发问题 .

如果两个 goroutine 同时修改同一个普通变量 , 程序可能产生数据竞争 :

```go
count := 0

go func() {
	count++
}()

go func() {
	count++
}()
```

当前项目使用不同工具解决不同问题 :

```text
channel：让 goroutine 传递数据或通知
sync.Mutex：保护共享数据
sync.WaitGroup：等待多个 goroutine 完成
```

## 小练习

1. 为什么无缓冲 channel 的发送方需要等待接收方 ?
2. `close(done)` 和 `done <- true` 有什么不同 ?
3. `shutdownDone` 为什么使用容量为 1 的 channel ?
4. `go work()` 后 , 为什么 `main()` 立即返回时不能保证 `work()` 已经完成 ?

参考 : [Go Tour：goroutine](https://go.dev/tour/concurrency/1)、[channel](https://go.dev/tour/concurrency/2) .
