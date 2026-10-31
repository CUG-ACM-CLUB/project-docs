# 指针、结构体和方法

## 1. 先把数据组合起来

```go
type Student struct {
	Name   string
	Solved int
}
```

`type` 声明类型 , `struct` 表示结构体 . `Student` 有两个字段 .

创建值并读取字段 :

```go
student := Student{Name: "Kita", Solved: 3}
fmt.Println(student.Name)
```

**省略的字段使用零值** :

```go
student := Student{Name: "Kita"} // Solved 为 0
```

`Student{...}` 是结构体字面量 , 不是在调用函数 .

## 2. `&` 取地址 , `*` 表示指针或解引用

```go
count := 3
pointer := &count
*pointer = 4
fmt.Println(count) // 4
```

`pointer` 的类型是 `*int` , 表示指向整数的指针 . 表达式 `*pointer` 取出指向位置的值 .

同一个 `*` 出现在类型中和表达式中 , 含义不同 :

```go
var p *Student // 类型：指向 Student 的指针，初始值为 nil
p = &student   // 表达式：取得 student 的地址
```

通过空指针访问数据会 panic.

Go 的指针不能像 C 指针那样直接做地址加减 , 也不用手动 `free` . 但文件、数据库连接等外部资源仍要按 API 要求关闭 .

## 3. 传值与传指针

```go
copy := student
copy.Solved = 10
```

此时原来的 `student.Solved` 没有变化 , 因为结构体值被复制了 .

```go
p := &student
p.Solved = 10
```

这次修改了原数据 . Go 允许对结构体指针直接写 `p.Solved` , 不必写 `(*p).Solved` .

不要把这个例子推广成 "复制结构体总是深拷贝" . 如果字段是切片、map 或指针 , 复制后仍可能共享底层数据 .

## 4. 方法比函数多了一个接收者

```go
func (s *Student) Accept() {
	s.Solved++
}

student.Accept()
```

函数名前面的 `(s *Student)` 是接收者 . 方法通过 `s` 操作对应对象 .

如果写成值接收者 :

```go
func (s Student) Count() int {
	return s.Solved
}
```

调用时会复制结构体值 . 需要修改原对象时 , 通常使用指针接收者 .

`Accept()` 后面的括号是调用 ; 只写 `student.Accept` 则是取得方法值 , 详见函数值篇 .

## 对照项目

`main.go` 创建服务器 :

```go
platformServer := &platform.Server{
	Store: store,
	Revision: revision,
}
```

`&platform.Server{...}` 创建结构体并取得指针 . `http.go` 中 :

```go
func (s *Server) Handler(ctx context.Context) http.Handler {
	return s.adaptFiber(s.App(ctx))
}
```

`Handler` 是 `*Server` 的方法 , 接收 context , 返回一个 HTTP handler.HTTP 类型见 [net 和 net/http](../02-standard-library/04-net-http.md) .

## 小练习

`copy := student` 与 `copy := &student` , 哪一种能通过修改 `copy.Solved` 改变原记录 ?

参考 : [Go Tour：指针](https://go.dev/tour/moretypes/1)、[方法](https://go.dev/tour/methods/1) .
