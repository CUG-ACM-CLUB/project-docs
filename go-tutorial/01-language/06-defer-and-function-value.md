# defer 和函数值

## 1. `defer` 把调用留到函数退出时

```go
func show() {
	defer fmt.Println("结束")
	fmt.Println("开始")
}
```

调用 `show()` , 先输出 "开始” , 再输出“结束" .

多个 defer 按后登记先执行的顺序运行 .

```go
defer fmt.Println("A")
defer fmt.Println("B")
```

函数退出时先输出 B , 再输出 A.循环里的 defer 不在本次循环结束时执行 , 而是在所在函数退出时执行 .

## 2. 项目用它清理资源

```go
store, err := platform.Open(ctx, os.Getenv("DATABASE_URL"))
if err != nil {
	return errors.New("database connection failed")
}
defer store.DB.Close()
```

连接成功后才登记关闭 . 后续无论在哪个分支正常返回 , 都会尝试关闭连接池 .

`defer` 不表示代码现在被放到后台执行 . 它仍然是当前函数退出过程的一部分 .

`os.Exit` 直接结束进程 , 不执行 defer.当前项目让 `serve()` 先返回 , 再由 `main()` 调用 `os.Exit` , 这样 `serve()` 内的 defer 有机会运行 .

## 3. 参数现在求值 , 函数稍后调用

```go
n := 1
defer fmt.Println(n)
n = 2
```

函数退出时输出 `1` , 因为登记 defer 时已经计算了参数 `n` . 这里先记住此规则 , 下一节会对比闭包 .

> [!NOTE]
>
> `defer` 语句执行时 , Go 运行时会做两件事 :
>
> 1. **立即求值**函数名和所有实参 , 得到一个 `(fn, args...)` 的元组
> 2. **把这个元组压入当前 goroutine 的 defer 栈**（保存起来 , 不调用）
>
> 等外层函数 return 时 , 才从 defer 栈里依次弹出并**真正调用**这些保存好的 `(fn, args...)` .
>
> > 相当于做了一个快照 , 最后时刻再弹出快照里面的内容 , 没错这个时候会造成内存负担 ! 尤其是在循环中 , 每次迭代压一条记录 , 循环 N 次就攒 N 条 , 全部到函数 return 才释放 . 这是最常见的坑 . 同时需要注意到 :
> >
> > - **Go 1.13** : 引入**开放编码（open-coded defer）**——对于 "非循环、defer 数量固定、函数不 panic 路径复杂" 的常见情况 , 编译器把 defer 记录直接放在**栈上** , 几乎零额外分配 . 绝大多数普通函数里的 defer 因此变得很便宜 .
> > - **Go 1.14** : 基于寄存器的调用约定进一步降低开销 .
> >
> > 但注意 : **循环里的 defer 无法用开放编码** , 会退回到堆分配——这也从编译器层面印证了 "循环里 defer 才是负担" .

## 4. 函数也可以是变量的值

> 有点像 函数指针

```go
func add(a, b int) int {
	return a + b
}

calculate := add
answer := calculate(2, 3) // 5
```

`add` 表示函数本身 ; `add(2, 3)` 表示调用结果 .

函数类型也能写成参数 :

```go
func apply(f func(int, int) int) int {
	return f(2, 3)
}
```

项目中 `serveHTTP` 接收 `drain func(context.Context) error` :

```go
func serveHTTP(
  ctx context.Context, 
  server *http.Server, 
  listener net.Listener, 
  drain func(context.Context) error
) error
```

它需要一个 "接收 context , 返回 error" 的函数 . 启动代码传入 `platformServer.Tasks.Shutdown` , 没有写括号 , 因此此时不执行关闭 .

## 5. 匿名函数

不单独起名字的函数就是匿名函数 :

```go
double := func(n int) int {
	return n * 2
}
fmt.Println(double(3)) // 6
```

定义后也可以立即调用 :

```go
func() {
	fmt.Println("立即执行")
}()
```

最后的 `()` 才是执行动作 .

## 6. 闭包访问外层变量

```go
n := 1
defer func() {
	fmt.Println(n)
}()
n = 2
```

退出时输出 `2` . 这个匿名函数读取的是外层变量 `n` ; 不是像 `defer fmt.Println(n)` 那样提前取出整数作为参数 .

`main.go` 中给 `model.Observe` 赋值的匿名函数会访问外层的 `store` 和 `configID` . 这就是项目里的闭包 .

只赋值给 `model.Observe` 不会立刻发起调用 . 模型适配器之后主动调用它时 , 里面的代码才执行 .

> [!TIP]
>
> **在 Go 中 , 闭包通常由匿名函数产生** , 但 "闭包”和“匿名函数" 强调的重点不同 :
>
> - 匿名函数 : 函数没有名字 .
> - 闭包 : 函数保存并使用了外层作用域中的变量 .
>
> ---
>
> Go 中严格意义上的闭包一定由匿名函数（函数字面量）产生 . 所以闭包一定是匿名函数 .

## 小练习

`defer cancel()` 与直接写 `cancel()` , 在执行时间上有什么不同 ?

参考 : [Go Tour：defer](https://go.dev/tour/flowcontrol/12)、[函数值](https://go.dev/tour/moretypes/24) .
