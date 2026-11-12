# module

前面把数据和操作组织在 function、object 中 . 代码分到不同文件后 , 就需要说明一个文件向外提供什么、另一个文件怎样使用它 .

## 从一个文件导出 , 在另一个文件导入

本篇使用 ES module , 简称 ESM . `export` 指定提供哪些值 , `import` 取得这些值 . 下列两个文件都位于 `/tmp/js-ts-study` .

`math.mjs` :

```js
export const limit = 100;
export function add(a, b) {
  return a + b;
}
export default function double(value) {
  return value * 2;
}
```

`example.mjs` :

```js
import double, { add as sum, limit } from "./math.mjs";
console.log(double(3), sum(2, 3), limit); // 6 5 100
```

在 `/tmp/js-ts-study` 执行 `node example.mjs` .

## 导入的名字与导出的名字如何对应

上例有两种导出 :

1. `limit` 和 `add` 按名字导出 , 称为 named export . import 中的 `{ add as sum, limit }` 按导出名取值 , 并把 `add` 在本文件中命名为 `sum` .
2. `double` 使用 default export . 每个文件最多一个 default export ; 导入时不写 `{}` , 本地名字可以自行选择 .

import 中的 `{}` 是导入语法 , 不是 object 解构 .

`import * as math from "./math.mjs"` 则把所有导出放在 `math` 中访问 , 例如 `math.add(2, 3)` . default export 对应 `math.default` .

## import 从哪里寻找文件

`./math.mjs` 从 `example.mjs` 所在目录开始查找 , 所以本例是 `/tmp/js-ts-study/math.mjs` . `../` 表示该目录的上一级 . Node.js 的相对 ESM import 需要写文件扩展名 .

如果写的是 `import "some-package"` , 就按依赖名称加载 , 不是查找本目录中的同名文件 . 依赖通常由 npm 安装 , 记录在 `package.json` 中 .

## 文件加载后发生什么

每个 module 有自己的变量范围 . 没有导出的变量不能被其他文件直接访问 . 同一程序重复导入同一个 module , 通常只执行一次它的顶层代码 .

import 不会把源码按文本复制到当前位置 ; 导入方使用的是被导出方提供的值 .

## 查阅 : 其他导入和导出写法

1. `export { add } from "./math.mjs"` 把另一个文件的 `add` 再导出 . `export *` 转发所有 named export , 但不包含 default export .
2. `import("./math.mjs")` 写在需要加载的位置 , 返回 Promise ; 成功值包含被导入文件的导出 . Promise 在 [异步执行](./13-async/README.md) 中介绍 .
3. `require(...)` 和 `module.exports` 属于另一套写法 CommonJS . 文件扩展名和 `package.json` 的 `"type"` 如何选择 module 规则 , 见 [配置和类型导入](../03-typescript/13-tsconfig-and-type-imports.md) .

下一篇 : [callback](./13-async/01-callback.md) .
