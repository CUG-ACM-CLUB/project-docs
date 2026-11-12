# 类型断言和 satisfies

前面通过判断缩小了类型范围 . 源码中还常见 `as`、`!` 和 `satisfies` : 它们有的要求 compiler 信任声明 , 有的要求 compiler 检查表达式 , 不能混为一谈 .

## `as` : 要求按指定类型使用

`as Type` 叫类型断言 . 它让 compiler 按指定类型使用值 , 不转换实际值 :

```ts
const input: unknown = "hello";
const text = input as string;
console.log(text.toUpperCase()); // "HELLO"
const raw: unknown = 42;
const wrong = raw as string;
// wrong.toUpperCase(); // TS 允许 , 运行时会报错
```

`raw as string` 不会把 `42` 变成字符串 , 所以调用字符串 method 仍会报错 . 真要转换值 , 使用 `String(42)` 或 `Number("42")` 等操作 .

## `!` : 声明这个值不为空

值后面的 `!` 同样要求 compiler 信任开发者 , 但只排除 `null` 和 `undefined` . 它叫非空断言 , 不同于值前面的逻辑非 `!value` :

```ts
const names = ["Ada"];
const found = names.find((name) => name === "Ada"); // string | undefined
console.log(found!.toUpperCase()); // "ADA"
```

`found!` 不做实际检查 . 如果没有找到 , 值仍然是 `undefined` , 调用就会报错 . 不能确定时 , 应先判断 `found !== undefined` .

## `as const` : 保留表达式中的具体值

有时不是 compiler 不允许操作 , 而是推断出的类型太宽 . 例如希望 `mode` 只表示 `"read"` , 而不是任意字符串 . `as const` 保留这些具体值 , 并添加只读标记 :

```ts
const options = { mode: "read", sizes: [10, 20] } as const;
// options.mode: "read"
// options.sizes: readonly [10, 20]
console.log(options);
```

这里的 `mode` 不再是任意字符串 , 而是 `"read"` . `sizes` 是只读 tuple , 两个位置分别是 `10` 和 `20` . 这些都是类型限制 , 不会在运行时冻结数据 .

## `satisfies` : 检查符合要求 , 不统一抹去具体类型

如果既想检查所有 property 满足一套要求 , 又想继续使用各个 property 自己的具体类型 , 可以使用 `satisfies` :

```ts
const palette = {
  red: [255, 0, 0],
  green: "green",
} satisfies Record<"red" | "green", string | [number, number, number]>;
console.log(palette.green.toUpperCase()); // "GREEN"
```

`Record` 要求 `red`、`green` 都存在 , 值可以是字符串或三个数字组成的 tuple . 检查通过后 , `palette.green` 仍是字符串 , 可以直接调用 `toUpperCase` .

所以 `satisfies` 与 `as` 的方向不同 : 前者要求 compiler 检查 , 后者要求 compiler 按断言使用值 . 两者都不替代程序运行时对外部输入的检查 .

下一篇 : [配置和类型导入](./13-tsconfig-and-type-imports.md) .
