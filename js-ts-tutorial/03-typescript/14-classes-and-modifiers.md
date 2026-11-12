# class 的类型和修饰符

JS class 已经可以创建 instance 并共享 method , 见 [prototype 和 class](../01-javascript/10-prototypes-and-classes.md) . TS 不改变这条主线 , 而是在数据和操作上增加类型要求与访问限制 .

## 限制数据类型与访问位置

field 和 method 统称成员 . 三种访问修饰符规定哪些代码可以访问成员 :
1. `public` : 外部代码可以访问 .
2. `protected` : class 和子 class 内部可以访问 .
3. `private` : 声明它的 class 内部可以访问 .
4. 不写修饰符时默认是 `public` .

```ts
class Counter {
  private count: number;
  readonly name: string;
  constructor(name: string) {
    this.name = name;
    this.count = 0;
  }
  next(): number {
    return ++this.count;
  }
}
const counter = new Counter("A");
console.log(counter.name, counter.next()); // "A" 1
// counter.count; // 类型错误
// counter.name = "B"; // 类型错误
```

`private count` 的限制由 TS 检查 , 不会生成 JS 的 `#count` . `#count` 的私有限制则在运行时也存在 .

上例的 `count` 是私有数字 , 外部通过 `next` 使用它 . `name` 允许读取 , 但不能在初始化后重新赋值 .

## 把 constructor 中的保存参数写成简写

constructor 经常只是把参数保存到 instance . 在参数前加访问修饰符或 `readonly` , TS 会自动创建同名 property 并保存传入值 , 这种写法叫 parameter property :

```ts
class Counter {
  constructor(
    public readonly name: string,
    private count: number = 0,
  ) {}
  next(): number {
    return ++this.count;
  }
}
const counter = new Counter("A");
console.log(counter.name, counter.next());
```

`name` 自动保存在 `this.name` , `count` 自动保存在 `this.count` , 不用再手动赋值 . 没有修饰符的普通参数不会自动变成 property .

## 要求子 class 补齐某些操作

有时父 class 只提供部分实现 , 某个操作必须由子 class 决定 . `abstract` class 可以声明这个要求 , 但不能直接用 `new` 创建 instance :

```ts
abstract class Reader {
  abstract read(): string;
  describe(): string {
    return "reader";
  }
}
class TextReader extends Reader {
  read(): string {
    return "text";
  }
  override describe(): string {
    return "text reader";
  }
}
const reader: Reader = new TextReader();
console.log(reader.read(), reader.describe());
```

`TextReader` 必须实现 `read` . `override describe` 则重写父 class 已有的 `describe` ; `override` 会要求 compiler 检查父 class 确实有这个成员 .

## 查阅 : 其他 class 类型写法

1. `implements Reader` 检查 instance 是否满足 interface , 不像 `extends` 那样继承实现 , 也不替 method 补写参数类型 .
2. 严格配置要求需要初始化的 field 在声明或 constructor 中得到值 . `name!: string` 表示由开发者保证在别处初始化 ; `!` 本身不赋值 .
3. `TextReader` 用作类型时描述 instance . `typeof TextReader` 描述 class 自身 , 包括 constructor 和 static 成员 .

下一篇 : [enum 和 namespace](./15-enums-and-namespaces.md) .
