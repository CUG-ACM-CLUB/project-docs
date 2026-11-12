# 类型转换和比较

变量可以保存不同类型的值 , 但运算需要决定怎样处理这些类型 . 先看值如何转换 , 再看比较和条件判断 .

## 转换值

`Number("12")` 得到数字 `12` , `String(12)` 得到字符串 `"12"` . 代码明确要求的转换叫显式转换 .

运算也可能自动触发转换 , 这叫隐式转换 . 例如数字与字符串使用 `+` 时会拼接字符串 , 而 `-` 会尝试执行数字减法 :

```js
console.log(1 + 2); // 3
console.log("1" + 2); // "12"
console.log("3" - 1); // 2
console.log(Number("bad")); // NaN
console.log(Number("")); // 0
```

`NaN` 表示数字运算或转换没有得到有效数字 . `Number.isNaN(value)` 检查某个值是否是 `NaN` .

## 比较值

比较时也要考虑转换 . `===` 不转换类型 , `==` 可能先转换类型 . 本教程使用 `===` 和 `!==` :

```js
console.log(1 === "1"); // false
console.log(1 == "1"); // true
console.log(null == undefined); // true
console.log(null === undefined); // false
console.log(NaN === NaN); // false
```

基本值比较的是值 ; object 则要区分是否指向同一个 object , 不能只看内容相同 :

```js
const first = { score: 80 };
const second = first;
console.log(first === second); // true
console.log(first === { score: 80 }); // false
console.log([] === []); // false
```

## 在条件中使用值

`if` 等条件不要求输入一定是 `boolean` , 而是把输入按真假解释 . `false`、`0`、`-0`、`0n`、`""`、`null`、`undefined` 和 `NaN` 按假处理 . 空数组 `[]`、普通 object 和字符串 `"0"` 按真处理 .

`Boolean(value)` 返回这个判断对应的 `true` 或 `false` .

## 选择一个值或默认值

`&&`、`||` 和 `??` 可以根据左侧的值选择结果 . 它们返回选中的原值 , 不一定返回 `boolean` .
1. `a && b` : `a` 按假处理时返回 `a` , 否则计算并返回 `b` .
2. `a || b` : `a` 按真处理时返回 `a` , 否则计算并返回 `b` .
3. `a ?? b` : 只有 `a` 是 `null` 或 `undefined` 时才计算并返回 `b` .

```js
console.log(0 || 10); // 10
console.log(0 ?? 10); // 0
console.log(null ?? 10); // 10
console.log("yes" && 7); // 7
console.log(false && console.log("不会执行"));
// 上一行只输出 false
```

如果默认值不应该替换 `0`、`false` 和空字符串 , 使用 `??` . 只有需要右侧的值时 , JS 才执行右侧表达式 ; 这叫 short-circuit . 上例中的内层 `console.log("不会执行")` 就被跳过了 .

`??` 与 `&&`、`||` 混用时必须用括号分组 .

下一篇 : [条件和循环](./03-conditions-and-loops.md) .
