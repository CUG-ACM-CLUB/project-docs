# type 和 interface

前面把 object 的 property 类型直接写在变量旁边 . 同一套要求需要在参数、返回值等多处使用时 , 可以先给类型起名字 .

## 用 `type` 给类型起名

下面把含有 `title`、`count` 的 object 类型命名为 `Item` :

```ts
type Item = {
  title: string;
  count: number;
};
const item: Item = { title: "book", count: 2 };
console.log(item);
```

其他变量或 function 参数也可以使用 `Item` , 不必再复制整段结构 .

## 用 `interface` 描述 object 的要求

interface 也可以描述 property , 还可以列出 method 的调用要求 :

```ts
interface Reader {
  title: string;
  read(): string;
}
const reader: Reader = {
  title: "book",
  read() {
    return this.title;
  },
};
console.log(reader.read());
```

`Reader` 要求 `title` 是字符串 , `read()` 返回字符串 . 实际的 `read` 代码仍需要写在 object 中 . `type` 和 `interface` 都只用于类型检查 , 不会生成对应的运行时 object .

## 名字便于复用 , 匹配主要看结构

给类型起名后 , TS 仍主要检查值有没有所需的 property 和 method , 不要求值先声明它实现了这个 interface :

```ts
interface Named {
  name: string;
}
const source = { name: "Ada", score: 90 };
const target: Named = source;
console.log(target.name); // "Ada"
```

`source` 有字符串 `name` , 所以可以赋给 `Named` . `target` 的类型只声明了 `name` , 因此不能直接写 `target.score` , 尽管它与 `source` 指向同一个 object .

直接写 `const target: Named = { name: "Ada", score: 90 }` 则会报错 . TS 对新写下的 object 还检查是否有多余 property .

## 在已有要求上增加内容

`extends` 在 interface 上增加要求 , `&` 要求同时满足两边的类型 :

```ts
interface Named {
  name: string;
}
interface Student extends Named {
  score: number;
}
type IdentifiedStudent = Student & { id: number };
const student: IdentifiedStudent = { id: 1, name: "Ada", score: 90 };
console.log(student);
```

`Student` 要求 `name` 和 `score` . `IdentifiedStudent` 还要求 `id` .

## 查阅 : 两种写法的区别
1. `type` 可以给 union、tuple、function 等类型起名 .
2. `interface` 可以重复声明同一个名字 , 把两次声明的成员合在一起 .
3. `type` 不能在同一范围内重复声明同名类型 .
`class X implements Reader` 则用来检查 class 创建的 instance 是否满足要求 , 见 [class 的类型和修饰符](./14-classes-and-modifiers.md) .

下一篇 : [union 和 literal 类型](./05-unions-and-literals.md) .
