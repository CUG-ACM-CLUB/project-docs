# 错误处理

function 正常执行时用 `return` 返回结果 . 无法完成操作时 , 可以用 `throw` 把失败交给调用方 .

## 抛出错误 , 停止当前调用

`new Error(message)` 创建保存错误信息的 object . 只有执行 `throw` , 才会中断当前代码并寻找处理错误的 `catch` :

```js
function divide(a, b) {
  if (b === 0) {
    throw new Error("divisor is zero");
  }
  return a / b;
}
try {
  console.log(divide(6, 0));
  console.log("不会执行");
} catch (error) {
  if (error instanceof Error) {
    console.log(error.message); // "divisor is zero"
  }
}
```

`divide` 抛错后 , `try` 中剩下的代码不再执行 , 程序转入 `catch` . `error` 保存抛出的值 . JS 也允许抛出字符串等其他值 , 所以上例先用 `instanceof Error` 判断 .

如果改成 `return new Error(...)` , 错误 object 会成为普通返回值 , 不会进入 `catch` .

## 用 `finally` 处理离开前的工作

正常返回与抛错是两条离开路径 . 两条路径都需要执行的清理代码可以写在 `finally` 中 :

```js
function read() {
  try {
    console.log("读取");
    return 10;
  } finally {
    console.log("清理");
  }
}
console.log(read());
// 依次输出 "读取"、"清理"、10
```

上例先记录要返回的 `10` , 执行 `finally` , 最后返回 . 如果 `finally` 再执行新的 `return` 或 `throw` , 就会覆盖原先的结果 , 因此通常只在这里写清理代码 .

本篇处理的是当前调用中的错误 . 稍后才执行的 callback 如果抛错 , 不会回到已经离开的 `try` . 异步结果的错误处理见 [async 和 await](./13-async/03-async-await.md) .

下一篇 : [module](./12-modules.md) .
