# object

数组按位置保存值 , object 则按名称保存值 . 当一组数据中的每一项有不同含义时 , 名称比下标更直接 .

## 用 property 保存数据

object 中的一项称为 property , 包含名称和值 . 下面的 `item` 保存标题与数量 :

```js
const item = {
  title: "book",
  count: 2,
};
console.log(item.title); // "book"
console.log(item["count"]); // 2
```

`item.title` 使用固定名称 . 如果名称保存在变量中 , 使用 `item[key]` :

```js
const item = { title: "book" };
const key = "title";
console.log(item[key]); // "book"
console.log(item.key); // undefined
```

名称包含连字符等字符时也使用方括号 , 例如 `item["display-name"]` . 创建 object 时可以写 `{ [key]: value }` , 用 `key` 的值作为名称 . 名称还可以是 symbol , 初读时先使用字符串即可 .

## 修改和检查 property

property 可以在创建后添加、修改和删除 :

```js
const item = { title: "book" };
item.count = 2;
item.count = 3;
console.log(Object.hasOwn(item, "count")); // true
delete item.count;
console.log(item.count); // undefined
console.log("title" in item); // true
```

`Object.hasOwn` 只检查 object 自己的 property . `in` 也检查继承来的 property , 见 [prototype](./10-prototypes-and-classes.md) . 这两种检查都能区分 property 不存在与值为 `undefined` .

## 用 method 保存操作

property 的值不只可以是数字和字符串 , 还可以是数组、另一个 object 或 function . object 提供的 function 叫 method :

```js
const title = "book";
const item = {
  title,
  describe() {
    return "an item";
  },
};
console.log(item.title, item.describe()); // "book" "an item"
```

object 中单独写 `title` , 是 `title: title` 的简写 . method 访问当前 object 的方式见 [this](./09-this.md) .

object 赋值与 [数组赋值](./06-arrays.md) 一样共享同一个 object . `const` 也不阻止修改 property .

## 当某一层数据可能不存在

读取嵌套数据时 , 中间一层可能是 `null` 或 `undefined` . `?.` 在这两种情况下返回 `undefined` , 不再继续访问 :

```js
const item = { detail: null };
console.log(item.detail?.title); // undefined
const operation = undefined;
console.log(operation?.()); // undefined
```

`operation?.()` 在 `operation` 为 `null` 或 `undefined` 时跳过调用 . 如果值存在但不是 function , 调用仍会报错 .

## 把 object 中的数据取出来

object 已经按名称保存了数据 . 需要统一处理这些数据时 , 三个工具可以把它们转换为数组 :
1. `Object.keys(item)` 返回 property 名称 .
2. `Object.values(item)` 返回 property 值 .
3. `Object.entries(item)` 返回 `[名称, 值]` 对 .

它们只处理 object 自己的可枚举字符串 property , 不包含继承来的 property 和 symbol 名称 . 可枚举的含义见 [条件和循环](./03-conditions-and-loops.md) .

例如 `Object.entries({ title: "book", count: 2 })` 得到 `[["title", "book"], ["count", 2]]` . 下一篇讲解如何把其中的名称和值分别取到变量中 .

下一篇 : [解构和展开](./08-destructuring-and-spread.md) .
