# SwitchToDocker
> 磨刀不误砍柴工

本分支不介绍 docker 的基础命令，这里只对其中的一些容易混淆的部分作一点总结，为求新手对 docker 有一个较为全面的认识。

### 所以 docker 到底是什么？

新一代虚拟机？容器？ 镜像？

我的使用感受是：正如软件开发中的模块化技术一样， docker 从系统级别为软件开发人员提供了模块化的体验。

> docker 是为开发者提供了系统级别的模块化体验的技术

就像其他领域的模块/组件化技术一样， docker 在软件开发下从系统环境层进行解藕， 分离出各类软件开发环境。 所以从理论上来讲， 你可以在拥有了 docker 运行环境的系统上使用任何编程语言而无需为主机安装任何的依赖。

这里所说的系统级别模块化，指的是把系统也分为模块来进行管理。系统中包含 CPU、内存、网络、硬盘、进程等，而在 docker 中你可以定制每个 docker 容器的底层操作系统、CPU、内存、网络、硬盘、进程等参数。

### 基本概念一览

#### 镜像 image

镜像其实就是平常所说的镜像， 例如 windows 镜像、 linux 镜像等， 一般指代系统操作环境的克隆。 在 docker 中也是这个意思即某一技术的操作环境。

这里的操作环境可能是 centos 、 windows server、 ubuntu 等操作系统镜像，也可能是像 java、 php、 nodejs、 go 的软件开发环境。 软件开发环境一般也是基于操作系统环境来进一步制作的。


#### 容器 container

容器就是具体的运行环境即一个启动的镜像应用。 如果把镜像比喻成安装包，那么容器就是解压安装后的可执行应用程序。但是和电脑软件不一样的地方在于，你可以拥有多个可定制的应用程序即执行镜像后每个容器是可定制的。 这里面的不同点包括这个应用程序的功能、网络、名称、cpu、内存大小等等。

每个容器是隔离的，相当于一个一个的模块，docker 通过它们暴露出的指定端口「类似模块 api」来使容器产生联系。

你可以在容器内部运行软件，例如在 nodejs 环境内运行 `node app.js` 执行 node app，然后通过暴露出的端口映射到主机上然后就可以实现访问了。


#### 卷 volume

docker 不推荐在容器内部储存数据，这样可以保持容器的无状态化。你的所有代码应该放到容器外，可以放在 git 服务器上也可以是主机上，但怎么把代码或数据库放进容器内供容器使用呢？

volume 就可以在容器内与主机间打开一个通道产生映射，当然也可以在容器与容器之间打开映射通道。

例如你希望给自己的容器配置上 ssh 秘钥进行 git clone 操作， 常规作法：
1. 进入容器
1. 在容器内部生成一个秘钥
1. 然后把秘钥填写到 git 等服务器上，进而就可以在容器内部使用 ssh 了

但是一旦容器重启之后，你在容器内的操作会全部销毁。 使用起来非常麻烦， 有了 volume 这事就变得简单多了， 你只需要在启动容器时挂载主机的 ssh 目录到容器的 ssh 目录下就实现了主机和容器的通信即容器的 ssh 目录就是主机的 ssh 目录。然后因为主机的 ssh 是不会变化的， 你只需要把主机的秘钥填写到 git 服务器上就可以了。

所以在容器内部的所有状态化数据一般来说都会使用 volume 来挂载到容器外部从而实现持久化，最常见的就是数据库的挂载了，因为容器内的数据在每次启动容器时会初始化。

如果 volume 没有挂载到容器外部来， 那么在所有使用这个 volume 的容器退出后 docker 将自动销毁这个 volume。

因为容器和容器之间是互相隔离的，所以我们经常会使用 volume 来使多个容器进行数据共享。

#### RUN、 CMD、 ENTRYPOINT 命令释义

在创建镜像时有这三个执行指令，都代表执行但又有区别：

1. RUN 可以用来执行多条构建指令，其他两条指令则只会执行最后一条指令
1. CMD 相当于在启动容器时的指定的各类参数「 docker run ...」，但也有可能被制作镜像时的 RUN 指令覆盖， 多条 CMD 指令只执行最后一条
1. ENTRYPOINT 作为 CMD 的升级版即必执行指令，它不会被 RUN 覆盖， 同样它也是只执行最后一条

#### ONBUILD

在构建容器时才执行的指令， 有的镜像内会有这样的指令：

````
ONBUILD RUN mkdir /app
ONBUILD COPY . /app
ONBUILD WORKDIR /app

RUN node app.js
````

这类指令会在你运行容器的时候才执行操作，这样一份镜像可以达到多次使用的目的。 所以上面的指令中你不会在制作镜像时就把当前目录下的文件复制到容器内， 也不会提前创建一个 app 文件夹。

#### link 参数

