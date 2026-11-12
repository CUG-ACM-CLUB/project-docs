# 泛型

一个取首项的 function 可以处理数字数组 , 也可以处理字符串数组 . 如果返回值只写成 `any` , 调用方就丢失了结果类型 . 如果固定写 `number` , 又不能用于字符串 .

## 用类型参数保留输入与输出的关系

泛型允许调用时再确定具体类型 . 下面用类型参数 `T` 同时表示数组元素与返回值的类型 :

```ts
function first<T>(values: T[]): T | undefined {
  return values[0];
}
const score = first([80, 90]); // number | undefined
const name = first<string>(["Ada"]); // string | undefined
console.log(score, name);
```

`T` 叫类型参数 , 名字可以自选 . `first([80, 90])` 中 , compiler 推断 `T` 是 `number` ; `first<string>(...)` 则由调用方指定 `string` .

参数 `T[]` 与返回类型中的 `T` 使用同一个类型 . 返回类型还有 `undefined` , 因为空数组没有首项 .

因此调用方仍然知道结果类型 : 输入数字数组 , 返回值就是数字或 `undefined` . `any` 不会保留这种关系 .

## 对类型参数提出最低要求

如果实现需要读取 `length` , 就不能接受任意类型 . `extends` 限制 `T` 必须具有数字类型的 `length` :

```ts
function size<T extends { length: number }>(value: T): number {
  return value.length;
}
console.log(size("hello"), size([1, 2])); // 5 2
// size(42); // 类型错误: number 没有 length
```

`extends` 在这里是类型约束 , 不是 JS class 的继承 . 符合这个要求的字符串和数组都可以传入 .

## 把相同关系用于数据结构

不仅 function 能接收类型参数 . 一个通用的数据结构也可以把变化的部分留给调用方指定 :

```ts
type Box<T> = { value: T };
interface Page<T> {
  items: T[];
  total: number;
}
const box: Box<string> = { value: "book" };
const page: Page<number> = { items: [80, 90], total: 2 };
console.log(box, page);
```

`Box<string>` 的 `value` 是字符串 ; `Page<number>` 的 `items` 是数字数组 .

因此可以共用 `Box` 的结构 , 同时让不同变量保存不同类型的 `value` . `Promise<number>` 和 `Map<string, number>` 也是同样的写法 , 分别规定成功值、key 和 value 的类型 .

## 补充 : 类型参数可以有默认值

`Box<T = string>` 中 , 不提供类型参数时使用 `string` :

```ts
type Box<T = string> = { value: T };
const first: Box = { value: "book" };
const second: Box<number> = { value: 42 };
console.log(first, second);
```

泛型仍然只是类型规则 . 生成 JS 后 , `first<number>([1])` 变成 `first([1])` , 不会在执行时携带 `number` 类型信息 .

下一篇 : [从已有声明取得类型](./09-keyof-typeof-and-indexed-access.md) .
