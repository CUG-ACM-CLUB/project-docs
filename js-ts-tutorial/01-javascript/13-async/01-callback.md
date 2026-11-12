# callback

function 可以作为参数 . 如果一段计算代码不想固定结果的处理方式 , 可以让调用方传入处理结果的 function .

## 把后续操作交给接收方调用

callback 就是这样交给其他代码调用的 function , 中文称回调函数 :

```js
function run(value, done) {
  const result = value * 2;
  done(result);
}

function printResult(result) {
  console.log(result);
}

run(3, printResult); // 6
```

`printResult` 是 callback . `run` 通过参数 `done` 接收它 , 算出 `6` 后调用 `done(6)` . 因此 `printResult` 收到的参数是 `6` .

`run` 负责计算并调用 callback , `printResult` 负责输出 . 换一个 callback 就能改变结果的处理方式 , 无须修改 `run` .

这里传入的是 `printResult` , 不是 `printResult()` . 后者会先执行 function , 再把返回值交给 `run` .

## 接收方可以现在调用 , 也可以稍后调用

上例的 `run` 在返回前就调用 callback , 属于同步调用 . 同样的参数传递方式也可以用于稍后才完成的操作 :

```js
function syncRun(done) {
  done("同步");
}
function laterRun(done) {
  setTimeout(() => done("稍后"), 0);
}
console.log("开始");
syncRun((message) => console.log(message));
laterRun((message) => console.log(message));
console.log("结束");
// 开始
// 同步
// 结束
// 稍后
```

`syncRun` 直接调用 `done` . `laterRun` 把 arrow function 交给 `setTimeout` 保存 ; 当前同步代码结束后 , Node.js 才安排调用它 , 再由它调用 `done("稍后")` .

因此 callback 不等于异步 . 是否稍后执行 , 取决于接收方怎样调用它 .

如果 `laterRun` 立即返回 , 但结果还没准备好 , 调用方就不能从本次返回值中直接拿到结果 . callback 提供了一种办法 : 先交出处理 function , 结果准备好后再由接收方调用 .

下一篇 : [Promise](./02-promise.md) .
