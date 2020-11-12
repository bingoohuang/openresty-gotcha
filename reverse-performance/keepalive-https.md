# nginx优化——包括https、keepalive等

[原文](https://lanjingling.github.io/2016/06/11/nginx-https-keepalived-youhua/)

## nginx之tcp_nopush、tcp_nodelay、sendfile

### TCP_NODELAY

你怎么可以强制 socket 在它的缓冲区里发送数据？

一个解决方案是 TCP 堆栈的 TCP_NODELAY选项。这样就可以使缓冲区中的数据立即发送出去。

Nginx的 TCP_NODELAY 选项使得在打开一个新的 socket 时增加了TCP_NODELAY选项。但这时会造成一种情况：

终端应用程序每产生一次操作就会发送一个包，而典型情况下一个包会拥有一个字节的数据以及40个字节长的包头，于是产生4000%的过载，很轻易地就能令网络发生拥塞。**为了避免这种情况，TCP堆栈实现了等待数据 0.2秒钟，因此操作后它不会发送一个数据包，而是将这段时间内的数据打成一个大的包。这一机制是由Nagle算法保证。**

Nagle化后来成了一种标准并且立即在因特网上得以实现。它现在已经成为默认配置了，但有些场合下把这一选项关掉也是合乎需要的。现在假设某个应用程序发出了一个请求，希望发送小块数据。我们可以选择立即发送数据或者等待产生更多的数据然后再一次发送两种策略。

如果我们马上发送数据，那么交互性的以及客户/服务器型的应用程序将极大地受益。如果请求立即发出那么响应时间也会快一些。**以上操作可以通过设置套接字的 `TCP_NODELAY = on` 选项来完成，这样就禁用了Nagle 算法。（不需要等待0.2s）**

### TCP_NOPUSH

在 nginx 中，tcp_nopush 配置和 tcp_nodelay “互斥”。它可以配置一次发送数据的包大小。也就是说，它不是按时间累计 0.2 秒后发送包，而是当包累计到一定大小后就发送。

> 注：在 nginx 中，`tcp_nopush` 必须和 `sendfile` 搭配使用。

### sendfile

现在流行的web 服务器里面都提供 sendfile选项用来提高服务器性能，那到底 sendfile是什么，怎么影响性能的呢？

sendfile实际上是 Linux2.0+以后的推出的一个系统调用，web服务器可以通过调整自身的配置来决定是否利用 sendfile这个系统调用。先来看一下不用 sendfile的传统网络传输过程：

1. read(file,tmp_buf, len);
1. write(socket,tmp_buf, len);

硬盘 >> kernel buffer >> user buffer>> kernel socket buffer >>协议栈

1. 一般来说一个网络应用是通过读硬盘数据，然后写数据到socket 来完成网络传输的。上面2行用代码解释了这一点，不过上面2行简单的代码掩盖了底层的很多操作。来看看底层是怎么执行上面2行代码的：

    - 系统调用 read()产生一个上下文切换：从 user mode 切换到 kernel mode，然后 DMA 执行拷贝，把文件数据从硬盘读到一个 kernel buffer 里。
    - 数据从 kernel buffer拷贝到 user buffer，然后系统调用 read() 返回，这时又产生一个上下文切换：从kernel mode 切换到 user mode。
    - 系统调用write()产生一个上下文切换：从 user mode切换到 kernel mode，然后把步骤2读到 user buffer的数据拷贝到 kernel buffer（数据第2次拷贝到 kernel buffer），不过这次是个不同的 kernel buffer，这个 buffer和 socket相关联。
    - 系统调用 write()返回，产生一个上下文切换：从 kernel mode 切换到 user mode（第4次切换了），然后 DMA 从 kernel buffer拷贝数据到协议栈（第4次拷贝了）。

    上面4个步骤有4次上下文切换，有4次拷贝，我们发现如果能减少切换次数和拷贝次数将会有效提升性能。在kernel2.0+ 版本中，系统调用 sendfile() 就是用来简化上面步骤提升性能的。sendfile() 不但能减少切换次数而且还能减少拷贝次数。

1. 再来看一下用 sendfile()来进行网络传输的过程：

    `sendfile(socket,file, len);`

    硬盘 >> kernel buffer (快速拷贝到kernelsocket buffer) >>协议栈

    - 系统调用sendfile()通过 DMA把硬盘数据拷贝到 kernel buffer，然后数据被 kernel直接拷贝到另外一个与 socket相关的 kernel buffer。这里没有 user mode和 kernel mode之间的切换，在 kernel中直接完成了从一个 buffer到另一个 buffer的拷贝。
    - DMA 把数据从 kernelbuffer 直接拷贝给协议栈，没有切换，也不需要数据从 user mode 拷贝到 kernel mode，因为数据就在 kernel 里。

    步骤减少了，切换减少了，拷贝减少了，自然性能就提升了。这就是为什么说在Nginx 配置文件里打开 sendfile on 选项能提高 web server性能的原因。

综上，这三个参数都应该配置成on：`sendfile on; tcp_nopush on; tcp_nodelay on`;

## nginx长连接——keepalive

当使用nginx作为反向代理时，为了支持长连接，需要做到两点：

1. 从client到nginx的连接是长连接
1. 从nginx到server的连接是长连接

### 保持和client的长连接

**默认情况下，nginx已经自动开启了对client连接的keep alive支持（同时client发送的HTTP请求要求keep alive）**。一般场景可以直接使用，但是对于一些比较特殊的场景，还是有必要调整个别参数（keepalive_timeout和keepalive_requests）。

```nginx
http {
    keepalive_timeout  120s 120s;
    keepalive_requests 10000;
}
```

#### keepalive_timeout

语法:

`keepalive_timeout timeout [header_timeout];`

1. 第一个参数：设置keep-alive客户端连接在服务器端保持开启的超时值（默认75s）；值为0会禁用keep-alive客户端连接；
1. 第二个参数：可选、在响应的header域中设置一个值“Keep-Alive: timeout=time”；通常可以不用设置；

> 注：keepalive_timeout默认75s，一般情况下也够用，对于一些请求比较大的内部服务器通讯的场景，适当加大为120s或者300s；

#### keepalive_requests

keepalive_requests指令用于**设置一个keep-alive连接上可以服务的请求的最大数量，当最大请求数量达到时，连接被关闭。默认是100**。

这个参数的真实含义，是指一个keep alive建立之后，nginx就会为这个连接设置一个计数器，记录这个keep alive的长连接上已经接收并处理的客户端请求的数量。如果达到这个参数设置的最大值时，则nginx会强行关闭这个长连接，逼迫客户端不得不重新建立新的长连接。

大多数情况下当QPS(每秒请求数)不是很高时，默认值100凑合够用。但是，对于一些QPS比较高（比如超过10000QPS，甚至达到30000,50000甚至更高) 的场景，默认的100就显得太低。

