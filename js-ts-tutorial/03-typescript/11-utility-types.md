# 常用类型工具

前两篇说明了怎样根据已有类型生成新类型 . 常见操作不需要自己实现 , TS 已提供一组类型工具 , 不需要 import .

这些工具都只产生新类型 , 不修改实际数据 . 以下按要生成的结果分组 , 遇到对应需求时查阅即可 .

## 调整 object 的 property 要求

| 工具 | 结果 |
| --- | --- |
| `Partial<T>` | T 的各 property 都可省略 |
| `Required<T>` | T 的各 property 都变成必填 |
| `Readonly<T>` | 限制通过新类型修改各 property |
| `Pick<T, K>` | 只保留 K 指定的 property |
| `Omit<T, K>` | 移除 K 指定的 property |
| `Record<K, V>` | K 中的每个 key 对应 V 类型的值 |

```ts
type Item = { id: number; title: string; note?: string };
const patch: Partial<Item> = { title: "pen" };
const complete: Required<Item> = { id: 1, title: "book", note: "" };
const view: Readonly<Item> = { id: 1, title: "book" };
const brief: Pick<Item, "id" | "title"> = { id: 1, title: "book" };
const draft: Omit<Item, "id"> = { title: "book" };
const counts: Record<"apple" | "pear", number> = { apple: 2, pear: 3 };
console.log(patch, complete, view, brief, draft, counts);
```

`Partial` 和 `Readonly` 只处理当前这一层 property , 不改变内部嵌套的 object 类型 . `Omit<Item, "id">` 只得到没有 `id` 要求的新类型 , 不会从已有 object 中删除 `id` .

## 从 union 中排除或保留选项

```ts
type Modes = "read" | "write" | "delete";
type Safe = Exclude<Modes, "delete">; // "read" | "write"
type Shared = Extract<Modes, "read" | "other">; // "read"
type Present = NonNullable<string | null | undefined>; // string
const mode: Safe = "write";
const shared: Shared = "read";
const title: Present = "book";
console.log(mode, shared, title);
```

`Exclude` 做排除 , `Extract` 做保留 . 上例分别得到 `"read" | "write"` 和 `"read"` . `NonNullable` 去掉 `null` 和 `undefined` .

## 从 function 和 Promise 取得类型

如果已经有 function 定义 , 可以从中取得参数与返回类型 ; 如果有 Promise 类型 , 可以取得等待成功后的值类型 :

```ts
function add(a: number, b: number): number {
  return a + b;
}
type Args = Parameters<typeof add>; // [a: number, b: number]
type Result = ReturnType<typeof add>; // number
type Resolved = Awaited<Promise<number>>; // number
const args: Args = [2, 3];
const result: Result = add(...args);
const value: Resolved = 42;
console.log(result, value);
```

`Parameters` 得到参数 tuple , 所以 `args` 必须按顺序提供两个数字 . `ReturnType` 得到返回类型 `number` . `Awaited` 得到等待成功后的值类型 , 本身不执行 `await` .

下一篇 : [类型断言和 satisfies](./12-assertions-and-satisfies.md) .
