# Dockerfile 怎么读

> [!NOTE]
>
> 评论是 : 这个文档即使是用skill写的也不如菜鸟教程一根(前面还可以 后面就很难懂了)
> https://www.runoob.com/docker/docker-dockerfile.html

Dockerfile 是制作镜像的说明文件。先理解两个步骤：

```text
docker build：读取 Dockerfile → 准备文件和环境 → 得到镜像
docker run：根据镜像创建容器 → 启动里面的程序
```

构建时会安装软件、复制文件；运行时才启动服务。不是每次启动容器都重新执行整个 Dockerfile。

## 1. 先看一个完整例子

假设当前目录有 `message.txt` 和下面这个 `Dockerfile`：

```dockerfile
FROM debian:bookworm-slim
WORKDIR /app
COPY message.txt .
RUN cp message.txt backup.txt
CMD ["cat", "message.txt"]
```

从上往下读：

| 指令      | 在这个例子里做什么                         |
| --------- | ------------------------------------------ |
| `FROM`    | 选择 Debian 基础镜像，里面已有常用系统工具 |
| `WORKDIR` | 将工作目录设为 `/app`，不存在就创建        |
| `COPY`    | 从构建目录复制文件到镜像内的 `/app`        |
| `RUN`     | 构建时执行复制命令，生成一份备份           |
| `CMD`     | 记录默认启动命令：读取并输出文件内容       |

下面是用法说明，不需要现在执行：

```bash
docker build -t file-demo .
docker run --rm file-demo
```

第一条制作名为 `file-demo` 的镜像，末尾 `.` 是构建目录。第二条启动容器，执行 `cat message.txt`，输出后退出。`--rm` 表示退出后删除容器。

## 2. 文件从哪里来，命令在哪里执行

`COPY 来源 目标` 中，来源通常是宿主机上的构建目录，目标是镜像内的路径：

```dockerfile
WORKDIR /app
COPY config.json .
COPY src/ /app/src/
```

这里 `config.json` 被复制为 `/app/config.json`。`src/` 的内容被复制到 `/app/src/`。

构建目录由 `docker build` 最后的参数决定，不一定是 Dockerfile 所在目录：

```bash
docker build -f deploy/Dockerfile -t demo .
```

这条命令使用 `deploy/Dockerfile`，但 `COPY` 仍从末尾 `.` 指定的目录取文件。`.dockerignore` 可以排除不应复制的文件，例如 `.git` 和 `.env`。

`RUN` 后面是普通系统命令，在构建环境中执行，不是直接修改宿主机：

```dockerfile
RUN mkdir -p /app/data && chmod 755 /app/data
```

`&&` 表示前一条成功才执行后一条；行末 `\` 表示下一行继续。不同 `RUN` 不共享同一个 shell，所以 `RUN cd /app` 不会改变下一条的目录，要用 `WORKDIR`。

## 3. ARG 和 ENV：值在什么时候提供

`ARG` 定义构建时使用的参数：

```dockerfile
ARG APP_VERSION=dev
RUN printf '%s\n' "$APP_VERSION" > version.txt
```

`APP_VERSION` 是名字，`dev` 是默认值，`$APP_VERSION` 表示读取它。构建时可以用 `--build-arg APP_VERSION=0.1.0` 覆盖。这里的 `printf` 将值输出，`>` 将输出写入文件。

`ENV` 设置环境变量：

```dockerfile
ENV APP_MODE=production
```

环境变量是程序启动时可以读取的配置。这里设置的值可供后续构建步骤使用；保留在最终镜像中的 `ENV` 也会成为容器默认环境。启动时可用 `docker run -e APP_MODE=debug ...` 覆盖。

| 指令  | 主要用途                     | 是否自动成为容器环境变量 |
| ----- | ---------------------------- | ------------------------ |
| `ARG` | 下载代理、编译选项、构建版本 | 否                       |
| `ENV` | 程序默认配置                 | 留在最终镜像中时，是     |

`ENV NAME=$NAME` 常用来把同名 `ARG` 的值保存下来。变量有阶段范围，不是整个 Dockerfile 都通用；独立的 `FROM` 阶段不会自动继承前一阶段的变量。

## 4. ENTRYPOINT 和 CMD：最后启动什么

项目里的配置是：

```dockerfile
ENTRYPOINT ["acm"]
CMD ["serve"]
```

两组参数拼成 `acm serve`。数组中每个双引号字符串是一个独立参数。

假设这个镜像名为 `demo`：

| 启动方式                    | 实际执行        |
| --------------------------- | --------------- |
| `docker run demo`           | `acm serve`     |
| `docker run demo cli login` | `acm cli login` |

镜像名后面的参数整体替换 `CMD`。`ENTRYPOINT` 可以通过 `--entrypoint` 另行覆盖。

没有 `ENTRYPOINT` 时，`CMD` 可以给出完整命令，例如 `CMD ["acm", "serve"]`，此时启动参数会替换整个默认命令。

注意：`RUN` 在构建时执行；`CMD` 和 `ENTRYPOINT` 在构建时只记录配置，等容器启动时才使用。同阶段多条 `CMD` 只有最后一条生效，不会逐条执行。

## 5. 方括号与 shell 写法

```dockerfile
CMD ["echo", "$NAME"]
CMD echo "$NAME"
```

这是两种写法的对比，不要一起使用。第一种直接执行 `echo`，参数是字面上的 `$NAME`；第二种通过 shell 执行，由 shell 替换变量。

shell 是解释命令的程序，负责理解 `$变量`、`&&`、管道等语法。需要这些功能时，也可以明确启动它：

```dockerfile
CMD ["sh", "-c", "echo \"$NAME\" && acm serve"]
```

只运行一个程序时，通常直接用数组形式。启动脚本中常见的 `exec "$@"` 则表示用传入的程序和参数替换当前 shell，便于把停止信号交给真正的程序。

## 6. 为什么一个文件有多个 FROM

每个 `FROM` 开始一个构建阶段，`AS 名称` 给阶段起名。项目的结构是：

```text
source：准备 Go、依赖和源码
  ├─ verify：运行容器时执行检查和测试
  └─ build：编译出 /out/acm
       └─ runtime：取出编译结果，默认执行 acm serve
```

`FROM source AS build` 表示继承 `source`；`FROM debian:... AS runtime` 则从 Debian 另起一个阶段。

`COPY --from=build /out/acm /usr/local/bin/acm` 从 `build` 阶段取文件，而不是从宿主机构建目录取文件。这样最终镜像可以只带程序和必要依赖，不带编译工具与源码。

构建默认以最后一个阶段为目标，也可以用 `--target verify` 指定目标。构建 `runtime` 不等于运行 `verify` 的检查；尤其检查写在 `CMD` 中时，必须启动对应容器才执行。

## 7. 其余常见指令

| 指令               | 用途                                                  |
| ------------------ | ----------------------------------------------------- |
| `USER app`         | 选择后续构建命令和启动程序使用的用户，不负责创建用户  |
| `EXPOSE 3000`      | 声明预期端口，不自动监听或映射宿主机端口              |
| `VOLUME ["/data"]` | 声明卷挂载位置，数据生命周期可独立于容器              |
| `LABEL key=value`  | 保存版本等元数据，不执行程序                          |
| `ADD`              | 类似复制，还支持解包等功能；普通文件复制通常用 `COPY` |
| `HEALTHCHECK`      | 定期执行健康检查，不等于自动修复或重启                |

以 `#` 开头的整行通常是注释。顶部的 `# syntax=...` 是选择语法版本的特殊指令；遇到 `RUN --mount` 等扩展，再查对应语法即可。
