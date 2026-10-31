# 接口

## 1. 接口描述“能做什么”

```go
type Greeter interface {
	Greet() string
}
```

这个接口要求一个方法：不接收参数，返回字符串的 `Greet`。

```go
type Student struct {
	Name string
}

func (s Student) Greet() string {
	return "hello, " + s.Name
}
```

`Student` 已经满足 `Greeter`，不需要再声明 `implements`。

```go
func welcome(g Greeter) {
	fmt.Println(g.Greet())
}

welcome(Student{Name: "Kita"})
```

`welcome` 不需要知道数据里有没有 `Name`，只依赖 `Greet()` 方法。

## 2. 签名必须匹配

方法名、参数类型和返回类型要匹配。返回 `int` 的 `Greet` 不能满足返回 `string` 的要求。

接收者也有影响：

| 方法声明 | 可以满足该接口的类型 |
| --- | --- |
| `func (s Student) Greet() string` | `Student` 与 `*Student` |
| `func (s *Student) Greet() string` | `*Student`，不包括 `Student` |

Go 有时允许通过变量自动取地址来调用方法，但这不表示值类型满足了指针类型的方法集合。

## 3. 当前项目为什么需要接口

`internal/application/agent/service.go` 中有：

```go
type Runner interface {
	Run(context.Context, int64, string, string, string) (analysis.Result, error)
}
```

任务服务只要求 runner 能执行 `Run`，不要求它属于某个具体结构体。

因此正式运行可以使用实际 Agent，测试可以使用一个满足相同接口的替代实现。两者都要遵守相同参数和返回类型。

`training.Service` 使用的 `Repository` 也是这个道理：应用层规定需要哪些读写能力，PostgreSQL 实现这些方法。

这没有自动生成数据库代码，也没有自动做权限检查。那些逻辑仍要由具体实现完成。

## 4. `error` 也是接口

Go 内置的 `error` 接口要求：

```go
type error interface {
	Error() string
}
```

这解释了为什么不同错误类型，都能作为 `error` 返回。

还有一个常见名字：

```go
any
```

它是 `interface{}` 的别名，表示没有方法要求的接口。它可以接收任意类型的值，但不能不经检查就假定值是字符串。

项目中的 `map[string]any` 会在 [集合篇](./07-collections.md) 介绍。

`any` 的完整用法，包括它保存的具体类型、类型断言和 `type switch`，见 [any 和类型断言](./10-any-and-type-assertion.md)。

## 5. 接口为 nil 的陷阱

```go
var p *Student = nil
var value any = p
fmt.Println(p == nil)     // true
fmt.Println(value == nil) // false
```

可以暂时把接口值理解为“具体类型 + 具体值”。`value` 已记录类型 `*Student`，因此不是空接口值。

返回 `error` 时也要注意这个问题。没有错误就直接返回 `nil`，不要把一个带类型的空指针误当成没有错误。

## 小练习

如果 `Greet` 只有指针接收者，为什么 `welcome(&student)` 可以，而 `welcome(student)` 不可以？

参考：[Go Tour：接口](https://go.dev/tour/methods/9)、[nil 接口值](https://go.dev/tour/methods/13)。
