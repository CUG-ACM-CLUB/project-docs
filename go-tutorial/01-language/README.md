# Go 语言基础

本目录只讲阅读当前项目所需要的 Go 语言规则 .

## 阅读顺序

1. [包、导入和文件](./01-package-import.md)
2. [函数](./02-function.md)
3. [返回值和错误](./03-return-and-error.md)
4. [指针、结构体和方法](./04-pointer-struct-method.md)
5. [接口](./05-interface.md)
6. [defer 和函数值](./06-defer-and-function-value.md)
7. [数组、切片和 map](./07-collections.md)
8. [goroutine、channel 和 select](./08-goroutine-channel.md)
9. [panic 和 recover](./09-panic-and-recover.md)
10. [any 和类型断言](./10-any-and-type-assertion.md)

每篇先读小例子 , 再对照项目 . 示例若没有 `package`、`import` 和 `main` , 就是局部片段 , 不能直接当作独立程序运行 .

读完本目录 , 再进入 [标准库](../02-standard-library/) . 构建和运行练习仍按项目约定在服务器 Docker 中进行 .
