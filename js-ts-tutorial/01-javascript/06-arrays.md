# 数组

数组把一组值按位置放在一起 . 本篇先看如何读取和增删元素 , 再区分数组赋值与复制 .

## 按位置读取元素

下标从 `0` 开始 , `length` 表示数组长度 . 同一个数组可以保存不同类型的值 , 读取越界位置得到 `undefined` :

```js
const values = [10, "hello", true];
console.log(values[0]); // 10
console.log(values[3]); // undefined
console.log(values.length); // 3
```

## 添加和删除元素

数组长度可以变化 . `push(value)` 在尾部添加元素并返回新长度 ; `pop()` 删除并返回最后一个元素 , 空数组返回 `undefined` .

```js
const scores = [60];
console.log(scores.push(80)); // 2
console.log(scores.pop()); // 80
console.log(scores); // [60]
```

## 赋值不会复制数组

保存了一组数据后 , 把变量赋给另一个变量 , 是否就得到两份数据 ? 对数组来说不是 :

```js
const first = [10, 20];
const second = first;
second[0] = 99;
console.log(first[0]); // 99
console.log(first === second); // true
```

`first` 和 `second` 访问同一个数组 , 所以 `second[0]` 的修改也能从 `first[0]` 读到 . 数组属于 object , 后面会看到普通 object 也遵守这条规则 .

把数组传给 function 时也一样 . function 修改元素会影响原数组 ; 但给参数重新赋值 , 只会改变参数本身 .

要得到新数组 , 可以用 `slice()` :

```js
const first = [10, 20];
const copy = first.slice();
copy[0] = 99;
console.log(first[0], copy[0]); // 10 99
```

如果元素本身是 object , 这一步不会继续复制内部 object . 这叫浅复制 , 例子见 [解构和展开](./08-destructuring-and-spread.md) .

## 补充 : 长度不保证每个位置都有元素

写入较大的下标会增加 `length` , 中间没有赋值的位置是空位 :

```js
const values = [10];
values[3] = 40;
console.log(values.length); // 4
console.log(values[1]); // undefined
values.length = 1;
console.log(values); // [10]
```

读取空位得到 `undefined` . 把 `length` 改小会删除超出新长度的元素 .

判断一个值是不是数组 , 使用 `Array.isArray(value)` , 返回 `boolean` . `typeof` 对数组只返回 `"object"` .

更多增删、排序和逐项处理操作见 [数组 method](../02-built-ins/02-array-methods.md) .

下一篇 : [object](./07-objects.md) .
