# function 类型

前面给 function 的定义标注了参数和返回类型 . 但 function 本身也可以存入变量、作为参数传递 , 这些位置同样需要描述它的调用要求 .

## 描述一个 function 值

`(value: number) => number` 表示接收一个数字、返回一个数字的 function :

```ts
const double: (value: number) => number = (value) => value * 2;
console.log(double(3)); // 6
```

`=` 左侧的 `(value: number) => number` 是类型 , 右侧的 `(value) => value * 2` 才是实际 function . 两处 `=>` 用途不同 .

## 参数数量也是调用要求的一部分

普通必填参数要求调用方提供值 . 默认参数、可选参数和 rest 参数分别允许省略值或提供多个值 :

```ts
function describe(title: string, count: number = 1, note?: string): string {
  return `${title}: ${count}, ${note ?? ""}`;
}
function sum(...values: number[]): number {
  return values.reduce((total, value) => total + value, 0);
}
console.log(describe("book"), sum(1, 2, 3));
```

`count` 默认是 `1` . `note?` 允许不传 `note` , 所以 function 内的 `note` 类型是 `string | undefined` . `...values` 接收任意多个数字 , 在 function 内是 `number[]` .

## 把调用要求用于 callback

callback 也是 function 值 . 接收方在参数中写出 function 类型 , 就明确了会提供什么输入、要求什么输出 :

```ts
function apply(value: number, operation: (input: number) => string): string {
  return operation(value);
}
const result = apply(3, (input) => `value=${input}`);
console.log(result); // "value=3"
```

`apply` 接收数字 `value` 和 function `operation` . 它调用 `operation(value)` , 并返回得到的字符串 . 因此上例 arrow function 的 `input` 推断为 `number` , 返回值必须符合 `string` .

## 不使用返回值时写 `void`

有些接收方只调用 function , 不处理它的返回值 . `() => void` 表示不接收参数、调用方不使用返回值的 function . 它允许接收一个实际返回了值的 function :

```ts
const operation: () => void = () => 42;
const result = operation(); // 类型是 void
console.log(result); // 运行时仍是 42
```

`result` 的 TS 类型是 `void` , 不能当数字使用 , 但执行时仍得到 `42` . 这里的 `void` 表示忽略返回值 , 不是把返回值改成 `undefined` .

但如果直接声明 `function show(): void` , 就不能在实现中写 `return 42` . 这个声明要求 function 本身不返回有用的值 ; 上例的 `() => void` 则允许接收已有 function 并忽略其返回值 .

## 查阅 : 多组调用方式

如果同一个 function 传字符串得到数字、传数字得到字符串 , 单独一个返回类型无法表达这种对应关系 . overload 允许分别声明这些调用方式 :

```ts
function parse(value: string): number;
function parse(value: number): string;
function parse(value: string | number): number | string {
  return typeof value === "string" ? Number(value) : String(value);
}
const first = parse("12"); // number
const second = parse(12); // string
console.log(first, second);
```

前两行规定允许怎样调用 : 传字符串得到数字 , 传数字得到字符串 . 最后一组负责实际执行 , 必须处理这两种情况 .

async function 的返回类型写成 `Promise<T>` . 例如 `async function score(): Promise<number>` 返回 Promise , `await score()` 得到的成功值才是数字 . `<T>` 的用法见 [泛型](./08-generics.md) .

下一篇 : [type 和 interface](./04-type-and-interface.md) .