有这样一个需求：
1. 一个 nodejs 容器负责在 3000 端口上开启服务
1. 一个 nginx 容器需要作反向代理即把 nodejs 的 3000 端口的应用方程式代理到 80 端口上
1. 启动两个容器并配置相应的端口映射，配置 nginx 容器代理 127.0.0.1:3000

同时启动两个容器，会发现 nginx 容器无法启动， 因为 nginx 容器内部没有 3000 端口， 并且容器内部的地址也不是 127.0.0.1。 这就涉及到容器间的互相通信问题， 其实 docker 会给所有容器分配一个 ip 地址，这个 ip 地址用于在容器之间进行通信。 我们使用命令 `docker inspect 「容器名称」` 来查看每个容器的 ip 地址。 截取其中一段信息获得 nodejs 容器的 ip 地址 172.17.0.3。 所以我们在 nginx 容器内需要监听 172.17.0.3 这个地址才能完成代理。所以你需要修改 nginx.conf 内的代理地址。

但有一个问题就是这个 docker 分配给容器的 ip 地址会随着容器的销毁和重启发生变化， 所以你不得不每次修改 nginx.conf 代理地址。 而 --link 参数可以解决容器与容器之间的网络互通问题。 当运行 nodejs 容器时我们可以指定这个容器的名称为 node， 然后我们在 nginx 容器运行时使用 link 参数 `--link node：app` 来设置 node 网络的别名为 app， 这样在 nginx 内 app 这个变量指的就是 `172.17.0.3` 这个 ip 地址了。 所以把代理地址修改成 app:3000 就可以正常运行了。 当 nodejs 容器重启后，这个地址 `app` 变量的值也会动态变化，至此便解决了容器间的网络通信问题。

有一篇官方翻译来的 [link 文档](https://kevinguo.me/2017/07/06/Docker-links/)


````
"Gateway": "172.17.0.1",
"GlobalIPv6Address": "",
"GlobalIPv6PrefixLen": 0,
"IPAddress": "172.17.0.3",
"IPPrefixLen": 16,
````

#### 用 Dockerfile 创建自己的镜像

我们说过 docker 内已经提供了各种各样的镜像，有系统镜像、软件运行镜像等。而且还有 ONBUILD 这个命令来实现镜像的重用，那么为什么要创建自己的镜像呢？我们创建自己的镜像的主要目的是依靠一些已有的底层镜像进一步满足一些定制化需求。例如把 npm 的源设置到国内、 用 volume 创建容器间的共享数据等等需求。

#### 调试 container

在我们运行容器的时候，有时明明 **docker run** 成功了，但使用 **docker ps** 查看运行中容器的时候发现刚才运行的容器不在列表中「即容器虽然启动成功但在运行时报错导致意外退出了」，在控制台也没有任何报错原因。 **docker ps -a** 查看所有容器, 那些运行失败的容器会列在这里，然后用 ** docker-inspect id ** 即可查看容器内的所有信息。

#### 用 [docker-compose.yml](https://docs.docker.com/compose/compose-file/#build) 编排一组容器

Dockerfile 用来指定单个容器，但项目常常由多个容器组合而成，例如用 nginx 容器作 web 服务器，以 mysql 容器作数据库，以 redis 容器作缓存数据库等等。 它们是一套服务容器，当然你可以对需要运行的每一个容器都 docker run 一下，但这显然不太简便易行，所以 docker-compose.yml 就是为了解决这样的问题出现，以前你写在 shell 脚本里的命令就可以全部移到这里。在这里指定各项容器参数，集中管理你所需的所有容器。在 docker-compose.yml 里每个容器被叫作 service。


#### docker-compose 命令

如果说 docker 命令「docker run、docker build、docker rm ...」 是面向单个容器的， 那么 docker-compose 「docker-compose start、docker-compose build、docker-compose rm ...」则是面向一组容器的。

docker-compose 是 Docker 推出的另一款工具主要用于启动一组容器「即 docker-compose.yml 内的 services」。docker-compose 需要另外安装。

#### 面向集群 docker stack 与 docker swarm

如果说 docker run 和 docker-compose 是面向单台服务器的部署方案，那 docker stack 与 docker swarm 则是面向多台服务器的部署方案「即所谓的集群部署方案」。

docker stack 类似于 docker-compose 但更强调于部署「deploy」。当然如果你不想安装 docker-compose 工具，使用 docker stack 命令也可以启动 docker-compose.yml 内的一组容器「我就是这么干的」。既然是集群方案，免不了在多台服务器上操作容器， 在 docker swarm 下，每一组运行的 docker stack 的服务器被称谓一个 node 「集群中的一个节点」。docker swarm 可以输出 ip 地址和 join-token 用于让其它服务器上的 stack 加入进来从而实现更高层次「即集群」的组合管理。


#### Docker Swarm、Kubernetes、Mesos

作为依托于 docker 技术的集群解决方案，目前主要有以下这三种选择。

![](https://cdn-images-1.medium.com/max/1600/1*M50BNQPKRomq2p76lAQnNQ.png)
