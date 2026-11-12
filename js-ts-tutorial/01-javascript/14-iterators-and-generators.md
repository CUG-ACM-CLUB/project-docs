# iterator 和 generator

本篇供遇到 `next()`、`yield` 时查阅 . 它解释前面使用的 `for...of` 怎样逐次取得值 .

## 从 `for...of` 走到 `next()`

数组、字符串、Map 和 Set 都支持按规则遍历 , 这种数据叫 iterable . JS 从中取得 iterator , 再反复调用 `next()` . 手动调用时可以直接看到每一步的结果 :

```js
const values = [10, 20];
const iterator = values[Symbol.iterator]();
console.log(iterator.next()); // { value: 10, done: false }
console.log(iterator.next()); // { value: 20, done: false }
console.log(iterator.next()); // { value: undefined, done: true }
```

`Symbol.iterator` 是 JS 约定的 method 名称 , 调用这个 method 得到 iterator . `next()` 返回 object : `value` 是本次取到的值 , `done` 为 `true` 表示遍历结束 .

## 用 generator 逐次提供值

如果自己编写 `next` , 就需要记录上次走到哪里 . generator 允许直接写出提供值的顺序 , 用 `yield` 暂停并保留执行位置 :

```js
function* numbers() {
  yield 10;
  yield 20;
}
const iterator = numbers();
console.log(iterator.next()); // { value: 10, done: false }
console.log(iterator.next()); // { value: 20, done: false }
console.log(iterator.next()); // { value: undefined, done: true }
console.log([...numbers()]); // [10, 20]
```

`numbers()` 返回 generator object , 此时还没执行 function 内的代码 . 每次 `next()` 继续执行 , 遇到 `yield` 就提供一个值并暂停 . function 结束后 , `done` 变成 `true` .

`yield* values` 可以逐个提供另一个 iterable 中的值 , 例如 `yield* [10, 20]` . `return` 则结束 generator , 返回值不会被普通 `for...of` 当作元素取出 .

## 每次取值需要等待时

普通 iterator 的 `next()` 直接返回结果 . async iterator 的 `next()` 返回 Promise , 因此遍历方需要等待每一步 .

async generator 可以创建这样的 iterator , `for await...of` 负责逐次等待 :

```js
async function* numbers() {
  yield 10;
  yield 20;
}
for await (const value of numbers()) {
  console.log(value); // 依次输出 10、20
}
```

本例按 `.mjs` 执行 . 异步遍历通过 `Symbol.asyncIterator` 取得 iterator ; 与普通遍历的区别是每次取值需要等待 Promise .

下一部分 : [JavaScript 内置对象](../02-built-ins/README.md) .
