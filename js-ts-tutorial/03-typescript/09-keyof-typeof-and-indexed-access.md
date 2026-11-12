# 从已有声明取得类型

本篇供查阅 . 泛型中的类型不一定要手写 , 也可以从已有声明中取出来 . 先分别取得名称和 property 类型 , 再把它们组合成按名称取值的 function .

## 用 `keyof` 取得允许的名称

对于下面固定名称的 object 类型 , `keyof` 得到名称组成的 union :

```ts
type Item = { title: string; count: number };
type Key = keyof Item; // "title" | "count"
const key: Key = "title";
console.log(key);
```

## 用 `typeof` 取得已有变量的类型

如果已经有实际值 , 不想再复制一份类型结构 , 可以在类型声明中使用 `typeof` :

```ts
const defaults = { title: "book", count: 2 };
type Options = typeof defaults; // { title: string; count: number }
const options: Options = { title: "pen", count: 3 };
console.log(typeof options); // 运行时字符串 "object"
```

`Options` 根据 `defaults` 得到 object 类型 . `console.log(typeof options)` 则执行普通 JS 运算 , 输出字符串 `"object"` .

## 用 `T[K]` 取得选中 property 的类型

有了 object 类型和名称 , 就能取出该名称对应的类型 . `Item["title"]` 得到 `string` , 不是某个实际标题 :

```ts
type Item = { title: string; count: number };
type Title = Item["title"]; // string
type Value = Item[keyof Item]; // string | number
type Rows = Item[];
type Row = Rows[number]; // Item , 即数组元素类型
const title: Title = "book";
const value: Value = 2;
const row: Row = { title, count: 1 };
console.log(value, row);
```

## 合起来描述按名称取值的 function

现在需要同时限制两件事 : 名称必须存在 , 返回类型必须对应这个名称 . 将 `keyof` 和 `T[K]` 用在泛型中 :

```ts
function get<T, K extends keyof T>(object: T, key: K): T[K] {
  return object[key];
}
const item = { title: "book", count: 2 };
const title = get(item, "title"); // string
const count = get(item, "count"); // number
// get(item, "missing"); // 类型错误
console.log(title, count);
```

`T` 是 object 类型 , `K` 是选中的名称 . `K extends keyof T` 禁止传入不存在的名称 ; 返回类型 `T[K]` 则与所选 property 一致 .

## 补充 : 名称不固定时的写法

前面的 `Item` 明确列出了名称 . 如果名称可以是任意字符串 , 只要求值是数字 , 可以使用 index signature :

```ts
type Counts = { [key: string]: number };
const counts: Counts = { apple: 2 };
console.log(counts["apple"]); // 2
```

`key` 只是声明中使用的名字 . 这个类型不保证每个名称都有值 ; 读取不存在的名称仍得到 `undefined` . 加强这项检查的配置见 [noUncheckedIndexedAccess](./13-tsconfig-and-type-imports.md) .

下一篇 : [mapped type 和 conditional type](./10-mapped-and-conditional-types.md) .
