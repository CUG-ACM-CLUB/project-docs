# 运行示例

本篇供需要亲自运行示例时查阅 . 只阅读代码可以直接进入 [JavaScript 语法](../01-javascript/README.md) .

## 准备一个练习目录

示例环境是 Node.js 22 和 TypeScript 5.9.3 . 安装 Node.js 后 , 在终端执行以下命令 . 练习文件统一放在 `/tmp/js-ts-study` .

```bash
mkdir -p /tmp/js-ts-study
cd /tmp/js-ts-study
npm init -y
npm install --save-dev typescript@5.9.3
node --version
npx tsc --version
```

`npm` 用来安装和管理依赖 . `npm init` 创建记录依赖的 `package.json` ; `npm install` 安装 TypeScript , `--save-dev` 把它记为开发工具 . 后续的 `npx tsc` 使用这里安装的 compiler .

## 直接运行 JS

每个代码块默认是独立例子 . 把一个 JS 代码块放到 `/tmp/js-ts-study/example.mjs` , 在练习目录执行 :

```bash
node example.mjs
```

例如文件内容是 :

```js
const score = 80;
console.log(score);
```

`console.log` 把值输出到终端 . `//` 后面是注释 ; 示例用注释标出输出的值 .

## 先把 TS 编译成 JS

TS 例子放在 `/tmp/js-ts-study/example.mts` . 例如 :

```ts
const score: number = 80;
console.log(score);
```

在练习目录检查、生成 JS 并运行 :

```bash
npx tsc example.mts --strict --target ES2022 --module NodeNext --noEmitOnError --outDir out
node out/example.mjs
```

第一个命令检查类型 , 把生成的 `.mjs` 放入 `/tmp/js-ts-study/out` . 第二个命令才执行 JS .

`strict` 开启严格类型检查 , `target` 和 `module` 指定生成规则 , `noEmitOnError` 表示有类型错误时不生成新文件 . 这些选项可以写进配置文件 , 详见 [配置和类型导入](../03-typescript/13-tsconfig-and-type-imports.md) .

只检查类型、不生成 JS 时使用 :

```bash
npx tsc example.mts --strict --target ES2022 --module NodeNext --noEmit
```

## 例子和路径的约定

1. 标注错误的代码行默认已被注释 . 不同例子可能使用同名变量 , 不要拼进同一个文件 .
2. 命令中的路径从终端工作目录开始查找 . 本篇统一在 `/tmp/js-ts-study` 执行命令 .
3. import 中的相对路径从源文件所在目录开始查找 . `/tmp/js-ts-study/example.mjs` 中的 `import "./x.mjs"` 指向 `/tmp/js-ts-study/x.mjs` .

下一部分 : [JavaScript 语法](../01-javascript/README.md) .
