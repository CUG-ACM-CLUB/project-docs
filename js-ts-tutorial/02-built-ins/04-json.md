# JSON

程序中已经有 object , 但文件和网络经常需要文本 . JSON 是一种表示数据的文本格式 , 用来连接这两种形式 .

## 从值转成文本 , 再从文本恢复值

`JSON.stringify(value)` 返回 JSON 字符串 . `JSON.parse(text)` 接收 JSON 字符串 , 返回解析得到的 JS 值 :

```js
const item = { title: "book", count: 2 };
const text = JSON.stringify(item);
console.log(typeof text); // "string"
console.log(text); // {"title":"book","count":2}
const parsed = JSON.parse(text);
console.log(parsed.count); // 2
console.log(parsed === item); // false
```

`item` 和 `parsed` 是两个 object ; `text` 才是可保存、传输的字符串 . JSON 中的 property 名称必须使用双引号 .

## 格式正确不代表内容符合需要

JSON 支持 object、数组、字符串、数字、`true`、`false` 和 `null` . 格式不合法时 , `JSON.parse` 抛出 `SyntaxError` :

```js
try {
  JSON.parse("{bad}");
} catch (error) {
  console.log(error instanceof SyntaxError); // true
}
console.log(JSON.parse("42")); // 42
```

解析成功也不保证得到 object . 例如 `JSON.parse("42")` 得到数字 , 不是含有 property 的 object .

例如程序需要 `{ count: number }` , 解析成功的数字 `42` 仍不满足这个要求 . 接收外部数据后需要继续检查 , TS 写法见 [unknown](../03-typescript/07-any-unknown-never.md) .

## 转成文本会丢失哪些内容

JSON 支持的值比 JS 少 . `JSON.stringify` 对不能直接表示的值采用以下处理 :
1. object 中值为 `undefined`、function 或 symbol 的 property 会被省略 .
2. 数组中这些值的位置通常变成 `null` .
3. 顶层 `undefined`、function 或 symbol 的结果是 `undefined` , 不是字符串 .
4. `NaN` 和正负无穷大转换成 `null` .
5. 默认情况下 , `bigint` 和循环引用会导致报错 . 循环引用指 object 直接或间接保存了自身 .

```js
console.log(JSON.stringify({ a: undefined, b: 1 })); // {"b":1}
console.log(JSON.stringify([undefined, NaN])); // [null,null]
console.log(JSON.stringify(undefined)); // undefined
```

因此 , `JSON.parse(JSON.stringify(value))` 不是通用复制操作 . class、Map 和 Set 也不会按原结构保留 .

只需让输出便于阅读时 , 使用 `JSON.stringify(value, null, 2)` , 返回带两格缩进的文本 .

下一篇 : [正则表达式](./05-regexp.md) .
