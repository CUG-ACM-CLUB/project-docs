# scope 和 closure

function 可以返回另一个 function . 要理解返回后的 function 还能访问什么 , 先看变量的访问范围 .

## 变量声明在哪里 , 决定哪里能访问它

这个访问范围叫 scope . `let`、`const` 声明在 `{}` 内时 , 只能在该代码块及其内部使用 . 内部代码可以访问外层变量 , 外层代码不能访问内部局部变量 .

```js
const outer = 10;
function show() {
  const inner = 20;
  if (true) {
    const blockValue = 30;
    console.log(outer, inner, blockValue); // 10 20 30
  }
  // console.log(blockValue); // ReferenceError
}
show();
// console.log(inner); // ReferenceError
```

内外层变量同名时 , 内层使用自己的变量 . 在本层 `let` 或 `const` 初始化之前访问它 , 会报 `ReferenceError` .

## 外层调用结束后 , 变量仍可被使用

closure 是 function 连同它能访问的外层变量 . 外层 function 返回后 , 返回的内层 function 仍可以使用这些变量 .

```js
function makeCounter() {
  let count = 0;
  return function next() {
    count++;
    return count;
  };
}
const first = makeCounter();
const second = makeCounter();
console.log(first()); // 1
console.log(first()); // 2
console.log(second()); // 1
```

`makeCounter()` 返回的是 `next` , 不是 `count` . `first` 保存这个 function ; 每次 `first()` 都使用并修改同一份 `count` .

`second` 来自另一次 `makeCounter()` , 因此使用另一份 `count` . 外层 function 的每次调用各自创建变量 , 不是所有 counter 共用一个变量 .

`next` 有名字 , 但仍然使用 closure . closure 与是否匿名不是一回事 .

## 补充 : 旧代码中的 `var`

`var` 不受 `if`、循环等普通代码块限制 . 在 function 内声明的 `var` 属于整个 function , 声明前读取它得到 `undefined` :

```js
function show() {
  console.log(value); // undefined
  if (true) {
    var value = 3;
  }
  console.log(value); // 3
}
show();
```

这也影响循环里创建的 closure . closure 使用变量 , 不会在创建时复制它的值 :

```js
const readers = [];
for (let i = 0; i < 3; i++) {
  readers.push(() => i);
}
console.log(readers[0](), readers[1](), readers[2]()); // 0 1 2
```

`let` 为每轮创建各自的 `i` . 改成 `var i` 后 , 三个 function 使用同一个 `i` ; 循环结束时它已变成 `3` , 所以三次调用都会返回 `3` .

另外 , `function add(...) {...}` 这样的声明可以在声明前调用 . `const add = ...` 则必须等变量初始化后才能调用 .

下一篇 : [数组](./06-arrays.md) .
