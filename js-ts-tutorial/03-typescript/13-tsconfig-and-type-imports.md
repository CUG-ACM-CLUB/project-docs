# 配置和类型导入

前面的类型声明参与检查 , 最终执行的仍是 JS . 本篇沿着这个过程说明 : compiler 读取什么配置、输出什么文件、哪些 import 只在检查时存在 .

## 用配置文件保存编译规则

`tsconfig.json` 保存 compiler 选项和输入文件范围 . 例如文件 `/tmp/js-ts-study/tsconfig.json` :

```json
{
  "compilerOptions": {
    "strict": true,
    "target": "ES2022",
    "module": "NodeNext",
    "noEmitOnError": true,
    "outDir": "out"
  },
  "include": ["*.mts"]
}
```

1. `strict` 开启严格类型检查 , 包括参数隐含为 `any`、可能为 `null` 等情况的检查 .
2. `target` 指定生成 JS 的语法版本 . 它不会为旧环境补上缺少的内置 method .
3. `module: "NodeNext"` 按 Node.js 的规则检查和输出 module .
4. `noEmitOnError` 表示有类型错误时不生成新 JS 文件 .
5. `outDir` 指定输出目录 , `include` 选择输入文件 . 两者都从配置文件所在目录起算 , 本例分别是 `/tmp/js-ts-study/out` 和 `/tmp/js-ts-study/*.mts` .

在 `/tmp/js-ts-study` 执行 `npx tsc -p .` , compiler 就使用这份配置 . 加 `--noEmit` 则只检查 , 不生成 JS .

[运行示例](../00-preparation/02-run-examples.md) 中的 `npx tsc example.mts ...` 直接指定了文件 , 不会读取这份配置 . 两种调用方式不要混用 .

## 文件扩展名决定怎样处理 module

使用 NodeNext 配置时 , compiler 需要判断输入文件按 ESM 还是 CommonJS 处理 :

1. `.mts` 按 ESM 处理 , 输出 `.mjs` .
2. `.cts` 按 CommonJS 处理 , 输出 `.cjs` .
3. `.ts` 参考所属 `package.json` 的 `"type"` : `"module"` 表示 ESM ; 未指定时通常按 CommonJS 处理 .

前两种扩展名明确指定规则 , 普通 `.ts` 则需要结合配置判断 . 两套 module 写法见 [module](../01-javascript/12-modules.md) .

## 只用于检查的类型 , 不必成为运行时 import

一个文件可能导出类型而不是 function 或 object . 其他文件通过 `import type` 使用这个类型 , 编译后整条 import 删除 :

文件 `/tmp/js-ts-study/types.mts` :

```ts
export interface Item {
  title: string;
}
```

文件 `/tmp/js-ts-study/example.mts` :

```ts
import type { Item } from "./types.mjs";
const item: Item = { title: "book" };
console.log(item.title);
```

在练习目录执行 :

```bash
npx tsc -p .
node out/example.mjs
```

TS 检查时能把 `./types.mjs` 对应到 `types.mts` . 路径写 `.mjs` 是沿用生成后的文件名 , 供 Node.js 加载 ; 不过上例只导入类型 , 最终整条 import 都会删除 .

`export type { Item }` 同样只导出类型 , 不生成运行时导出 .

## 声明文件说明已有代码的类型

使用 JS 依赖时 , 实现可能已经由依赖提供 , TS 只需要知道它有哪些值和调用方式 . `.d.ts` 就用于保存这类类型声明 , 不提供实现 . 依赖可能自带声明文件 , 也可能通过 `@types/...` 依赖单独提供 .

例如 `declare const version: string` 告诉 compiler : 别处提供了一个字符串变量 `version` . 这条声明不会创建变量 ; 实际执行时仍需要对应代码提供它 .

## 查阅 : 更严格的可选值检查

以下两项没有在本教程中默认开启 :

1. `noUncheckedIndexedAccess` : 不确定下标或 property 是否存在时 , 读取类型包含 `undefined` .
2. `exactOptionalPropertyTypes` : 区分没有提供可选 property , 与提供了值为 `undefined` 的 property .

下一篇 : [class 的类型和修饰符](./14-classes-and-modifiers.md) .
