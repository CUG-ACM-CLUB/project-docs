# 执行顺序

前面看到 , `await` 暂停当前 function , 外面的代码却继续执行 . 本篇把这些规则放到同一个输出顺序中观察 .

## 当前代码先执行完

下面先执行同步语句 , 再执行 `.then` 的 callback , 最后执行 timer callback :

```js
console.log("sync 1");
setTimeout(() => console.log("timer"), 0);
Promise.resolve().then(() => console.log("promise"));
console.log("sync 2");
// sync 1
// sync 2
// promise
// timer
```

JS 执行到 `setTimeout` 时只是安排稍后的调用 , 不执行其中的 callback . 执行到 `.then` 时也只是登记处理 function . 因此 `"sync 2"` 不会被它们打断 .

## 稍后的代码由运行环境安排

`.then` 的 callback 通过 microtask queue 排队 , 即保存待执行工作的队列 . 当前同步代码结束后 , 程序先处理这些工作 , 再处理上例的 timer callback .

`setTimeout(callback, 0)` 不要求立即调用 , 也不承诺精确的执行时刻 . Node.js 需要等待当前代码和排在前面的工作完成 .

运行环境不断安排这些后续工作的机制叫 event loop . Node.js 和浏览器还有其他调度规则 ; 不需要用这一段输出推断所有异步操作的顺序 .

## `await` 也是稍后继续

即使等待的 Promise 已经成功 , `await` 后的代码也不会接着立即执行 :

```js
async function show() {
  console.log("before await");
  await Promise.resolve();
  console.log("after await");
}
show();
console.log("outside");
// before await
// outside
// after await
```
`show` 输出第一行后暂停 . 外面的 `"outside"` 先输出 , 然后 `show` 才继续 . 这与 `.then` 在同步代码结束后执行的规则相接 .

下一篇 : [iterator 和 generator](../14-iterators-and-generators.md) .
