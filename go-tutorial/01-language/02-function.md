# 函数

## 1. 返回类型写在后面

```go
func add(a int, b int) int {
	return a + b
}
```

从左到右读 : 声明函数 `add` , 接收两个 `int` , 返回一个 `int` .

相邻参数类型相同时 , 可以简写 :

```go
func add(a, b int) int {
	return a + b
}
```

项目的 `env` 使用了同样的写法 :

```go
func env(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
```

`key` 和 `fallback` 都是字符串 . 函数读取指定环境变量 ; 读到非空值就返回它 , 否则返回默认值 .

## 2. 没有返回值与多个返回值

没有返回值 , 就不写返回类型 :

```go
func printName(name string) {
	fmt.Println(name)
}
```

返回多个值 , 要用括号 :

```go
func bounds() (int, int) {
	return 1, 10
}
```

调用时按位置接收 :

```go
low, high := bounds()
```

普通 Go 函数当然可以返回值 . 特殊的是入口 `main` : 它必须没有参数、没有返回值 .

```go
func main() {}
func serve() error { return nil }
```

`serve` 返回一个 `error` ; `main` 调用它并决定是否退出进程 .

普通函数声明了返回类型后 , 需要按约定返回结果 ; 不能在应该返回字符串的分支只写一个空 `return` . 本教程先使用显式返回值 , 不引入具名返回值的简写 .

## 3. `:=` 是声明 , `=` 是赋值

```go
name := "ACM" // 声明变量，并推断类型为 string
name = "OJ"   // 给已有变量赋值
```

`:=` 用于函数内部 . 包级变量要使用 `var` 等声明 :

```go
var revision = "development"
```

同一作用域下 , `:=` 左侧至少有一个新的非空白变量 . 例如 :

```go
store, err := openStore()
assets, err := loadAssets()
```

第二行新增 `assets` , 同时给已有的 `err` 赋值 .

这里的两个函数名是教学示意 , 不是项目已有函数 .

## 4. `if` 中声明变量

```go
if err := serve(); err != nil {
	fmt.Println(err)
}
```

分号前调用函数并声明 `err` , 分号后检查条件 . `err` 的范围限于这个 `if` , 包括可能存在的 `else` .

把它移出 `if` 后 , 作用范围不同 :

```go
err := serve()
if err != nil {
	fmt.Println(err)
}
// 这里仍可访问 err。
```

Go 不要求函数先声明再调用 . `main` 可以调用写在文件后面的 `serve` , 也可以调用同包其他文件中的函数 .

## 5. 可变参数的 `...`

```go
func printNames(names ...string) {
	fmt.Println(names)
}

printNames("A", "B")
```

`...string` 表示可以传入多个字符串 . 在函数内部 , `names` 是 `[]string` , 也就是字符串切片 .

已有切片时 , 可以展开后传入 :

```go
names := []string{"A", "B"}
printNames(names...)
```

项目中的 `signal.NotifyContext` 可以接收多个信号 , `fmt.Println` 也接收可变参数 . 切片在 [集合篇](./07-collections.md) 展开 .

## 6. 参数传递先记一个规则

Go 的参数按值传递 : 调用时复制参数值 .

传入指针时 , 复制的是指针 , 而不是它指向的整份数据 . 因此函数仍可能修改同一份数据 . 指针篇会展开 .

## 小练习

读 [main.go](../../../acm-platform/cmd/acm/main.go) 中的 `main`、`env`、`serve` :

1. 哪个函数有参数 ?
2. 哪个函数返回字符串 ? 哪个返回错误 ?
3. 为什么不能把 `revision := "development"` 写在包级 ?

参考 : [Go 语言规范：函数声明](https://go.dev/ref/spec#Function_declarations) .
