# prototype 和 class

多个 object 可以拥有各自的数据 , 同时使用同一套 method . JS 用 prototype 实现共享查找 , class 则把创建 object 和定义 method 的代码组织在一起 .

## 从自身找不到 , 就到 prototype 查找

prototype 是 object 关联的另一个 object . 读取 property 时 , JS 先检查自身 , 找不到再检查 prototype ; prototype 还可以有自己的 prototype .

```js
const base = {
  describe() {
    return "shared";
  },
};
const item = Object.create(base);
item.title = "book";
console.log(item.describe()); // "shared"
console.log(Object.hasOwn(item, "describe")); // false
```

`item` 的 prototype 是 `base` . `item.describe()` 在 `item` 自身找不到 `describe` , 就使用 `base` 中的 method .

## 用 class 创建具有相同操作的 object

实际代码常用 class 组织这种关系 . `constructor` 保存初始化代码 , `new` 创建的 object 叫 instance :

```js
class Counter {
  #count = 0;

  constructor(start = 0) {
    this.#count = start;
  }

  next() {
    this.#count++;
    return this.#count;
  }

  static create() {
    return new Counter();
  }
}
const counter = new Counter(3);
console.log(counter.next()); // 4
console.log(Counter.create().next()); // 1
```

`new Counter(3)` 创建 instance , 用它作为 `this` 执行 `constructor(3)` , 再返回这个 instance . `counter` 保存返回值 .

这里把数据与操作分开放置 :

1. `#count` 是 instance 的数据 , 叫 field . 每个 instance 有各自的 `#count` .
2. `next` 放在 `Counter.prototype` 上 , 多个 instance 共享这个 method .
3. `static create` 属于 class 自身 , 用 `Counter.create()` 调用 , 不属于 `counter` .

`#count` 中的 `#` 表示 private field . 只有声明它的 class 内部代码可以访问 ; class 外直接写 `counter.#count` 会产生语法错误 .

## 在已有 class 上扩展

需要保留已有操作并增加内容时 , 子 class 可以用 `extends` 继承父 class :

```js
class Counter {
  constructor(start) {
    this.count = start;
  }
  next() {
    return ++this.count;
  }
}
class NamedCounter extends Counter {
  constructor(name) {
    super(0);
    this.name = name;
  }
  next() {
    return `${this.name}: ${super.next()}`;
  }
}
const counter = new NamedCounter("A");
console.log(counter.next()); // "A: 1"
console.log(counter instanceof Counter); // true
```

子 class 的 constructor 必须先调用 `super` , 才能使用 `this` . 上例中 `super(0)` 执行父 class 的初始化代码 , `super.next()` 调用父 class 的 method .

`counter instanceof Counter` 沿 prototype 链检查继承关系 . `NamedCounter` 继承自 `Counter` , 所以这里得到 `true` .

## 补充 : 读取和赋值也能执行代码

普通 property 直接保存数据 . `get` 和 `set` 则允许在读取或赋值时调用代码 , 分别称为 getter 和 setter :

```js
class Counter {
  #count = 0;
  get value() {
    return this.#count;
  }
  set value(next) {
    this.#count = next;
  }
}
const counter = new Counter();
counter.value = 3;
console.log(counter.value); // 3
```

`counter.value = 3` 调用 `set value` , 参数 `next` 得到 `3` . `console.log(counter.value)` 调用 `get value` , 使用它返回的值 .

下一篇 : [错误处理](./11-errors.md) .
