# panic 和 recover

## 1. `panic` 是什么

`panic` 表示程序遇到了不能继续按正常流程处理的情况 .

程序可以主动调用 `panic` :

```go
func mustBePositive(n int) {
	if n <= 0 {
		panic("n 必须是正数")
	}
}
```

调用 `mustBePositive(0)` 后 , 因为不符合 "必须是正数的要求" , 程序会处理这次 panic , 而不会返回 `return` .

程序也可能因为运行时错误自动触发 panic , 例如 :

```go
numbers := []int{1, 2}
fmt.Println(numbers[2]) // 下标越界，触发 panic
```

当前教程前面已经遇到过两种情况 :

- 程序向 nil map 写入数据 .
- 程序使用不带 `ok` 的类型断言 , 但实际类型不匹配 .

空指针访问、数组或切片下标越界 , 也可能触发 panic.

## 2. `panic` 会沿调用栈展开

下面的代码有三层函数 , 执行的时候因为 panic 他们会按照调用栈退回 , 这个退回不是为了执行 "后面的函数" , 而是寻找有没有 `recover` , 如果没有就退出程序了(当然这里会依据调用栈产生相应的报错信息) .

```go
func levelOne() {
	levelTwo()
}

func levelTwo() {
	panic("发生错误")
}

func main() {
	levelOne()
	fmt.Println("这一行不会执行")
}
```

`panic` 不会像普通 `error` 一样自动变成返回值 . 调用方只有在明确使用 `recover` 时 , 才可以恢复这次 panic.

## 3. panic 不会取消已经注册的 defer

```go
func work() {
	defer fmt.Println("清理工作")
	panic("工作失败")
}
```

程序调用 `work()` 时 , 程序会先登记 `defer` , 再触发 panic.Go 运行时在离开 `work` 时仍会执行已经登记的 `defer` , 所以程序会先输出 "清理工作" , 再继续处理 panic.如果调用栈中的上层函数也登记了 `defer` , 上层函数的 `defer` 也会在展开过程中执行 .

这个规则解释了为什么程序经常把关闭文件、数据库连接和取消 context 写成 :

```go
defer resource.Close()
defer cancel()
```

但是 , `os.Exit` 不会展开调用栈 , 也不会执行已经登记的 `defer` . 这就是为什么资源清理不能依赖 `os.Exit` 来完成 .

## 4. `recover` 函数

关于 `recover` 函数 , 有三个知识点 :

- `recover` 函数的返回值是 panic 传入的内容 , 函数本身的返回值类型是 `any` 

- `recover` 只能在 `defer` 中使用

- 上一级的函数可以处理下一级函数的 `panic` , 但是触发 `panic` 的函数和调用 `recover()` 的函数必须运行在同一个 goroutine 中 , 否则不能处理 `panic` .

程序可以使用 `recover` 把当前 goroutine 中的 panic 转换成普通流程

```go
func safeWork() (err error) {
	defer func() {
		if value := recover(); value != nil {
			err = fmt.Errorf("工作失败: %v", value)
		}
	}()

	panic("测试错误")
}
```

调用 `safeWork()` 后 , 函数会返回一个普通的 `error` , 而不是让 panic 继续结束进程 .

上面的代码有三个关键点 :

1. `recover` 写在 `defer` 调用的匿名函数中 .
2. 这个匿名函数和触发 panic 的代码运行在同一个 goroutine 中 .
3. 匿名函数把 panic 信息转换成了返回值 .

如果程序在普通函数中直接调用 `recover` , 这个调用通常会返回 `nil` :

```go
value := recover() // 不在 defer 登记的函数中，不能恢复正在展开的 panic
```

- 如果程序已经恢复了 panic , 程序不会自动从触发 panic 的那一行继续执行 . 程序会从完成恢复的 `defer` 函数之后继续返回 .

## 5. 什么时候返回 `error`

程序遇到可以预期、可以交给调用方处理的失败时 , 通常应该返回 `error` :

```go
func loadConfig(path string) ([]byte, error) {
	return os.ReadFile(path)
}
```

文件不存在、用户输入无效、网络请求失败 , 通常都属于这类情况 . 调用方可以决定显示错误、重试还是结束当前操作 .

程序只有在遇到违反内部假设、无法继续保持正常状态的情况时 , 才考虑使用 `panic` . 即使程序使用了 `panic` , 程序也应该让上层边界决定是否记录日志、恢复请求或结束进程 .

不要把所有错误都改成 `panic` . 这样会让单个输入问题扩大成整个进程的问题 , 也会让调用方失去选择处理方式的机会 .

## 6. 当前项目中的两层处理

当前项目的 `internal/platform/http.go` 在请求安全中间件中登记了 deferred 函数 :

```go
defer func() {
	if v := recover(); v != nil {
		slog.Error("request panic", "path", c.Path())
		_ = fiberError(c, 500, "请求处理失败")
	}
}()
```

如果同一个请求 goroutine 中的后续处理触发 panic , 这个 deferred 函数会记录日志 , 并尝试向浏览器返回 500 错误 .

Fiber 的 `ErrorHandler` 处理的是 handler 返回的错误 , 例如路由不存在或请求体过大 . `recover` 处理的是 Go 运行时展开的 panic.这两种情况都可能最后产生 HTTP 错误响应 , 但触发原因不同 .

请求边界可以恢复一次 panic , 不表示业务代码可以忽略错误检查 . 数据库错误、模型超时和用户输入错误仍然应该通过 `error` 返回和处理 .

## 小练习

请判断下面三种情况应该优先使用什么方式 :

1. 用户输入了不存在的题目 ID.
2. 数据库连接暂时失败 .
3. 程序发现一个本来不可能出现的内部状态 .

前两种情况通常返回 `error` . 第三种情况需要结合系统边界判断是否使用 `panic` , 不能只根据错误文字决定 .

参考 : [Go 语言规范：Handling panics](https://go.dev/ref/spec#Handling_panics) .
