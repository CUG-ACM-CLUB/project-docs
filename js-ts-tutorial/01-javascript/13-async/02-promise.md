# Promise

callback 把后续操作交给别人调用 . Promise 则让操作先返回一个 object , 调用方通过它安排结果准备好后要做的事 .

## 先返回一个表示结果的 object

Promise 可以处于三种状态 :

1. `pending` : 尚未得到结果 .
2. `fulfilled` : 已成功 , 保存结果值 .
3. `rejected` : 已失败 , 保存失败原因 .

状态只能从 `pending` 变为成功或失败 , 确定后不再改变 .

`new Promise(...)` 接收并立即调用一个 function . 它传入 `resolve` 和 `reject` 两个 function , 让这段代码报告成功或失败 :

```js
const result = new Promise((resolve, reject) => {
  setTimeout(() => resolve(42), 10);
});
console.log(result); // Promise { <pending> }
```

`result` 此时保存 Promise , 不是数字 `42` . 稍后 timer callback 调用 `resolve(42)` , Promise 才变成成功 , 保存结果值 `42` . 调用 `reject(error)` 则表示失败 .

传给 `new Promise` 的 function 如果直接抛错 , Promise 也会失败 . `resolve` 如果接收另一个 Promise , 当前 Promise 会跟随它的结果 .

## 用 `.then` 处理成功值

拿到 Promise 后 , 通过 `.then(callback)` 安排成功后的操作 . Promise 成功时 , callback 收到结果值 .

`.then` 自己又返回一个新 Promise , 因此处理步骤可以连起来 :

```js
Promise.resolve(2)
  .then((value) => value * 3)
  .then((value) => console.log(value)); // 6
```

`Promise.resolve(2)` 创建成功值为 `2` 的 Promise . 第一个 callback 收到 `2` 并返回 `6` , 所以下一个 callback 收到 `6` . 如果 callback 返回另一个 Promise , 后续步骤会等待它的结果 .

这条链传递的是每一步处理后的结果 . 忘记在 callback 中返回结果 , 下一步就会收到 `undefined` .

## 用 `.catch` 处理失败

callback 抛错会让后续 Promise 失败 . 失败会跳过只处理成功的 `.then(callback)` , 直到 `.catch(callback)` :

```js
Promise.resolve("input")
  .then(() => {
    throw new Error("bad input");
  })
  .catch((error) => {
    console.log(error.message); // "bad input"
    return "fallback";
  })
  .then((value) => console.log(value)); // "fallback"
```

`.catch` 的 callback 收到错误 . 它返回 `"fallback"` 后 , 后续 Promise 恢复为成功 , 所以下一个 `.then` 能收到这个字符串 .

成功和失败都需要执行的清理操作可以写在 `.finally(callback)` . callback 正常结束时保留原结果 ; 抛错或返回失败的 Promise 时改为失败 .

## 处理结果的 callback 何时执行

创建 Promise 时传入的 function 立即执行 , 但 `.then` 的 callback 需要等当前同步代码结束 . 即使 Promise 已经成功 , 规则也一样 :

```js
console.log("start");
Promise.resolve().then(() => console.log("promise"));
console.log("end");
// start
// end
// promise
```

多个 Promise 如何一起等待 , 下一篇使用 `Promise.all` 说明 .

下一篇 : [async 和 await](./03-async-await.md) .
