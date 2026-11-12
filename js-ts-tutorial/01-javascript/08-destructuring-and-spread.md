# 解构和展开

前两篇介绍了数组和 object 如何保存数据 . 本篇只处理两个方向 : 从已有数据中取值 , 或把已有数据放进新的结构中 .

## 从已有数据中取值

解构把取出的值保存到变量 . 数组按位置取值 :

```js
const pair = [10, 20];
const [first, second] = pair;
console.log(first, second); // 10 20
```

object 则按 property 名称取值 , 与排列顺序无关 :

```js
const item = { title: "book", count: 2 };
const { count, title: name, price = 0 } = item;
console.log(count, name, price); // 2 "book" 0
```

`title: name` 表示读取 `title` 并声明变量 `name` , 不是声明变量 `title` . 默认值只在取出的值为 `undefined` 时生效 , 不替换 `null` .

参数也可以在接收时解构 . 调用方仍然传入一个 object :

```js
function describe({ title, count = 1 }) {
  return `${title}: ${count}`;
}
console.log(describe({ title: "book" })); // "book: 1"
```

`${...}` 在字符串中插入值 , 见 [字符串](../02-built-ins/01-string.md) . 传入 `null` 或 `undefined` 时 , 这次解构会报错 .

## 把已有值展开到新位置

解构从数据中取值 , 展开则把已有内容放进新数组、object 或 function 参数中 .

数组展开使用 `...array` :

```js
const first = [1, 2];
const all = [...first, 3];
console.log(all); // [1, 2, 3]
console.log(Math.max(...all)); // 3
```

`Math.max` 返回参数中的最大数字 . `Math.max(...all)` 相当于 `Math.max(1, 2, 3)` .

object 展开使用 `{ ...object }` . 它复制自身可枚举的 property , 后写的同名项覆盖前面的值 :

```js
const defaults = { size: 10, color: "red" };
const options = { ...defaults, size: 20 };
console.log(options); // { size: 20, color: "red" }
```

## 相同的 `...` 也可以收集剩余项

上面的 `...` 把值展开出去 . 写在解构变量中时 , 它反过来收集尚未取走的项 , 这种用法叫 rest :

```js
const [first, ...others] = [1, 2, 3];
const { title, ...detail } = { title: "book", count: 2, price: 8 };
console.log(first, others); // 1 [2, 3]
console.log(title, detail); // "book" { count: 2, price: 8 }
```

rest 必须放在对应解构列表的最后 . function 的 rest 参数见 [function](./04-functions.md) .

## 新的外层不代表内部也被复制

展开产生新的外层 object , 但内部嵌套的 object 仍然共享 . 这就是前面提到的浅复制 :

```js
const first = { detail: { count: 1 } };
const copy = { ...first };
copy.detail.count = 9;
console.log(first.detail.count); // 9
console.log(first === copy); // false
console.log(first.detail === copy.detail); // true
```

`first` 与 `copy` 是两个 object , 但它们的 `detail` 指向同一个 object . 因此修改 `copy.detail.count` 也会影响 `first.detail.count` .

下一篇 : [this](./09-this.md) .
