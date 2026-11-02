# http.Client : 发送 request

`02/04` 中的 Go 程序是 server , 负责接收浏览器发送的 request . 本篇中的 Go 程序是 client , 负责向 server 发送 request .

## 1. 一个完整程序

假设 [02/04 第一节](../04-net-http.md#1-一个完整程序) 的 server 已经运行 , 并监听 `127.0.0.1:8080` . 下面的 client 访问这个 server , 并输出 response 的 status code .

```go
package main

import (
	"context"
	"fmt"
	"net/http"
	"time"
)

func fetchStatus(ctx context.Context) (int, error) {
	client := &http.Client{
		Timeout: 3 * time.Second,
	}

	req, err := http.NewRequestWithContext(
		ctx,
		http.MethodHead,
		"http://127.0.0.1:8080/",
		nil,
	)
	if err != nil {
		return 0, err
	}

	resp, err := client.Do(req)
	if err != nil {
		return 0, err
	}
	defer resp.Body.Close()

	return resp.StatusCode, nil
}

func main() {
	code, err := fetchStatus(context.Background())
	if err != nil {
		fmt.Println(err)
		return
	}
	fmt.Println(code)
}
```

server 正常运行时 , 这个程序通常输出 :

```text
200
```

如果 server 没有运行 , 程序会输出 connection 错误 .

这段程序的执行顺序是 :

1. `fetchStatus` 创建一个 `http.Client` .
2. `http.NewRequestWithContext` 创建一个 request .
3. `client.Do(req)` 发送 request , 并等待 response .
4. 程序读取 response 的 `StatusCode` .
5. `fetchStatus` 返回 status code 和 `error` .

## 2. `http.Client` 是什么

程序使用下面的代码创建 client :

```go
package main

import (
	"net/http"
	"time"
)

func main() {
	client := &http.Client{
		Timeout: 3 * time.Second,
	}
}
```

`http.Client` 是一个 struct . `http.Client{...}` 创建一个 struct value , 前面的 `&` 取得这个 value 的地址 . 因此 , 变量 `client` 的类型是 `*http.Client` .

`client` 有一个 `Timeout` field . 这个 field 的类型是 `time.Duration` , 表示一次 request 的总等待时间上限 . 这个时间包括建立 connection、处理 redirect 和读取 response body .

`3 * time.Second` 的类型是 `time.Duration` , 表示三秒 . `time.Duration` 和时间单位见 [time 篇第一、二节](../03-time-signal.md#1-时间点和时间段) .

`Timeout` 为零表示 client 没有设置这个总时间上限 . **同一个 client 可以发送多次 request , 程序不需要为每次 request 都创建一个新的 client . **

## 3. `http.NewRequestWithContext` 创建 request

第一节中的 `fetchStatus` 调用 :

```go
req, err := http.NewRequestWithContext(
	ctx,
	http.MethodHead,
	"http://127.0.0.1:8080/",
	nil,
)
```

`NewRequestWithContext` 的完整签名是 :

```go
func NewRequestWithContext(
	ctx context.Context,
	method string,
	url string,
	body io.Reader,
) (*Request, error)
```

这个函数接收四个参数 :

| 参数 | 类型 | 第一节传入的值 |
| --- | --- | --- |
| `ctx` | `context.Context` | `fetchStatus` 接收的 context |
| `method` | `string` | `http.MethodHead` , 值为 `"HEAD"` |
| `url` | `string` | server 的地址 |
| `body` | `io.Reader` | `nil` , 表示没有 request body |

`HEAD` method 要求 server 返回 response header , 不发送 response body . 

> [!NOTE]
>
> 常见的 `method` 有 :
>
> - `GET` : 读取资源 , 例如读取题目详情 .
> - `POST` : 提交数据 , 例如提交代码或创建记录 .
> - `PUT` : 整体更新资源 .
> - `PATCH` : 部分更新资源 .
> - `DELETE` : 删除资源 .
> - `HEAD` : 只获取 response header , 不获取 response body .
>
> 标准库提供了这些常量 , 避免手写字符串 :
>
> ```text
> http.MethodGet
> http.MethodHead
> http.MethodPost
> http.MethodPut
> http.MethodPatch
> http.MethodDelete
> ```
> 第一节只查看 status code , 所以使用 `HEAD` . 程序需要读取 response body 时 , 可以改用 `http.MethodGet` , 它的值是 `"GET"` .

`body` 参数表示要发送给 server 的 request body , 不是 server 将要返回的 response body . `io.Reader` 会在 [io 篇第一节](../05-io-fs-embed.md#1-ioreader-接口) 介绍 ; 第一节没有要发送的数据 , 所以传入 `nil` .

这个函数返回两个值 :

| 变量 | 类型 | 含义 |
| --- | --- | --- |
| `req` | `*http.Request` | 创建好的 request |
| `err` | `error` | 创建 request 时产生的错误 |

这次调用只创建 request object , 不会发送网络 request . `client.Do(req)` 才会发送它 .

## 4. `client.Do` 发送 request

第一节中的 `client.Do(req)` 会执行真正的网络请求 :

```go
resp, err := client.Do(req)
if err != nil {
	return 0, err
}
defer resp.Body.Close()
```

`Do` 是 `*http.Client` 的 method , 签名是 :

```go
func (c *Client) Do(req *Request) (*Response, error)
```

`Do` 接收一个 `*http.Request` , 返回两个值 :

| 变量 | 类型 | 含义 |
| --- | --- | --- |
| `resp` | `*http.Response` | server 返回的 response |
| `err` | `error` | connection、timeout 等调用错误 |

程序必须先检查 `err` , 再使用 `resp` . 如果 `Do` 失败 , 程序不能假定 `resp` 可以使用 .

`resp.Body` 的类型是 `io.ReadCloser` interface . 这个 interface 同时提供 `Read` 和 `Close` method . `Close()` 的返回类型是 `error` .

`defer resp.Body.Close()` 表示 `fetchStatus` 返回时关闭 response body . 本例没有保存 `Close` 返回的错误 .

即使本例使用 `HEAD` method , 程序也应该关闭 `resp.Body` . 如果程序使用 `GET` method , `Do` 成功也不表示 response body 已经全部读入内存 , 程序还要读取 `resp.Body` . 读取方法见 [io 篇第六节](../05-io-fs-embed.md#6-http-响应体也是读取来源) .

## 5. `error` 和 status code 不是一回事

第一节通过下面的语句返回 status code :

```go
return resp.StatusCode, nil
```

`resp.StatusCode` 的类型是 `int` . 第二个返回值 `nil` 表示这次 `Do` 没有报告调用错误 , 不代表 status code 一定是 `200` .

常见 status code :

| status code | 含义 |
| --- | --- |
| `200` | request 成功 |
| `404` | 请求的 resource 不存在 |
| `429` | request 过于频繁 |
| `500` | server 处理失败 |

server 正常返回 `404` 时 , client 仍然可能完整收到 response . 因此 , `Do` 返回的 `err` 可以是 `nil` .

两种情况的区别是 :

```text
server 没有运行
    → Do 返回 connection error
    → fetchStatus 返回 0 和这个 error

server 运行，但返回 404
    → Do 返回 response 和 nil
    → fetchStatus 返回 404 和 nil
```

如果调用方只接受 `200` , 程序可以这样检查 :

```go
package main

import (
	"fmt"
	"net/http"
)

func checkResponse(resp *http.Response) error {
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("HTTP status code: %d", resp.StatusCode)
	}
	return nil
}

func main() {
	// ...
}
```

`http.StatusOK` 是值为 `200` 的 int constant . `fmt.Errorf` 创建一个 `error` , 不会直接输出文字 ; 具体用法见 [errors 篇第三节](../06-errors.md#3-fmterrorf-增加错误说明) .

## 6. context 和 client timeout 一起生效

第一节把 `fetchStatus` 的参数 `ctx` 继续传给了 `NewRequestWithContext` . 如果这个 context 被取消 , client 就能够停止等待这次 request .

假设调用方传入一个五秒 timeout 的 context , 而 client 的 `Timeout` 是三秒 :

- 三秒先到 , client 的 timeout 会限制这次 request . 两个时间不会相加成八秒 .
- 如果 parent context 在第一秒取消 , client 也不应该再等待完整三秒 .

context 的创建和 parent-child 关系见 [context 篇第五、六节](../02-context.md#5-withtimeout-设置等待上限) . 取消通知不会替调用方完成全部清理 ; 本例的 body 关闭仍由第四节的 `defer` 安排 .

## 小练习

1. `NewRequestWithContext` 和 `client.Do` , 哪一个会发送 request ?
2. `req`、`resp` 和 `resp.StatusCode` 的类型分别是什么 ?
3. `err == nil` 能否说明 server 返回了 `200` ?

下一篇 : [服务关闭、timeout 和 callback](./02-shutdown-and-options.md) .
