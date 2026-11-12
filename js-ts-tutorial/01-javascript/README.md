# JavaScript 语法

## 保存值并决定怎么使用它

先看变量能保存什么 , 再看运算如何处理这些值 . 条件与循环沿用已有编程基础 , 只补充 JS 的写法和遍历规则 .

1. [变量和值](./01-variables-and-values.md) : 声明变量 , 区分重新赋值与修改内部内容 .
2. [类型转换和比较](./02-conversion-and-comparison.md) : 解释混合类型的运算、比较和真假判断 .
3. [条件和循环](./03-conditions-and-loops.md) : 根据判断选择语句 , 按值或名称遍历数据 .

## 把 function 当作值使用

function 不仅能调用 , 也能赋值、传参和返回 . 在此基础上 , closure 解释返回的 function 为什么还能使用外层变量 .

4. [function](./04-functions.md) : 从普通调用到传递 function .
5. [scope 和 closure](./05-scope-and-closures.md) : 从变量的访问范围到保留外层变量 .

## 把数据和操作组织在一起

数组按位置保存值 , object 按名称保存值 . 理解它们的存储方式后 , 再学取值与复制的简写 . object 保存 function 时形成 method , 由此继续学习 `this` 和 class .

6. [数组](./06-arrays.md) : 按下标访问 , 区分共享数组与复制数组 .
7. [object](./07-objects.md) : 按名称保存值 , 把 function 保存为 method .
8. [解构和展开](./08-destructuring-and-spread.md) : 取出已有值 , 或用它们组成新数据 .
9. [this](./09-this.md) : method 怎样知道本次调用操作哪个 object .
10. [prototype 和 class](./10-prototypes-and-classes.md) : 多个 object 怎样共享 method , class 怎样创建 instance .

## 跨越一次调用或一个文件

程序不总能直接返回结果 : 有时会失败 , 有时需要另一个文件的代码 , 有时结果还没准备好 .

11. [错误处理](./11-errors.md) : 用 `throw` 把失败交给调用方 .
12. [module](./12-modules.md) : 用 import 和 export 连接不同文件 .
13. [异步执行](./13-async/README.md) : 从 callback 走到 Promise 和 await .

## 查阅 : 逐次提供数据

14. [iterator 和 generator](./14-iterators-and-generators.md) : 理解 `for...of` 背后的取值规则 . 读完异步部分后再看 `for await...of` .

返回 [教程索引](../README.md) .
