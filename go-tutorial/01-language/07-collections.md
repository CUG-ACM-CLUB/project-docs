# 数组、切片和 map

## 1. 数组的长度会写进类型

```go
var ids [3]int
```

这是一个有 3 个元素的整数数组 , 初始元素都是 0.

在 Go 中 , `[3]int` 和 `[4]int` 是两种不同的类型 :

```go
var three [3]int
var four [4]int

three = four // 编译错误：两种类型不同
```

这里的写法可以这样读 :

```text
[3]int：长度为 3 的整数数组
[4]int：长度为 4 的整数数组
```

所以 "数组的长度会写进类型" 不是说长度不能改变 , 而是说数组声明后 , 长度就是它类型的一部分 , 不能把不同长度的数组直接相互赋值 . 切片和数组也不是同一种类型 .

当前项目更常使用切片 :

```go
ids := []int{10, 20, 30}
```

`[]int` 表示整数切片 , 类型里不固定长度 . 两个切片的元素类型相同是可以复制 , 但是赋值复制的是切片描述信息 , 不是底层数据 .

```go
a := []int{1, 2, 3}
b := a

b[0] = 100

fmt.Println(a[0]) // 100
```

`b = a` 之后 , `a` 和 `b` 指向同一份底层数组 , 所以修改 `b` 也会影响 `a` .

## 2. 项目里的 `os.Args`

`os.Args` 是 `[]string` :

```go
args := []string{"acm", "cli", "login"}
fmt.Println(args[1])  // cli
fmt.Println(args[2:]) // [login]
```

`args[a:b]` 是左闭右开区间 , `[a , b)` . 省略 b 表示取到末尾 .

因此 `main.go` 把 `os.Args[2:]` 交给 `cli.Run` , 就是去掉程序名和 `cli` , 只传后面的参数 .

越界访问会 panic.项目先检查 `len(os.Args) > 1` , 才读取 `os.Args[1]` .

## 3. 切片可能共享底层数组

```go
names := []string{"A", "B", "C"}
part := names[1:]
part[0] = "X"
fmt.Println(names[1]) // X
```

切片不是底层数组的独立副本 . 若需要独立数据 , 要明确复制 :

```go
copied := make([]string, len(names))
copy(copied, names)
```

这里 `make` 创建指定长度的切片 , 内置函数 `copy` 复制元素 .

添加元素 :

```go
names = append(names, "D")
```

- 注意 : `append` 函数只能处理切片 , 不能直接传入数组 .

这里把 `append` 返回的切片重新赋给 `names` . `append` 可能会换用新的底层数组 , 所以不能只写 :

```go
append(names, "D") // 返回值没有被保存
```

更准确地说 , `append` 会返回 "添加元素后的切片" . 它有时可以继续使用原来的底层数组 , 有时需要申请更大的新数组 ; 调用方不应该依赖这两种情况中的哪一种 , 因此总是写成 :

```go
names = append(names, "D")
```

## 4. map 保存键值对

```go
scores := map[string]int{
	"Kita": 3,
}
scores["Kita"] = 4
score, ok := scores["Nobody"]
```

类型从左到右读 : 键是 `string` , 值是 `int` . 不存在的键返回值类型的零值 , `ok` 为 `false` .

```go
var scores map[string]int
```

这条声明会让 `scores` 成为一个 nil map.nil map 还没有初始化可以保存键值对的内部 map 结构 .

程序可以从 nil map 中读取数据 . 因为 map 中不存在任何键 , 所以读取会得到值类型的零值 :

```go
score := scores["Nobody"]
fmt.Println(score) // 0
```

但是 , 程序不能直接向 nil map 写入数据 :

```go
scores["Kita"] = 3 // panic
```

这是因为 `scores` 还没有可供写入的 map 结构 . 程序必须先使用 `make` 或 map 字面量初始化 :

```go
scores = make(map[string]int)
scores["Kita"] = 3
```

程序也可以直接使用 map 字面量完成初始化 :

```go
scores := map[string]int{
	"Kita": 3,
}
```

map 遍历顺序不保证固定 . 普通 map 也不能无保护地并发读写 .

## 5. 对照项目中的类型

```go
map[string]any{"status": "ok", "revision": revision}
```

这是字符串键、任意类型值的 map , 常用于构造 JSON 响应 . `any` 见 [./05-interface.md](./05-interface.md) .

```go
[]byte
```

表示字节切片 . `byte` 是 `uint8` 的别名 , 项目用它保存请求体、JSON 和网页文件内容 .

字符串的 `len` 返回字节数 , 不一定是文字个数 . 读 UTF-8 中文时不能把每个字节当作一个汉字 .

## 小练习

`[]string{"acm", "cli", "login", "Kita"}[2:]` 得到什么 ? 如果只想取 `"cli"` , 切片边界应如何写 ?

参考 : [Go Tour：切片](https://go.dev/tour/moretypes/7)、[map](https://go.dev/tour/moretypes/19) .
