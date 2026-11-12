# Map 和 Set

数组按下标取值 . 如果需要按一个 key 查找对应数据 , 可以使用 Map ; 如果只关心某个值是否出现过 , 可以使用 Set .

## Map : 按 key 保存和查询 value

key 是查询使用的键 , value 是对应的值 . Map 的 key 不限于字符串 , 也可以是数字或 object :

```js
const counts = new Map([["apple", 2]]);
counts.set("pear", 3);
console.log(counts.get("apple")); // 2
console.log(counts.get("missing")); // undefined
console.log(counts.has("pear")); // true
console.log(counts.size); // 2
counts.delete("pear");
for (const [key, value] of counts) {
  console.log(key, value); // "apple" 2
}
```

上例用 `[["apple", 2]]` 提供初始数据 . `set` 添加或修改一项 , 返回 Map 本身 ; `delete` 返回是否删除成功 . `clear()` 删除全部项 .

`get` 返回 `undefined` 时 , 可能是 key 不存在 , 也可能保存的值就是 `undefined` . `has` 只判断 key 是否存在 , 可区分这两种情况 .

Map 数据通过 `set`、`get` 操作 . 写 `counts.apple = 2` 只会添加普通 property , 不会添加一条 Map 数据 .

## Set : 只记录不重复的值

不需要对应的 value , 只想记录出现过哪些值时 , 使用 Set :

```js
const values = new Set([1, 2, 2]);
values.add(3);
console.log(values.size); // 3
console.log(values.has(2)); // true
values.delete(1);
console.log([...values]); // [2, 3]
```

`add` 返回 Set 本身 ; `delete` 返回是否删除成功 . Set 和 Map 都按插入顺序遍历 .

`[...new Set(array)]` 可以把数组先去重 , 再转回数组 . 但这里按值是否相同去重 , 不比较 object 内容 .

## object 是否相同 , 仍取决于是不是同一个 object

这个规则同时适用于 Map 的 key 和 Set 的值 :

```js
const first = { id: 1 };
const values = new Set([first, first, { id: 1 }]);
console.log(values.size); // 2
console.log(values.has({ id: 1 })); // false
```

对基本值的比较有两个细节 : 重复的 `NaN` 只算一个值 , `0` 与 `-0` 也算同一个值 .

上例里 `first` 重复放入只算一次 , 新写的 `{ id: 1 }` 却是另一个 object . 如果要按 `id` 去重 , 需要把 `id` 作为比较依据自行处理 .

Map 转为普通 object 的写法是 `Object.fromEntries(map)` . 转换后名称只能是字符串或 symbol , 不再保留任意类型的 key .

下一篇 : [JSON](./04-json.md) .
