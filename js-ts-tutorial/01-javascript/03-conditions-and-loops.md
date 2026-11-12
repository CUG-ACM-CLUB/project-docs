# 条件和循环

本篇先给出条件和循环的 JS 写法 , 再区分按值遍历与按名称遍历 .

## 条件和普通循环

`if`、`for` 和 `while` 的写法如下 . 本教程统一用 `{}` 包住它们执行的语句 .

```js
const scores = [60, 80];
for (let i = 0; i < scores.length; i++) {
  if (scores[i] >= 70) {
    console.log(scores[i]); // 80
  }
}
let left = 2;
while (left > 0) {
  left--;
}
```

`condition ? yes : no` 是有值的表达式 , 只计算选中的一支 . 例如 `const label = score >= 60 ? "pass" : "fail"` .

`switch` 的 `case` 比较不转换类型 . 命中后没有 `break`、`return` 或 `throw` 就会继续执行后面的语句 :

```js
const mode = "read";
switch (mode) {
  case "read":
    console.log("读取");
    break;
  default:
    console.log("其他模式");
}
```

## 取出每个值 : `for...of`

不需要手动处理下标时 , 可以逐个取出数组的值 :

```js
const scores = [60, 80];
for (const score of scores) {
  console.log(score); // 依次输出 60、80
}
```

每轮都会创建新的 `score` , 因此这里可以使用 `const` . 字符串、Map 和 Set 也支持这种遍历 , 后面分别介绍 .

## 取出每个名称 : `for...in`

object 按名称保存值 , 每一项称为 property . 与取值的 `for...of` 不同 , `for...in` 取出的是名称 :

```js
const item = { title: "book", count: 2 };
for (const key in item) {
  console.log(key, item[key]); // title book ; count 2
}
```

`for...in` 只取字符串名称 , 并且可能取到继承来的 property . property 还可以标记为不可枚举 , 即不参加这种遍历 ; 上例直接创建的 property 默认都可枚举 .

数组取值使用 `for...of` , 不要用 `for...in` 代替 . object 同时取名称和值的方法见 [object](./07-objects.md) .

`break` 结束循环 , `continue` 跳过本轮 . 在 function 内的循环中执行 `return` , 会结束整个 function .

下一篇 : [function](./04-functions.md) .
