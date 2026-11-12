# enum 和 namespace

前面的 `type` 和 `interface` 在生成 JS 后消失 . TS 还有一些声明会生成实际代码 , 本篇用 enum 和 namespace 说明这个区别 , 遇到时查阅即可 .

## enum : 给一组实际值起名字

普通 enum 会生成 JS object , 执行时可以通过成员名取值 :

```ts
enum Mode {
  Read = "read",
  Write = "write",
}
const mode: Mode = Mode.Read;
console.log(mode); // "read"
```

`Mode.Read` 的实际值是 `"read"` . 变量类型写成 `Mode` 时 , 要用 `Mode.Read`、`Mode.Write` 这样的成员赋值 .

不指定值时 , enum 从 `0` 开始递增 . 数字 enum 还可以从数字查回成员名 :

```ts
enum State {
  Pending,
  Done,
}
console.log(State.Pending); // 0
console.log(State[0]); // "Pending"
```

字符串 enum 没有这种数字到名称的对应关系 .

如果只需要限制字符串选项 , 可以用 [literal union](./05-unions-and-literals.md) , 不必额外创建 enum object .

`const enum` 是另一种处理方式 : 编译时可以直接把成员替换成值 . 是否保留 enum object 取决于配置 , 因此不要假定它像普通 enum 一样可以遍历 .

## namespace : 把声明放在同一个名字下

namespace 把一组声明组织为 `名字.成员` 的访问形式 :

```ts
namespace Text {
  export function upper(value: string): string {
    return value.toUpperCase();
  }
}
console.log(Text.upper("book")); // "BOOK"
```

`export` 让外部代码可以通过 `Text.upper` 访问这个 function . 上例的 namespace 会生成 JS 代码 , 不是单纯的类型声明 . 它与文件之间的 [module](../01-javascript/12-modules.md) 不同 .

## 加上 `declare` 后 , 只描述已有内容

`declare namespace` 不创建上面的运行时结构 , 而是描述别处已经提供的名字 . 声明文件中的 `declare module "package-name"` 同样描述指定依赖的类型 , 不提供依赖实现 .

因此阅读声明时要区分 : 当前代码是在创建值 , 还是只向 compiler 说明已有值的类型 . `declare` 和声明文件的关系见 [配置和类型导入](./13-tsconfig-and-type-imports.md) .

返回 [TypeScript 索引](./README.md) .
