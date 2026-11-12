# this

object 可以保存 method . 如果多个 object 使用同一个 method , method 怎样知道这次应该读取谁的数据 ? 普通 method 通过 `this` 取得本次调用的 object .

## 调用方式决定 `this`

对 `object.method()` 这样的普通调用 , `this` 是点号左边的 object :

```js
const first = {
  title: "first",
  read() {
    return this.title;
  },
};
const second = { title: "second", read: first.read };
console.log(first.read()); // "first"
console.log(second.read()); // "second"
```

两个 `read` 保存同一个 function . `first.read()` 中的 `this` 是 `first` , `second.read()` 中的 `this` 是 `second` .

同一个 function 可以操作不同 object , 也意味着它不会自动记住最初保存它的 object . 把 method 取出来单独调用时 , 原来的调用关系就丢失了 :

```js
const item = {
  title: "book",
  read() {
    return this.title;
  },
};
const read = item.read;
// read(); // TypeError: this 是 undefined
console.log(read.call(item)); // "book"
```

本教程的 `.mjs` 自动启用严格模式 . 在这种模式下 , `read()` 单独调用时的 `this` 是 `undefined` , 所以读取 `this.title` 报错 .

## 主动指定调用使用哪个 object

取出的 function 仍可以调用 , 但需要提供 `this` . `call`、`apply` 和 `bind` 分别提供立即调用和保存后再调用的方式 :

```js
function describe(prefix) {
  return prefix + this.title;
}
const item = { title: "book" };
console.log(describe.call(item, "A ")); // "A book"
console.log(describe.apply(item, ["A "])); // "A book"
const bound = describe.bind(item);
console.log(bound("A ")); // "A book"
```

`call` 和 `apply` 立即执行 `describe` , 区别只是参数逐个传入还是用数组传入 . `bind` 返回新 function `bound` , 此时不执行 `describe` ; 以后调用 `bound` 时才执行 , 并使用绑定的 `item` 作为 `this` .

## arrow function 沿用外层的 `this`

普通 function 在调用时确定 `this` . arrow function 不采用这条规则 , 它沿用定义位置外层代码的 `this` :

```js
const item = {
  title: "book",
  makeReader() {
    return () => this.title;
  },
};
const read = item.makeReader();
console.log(read()); // "book"
```

即使 `read()` 单独调用 , 它仍使用 `item` . `call` 和 `bind` 也不能替换 arrow function 的 `this` .

因此 , 在 method 内创建 arrow function 可以保留本次 method 使用的 `this` . 但直接写 `{ read: () => this.title }` 不会让 `this` 指向这个 object , 因为 object 的 `{}` 不提供新的 `this` .

下一篇中的 `new` 会创建 object , 并把新 object 作为初始化代码的 `this` .

下一篇 : [prototype 和 class](./10-prototypes-and-classes.md) .