简单计算一下，QPS=10000时，客户端每秒发送10000个请求(通常建立有多个长连接)，每个连接只能最多跑100次请求，意味着平均每秒钟就会有100个长连接因此被nginx关闭。同样意味着为了保持QPS，客户端不得不每秒中重新新建100个连接。因此，就会发现有大量的TIME_WAIT的socket连接(即使此时keep alive已经在client和nginx之间生效)。**因此对于QPS较高的场景，非常有必要加大这个参数，以避免出现大量连接被生成再抛弃的情况，减少TIME_WAIT**。

### 保持和server的长连接

为了让nginx和后端server（nginx称为upstream）之间保持长连接，典型设置如下：（默认nginx访问后端都是用的短连接(HTTP1.0)，一个请求来了，Nginx 新开一个端口和后端建立连接，后端执行完毕后主动关闭该链接）

```nginx
http {
    upstream  BACKEND {
        server   192.168.0.1：8080  weight=1 max_fails=2 fail_timeout=30s;
        server   192.168.0.2：8080  weight=1 max_fails=2 fail_timeout=30s;
        keepalive 300;        # 这个很重要！
    }
    server {
        listen 8080 default_server;
        server_name "";
        location /  {
            proxy_pass http://BACKEND;
            proxy_set_header Host  $Host;
            proxy_set_header x-forwarded-for $remote_addr;
            proxy_set_header X-Real-IP $remote_addr;
            add_header Cache-Control no-store;
            add_header Pragma  no-cache;
            proxy_http_version 1.1;        # 这两个最好也设置
            proxy_set_header Connection "";
        }
    }
}
```

#### location中有两个参数需要设置

```nginx
http {
    server {
        location /  {
            proxy_http_version 1.1; # 这两个最好也设置
            proxy_set_header Connection "";
        }
    }
}
```

HTTP协议中对长连接的支持是从1.1版本之后才有的，因此最好通过proxy_http_version指令设置为”1.1”；

而”Connection” header应该被清理。清理的意思，我的理解，是清理从client过来的http header，因为即使是client和nginx之间是短连接，nginx和upstream之间也是可以开启长连接的。这种情况下必须清理来自client请求中的”Connection” header。

#### upstream中的keepalive设置

此处keepalive的含义不是开启、关闭长连接的开关；也不是用来设置超时的timeout；更不是设置长连接池最大连接数。官方解释：

1. The connections parameter sets the maximum number of idle keepalive connections to upstream servers connections（**设置到upstream服务器的空闲keepalive连接的最大数量**）
1. When this number is exceeded, the least recently used connections are closed. （**当这个数量被突破时，最近使用最少的连接将被关闭**）
1. It should be particularly noted that the keepalive directive does not limit the total number of connections to upstream servers that an nginx worker process can open.（**特别提醒：keepalive指令不会限制一个nginx worker进程到upstream服务器连接的总数量**）

我们先假设一个场景： 有一个HTTP服务，作为upstream服务器接收请求，响应时间为100毫秒。如果要达到10000 QPS的性能，就需要在nginx和upstream服务器之间建立大约1000条HTTP连接。nginx为此建立连接池，然后请求过来时为每个请求分配一个连接，请求结束时回收连接放入连接池中，连接的状态也就更改为idle。我们再假设这个upstream服务器的keepalive参数设置比较小，比如常见的10.

