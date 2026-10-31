# any 和类型断言

## 0. 阅读指南

读者可以先阅读 [接口](./05-interface.md)，理解 `any` 是一个没有方法要求的接口；读者再阅读本篇，学习如何检查接口中保存的具体类型。

读者可以在 [数组、切片和 map](./07-collections.md) 中看到 `map[string]any` 作为项目 JSON 数据的例子。

读者阅读项目代码时，看到 `any` 可以先问两个问题：

1. 这里允许哪些具体类型？
2. 程序在什么位置检查了取出值的实际类型？

如果读者找不到这两个问题的答案，读者还需要继续查看调用方和数据来源。

## 1. `any` 是什么

`any` 是 `interface{}` 的别名。

`interface{}` 是一个没有方法要求的接口。因为这个接口没有提出任何要求，所以所有具体类型都满足这个接口。字符串、整数、切片和结构体都可以保存到 `any` 类型的变量中。

```go
var value any
```

程序可以把不同类型的值依次保存到 `value` 中：

```go
value = "hello"
value = 123
value = []int{1, 2, 3}
```

每次赋值都会替换 `value` 当前保存的值。执行完上面的代码后，`value` 保存的是：

```go
[]int{1, 2, 3}
```

前面的字符串和整数已经被替换掉了。因此，一个 `any` 变量在同一时间只能保存一个值。

虽然 `value` 的声明类型是 `any`，但 Go 仍然会记录它当前保存的具体类型。例如：

```go
var value any = 123
```

此时：

- `value` 的声明类型是 `any`；
- `value` 当前保存的值是 `123`；
- `value` 当前保存的具体类型是 `int`。

## 2. 程序取出值时需要检查类型

程序读取 `any` 变量时，Go 不会自动把它当成某一种具体类型使用：

```go
var value any = "hello"

// fmt.Println(value + " world") // 不能直接这样使用
```

程序需要先确认 `value` 当前保存的具体类型，再把它当成对应类型使用。程序可以使用类型断言完成这项工作：

```go
text, ok := value.(string)
if ok {
	fmt.Println(text)
}
```

表达式 `value.(string)` 是类型断言。这个表达式要求 Go 运行时检查 `value` 当前保存的具体类型是否为 `string`。如果是，就把这个值取出来。

带有 `ok` 的类型断言会返回两个值：

```text
text   类型断言成功后得到的 string
ok     类型断言是否成功
```

如果当前值不是字符串，`ok` 就是 `false`，程序不会因为这次断言触发 panic。

```go
number, ok := value.(int)
if !ok {
	fmt.Println("value 不是 int")
}
```

如果程序只写一个返回值：

```go
number := value.(int)
```

而 `value` 当前保存的不是 `int`，这条语句会触发 panic。程序读取来源不确定的数据时，通常应该使用带 `ok` 的类型断言。

## 3. `type switch` 一次检查多种类型

`type switch`是另一种类型检查的方式 : 

```go
func describe(value any) {
	switch value := value.(type) {
	case string:
		fmt.Println("字符串:", value)
	case int:
		fmt.Println("整数:", value)
	default:
		fmt.Println("其他类型")
	}
}
```

`value.(type)` 只能写在 `type switch` 中。Go 运行时会依次检查 `value` 当前保存的具体类型。

如果当前值是 `string`，程序会执行第一个 `case`。在这个分支中，`value` 已经被当作 `string` 使用。如果当前值是 `int`，程序会执行第二个 `case`。如果两个 `case` 都不匹配，程序会执行 `default` 分支。

## 4. `any` 和泛型不是一回事

下面的泛型函数可以接收不同元素类型的切片：

```go
func first[T any](items []T) T {
	return items[0]
}
```

调用这个函数时，Go 编译器会根据传入的切片确定 `T` 的具体类型。函数返回值仍然保留这个具体类型。

下面的函数使用的是普通 `any`：

```go
func firstValue(items []any) any {
	return items[0]
}
```

调用 `firstValue` 后，调用方得到的结果仍然是 `any`。如果调用方需要把结果当成字符串使用，调用方还要进行类型断言。

两种写法都可以接收多种类型，但类型检查的时间不同：

```text
泛型：Go 编译器在编译时保留具体类型
any：Go 程序在运行时再检查具体类型
```

当前项目没有使用泛型。读者不应该因为 `any` 可以保存任意类型，就把所有参数都设计成 `any`。

## 5. 当前项目中的 `map[string]any`

当前项目会构造类似下面的 JSON 数据：

```go
map[string]any{
	"status":   "ok",
	"revision": revision,
	"count":    3,
}
```

这个 map 的键类型固定为 `string`，值类型是 `any`。因此，程序可以把字符串、整数、布尔值、切片或其他可编码的数据放入不同键中。

这种类型适合字段结构不固定的 JSON，但这种写法也有代价：

- Go 编译器不能提前检查每个键对应的值类型。
- 程序读取值时通常需要进行类型断言。
- 键名拼写错误通常只能在运行时暴露。
- 复杂的业务数据不应该全部依赖 `map[string]any`。

如果 JSON 字段固定，程序通常应该优先定义结构体：

```go
type Health struct {
	Status   string `json:"status"`
	Revision string `json:"revision"`
}
```

结构体明确规定了每个字段的类型，因此编辑器和 Go 编译器可以更早发现错误。

## 小练习

```go
var value any = "acm"
```

请判断下面三件事：

1. `value.(string)` 是否成功？
2. 带有两个返回值的 `value.(int)` 中，`ok` 的值是什么？
3. 如果程序直接执行 `value.(int)`，会发生什么？

参考：[Go Tour：类型断言](https://go.dev/tour/methods/15)、[类型 switch](https://go.dev/tour/methods/16)。
