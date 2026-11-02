# 怎样读函数签名和返回值

Go 的 `:=` 不会把变量类型写在左边 . 编译器会根据右边表达式的类型确定变量类型 . 阅读者也可以沿着这个关系判断类型 .

## 1. 从函数签名确定变量类型

假设有一个函数 :

```go
func length(text string) int {
	return len(text)
}
```

`length` 接收一个 `string` , 返回一个 `int` . 因此 :

```go
n := length("hello")
```

变量 `n` 的类型是 `int` . 这行也可以用显式类型写成 :

```go
var n int = length("hello")
```

两种写法声明的变量类型相同 . `:=` 不表示变量可以随意改变类型 .

## 2. 多个返回值按位置对应

下面是 `os.LookupEnv` 的签名 :

```go
func LookupEnv(key string) (string, bool)
```

这个函数属于 `os` 包 , 所以调用时写 `os.LookupEnv` :

```go
value, exists := os.LookupEnv("APP_MODE")
```

返回类型按顺序对应左边的变量 :

| 变量 | 类型 | 含义 |
| --- | --- | --- |
| `value` | `string` | 环境变量的值 |
| `exists` | `bool` | 环境变量是否存在 |

函数签名有时会给返回值命名 , 例如 `(value string, exists bool)` . 这些名字用于说明返回值 , 调用方可以使用自己的变量名 .

## 3. 返回值也可以是函数

下面是一个完整程序 :

```go
package main

import "fmt"

func makePrinter() func() {
	return func() {
		fmt.Println("hello")
	}
}

func main() {
	printHello := makePrinter()
	printHello()
}
```

先读 `makePrinter` 的签名 :

```go
func makePrinter() func()
```

`makePrinter` 不接收参数 . 它的返回类型是 `func()` , 表示 "不接收参数、不返回值的函数" .

因此 , 变量 `printHello` 的类型也是 `func()` . `printHello := makePrinter()` 会调用外层函数并保存返回的函数值 ; 这时还没有输出 `hello` .

程序随后执行 `printHello()` , 才会调用保存在变量中的函数 , 输出 `hello` .

## 4. 有名字的函数类型

标准库也会给函数类型起名字 . 例如 `context` 包定义了 :

```go
type CancelFunc func()
```

这条定义声明了一个名为 `CancelFunc` 的函数类型 . 其他包引用它时写 `context.CancelFunc` .

如果变量 `cancel` 的类型是 `context.CancelFunc` , 程序就可以写 :

```go
cancel()
```

变量名后面的 `()` 表示调用这个函数值 . 它在用途上有些像 C 的函数指针 , 但 Go 这里的类型直接写成 `func()` , 不是指针类型 `*某种类型` . Go 函数值还可以使用定义时的外层变量 .

`cancel` 只是变量名 , 不是关键字 . 程序可以把同一个返回值命名为 `stop` , 再写 `stop()` .

## 5. 区分函数、指针和接口

这三种类型分别描述不同的东西 : 函数类型描述可以调用的函数 , 指针类型描述指向某个值的地址 , 接口类型描述一个值必须提供哪些方法 .

### 函数类型 : 变量保存可以调用的函数

下面的片段放在函数内部 , 需要导入 `fmt` :

```go
show := func() {
	fmt.Println("hello")
}
show()
```

变量 `show` 的类型是 `func()` . 它保存一个函数值 , 程序通过 `show()` 调用这个函数 .

函数类型规定参数和返回值 . 例如 `func(string) error` 表示这个函数接收一个字符串 , 返回一个 `error` .

### 接口类型 : 规定一个值必须提供哪些方法

接口不指定唯一的具体结构体 , 而是列出需要的方法 . 例如 :

```go
type Greeter interface {
	Greet() string
}
```

`Greeter` 是接口类型 . 某个具体类型只要提供了签名匹配的 `Greet() string` 方法 , 就满足这个接口 , 它的值就可以赋给 `Greeter` 类型的变量 .

假设变量 `speaker` 的类型是 `Greeter` , 并且已经保存了一个满足接口的具体值 , 程序就可以调用 `speaker.Greet()` . 调用时 , 程序执行的是这个具体值对应的方法 .

标准库中的 `io.Reader` 也是接口 , 要求具体类型提供 `Read` 方法 . 文件和内存中的字符串读取器都可以满足它 , 因此需要 `io.Reader` 的函数可以处理不同来源的数据 . 读取方法的参数和返回值会在 [io 篇](./05-io-fs-embed.md) 讲解 .

### 怎样判断一个名字代表什么类型

| 类型写法 | 判断依据 |
| --- | --- |
| `func()` | `func` 后面是参数和返回值 , 表示函数类型 |
| `*int`、`*os.File` | 类型前面的 `*` 表示指针类型 |
| `Greeter`、`io.Reader` | 需要查看定义 , 看到 `interface` 才能确认是接口 |

`包名.名字` 只说明这个名字来自哪个包 , 不能据此判断它是结构体、接口还是函数类型 . 遇到不熟悉的名字 , 读者需要继续查看它的类型定义 .

## 小练习

某个函数的签名是 :

```go
func prepare() (string, func() error)
```

程序调用 :

```go
name, finish := prepare()
```

`name` 的类型是 `string` . `finish` 的类型是 `func() error` , 所以 `finish()` 会返回一个 `error` , 调用方应检查这个返回值 .

下一篇 : [fmt、os 和 slog](./01-fmt-os-log.md) .