- 假设请求和响应是均匀而平稳的，那么这1000条连接应该都是一放回连接池就立即被后续请求申请使用，线程池中的idle线程会非常的少，趋进于零，不会造成连接数量反复震荡。
- 显示中请求和响应不可能平稳，我们以10毫秒为一个单位，来看连接的情况(注意场景是1000个线程+100毫秒响应时间，每秒有10000个请求完成)，我们假设应答始终都是平稳的，只是请求不平稳，第一个10毫秒只有50,第二个10毫秒有150：
    1. 下一个10毫秒，有100个连接结束请求回收连接到连接池，但是假设此时请求不均匀10毫秒内没有预计的100个请求进来，而是只有50个请求。注意此时连接池回收了100个连接又分配出去50个连接，因此连接池内有50个空闲连接。
    1. 然后注意看keepalive=10的设置，这意味着连接池中最多容许保留有10个空闲连接。因此nginx不得不将这50个空闲连接中的40个关闭，只留下10个。
    1. 再下一个10个毫秒，有150个请求进来，有100个请求结束任务释放连接。150 - 100 = 50,空缺了50个连接，减掉前面连接池保留的10个空闲连接，nginx不得不新建40个新连接来满足要求。
- 同样，如果假设相应不均衡也会出现上面的连接数波动情况。

造成连接数量反复震荡的一个推手，就是这个keepalive 这个最大空闲连接数。毕竟连接池中的1000个连接在频繁利用时，出现短时间内多余10个空闲连接的概率实在太高。**因此为了避免出现上面的连接震荡，必须考虑加大这个参数，比如上面的场景如果将keepalive设置为100或者200,就可以非常有效的缓冲请求和应答不均匀**。

总结：

keepalive 这个参数一定要小心设置，尤其对于QPS比较高的场景，推荐先做一下估算，根据QPS和平均响应时间大体能计算出需要的长连接的数量。比如前面10000 QPS和100毫秒响应时间就可以推算出需要的长连接数量大概是1000. 然后将keepalive设置为这个长连接数量的10%到30%。比较懒的同学，可以直接设置为keepalive=1000之类的，一般都OK的了。

#### 综上，出现大量TIME_WAIT的情况

1. 导致 nginx端出现大量TIME_WAIT的情况有两种：
    - keepalive_requests设置比较小，高并发下超过此值后nginx会强制关闭和客户端保持的keepalive长连接；（主动关闭连接后导致nginx出现TIME_WAIT）
    - keepalive设置的比较小（空闲数太小），导致高并发下nginx会频繁出现连接数震荡（超过该值会关闭连接），不停的关闭、开启和后端server保持的keepalive长连接；
1. 导致后端server端出现大量TIME_WAIT的情况：
    - nginx没有打开和后端的长连接，即：没有设置proxy_http_version 1.1;和proxy_set_header Connection “”;从而导致后端server每次关闭连接，高并发下就会出现server端出现大量TIME_WAIT

## nginx配置https

### 配置

```nginx
server {
    listen          80  default_server;
    listen          443 ssl;
    server_name     toutiao.iqiyi.com  toutiao.qiyi.domain m.toutiao.iqiyi.com;
    root            /data/none;
    index           index.php index.html index.htm;

    ###ssl settings start
    ssl_protocols                   TLSv1 TLSv1.1 TLSv1.2;
    ssl_certificate                 /usr/local/nginx/conf/server.pem;
    ssl_certificate_key             /usr/local/nginx/conf/server.key;
    ssl_session_cache               shared:SSL:10m;
    ssl_session_timeout             10m;
    ssl_ciphers ALL:!kEDH!ADH:RC4+RSA:+HIGH:+EXP;
    ssl_prefer_server_ciphers       on;
    ###ssl settings end
    # ...
}
```

### 性能比较

通过https访问Nginx一般会比http访问慢30%（https方式访问主要是耗Nginx服务器的cpu）通过下面实验验证：

1. nginx后端挂了5台java服务器，java服务器中有个简单的java程序，从redis缓存随机读取一个value值输出到前端；（挂的java服务器越多，对nginx压力越大）
1. 压测nginx，3000并发，一共请求30000次，返回结果都是200的情况下进行对比；

实验结果：

1. 服务器负载对比：
    - https访问，服务器cpu最高可以达到20%，而http的访问，服务器cpu基本在1%左右；无论那种访问，nginx服务器负载、内存都不高；
1. nginx吞吐量对比（qps）：
    - https访问，30000次请求花了28s；（是http的3倍）
    - http访问，30000次请求花了9s；

统计qps时，每次清空nginx日志，然后加压，执行完毕后使用如下命令查看qps：

`cat log.2.3000https | grep '/api/news/v1/info?newsId=' | awk '{print$3}'| uniq | wc -l`

注：不能持续加压，否则无限加大压力后往往是后端java服务出现瓶颈，导致返回给nginx的响应变慢，从而使得nginx压力变小。

### 优化

Nginx默认使用DHE算法来产生密匙，该加密算法效率很低。可以通过如下命令，删掉了kEDH算法。

`ssl_ciphers ALL:!kEDH!ADH:RC4+RSA:+HIGH:+EXP;`
