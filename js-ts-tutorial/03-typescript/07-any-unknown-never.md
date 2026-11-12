# any、unknown 和 never

union 列出了可能的类型 . 如果还不知道输入是什么类型 , 就需要区分三种情况 : 不检查它、先检查再使用它、判断后已经没有剩余情况 .

## `any` : 不再要求你先判断

`any` 允许跳过大量类型检查 . 下面即使 `value` 已变成数字 , compiler 也允许调用字符串 method :

```ts
let value: any = "hello";
value = 42;
// value.toUpperCase(); // TS 允许 , 执行时会报 TypeError
console.log(value);
```

这让代码容易写下去 , 却把错误留到了执行时 . 如果想让 compiler 提醒自己先检查 , 使用 `unknown` .

## `unknown` : 尚未确定 , 先判断再使用

`unknown` 也能接收任意值 , 但不允许直接读取 property 或调用 method . 前面学过的 narrowing 可以逐步确认这个值 :

```ts
const input: unknown = JSON.parse('{"count":2}');
if (
  typeof input === "object"
  && input !== null
  && "count" in input
  && typeof input.count === "number"
) {
  console.log(input.count + 1); // 3
}
```

`JSON.parse` 默认返回 `any` . 把结果保存为 `unknown` 后 , 必须先确认 `input` 是非空 object , 有 `count` , 且 `count` 是数字 , 才能执行加法 .

同样 , JS 可以抛出任意值 . 严格配置下 `catch` 中的错误也是 `unknown` , 使用 `message` 前需要判断是不是 Error :

```ts
try {
  throw new Error("failed");
} catch (error) {
  if (error instanceof Error) {
    console.log(error.message);
  } else {
    console.log(String(error));
  }
}
```

## `never` : 不会得到正常值

`unknown` 表示类型尚未确定 , `never` 则表示不可能得到正常值 . 始终抛错的 function 不会正常返回 , 返回类型可以这样写 :

```ts
function fail(message: string): never {
  throw new Error(message);
}
// fail("stop"); // 调用后不会正常返回
```

`void` 表示不使用返回值 , function 仍可以正常结束 . `never` 则表示不会正常返回 .

## 用没有剩余情况来检查遗漏

narrowing 也可能把所有可能性都排除 . 这时剩余类型就是 `never` , 可以利用它检查是否漏写分支 :

```ts
type Mode = "read" | "write";
function assertNever(value: never): never {
  throw new Error(`unexpected: ${value}`);
}
function describe(mode: Mode): string {
  switch (mode) {
    case "read":
      return "读取";
    case "write":
      return "写入";
    default:
      return assertNever(mode);
  }
}
console.log(describe("read"));
```

目前 `read` 和 `write` 都已经返回 , 所以 `default` 中的 `mode` 是 `never` .

如果给 `Mode` 增加 `"delete"` 却不增加对应 `case` , `default` 就可能收到 `"delete"` . 它不符合 `assertNever` 要求的 `never` 参数 , compiler 因而报错 .

下一篇 : [泛型](./08-generics.md) .
