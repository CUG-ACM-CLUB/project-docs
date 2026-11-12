# JavaScript 和 TypeScript

## JS 代码由谁执行

JavaScript , 简称 JS . JavaScript engine 是读取并执行 JS 代码的程序 . 浏览器可以运行 JS , 本教程则使用终端中的 Node.js .

JS 自带数组等数据结构 . Node.js 在此基础上提供文件读取等额外功能 ; 浏览器则提供操作网页的功能 . 相同的 JS 语法 , 在两个环境中能使用的功能不完全相同 .

## TS 在执行前做什么

TypeScript , 简称 TS , 在 JS 基础上增加类型检查 . 例如 :

```ts
const score: number = 80;
// score 的类型是 number
```

`: number` 要求 `score` 保存数字 . 本教程用 TypeScript compiler `tsc` 检查这些要求 , 并生成 JS . compiler 就是编译器 .

生成的 JS 不再包含 `: number` , 交给 Node.js 执行的代码相当于 :

```js
const score = 80;
```

所以 TS 不会替代 JS 的执行规则 . 从文件或网络读到数据后 , 程序仍需要检查数据本身 ; 写一个类型标注不会自动检查这些输入 .

## 本教程使用什么文件

JS 示例放在 `.mjs` 文件中 , TS 示例放在 `.mts` 文件中 . `.mts` 通过 `tsc` 生成 `.mjs` , 再交给 Node.js .

这两种文件都按 module 组织 . module 允许一个文件导出代码 , 另一个文件导入使用 , 语法见后面的 [module](../01-javascript/12-modules.md) .

下一篇 : [运行示例](./02-run-examples.md) .
