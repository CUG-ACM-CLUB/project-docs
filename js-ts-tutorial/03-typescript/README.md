# TypeScript 类型规则

本部分沿用前面的 JS 语法 . 先为已有的值和 function 写出限制 , 再处理不确定的类型 , 最后学习类型之间的关系 .

## 描述值与调用的要求

1. [类型标注和推断](./01-annotations-and-inference.md) : 变量允许保存什么值 , 哪些类型可以省略不写 .
2. [数组、tuple 和 object](./02-arrays-tuples-and-objects.md) : 把单个值的类型扩展为一组数据的结构 .
3. [function 类型](./03-function-types.md) : 规定调用方提供什么、实现方返回什么 .
4. [type 和 interface](./04-type-and-interface.md) : 给重复使用的要求起名字 , 按结构匹配值 .

## 处理不确定的类型

5. [union 和 literal](./05-unions-and-literals.md) : 声明多种可能 , 或只允许几个具体值 .
6. [类型缩小范围](./06-narrowing.md) : 根据实际判断确定当前可以执行的操作 .
7. [any、unknown 和 never](./07-any-unknown-never.md) : 区分不检查、尚未确定和不可能出现的值 .

## 保留输入与输出的关系

8. [泛型](./08-generics.md) : 不固定某一个类型 , 但仍让返回类型跟随输入类型 .
9. [从已有声明取得类型](./09-keyof-typeof-and-indexed-access.md) : 从 object 的类型取出名称、property 类型 , 再把它们用于泛型 .
10. [mapped type 和 conditional type](./10-mapped-and-conditional-types.md) : 根据已有类型产生新类型 .
11. [常用类型工具](./11-utility-types.md) : 使用 TS 已提供的类型处理方法 .

第 9 至 11 篇可以留作查阅 . 初读完泛型后 , 可以直接继续第 12 篇 .

## 回到源码中的声明

12. [类型断言和 satisfies](./12-assertions-and-satisfies.md) : 区分声明一个类型供使用 , 与检查是否符合类型要求 .
13. [配置和类型导入](./13-tsconfig-and-type-imports.md) : 区分检查时需要的声明与执行时需要的代码 .
14. [class 的类型和修饰符](./14-classes-and-modifiers.md) : 在 JS class 上补充类型与访问限制 .
15. [enum 和 namespace](./15-enums-and-namespaces.md) : 识别会生成实际 JS 代码的 TS 声明 .

返回 [教程索引](../README.md) .
