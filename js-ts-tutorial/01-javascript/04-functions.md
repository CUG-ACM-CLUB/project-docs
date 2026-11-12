# function

## 声明并调用 function

用 `function` 声明函数 . JS 不要求为参数和返回值写类型 :

```js
function add(a, b) {
  return a + b;
}
console.log(add(2, 3)); // 5
```

`add` 表示 function 本身 , `add(2, 3)` 才执行 function 并取得返回值 . 没有执行带值的 `return` 时 , 返回值是 `undefined` . 返回表达式要跟在 `return` 同一行开始书写 .

## 把 function 保存到变量

既然 `add` 可以表示一个值 , 就可以像其他值一样赋给变量 . 下面直接创建一个没有自己名字的 function , 称为匿名 function :

```js
const double = function (value) {
  return value * 2;
};
const sameFunction = double;
console.log(sameFunction(3)); // 6
```

`double` 保存这个 function ; `double(3)` 才是调用 . `sameFunction` 与 `double` 保存的是同一个 function .

## 把 function 传入或返回

function 可以赋给变量 , 也就可以作为参数或返回值 . 下面的 `makeDouble` 返回 function , `apply` 接收并调用 function :

```js
function apply(value, operation) {
  return operation(value);
}
function makeDouble() {
  return function (value) {
    return value * 2;
  };
}
const double = makeDouble();
console.log(apply(3, double)); // 6
```

`double` 保存 `makeDouble()` 返回的 function . `apply(3, double)` 把它传入参数 `operation` , 再由 `apply` 调用 `operation(3)` .

交给其他代码调用的 function 称为 [callback](./13-async/01-callback.md) . 这里先理解传递与调用的关系 , 后面的异步部分再使用它 .

## 用 arrow function 简写

保存在变量中的 function 也可以使用 `=>` 定义 , 这种写法叫 arrow function :

```js
const double = (value) => value * 2;
const add = (a, b) => {
  const result = a + b;
  return result;
};
const makeItem = (title) => ({ title: title });
console.log(double(3), add(2, 3), makeItem("book"));
// 6 5 { title: "book" }
```

`double` 直接返回 `value * 2` . `add` 右侧用了代码块 , 需要 `return` 指定返回值 . `makeItem` 返回 object 时使用 `({...})` , 避免 JS 把 `{}` 当成代码块 .

arrow function 的 `this` 规则不同 , 见 [this](./09-this.md) .

## 补充 : 参数如何得到值

不论使用哪种定义写法 , 普通参数都按位置接收实参 . 少传的参数得到 `undefined` , 多传参数不会仅因数量多而报错 .

默认参数在没有传值或传入 `undefined` 时生效 :

```js
function greet(name = "guest") {
  return name;
}
console.log(greet()); // "guest"
console.log(greet(undefined)); // "guest"
console.log(greet(null)); // null
```

传入 `null` 不会使用默认值 . 如果需要接收不确定数量的参数 , 用最后一个 `...rest` 参数收集为数组 :

```js
function firstAndRest(first, ...rest) {
  console.log(first, rest);
}
firstAndRest(1, 2, 3); // 1 [2, 3]
```

下一篇 : [scope 和 closure](./05-scope-and-closures.md) .
