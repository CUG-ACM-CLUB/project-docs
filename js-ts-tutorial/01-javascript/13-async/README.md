# 异步执行

前面已经讲过 [function 可以作为值传递](../04-functions.md) . 现在用这条规则解决一个问题 : 结果稍后才准备好时 , 后面的代码由谁、在什么时候调用 ?

1. [callback](./01-callback.md) : 不立即索取结果 , 而是把处理结果的 function 交出去 .
2. [Promise](./02-promise.md) : 用 object 表示还没确定的结果 , 把成功、失败和后续处理连起来 .
3. [async 和 await](./03-async-await.md) : 沿用 Promise , 改为按先后顺序书写等待结果的代码 .
4. [执行顺序](./04-execution-order.md) : 回到输出顺序 , 看当前代码和稍后继续的代码如何交替执行 .

返回 [JavaScript 语法索引](../README.md) .
