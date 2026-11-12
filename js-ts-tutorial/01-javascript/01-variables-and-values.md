# 变量和值

## 声明变量

JS 用 `let` 声明可以重新赋值的变量 , 用 `const` 声明不能重新赋值的变量 . `const` 必须在声明时提供初始值 .

```js
let score = 80;
score = 90;
const limit = 100;
// limit = 120; // TypeError
console.log(score, limit); // 90 100
```

JS 的类型属于值 . `let value = 1` 之后可以执行 `value = "one"` , 同一个变量先保存数字 , 后保存字符串 .

## 值有哪些类型

下面前七项是基本值 , 也称 primitive value . object 则把多个值放在一起 ; 数组也属于 object .

| 类型 | 例子 | 说明 |
| --- | --- | --- |
| `undefined` | `undefined` | 变量声明后未赋值时得到这个值 |
| `null` | `null` | 通常由代码主动表示没有值 |
| `boolean` | `true`、`false` | 真假值 |
| `number` | `1`、`1.5`、`NaN` | 普通数字 , 包含特殊数字值 |
| `bigint` | `123n` | 可以精确表示超出普通安全整数范围的整数 |
| `string` | `"hello"` | 字符串 |
| `symbol` | `Symbol("id")` | 创建不同于其他 symbol 的标识值 |
| object | `{ score: 80 }`、`[1, 2]` | 把多个值放在一起 , 各个值可以有名称 |

先使用 `number`、`string`、`boolean` 以及表示没有值的 `undefined`、`null` 即可 . `bigint` 和 `symbol` 可以遇到时再查 .

`number` 不区分整数和浮点类型 , 因而 `5 / 2` 得到 `2.5` . 它按浮点数计算 , 例如 `0.1 + 0.2 === 0.3` 为 `false` . `bigint` 用于精确整数计算 , 但不能直接与 `number` 混合做算术 .

知道有哪些类型后 , 可以用 `typeof` 查看一个值的类型 . 它返回字符串 :

```js
let value;
console.log(value); // undefined
console.log(typeof value); // "undefined"
console.log(typeof 1); // "number"
console.log(typeof 1n); // "bigint"
console.log(typeof "one"); // "string"
console.log(typeof []); // "object"
console.log(typeof null); // "object"
```

`typeof null` 是历史例外 . 检查 `null` 应使用 `value === null` , 不使用 `typeof` . function 的 `typeof` 结果是 `"function"` .

## 重新赋值与修改内容不同

`const` 限制的是变量重新赋值 , 不是把数组或 object 的内部内容锁住 .

```js
const scores = [80];
scores[0] = 90;
console.log(scores[0]); // 90
// scores = [100]; // TypeError
```

上例一直使用同一个数组 , 只是改了其中的数字 . `scores = [100]` 则要求变量改为保存另一个数组 , 因此报错 .

本教程默认用 `const` , 需要重新赋值时用 `let` . 旧代码中的 `var` 有不同的访问范围 , 见 [scope 和 closure](./05-scope-and-closures.md) .

下一篇 : [类型转换和比较](./02-conversion-and-comparison.md) .
