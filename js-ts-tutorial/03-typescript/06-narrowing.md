# 类型缩小范围

union 声明有哪些可能 , 但调用字符串 method 前仍需要确定本次值是字符串 . TS 会根据代码中的判断缩小可能范围 , 这叫 narrowing .

## 用判断区分值的类型

```ts
function describe(value: string | number): string {
  if (typeof value === "string") {
    return value.toUpperCase(); // 这里是 string
  }
  return value.toFixed(2); // 这里是 number
}
console.log(describe("book"), describe(2));
```

`if` 内已经确定 `value` 是字符串 , 所以允许调用 `toUpperCase` . 这一支执行了 `return` , 剩下的路径就只可能是数字 .

这里执行的仍是普通 JS 条件 . compiler 只是沿着这些条件判断每条路径中还剩哪些类型 . `instanceof`、`in` 和 `value !== null` 也可以提供判断依据 .

## 用状态区分 object 的结构

如果两个 object 只有形状不同 , 判断起来可能不方便 . 可以让它们用同一个 property 保存不同的状态值 :

```ts
type Result =
  | { status: "ok"; value: number }
  | { status: "error"; message: string };

function describe(result: Result): string {
  if (result.status === "ok") {
    return String(result.value);
  }
  return result.message;
}
console.log(describe({ status: "ok", value: 42 }));
```

`status` 为 `"ok"` 时一定有 `value` ; 为 `"error"` 时一定有 `message` . compiler 根据这个对应关系 , 允许各分支读取自己的 property .

这样先判断 `status` , 就同时确定了哪些其他 property 可以读取 . union 中的 literal 不只是限制选项 , 也能把状态和对应数据联系起来 .

## 把重复判断写成 function

检查逻辑需要复用时 , 可以提取为判断 function . 返回类型 `value is Named` 告诉 compiler : 返回 `true` 时 , 参数符合 `Named` . 这种写法叫 type predicate :

```ts
type Named = { name: string };
function isNamed(value: unknown): value is Named {
  return typeof value === "object"
    && value !== null
    && "name" in value
    && typeof value.name === "string";
}
const input: unknown = { name: "Ada" };
if (isNamed(input)) {
  console.log(input.name); // input: Named
}
```

`unknown` 表示尚未确定类型的值 , 见 [下一篇](./07-any-unknown-never.md) . `isNamed` 先排除 `null` , 再检查 `name` 是否存在且为字符串 . `if` 内的 `input` 因而按 `Named` 使用 .

`typeof null` 的结果也是 `"object"` , 所以上例还要单独排除 `null` .

compiler 信任 `value is Named` 这项声明 , 不会证明内部判断正确 . 如果只写 `return true` , 类型检查也会信任它 , 但程序并没有检查输入 .

下一篇 : [any、unknown 和 never](./07-any-unknown-never.md) .
