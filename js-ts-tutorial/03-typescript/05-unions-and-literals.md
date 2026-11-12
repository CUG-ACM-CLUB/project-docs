# union 和 literal 类型

前面的类型给出了确定结构 . 实际数据也可能有多种情况 : 输入可能是数字或字符串 , 状态可能只允许 `"read"` 或 `"write"` .

## 用 union 表示多种可能

`A | B` 表示值可以属于 A 或 B , 叫 union :

```ts
function show(value: string | number): string {
  return String(value);
}
console.log(show("12"), show(12));
```

`String(value)` 能处理两种值 , 所以允许调用 . `value.toUpperCase()` 只有字符串支持 , 不能直接调用 ; 需要先判断类型 , 见 [下一篇](./06-narrowing.md) .

## 用 literal 限定具体值

`string` 允许任意字符串 . 如果只允许几个选项 , 可以把具体字符串作为类型 . 只允许一个具体值的类型叫 literal 类型 :

```ts
type Mode = "read" | "write";
let mode: Mode = "read";
mode = "write";
// mode = "delete"; // 类型错误
console.log(mode);
```

## 声明值可能为空

`string` 不包含 `null` 和 `undefined` . 开启严格检查后 , 可能为空的输入要显式写出 :

```ts
function normalize(value: string | null | undefined): string {
  return value ?? "guest";
}
console.log(normalize(null)); // "guest"
```

下一篇会根据判断结果排除这些可能性 . 先声明可能有哪些情况 , 再判断本次属于哪种情况 , 是处理不确定数据的两步 .

## 查阅 : 同时满足多个要求

`|` 表示可以属于任意一种类型 ; `&` 则要求同时满足两种类型 , 叫 intersection :

```ts
type Named = { name: string };
type Scored = { score: number };
const student: Named & Scored = { name: "Ada", score: 90 };
console.log(student);
```

上例要求 `student` 同时有字符串 `name` 和数字 `score` .

括号决定 union 组合在哪一层 . `string | number[]` 是字符串或数字数组 ; `(string | number)[]` 是元素可以为字符串或数字的数组 .

## 查阅 : 从模板组成字符串类型

template literal type 可以从几个选项生成另一组字符串类型 . 下面的 `EventName` 只允许 `"before:read"` 或 `"before:write"` :

```ts
type Method = "read" | "write";
type EventName = `before:${Method}`;
const event: EventName = "before:read";
console.log(event);
```

这里的模板生成类型 , 不是执行字符串拼接 . 运行时的字符串模板见 [字符串](../02-built-ins/01-string.md) .

下一篇 : [类型缩小范围](./06-narrowing.md) .
