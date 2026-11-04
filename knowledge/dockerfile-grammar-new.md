# Dockerfile 预备知识

> [!NOTE]
>
> 指路 [菜鸟教程](https://www.runoob.com/docker/docker-dockerfile.html)

## Docker 基础概念

1. image (镜像) 保存程序文件、运行所需的库和默认启动配置 .
2. container (容器) 是 Docker 根据 image 创建的运行环境 . 同一个 image 可以创建多个 container , 各自运行程序 .
3. Dockerfile 是制作 image 的说明文件 . `docker build` 按照其中的指令构建 image ; `docker run` 根据 image 创建并启动 container .
4. host (宿主机) 是运行 Docker 的机器 . 下文的 host 路径和 container 内部路径是两套路径 .
5. 可以把 image 比作模具 , Dockerfile 是制作模具的说明 , container 是根据模具创建的实例 .

## 最小样例

假设 host 上的 `/home/student/demo/` 中有 `message.txt` 和下面这个 `Dockerfile` :

```dockerfile
FROM debian:bookworm-slim
WORKDIR /app
COPY message.txt .
RUN cp message.txt backup.txt
CMD ["cat", "backup.txt"]
```

1. `FROM` 指定基础 image . `debian:bookworm-slim` 提供 Debian 的基本文件和命令 , 例如这里使用的 `cp` 和 `cat` .
2. `WORKDIR /app` 把后续指令的工作目录设为 `/app` ; 目录不存在时 , Docker 会创建它 .
3. `COPY` 把 host 的 `message.txt` 复制到 image 内的 `/app/message.txt` .
4. `RUN` 在构建环境中执行 `cp` , 得到 `/app/backup.txt` .
5. `CMD` 记录 container 启动时执行的命令 . 构建到这一行时不会执行 `cat` .

下面两条命令分别构建和运行这个例子 :

```bash
docker build -t file-demo /home/student/demo
docker run --rm file-demo
```

- `-t file-demo` 给 image 命名 . 
- 第二条命令启动 container , 执行 `cat backup.txt` 并输出文件内容 . 
- 程序结束后 , `--rm` 让 Docker 删除这个 container , image 仍然保留 .

## 文件与路径

复制文件涉及两套目录 : host 上的来源目录 , 以及 image 内部的目标目录 . `COPY` 两侧的路径需要分别判断 , 不能共用一个前缀 .

### Container 根目录

Linux 的 `/` 是根目录 , container 内也使用这个路径规则 . 以 Debian 为基础的 image 已经包含系统命令、库和配置文件 , 并不是只有一个空目录 . 加入应用目录后 , container 内可见的目录结构可以简化为 :

```text
/
|-- etc/
|-- usr/
|-- home/
`-- app/
```

1. 这里的 `/` 是 container 中的程序看到的根目录 . 
2. Docker 把 image 中的文件和 container 自己的文件变化组合起来 , 作为 container 可见的文件系统 . Docker 管理的底层存储位置 , 不会作为路径前缀显示给 container 内的程序 .

### Host 路径与 build context

Docker 构建时需要知道从 host 的哪个目录取文件 . 本例使用 host 目录作为构建输入 , `docker build` 最后的参数指定 build context , 即供构建读取文件的目录范围 . 

```bash
docker build -f /home/student/demo/deploy/Dockerfile /home/student/demo
```

1. `-f` 指定 Dockerfile 文件 ; 最后的 `/home/student/demo` 指定 build context . 两者是独立指定的路径 .
2. 不使用 `-f` 时 , Docker 默认读取 build context 根目录中的 `Dockerfile` , 本例就是 `/home/student/demo/Dockerfile` .
3. 普通 `COPY [build context]/to/path [container's WORKDIR]/to/path` . 或者使用以 `/` 开头的绝对路径 .
4. 命令末尾写 `.` 时 , build context 是执行 `docker build` 时的当前目录 . 
5. build context 根目录中的 `.dockerignore` 可以列出 `.git`、`.env` 等排除项 . Docker 不把这些文件交给构建过程 , 普通 `COPY` 也就不会复制它们 .

### 内部工作目录与 `WORKDIR`

工作目录是程序当前所在的目录 , `pwd` 输出的就是这个位置 . 它不是固定的 `/` , 而是可以由`WORKDIR` 设置的后续构建命令的工作目录(默认是`/`) , 也保存为 container 启动程序的默认工作目录 . 它不改变根目录 , 不把所有路径都加上一个前缀 .

假设当前工作目录是 `/home/user` , 以下各行分别执行时的结果是 :

| 指令 | 路径性质 | 执行后的工作目录 |
| --- | --- | --- |
| `WORKDIR /app` | 以 `/` 开头 , 从根目录计算 | `/app` |
| `WORKDIR app` | 不以 `/` 开头 , 从当前工作目录计算 | `/home/user/app` |
| `WORKDIR /app/logs` | 绝对路径 | `/app/logs` |

1. 如果目标目录不存在 , Docker 会创建它 .
2. 连续执行 `WORKDIR /app` 和 `WORKDIR logs` 时 , 最终目录是 `/app/logs` . 第二条改成 `WORKDIR /app/logs` 可以直接写明目标 , 不依赖之前的工作目录 .
3. 未写 `WORKDIR` 时 , 可能继承基础 image 已设置的工作目录 ; 基础 image 也未设置时 , 默认是 `/` . 

### `COPY` 的来源与目标

沿用 build context `/home/student/demo` , Dockerfile 中写 :

```dockerfile
WORKDIR /app
COPY message.txt .
COPY src/ /app/src/
COPY config.json /data/config.json
```

| 指令 | host 上的来源 | image 内的目标 |
| --- | --- | --- |
| `COPY message.txt .` | `/home/student/demo/message.txt` | `/app/message.txt` |
| `COPY src/ /app/src/` | `/home/student/demo/src/` | `/app/src/` |
| `COPY config.json /data/config.json` | `/home/student/demo/config.json` | `/data/config.json` |

`WORKDIR /app` 只参与相对目标路径的计算 , 不改变来源文件的位置 , 也不改变 `/data/config.json` 这样的绝对目标路径 . 同理 , `COPY . .` 的第一个 `.` 指 build context , 第二个 `.` 指内部工作目录 .

这里讲的是普通 `COPY` . `COPY --from=build` 从另一个构建阶段取文件 , 来源规则见[多阶段构建](#多阶段构建) .

###  `ADD` 的来源与处理方式

`ADD` 在构建时把指定来源的文件放入 image . 基本形式是 `ADD 来源 目标` ; 他的路径选择和`COPY`命令一样 , 但是会根据来源的格式做一些额外处理 . 

1. 如果是普通文件就直接复制 .
2. 如果是支持自动解包的本地 tar 归档 , 就解包到目标路径下面
   - `ADD files.tar.gz /app/`
   -  读取 host 的 `/home/student/demo/files.tar.gz` , 默认把其中的文件解包到 image 的 `/app/` . 
   - 假设归档内有 `readme.txt` , 结果就是 `/app/readme.txt` . 
   - 支持自动解包的本地文件格式包括 `.tar`、`.tar.gz`、`.tar.bz2`、`.tar.xz` 
   - Docker 根据文件内容识别格式 , 不只看扩展名 .
3. 如果是 URL 就会自动下载(默认不解包) 
   - `ADD https://example.com/config.json /app/config.json` 从指定 URL 下载文件 , 保存为 image 内的 `/app/config.json` . 

只需要普通文件复制时使用 `COPY` 即可 .

## `RUN`、`CMD` 和 `ENTRYPOINT`

这三个指令都用于指定命令 , 区别在于执行时机 :

1. `RUN` 指定的命令在构建 image 时执行 .
2. `CMD` 和 `ENTRYPOINT` 给出的命令在 container 启动时执行 . 构建时只保存这份配置 , 不执行命令 .
3. 这些命令在构建环境或 container 内执行 , 命令中的路径也是对应环境内的路径 .

### `RUN`

`RUN` 常用于安装软件、创建目录和编译程序 . 下面的命令在构建时创建 `/demo` 目录 :

```dockerfile
RUN mkdir /demo
```

> [!NOTE]
>
> ### shell form 与 exec form
>
> `RUN`、`CMD` 和 `ENTRYPOINT` 都支持下面两种写法 . 两行执行相同的操作 , 使用时选一种 :
>
> ```dockerfile
> RUN mkdir /demo
> RUN ["mkdir", "/demo"]
> ```
>
> 1. `shell form` : 第一种写法 , 把命令交给 shell 执行 .
>    - shell 是解释命令的程序 , 负责读取 `$变量`、处理 `&&`、管道 `|` 和重定向 `>` . `&&` 表示前一条命令成功后才执行后一条 .
>    - `RUN echo "$NAME"` 会读取环境变量 `NAME` 并输出它的值 .
>    - 本文的 Linux image 默认使用 `/bin/sh -c` ; `-c` 表示执行后面的命令字符串 .
> 2. `exec form` : 第二种写法 , 用数组直接指定程序和参数 , 不自动经过 shell .
>    - 第一个字符串是程序名 , 后面的每个字符串是一个参数 .
>    - `RUN ["echo", "$NAME"]` 把 `$NAME` 当作普通参数 , 输出的也是 `$NAME` .
>    - 数组使用 JSON 写法 , 字符串用双引号包围 ; 字符串内部的双引号写成 `\"` .
> 3. 需要 shell 时 , 数组也可以明确启动它 .
>    - `RUN ["sh", "-c", "echo \"$NAME\""]` 先启动 `sh` , 再由它读取变量并执行 `echo` .

### `CMD` 和 `ENTRYPOINT`

这两个命令通常都使用`exec form` , 主要是因为 `ENTRYPOINT` 通常能直接成为 container 的主 process , 更容易接收 `SIGTERM` 等停止信号 . 使用 exec form 时 , `ENTRYPOINT` 指定程序及固定参数 , `CMD` 提供默认追加参数 :

```dockerfile
ENTRYPOINT ["acm"]
CMD ["serve"]
```

假设上面的 image 名为 `acm-demo` :

1. 默认启动时 , 两者组合执行 .
   - `docker run acm-demo` 会执行 `acm serve` .
2. image 名后面的参数替换 `CMD` , 保留 `ENTRYPOINT` .
   - `docker run acm-demo cli login` 用 `cli login` 替换 `CMD` , 执行 `acm cli login` .
3. `--entrypoint` 可以替换启动程序 .
   - `docker run --entrypoint /bin/sh acm-demo -c 'echo hello'`
   - 这条命令执行 `/bin/sh -c 'echo hello'` , 不执行 `acm` .
   - 指定 `--entrypoint` 也会清除 image 原有的 `CMD` ; 新参数写在 image 名后面 .
4. 没有 `ENTRYPOINT` 时 , `CMD` 自己指定完整命令 .
   - 例如 `CMD ["acm", "serve"]` .
   - 此时 image 名后面的命令替换整个 `CMD` , 而不是只替换 `serve` .
5. 同一构建阶段内 , 多条 `CMD` 只有最后一条生效 ; `ENTRYPOINT` 也一样 .
6. shell form 的 `ENTRYPOINT acm serve` 不会把 `CMD` 或 `docker run` 追加的参数传给 `acm` . 需要组合程序和参数时使用上面的 exec form .

> [!NOTE]
>
> 当前项目没有使用启动脚本 , `Dockerfile` 会直接启动 `acm` :
>
> ```dockerfile
> ENTRYPOINT ["acm"]
> CMD ["serve"]
> ```
>
> 一个成熟 Docker 项目通常还会把复杂的启动指令放到一个 `.sh` 文件中 , 通过启动这个文件完成环境检查、目录准备和其他启动前操作 . 例如 :
>
> ```dockerfile
> ENTRYPOINT ["sh", "/entrypoint.sh"]
> CMD ["acm", "serve"]
> ```
>
> 这时 , `entrypoint.sh` 会负责启动真正的应用 . 脚本通常使用 `exec "$@"` 把当前 process 交给应用 , 让应用直接接收 Docker 发送的停止 signal .
>
> > `exec "$@"` 写在脚本中时 , `"$@"` 会展开为脚本接收到的全部参数 . 例如执行 `sh /entrypoint.sh acm serve` 时 , `"$@"` 会展开为 `acm serve` , 所以整条命令相当于 `exec acm serve` . 执行后 , 原来的 shell process 被 `acm` 替换 , 这个 process 不再运行 shell , 而是运行 `acm serve` .
>
> 当前项目没有这个文件 , 所以本教程不展开启动脚本、`exec` 和 `STOPSIGNAL` .

## ARG 和 ENV 

- `ARG` 声明构建参数 , 只在 image 构建时有效 , 不会自动成为 container 的运行时环境变量 . 
  - 格式为 `ARG <参数名>[=<默认值>]` , 方括号中的部分可省略 . 
  - 构建时可用 `--build-arg <参数名>=<值>` 传入或覆盖参数值 .
- `ENV` 设置环境变量 , 供后续构建指令和从该 image 启动的程序使用 . 
  - 格式为 `ENV <变量名>=<值>` , 同一行可以设置多个变量 . 
  - 运行时可用 `docker run -e <变量名>=<值> ...` 覆盖本次运行的值 .

## 多阶段构建

### 阶段声明与文件复制

一个 stage 就是一段从 `FROM` 开始、到下一条 `FROM` 或文件结尾结束的构建步骤 . 多阶段构建把准备源码、测试、编译和运行环境拆开 , 最终 image 可以只包含运行所需的文件 .

1. `AS` 给阶段起名 .
   - `FROM golang:1.26 AS source` 把这个阶段命名为 `source` .
2. 后面的阶段可以继承前面的阶段 , 也可以从另一个 image 开始 .
   - `FROM source AS build` 在 `source` 已有的文件和配置上继续构建 .
   - `FROM debian:bookworm-slim AS runtime` 从 Debian image 开始 , 不自动带上 `build` 的文件 .
3. `COPY --from` 从指定阶段取文件 .
   - `COPY --from=build /out/app /usr/local/bin/app`
   - 来源是 `build` 阶段内的 `/out/app` ; 目标是当前阶段内的 `/usr/local/bin/app` .
   - 来源从指定阶段的根目录 `/` 查找 , 不受来源阶段的 `WORKDIR` 影响 .
4. `COPY --from` 只复制指定文件 . 例如只复制编译好的程序 , 就可以把编译工具和源码留在前面的阶段中 .

### 构建目标

构建目标决定最终生成哪个阶段的 image . 默认使用最后一个阶段 , 也可以用 `docker build --target 阶段名` 指定 .

下面以一个 Go 程序为例 . 假设 build context 包含 `go.mod`、`go.sum` 和源码 , 根目录是可编译的 main package :

```dockerfile
FROM golang:1.26 AS source
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .

FROM source AS verify
CMD ["go", "test", "./..."]

FROM source AS build
RUN CGO_ENABLED=0 go build -o /out/app .

FROM debian:bookworm-slim AS runtime
COPY --from=build /out/app /usr/local/bin/app
ENTRYPOINT ["app"]
```

- `docker build -t app-demo .` 以最后的 `runtime` 为目标 , 通过 `build` 取得编译结果 . `CGO_ENABLED=0` 禁用 cgo , 适用于不依赖 cgo 的程序 .
- `docker build --target verify -t app-tests .` 生成包含源码和测试命令的 image , 再用 `docker run --rm app-tests` 执行测试 .
- `verify` 和 `build` 都继承 `source` , 但彼此独立 . 阶段名没有特殊含义 , Docker 不会因为它叫 `verify` 就自动执行测试 . 这里的测试写在 `CMD` 中 , 构建时不执行 ; 若某阶段写 `RUN go test ./...` , 则在构建该阶段时执行 .

### 配置继承

1. `ARG` 从声明位置开始生效 . 通过 `FROM source` 继承阶段时 , 子阶段可以继续使用 `source` 中已声明的 `ARG` 和 `ENV` .
2. 从另一个 image 开始时 , 新阶段继承的是那个基础 image 的配置 , 不会自动获得其他阶段的变量 . `COPY --from` 只复制文件 , 不复制 `ARG`、`ENV`、`WORKDIR` 或启动配置 .
3. 第一个 `FROM` 之前的 `ARG` 属于全局作用域 , 可以给 `FROM` 提供参数 . 阶段内部也要使用它时 , 需要再声明一次 :

```dockerfile
ARG BASE_VERSION=bookworm-slim
FROM debian:${BASE_VERSION}
ARG BASE_VERSION
RUN echo "Base version: $BASE_VERSION"
```

两处 `ARG` 使用同一个名字 . 外面的声明提供默认值或接收 `--build-arg` , 里面的声明把这个值引入当前阶段 .

### 构建缓存

1. Docker 可以复用之前的构建结果 , 这叫构建缓存 . 某一步的指令或相关输入改变后 , Docker 重新构建这一步及依赖它的后续步骤 .
2. 可以把变化较少的依赖安装放在复制全部源码之前 . 例如上面的 Go 示例先复制 `go.mod` 和 `go.sum` , 再执行 `go mod download` , 最后复制其他源码 .
   - 只改源码时 , 前面的依赖下载步骤通常可以使用缓存 .
   - 修改依赖文件时 , Docker 会重新执行依赖下载步骤 .
3. 缓存不保证远程内容最新 . 例如 , `RUN apt-get update` 可以复用旧结果 , Docker 不会仅因软件源更新就重新执行它 .

## 运行配置

### 用户身份

1. `USER app` 让后续 `RUN` 和 container 启动程序以 `app` 用户身份执行 .
2. `USER` 不创建用户 . 用户需要已存在于基础 image 中 , 或先通过 `RUN` 创建 . 例如在 Debian image 中先写 `RUN useradd --create-home app` , 再写 `USER app` ; 其他发行版的创建命令可能不同 .

### 端口声明与映射

1. `EXPOSE 3000` 声明 container 预期使用 `3000` 端口 , 不会启动监听 , 也不会自动把端口映射到 host .
2. `docker run -p 127.0.0.1:13000:3000 image-name` 设置端口映射 .
   - host 地址是 `127.0.0.1:13000` .
   - Docker 把收到的连接转发到 container 的 `3000` 端口 .
   - 应用仍需监听 container 的网络地址 , 例如 `0.0.0.0:3000` ; 只监听 container 内的 `127.0.0.1` 不能通过这个映射访问 .

### 数据存储

volume 是 Docker 管理的一块存储空间 . 把它挂载到 container 的 `/data` , 就是让程序读写 `/data` 时访问这块空间 .

1. `VOLUME ["/data"]` 声明挂载位置 .
   - `/data` 是 container 内的目录 , 不是 host 上的同名目录 .
   - 这条指令没有给 volume 起名 .
2. 运行时可以指定一个有名字的 volume .
   - `docker run --mount type=volume,source=app-data,target=/data image-name`
   - `app-data` 是 volume 名称 , `/data` 是 container 内的挂载位置 .
   - Dockerfile 没写 `VOLUME` , 也可以这样挂载 .
3. Dockerfile 声明了 `VOLUME` , 运行时却没有为该位置指定挂载时 , Docker 创建匿名 volume .
   - Docker 自动生成它的名称 .
   - 使用 `docker run --rm` 时 , 退出后会清理这次创建的匿名 volume , 但不会删除上例中有名字的 `app-data` .
4. 删除 container 不等于删除有名字的 volume . 后续 container 可以继续挂载 `app-data` ; 删除 volume 本身仍会丢失数据 , 所以 volume 不代替备份 .

### 健康检查

`HEALTHCHECK` 让 Docker 定期执行命令 , 根据命令结果判断服务是否正常 . 假设 image 已安装 `curl` , 应用提供 `/health` :

```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
    CMD curl --fail http://127.0.0.1:3000/health || exit 1
```

1. 检查命令在 container 内执行 , 所以这里的 `127.0.0.1` 指 container 自身 .
   - `curl --fail` 请求 `/health` , HTTP 错误状态会让命令失败 .
   - `|| exit 1` 表示 `curl` 失败时返回退出码 `1` .
2. Docker 根据退出码判断结果 : `0` 表示成功 , `1` 表示失败 .
3. 本例设置三个参数 .
   - `--interval=30s` : 通常在上次检查结束后等待 30 秒再检查 .
   - `--timeout=3s` : 单次检查超过 3 秒算失败 .
   - `--retries=3` : 连续失败 3 次后标记为 `unhealthy` .
4. 初始状态是 `starting` ; 检查成功后是 `healthy` ; 连续失败达到次数后是 `unhealthy` .
5. `HEALTHCHECK` 只报告状态 , Docker Engine 不会仅因 `unhealthy` 自动重启 container . `HEALTHCHECK NONE` 可以取消基础 image 中的检查 .
6. 这里的 `CMD` 属于检查指令 , 不替换 container 的[默认启动命令](#cmd-和-entrypoint) .

### 镜像说明信息 `LABEL`

`LABEL key=value` 给 image 添加元数据 , 例如名称、说明和源码版本 . 可以一次写多个键值对 , 也可以分成多条指令 :

```dockerfile
ARG VCS_REF=unknown
LABEL org.opencontainers.image.title="Example app"
LABEL org.opencontainers.image.revision=$VCS_REF
```

构建时用 `--build-arg VCS_REF=版本标识` 传入值 , 就能把它记在 image 的标签中 . `LABEL` 本身不会设置环境变量 , 也不会修改程序内的变量 ; 用 `docker image inspect image-name` 可以查看这些元数据 .

## 注释与扩展指令

### 注释与语法版本

1. `# Install dependencies` 这样的独立行是注释 , 不执行命令 .
2. 文件顶部的 `# syntax=docker/dockerfile:1` 是特殊配置 , 用来选择解析 Dockerfile 的工具版本 , 不是普通注释 . `:1` 选择稳定的 1 系列语法版本 .

### 构建触发器 `ONBUILD`

`ONBUILD 指令` 把指令留给使用这个 image 作为基础镜像的后续构建 , 常用于约定好目录结构的基础 image .

1. 当前 Dockerfile 写 `ONBUILD COPY . /app` , 构建并命名为 `base-demo` . 这时只保存指令 , 不执行复制 .
2. 另一个 Dockerfile 写 `FROM base-demo` 时 , Docker 才执行这条 `COPY` .
   - 来源是另一次构建的 build context .
   - 目标是新构建阶段内的 `/app` .
3. 单纯运行 `base-demo` 不会触发 `ONBUILD` .

## 参考资料

- [Dockerfile reference](https://docs.docker.com/reference/dockerfile/)
- [Build variables](https://docs.docker.com/build/building/variables/)
- [Build context](https://docs.docker.com/build/concepts/context/)
- [Multi-stage builds](https://docs.docker.com/build/building/multi-stage/)
- [Optimize cache usage](https://docs.docker.com/build/cache/optimize/)
- [Volumes](https://docs.docker.com/engine/storage/volumes/)
