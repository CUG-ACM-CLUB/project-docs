# 数组 method

数组 method 可以直接修改数据 , 也可以返回新数组 . 先看这两种操作的区别 , 再用 callback 描述每个元素的处理规则 . 下标和复制见 [数组](../01-javascript/06-arrays.md) .

## 修改原数组 , 或产生新数组

| method | 返回值 | 修改原数组 |
| --- | --- | --- |
| `push(x)`、`unshift(x)` | 新长度 | 是 , 分别从尾部和头部添加 |
| `pop()`、`shift()` | 删除的元素 , 空数组为 `undefined` | 是 |
| `slice(start, end)` | 新数组 , 不含 `end` 位置 | 否 |
| `splice(start, count, ...items)` | 被删除元素组成的数组 | 是 |
| `includes(x)` | `boolean` | 否 |
| `indexOf(x)` | 首个下标 , 不存在为 `-1` | 否 |
| `sort(compare)`、`reverse()` | 原数组本身 | 是 |

例如排序会直接修改原数组 . 如果还要保留原顺序 , 就先复制再排序 :

```js
const values = [10, 2, 30];
const sorted = values.slice().sort((a, b) => a - b);
console.log(sorted); // [2, 10, 30]
console.log(values); // [10, 2, 30]
```

`sort()` 默认按字符串形式排序 . 传入 `(a, b) => a - b` 后 , `sort` 会调用这个比较 function : 返回负数表示 `a` 在前 , 正数表示 `b` 在前 , `0` 表示二者排序上相等 .

`slice()` 先复制数组 , 所以这里不会修改 `values` . `toSorted`、`toReversed` 和 `toSpliced` 也返回新数组 , 分别对应不修改原数组的排序、反转和增删操作 .

## 把逐项处理的规则传入

排序时由 `sort` 调用比较 function . 同样 , `map`、`filter` 等 method 也可以代替手写循环 , 由调用方提供处理单个元素的 callback :

```js
const values = [2, 4, 6];
const doubled = values.map((value) => value * 2);
const large = values.filter((value) => value > 2);
console.log(doubled); // [4, 8, 12]
console.log(large); // [4, 6]
```

`map` 把每次返回值放进新数组 ; `filter` 根据每次判断保留原元素 . callback 都由 method 调用 , 接收 `(value, index, array)` : 当前元素、下标和原数组 . 上例只需要第一个参数 .

如果需求不是转换或筛选 , 可以按结果选择其他 method :

| method | callback 的返回值如何使用 | method 的返回值 |
| --- | --- | --- |
| `forEach` | 忽略返回值 | `undefined` |
| `map` | 每次返回值成为新元素 | 新数组 |
| `filter` | 按真假决定是否保留原元素 | 新数组 |
| `find` | 首次按真处理时返回原元素 | 元素或 `undefined` |
| `some` | 任意一次按真处理即可结束 | `boolean` |
| `every` | 任意一次按假处理即可结束 | `boolean` |

表中的 callback method 不会自行修改原数组 , 但 callback 仍可以主动修改数据 . `filter` 只创建新数组 , 不复制 object 元素 .

## 把多个元素合成一个结果

`map` 每次产生一个元素 . 如果要累加成一个总数 , 则需要把上一步的结果交给下一步 . `reduce` 负责这个传递过程 :

```js
const values = [2, 4, 6];
const total = values.reduce((sum, value) => sum + value, 0);
console.log(total); // 12
```

第二个参数 `0` 是初始值 . 三次 callback 分别计算 `0 + 2`、`2 + 4`、`6 + 6` , 最终返回 `12` .

callback 完整参数是 `(accumulator, value, index, array)` . accumulator 是上一步的结果 , 上例命名为 `sum` . 省略初始值时 , 首个已有元素作为初始值 , 从下一个元素开始调用 callback ; 空数组没有初始值会报错 .

## callback 返回 Promise 时

上面的 callback 都立即返回普通值 . 如果返回 Promise , 就需要确认数组 method 如何使用这个返回值 .

`forEach` 忽略返回值 , 所以也不会等待 Promise . `map` 则会把 Promise 放进新数组 , 可以再交给 `Promise.all` :

```js
async function double(value) {
  return value * 2;
}
const results = await Promise.all([1, 2].map(double));
console.log(results); // [2, 4]
```

需要逐项等待时 , 用 `for...of` 配合 `await` . 上例按 `.mjs` 运行 ; `Promise.all` 的规则见 [async 和 await](../01-javascript/13-async/03-async-await.md) .

## 查阅 : 展开一层数组

`flat()` 把嵌套数组展开一层 ; `flatMap(callback)` 先逐项处理 , 再展开一层 . 例如 `[1, 2].flatMap(x => [x, x])` 得到 `[1, 1, 2, 2]` .

另外 , `forEach` callback 中的 `return` 只结束本次 function 调用 , 不会结束整个遍历 .

下一篇 : [Map 和 Set](./03-map-and-set.md) .
