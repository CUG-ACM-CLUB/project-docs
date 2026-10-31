# 返回值和错误

## 1. 错误也是返回值

下面是一个完整的小程序 :

```go
package main

import (
	"errors"
	"fmt"
)

func divide(a, b int) (int, error) {
	if b == 0 {
		return 0, errors.New("不能除以零")
	}
	return a / b, nil
}

func main() {
	value, err := divide(10, 0)
	if err != nil {
		fmt.Println(err)
		return
	}
	fmt.Println(value)
}
```

`divide` 返回两个值 : 计算结果、错误 .

`errors.New` 创建错误 . 成功时返回 `nil` , 表示这里没有错误 . 失败时约定第一个结果不可用 , 调用方不要继续使用它 .

Go 不会因为返回了 `error` 就自动停止执行 . 调用方必须检查 `err` .

## 2. 项目如何处理错误

在 `main.go` 中 :

```go
if err := serve(); err != nil {
	slog.Error("server stopped", "error", err)
	os.Exit(1)
}
```

`serve()` 返回错误后 , `main` 记录原因并退出 . 这里没有 `try/catch` .

在 `serve()` 内部 :

```go
store, err := platform.Open(ctx, os.Getenv("DATABASE_URL"))
if err != nil {
	return errors.New("database connection failed")
}
```

连接失败就返回新错误 , 后面的启动代码不会执行 . 这里没有附带原始连接错误 , 不能把它和下面的 "包装错误" 混为一谈 .

## 3. 直接返回与包装

```go
return err
```

把已有错误交给调用方 .

```go
return fmt.Errorf("database migration failed: %w", err)
```

为已有错误增加说明 , 并通过 `%w` 保留原始错误关系 .

后续可以用 `errors.Is` 检查被包装的错误 , 不必比较报错文字 . 用法见 [errors 包](../02-standard-library/06-errors.md) .

## 4. `nil` 不只用于错误

`nil` 也可用于指针、切片、map、channel、函数和接口 , 不能当作任意类型的空值 .

例如 `int` 的零值是 `0` , `string` 的零值是 `""` , 不是 `nil` .

本篇先记住最常见的错误约定 :

```text
err == nil    没有报告错误
err != nil    有错误需要处理
```

接口中装入空指针不一定等于 `nil` , 接口篇会解释 .

## 5. `return`、`os.Exit`、`panic`

| 写法 | 作用 |
| --- | --- |
| `return` | 结束当前函数 , 把返回值交给调用方 |
| `os.Exit(1)` | 立即结束进程 , 退出码为 1 |
| `panic(...)` | 中断当前正常流程并沿调用栈展开 , 可被 `recover` 捕获 |

函数返回时会执行已登记的 `defer` . `os.Exit` 不执行它们 . `panic` 展开调用栈时通常会执行沿途的 `defer` ; 普通的输入错误、数据库错误不需要因此改成 `panic` .

这里先只区分三种退出方式 . `panic` 如何产生、如何展开、为什么仍会执行 `defer` , 以及 `recover` 如何介入 , 会在 [panic 和 recover](./09-panic-and-recover.md) 中单独讲解 .

不使用某个返回值时 , 可以写 `_` :

```go
_, err = store.DB.Exec(ctx, query)
```

这里忽略 SQL 执行结果 , 但保留错误检查 . `_` 不保存数据 , 也不能被读取 .

## 小练习

如果删掉最小程序里的 `if err != nil` , 为什么除零错误不会自动被处理 ?

参考 : [Go 官方博客：错误处理](https://go.dev/blog/error-handling-and-go) .
