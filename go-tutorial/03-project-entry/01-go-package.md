# GO 包管理

1. `go.sum` 是校验文件
2. `go.mod` 用来明确依赖的外部包和内部结构
   1. `module github.com/CUG-ACM-CLUB/acm-platform` 声明整个项目的名称 , 表明项目根目录就是`go.mod`所在文件夹 , 之后所有包就知道会从当前根目录开始查找 .
   2. `go 1.26.0` 要求版本不低于此 .
   3. `require` 列出依赖的 module 及其版本 .
      1. 项目源码直接 import 某个 module 中的 package , 这个 module 就是直接依赖 .
      2.  `// indirect` 标记间接依赖 , 即项目没有直接 import 其中的 package , 但其他依赖需要它 . 一般会把直接依赖和间接依赖分开
      3. Go 自带的 package , 例如 `fmt`、`os`、`net/http` , 合称标准库 , 不需要写进 `require` . 当前 module 自己的 package , 例如 `internal/cli` , 也不需要写进 `require` .
      4. 路径末尾的 `/v2`、`/v5` 表示主版本 . 例如 , `github.com/jackc/pgx/v5` 使用主版本 5 , `/v5` 也是 import path 的一部分 , 不能省略 .
      5. `v0.0.0-20240606120523-5a60cdf6a761` 这种版本号称为 pseudo-version , 用来指定一次具体的 Git commit . 中间的 `20240606120523` 是提交时间 (UTC , 2024 年 6 月 6 日 12:05:23) , 末尾的 `5a60cdf6a761` 是 commit hash 的前缀 .
3. 相关的 `go command`
   1. `go mod tidy` 根据源码和测试中的 import 补充缺少的依赖、删除不再需要的依赖 , 并更新 `go.mod` 和 `go.sum` .
   2. `go mod download` 下载依赖到 Go 的本地缓存目录 , 也可能补充 `go.sum` . 它不编译项目 , 也不运行测试 .

下一篇 : [main 和 CLI](./02-main-and-cli.md) .
