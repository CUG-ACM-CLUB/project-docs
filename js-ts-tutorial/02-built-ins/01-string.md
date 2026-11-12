# 字符串

字符串处理通常经过三步 : 组成文本 , 找到需要的内容 , 再生成处理后的新文本 .

## 组成字符串

单引号和双引号都可以包住字符串 . 反引号还支持换行和 `${expression}` , 后者把表达式的值插入字符串 , 这种写法叫 template literal :

```js
const title = "book";
const count = 2;
const text = `${title}: ${count}`;
console.log(text); // "book: 2"
console.log(text[0]); // "b"
console.log(text.length); // 7
```

## 处理结果是新值

字符串不能直接修改内部字符 . 调用 method 得到的是处理结果 , 原字符串不变 :

```js
const text = "  Hello  ";
const clean = text.trim();
console.log(clean); // "Hello"
console.log(text.length); // 9
console.log(clean.toLowerCase()); // "hello"
```

后面使用查找、截取和替换 method 时 , 都沿用这条规则 . 需要保留结果就赋给变量 .

## 找到或截取需要的内容

| 调用 | 返回值 | 规则 |
| --- | --- | --- |
| `"hello".includes("ell")` | `true` | 是否包含指定子串 |
| `"hello".startsWith("he")` | `true` | 是否以指定子串开始 |
| `"hello".endsWith("lo")` | `true` | 是否以指定子串结束 |
| `"hello".indexOf("l")` | `2` | 首个位置 , 找不到返回 `-1` |
| `"hello".slice(1, 4)` | `"ell"` | 从下标 `1` 到 `4` 之前 |

`includes` 只回答是否存在 , `indexOf` 返回位置 , `slice` 返回截取后的字符串 . 它们解决的问题不同 .

`slice(start, end)` 不包含 `end` 位置 . 省略 `end` 表示取到末尾 ; `slice(-2)` 表示取最后两个位置 .

只判断是否包含子串时 , 使用 `includes` . 使用 `indexOf` 时要与 `-1` 比较 , 不能直接按真假判断 : 下标 `0` 按假处理 , 没找到时的 `-1` 反而按真处理 .
## 替换内容 , 或拆成数组

找到目标后可以替换它 . 如果需要逐段处理文本 , 可以用 `split` 拆成数组 , 处理后再用数组的 `join` 拼回字符串 :

```js
const text = "a-b-a";
console.log(text.replace("a", "x")); // "x-b-a"
console.log(text.replaceAll("a", "x")); // "x-b-x"
const parts = text.split("-");
console.log(parts); // ["a", "b", "a"]
console.log(parts.join("/")); // "a/b/a"
```

`replace` 的字符串模式只替换首个匹配 , `replaceAll` 替换全部 . `split` 返回字符串数组 ; `join` 是数组 method , 返回拼接的字符串 .

## 补充 : 长度与显示字符数

`length` 统计 UTF-16 编码中的 16 位单元数 , 不一定是眼睛看到的字符数 . 例如 `"😀".length` 是 `2` . 因此不能直接把字符串长度当作显示字符数 .

下一篇 : [数组 method](./02-array-methods.md) .
