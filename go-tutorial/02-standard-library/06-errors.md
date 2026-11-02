# errors : 创建、识别和组合错误

`01/` 已经介绍了 `error` 返回值 . 本篇学习怎样创建具体错误 , 以及怎样在多层函数之间保留和识别错误 .

## 1. `errors.New` 创建错误值

签名 :

```go
func New(text string) error
```

完整程序 :

```go
package main

import (
	"errors"
	"fmt"
)

func checkAge(age int) error {
	if age < 0 {
		return errors.New("年龄不能为负数")
	}
	return nil
}

func main() {
	err := checkAge(-1)
	if err != nil {
		fmt.Println(err)
	}
}
```

`errors.New` 接收错误说明 `string` , 返回 `error` . 变量 `err` 的声明类型也是 `error` .

创建错误和返回错误都不会自动输出文字 . 例子中真正输出错误的是 `fmt.Println(err)` .

## 2. 需要比较的错误可以保存为变量

`errors.New` 每次调用都会产生新的错误值 . 即使说明文字相同 , 两个错误值也不相等 :

```go
package main

import (
	"errors"
	"fmt"
)

func main() {
	a := errors.New("记录不存在")
	b := errors.New("记录不存在")
	fmt.Println(a == b) // false
}
```

`a` 和 `b` 的声明类型都是 `error` . 两次调用创建了两个不同的错误值 , 所以比较结果是 `false` .

如果程序需要稳定地识别某种失败 , 可以在包级保存一个错误变量 :

```go
var ErrMissing = errors.New("记录不存在")
```

后续函数返回这个变量 , 而不是每次重新创建相同文字的错误 . 前缀 `Err` 是常见命名习惯 , 不是 Go 语法要求 .

## 3. `fmt.Errorf` 增加错误说明

`fmt.Errorf` 用来**创建一个 `error`** , 并且可以把变量的值写进错误说明中 . 签名 :

```go
func Errorf(format string, a ...any) error
```

完整程序 :

```go
package main

import (
	"errors"
	"fmt"
)

func main() {
	original := errors.New("记录不存在")
	err := fmt.Errorf("读取失败: %w", original)
	fmt.Println(err)
}
```

`original` 和 `err` 的声明类型都是 `error` . 程序输出 :

```text
读取失败: 记录不存在
```

`%w` 在添加文字时还保留了新错误与原错误的关系 , 这叫作包装错误 . 调用方既能看到补充说明 , 也能继续识别原始原因 .

如果这里改用 `%v` , 程序虽然也能生成相同文字 , 但不会通过这个占位符保留包装关系 .

## 4. `errors.Is` 检查错误值

签名 :

```go
func Is(err, target error) bool
```

完整程序 :

```go
package main

import (
	"errors"
	"fmt"
)

var ErrMissing = errors.New("记录不存在")

func main() {
	err := fmt.Errorf("读取失败: %w", ErrMissing)

	fmt.Println(err == ErrMissing)         // false
	fmt.Println(errors.Is(err, ErrMissing)) // true
}
```

`err` 已经是包装后的错误 , 所以直接比较不相等 . `errors.Is` 会继续检查包装关系 , 寻找是否匹配目标错误 ; 它返回 `bool` .

程序不需要靠比较 `err.Error()` 的文字来识别原因 . 文字是说明 , 不是稳定的错误标识 .

HTTP 章节中的 `http.ErrServerClosed` 也可以作为 `errors.Is` 的目标 : 调用方用它区分预期关闭和其他失败 .

## 5. `errors.As` 检查错误类型

有时程序不只要识别某个错误 , 还需要读取特定错误类型的字段 , 将错误转换为特定类型以便进一步处理 . 签名 :

```go
func As(err error, target any) bool
```

完整程序 :

```go
package main

import (
        "errors"
        "fmt"
)

type MyError struct {
        Code int
        Msg  string
}

func (e *MyError) Error() string {
        return fmt.Sprintf("Code: %d, Msg: %s", e.Code, e.Msg)
}

func getError() error {
        return &MyError{Code: 404, Msg: "Not Found"}
}

func main() {
        err := getError()
        var myErr *MyError
        if errors.As(err, &myErr) {
          			// 发现 err 是 MyError 类型的 , 于是对于这个类型可以统一处理
                fmt.Printf("Custom error - Code: %d, Msg: %s\n", myErr.Code, myErr.Msg)
        }
}
```

## 6. `errors.Join` 保留多个错误

签名 :

```go
func Join(errs ...error) error
```

完整程序 :

```go
package main

import (
	"errors"
	"fmt"
)

func main() {
	first := errors.New("第一项失败")
	second := errors.New("第二项失败")
	combined := errors.Join(first, second)

	fmt.Println(errors.Is(combined, first))  // true
	fmt.Println(errors.Is(combined, second)) // true
}
```

三个变量的声明类型都是 `error` . `Join` 把多个错误合并为一个返回值 , 同时保留检查各个错误的能力 .

`Join` 会忽略 `nil` 参数 . 如果所有参数都是 `nil` , 它就返回 `nil` .

这个函数只组合已经产生的错误 , 不会替调用方执行任务或清理资源 .

## 小练习

1. `errors.New` 和 `fmt.Errorf` 的返回类型是什么 ? 它们会直接输出文字吗 ?
2. `errors.Is` 和 `errors.As` 分别检查什么 ?
3. `pathErr` 与 `&pathErr` 的类型分别是什么 ? 为什么例子要传后者 ?

查阅签名时 , 可以在 Go 官方文档中搜索 `errors` .

读完本目录后 , 再进入 [项目启动过程](../03-project-entry/) .
