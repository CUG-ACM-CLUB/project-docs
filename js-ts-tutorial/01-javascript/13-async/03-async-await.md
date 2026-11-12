# async 和 await

Promise 已经能把多个处理步骤连起来 . `async` 和 `await` 沿用同一套结果与失败规则 , 但允许把后续步骤写成普通语句 .

## `async` 让 function 返回 Promise

在 function 前加 `async` 后 , 调用结果一定是 Promise . 即使直接返回数字 , 数字也只是 Promise 的成功值 :

```js
async function getScore() {
  return 80;
}
const result = getScore();
console.log(result instanceof Promise); // true
result.then((value) => console.log(value)); // 80
```

## `await` 取得成功值 , 再继续当前 function

不使用 `.then` 时 , 可以在 async function 内使用 `await` . 当前 function 暂停 , 调用方继续执行 ; 等 Promise 成功后 , 暂停的 function 取得成功值并继续 :

```js
function later(value) {
  return new Promise((resolve) => setTimeout(() => resolve(value), 10));
}

async function read() {
  console.log("before");
  const value = await later(42);
  console.log(value); // 42
}

read();
console.log("after");
// before
// after
// 42
```

`read()` 执行到 `await` 时暂停 , 所以外面的 `"after"` 先输出 . 等 `later(42)` 成功后 , `value` 才得到数字 `42` .

## 等待失败时 , 使用 `try/catch`

`await` 不只取得成功值 . Promise 失败时 , 它还会抛出失败原因 , 因而可以沿用前面的 `try/catch` :

```js
async function read() {
  try {
    return await Promise.reject(new Error("failed"));
  } catch (error) {
    return "fallback";
  }
}
read().then((value) => console.log(value)); // "fallback"
```

这里需要 `return await` 才能让当前 `catch` 接收 Promise 的失败 . 如果直接 `return Promise.reject(...)` , 失败会通过返回的 Promise 交给调用方 .

没有处理的错误会让当前 async function 返回的 Promise 失败 .

## 先区分启动操作和等待操作

`await later(1)` 完成后再调用 `later(2)` , 两个 timer 就是依次开始 . 如果它们互不依赖 , 可以先启动两个操作 , 再一起等待 :

```js
function later(value) {
  return new Promise((resolve) => setTimeout(() => resolve(value), 10));
}
async function readBoth() {
  const first = later(1);
  const second = later(2);
  return await Promise.all([first, second]);
}
readBoth().then((values) => console.log(values)); // [1, 2]
```

`first` 和 `second` 都是 Promise . 调用 `later` 时 timer 已经开始计时 , 不是等到 `Promise.all` 才开始 .

`Promise.all` 返回新 Promise . 全部成功后 , 成功值是按输入顺序排列的数组 ; 任意一项失败 , 它就失败 , 不会自动停止其他操作 .

## 补充 : `await` 可以写在哪里

`await` 可以写在 async function 中 . 本教程的 `.mjs` 也允许在所有 function 外使用 , 这叫 top-level await . 普通 function 内不能直接写 `await` .

下一篇 : [执行顺序](./04-execution-order.md) .
