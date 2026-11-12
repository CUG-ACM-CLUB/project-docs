# mapped type 和 conditional type

本篇供查阅 . 前面已经能从类型中取出名称和 property 类型 . 接下来把这些信息用于生成新类型 : 先批量处理 property , 再根据条件选择类型 .

## 按已有 property 生成新结构

例如更新数据时可能只提供部分 property . `Optional<T>` 保留原名称和类型 , 给每一项增加可选标记 :

```ts
type Item = { title: string; count: number };
type Optional<T> = {
  [K in keyof T]?: T[K];
};
const patch: Optional<Item> = { count: 3 };
console.log(patch);
```

当 `T` 是 `Item` 时 , `K` 依次表示 `"title"` 和 `"count"` . `T[K]` 取得各自的类型 , `?` 添加可选标记 . 所以 `Optional<Item>` 相当于 `{ title?: string; count?: number }` .

这种按名称生成 property 的写法叫 mapped type . 在 `[K in keyof T]` 前写 `readonly` 可以添加只读限制 ; `-readonly` 移除只读限制 , `-?` 移除可选标记 .

## 根据输入类型选择结果类型

批量生成结构之外 , 也可以根据类型关系选择结果 . `T extends U ? A : B` 表示 `T` 满足 `U` 时选择 `A` , 否则选择 `B` , 叫 conditional type :

```ts
type Label<T> = T extends string ? "text" : "other";
const first: Label<string> = "text";
const second: Label<number> = "other";
console.log(first, second);
```

`Label<string>` 得到 `"text"` , `Label<number>` 得到 `"other"` . 这是类型计算 , 不是程序执行时的条件判断 .

## 匹配后 , 取出其中一部分

确定输入是数组类型后 , `infer` 可以进一步取得它的元素类型 :

```ts
type ElementOf<T> = T extends readonly (infer E)[] ? E : never;
type Score = ElementOf<number[]>; // number
type Invalid = ElementOf<string>; // never
const score: Score = 80;
console.log(score);
```

`T` 符合数组类型时 , compiler 把元素类型记为 `E` , 并返回 `E` . 不符合数组类型时 , 结果是 `never` .

## 补充 : union 可能会被逐项处理

`T extends ...` 直接检查类型参数 `T` 时 , union 会逐项参与上面的类型计算 :

```ts
type Wrap<T> = T extends unknown ? T[] : never;
type Result = Wrap<string | number>; // string[] | number[]
const result: Result = [1, 2];
console.log(result);
```

`Wrap<string>` 得到 `string[]` , `Wrap<number>` 得到 `number[]` , 最后合成 `string[] | number[]` . 这不等于允许混合元素的 `(string | number)[]` .

不希望逐项处理时 , 把检查写成 `[T] extends [U] ? A : B` .

下一篇 : [常用类型工具](./11-utility-types.md) .
