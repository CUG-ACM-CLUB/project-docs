# 类型标注和类型推断

JS 允许变量先后保存不同类型的值 . TS 可以在代码执行前限制这些赋值 , 先从一个变量开始 .

## 给变量写出类型要求

变量名后的 `: number` 要求变量保存数字 , 这种写法叫类型标注 :

```ts
let score: number = 80;
score = 90;
// score = "90"; // 类型错误: string 不能赋给 number
const title: string = "book";
const enabled: boolean = true;
console.log(score, title, enabled);
```

`score = "90"` 不符合要求 , compiler 会报类型错误 . 这项检查不会把字符串转换为数字 .

## 没写标注 , 也有类型

如果初始值已经足够明确 , compiler 会根据代码确定类型 , 这叫类型推断 :

```ts
let score = 80; // score: number
// score = "high"; // 类型错误
const limit = 100; // limit: 100
```

`score` 的类型是 `number` , 可以改成其他数字 . `limit` 不能重新赋值 , 类型更具体 , 就是 `100` . 只允许一个具体值的类型叫 literal 类型 , 见 [union 和 literal](./05-unions-and-literals.md) .

`const item = { count: 2 }` 中的 `count` 仍能修改 , 因此它推断为 `number` , 而不是只允许 `2` . 保留具体值的方法后面在 [as const](./12-assertions-and-satisfies.md) 中介绍 .

## 把要求写到 function 边界上

变量赋值可以检查类型 , function 的参数与返回值也可以 . 参数类型限制调用方 , 返回类型约束实现 :

```ts
function add(a: number, b: number): number {
  return a + b;
}
const total = add(2, 3); // total: number
console.log(total);
```

参数括号后的 `: number` 表示返回类型 , `total` 据此推断为 `number` . 这个返回标注也可以省略 , compiler 会根据 `return a + b` 推断 , 不需要每个位置都重复写类型 .

## 类型检查和实际执行是两件事

`const score: number = 80` 生成 JS 后是 `const score = 80` . 执行时没有 `: number` 这项检查 ; 从外部读到的数据仍需要程序自己判断 .

本部分统一开启 `strict` 严格检查 . 选项含义见 [配置和类型导入](./13-tsconfig-and-type-imports.md) .

下一篇 : [数组、tuple 和 object 类型](./02-arrays-tuples-and-objects.md) .
