# 数组、tuple 和 object 类型

单个变量可以标注为 `number` . 一组数据则需要继续说明 : 每个元素是什么类型、不同位置是否有不同要求、哪些 property 可以省略 .

## 同类元素用数组类型

`number[]` 表示元素为数字的数组 , 不限制长度 . `Array<number>` 是另一种等价写法 :

```ts
const scores: number[] = [60, 80];
scores.push(90);
// scores.push("high"); // 类型错误
const names: Array<string> = ["Ada", "Lin"];
console.log(scores, names);
```

## 不同位置有不同含义时用 tuple

如果第一项是标题、第二项是数量 , 就需要让每个位置符合各自的要求 . tuple 按位置规定类型 :

```ts
const pair: [string, number] = ["book", 2];
const title = pair[0]; // string
const count = pair[1]; // number
console.log(title, count);
// pair[0] = 3; // 类型错误
```

`(string | number)[]` 则允许每个位置是字符串或数字 , 不限制哪个位置使用哪种类型 . `|` 见 [union](./05-unions-and-literals.md) .

## 用名称区分数据时写 object 类型

tuple 按位置说明要求 , object 类型则按 property 名称说明要求 . 类型在 `=` 左侧 , 实际值在右侧 :

```ts
const item: {
  title: string;
  count: number;
  note?: string;
} = {
  title: "book",
  count: 2,
};
console.log(item.note); // undefined
```

`note?` 表示可以不提供 `note` . 读取 `item.note` 的类型是 `string | undefined` , 因为它可能不存在 .

## 再决定哪些内容允许修改

`const` 只限制变量重新赋值 . 如果还需要限制通过当前类型修改数据 , 使用 `readonly` :

```ts
const item: { readonly id: number; count: number } = { id: 1, count: 2 };
item.count = 3;
// item.id = 2; // 类型错误
const pair: readonly [string, number] = ["book", 2];
const scores: readonly number[] = [60, 80];
// scores.push(90); // 类型错误
console.log(item, pair, scores);
```

`readonly id` 限制 `id` 的赋值 ; `readonly number[]` 禁止通过 `scores` 增删和改写元素 . 这些限制只参与类型检查 , 不会在生成的 JS 中冻结数据 .

## 补充 : 类型不保证下标一定存在

本教程默认配置下 , `number[]` 的下标读取类型是 `number` , 但越界执行时仍得到 `undefined` . [noUncheckedIndexedAccess](./13-tsconfig-and-type-imports.md) 可以加强这项检查 .

普通 tuple 仍允许 `push` 等操作 , 并不会在运行时锁住长度 . 不需要修改时使用 readonly tuple .

下一篇 : [function 类型](./03-function-types.md) .
