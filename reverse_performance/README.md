# 反向代理几种实现方式的性能测试对比

## 依赖

1. [openresty](https://openresty.org/cn/download.html)
1. [resty.http](https://github.com/ledgetech/lua-resty-http)
1. [gobench](https://github.com/bingoohuang/gobench/tree/master/cmd/gobench)
1. [go-rest-server](https://github.com/bingoohuang/gobench/tree/master/cmd/go-rest-server)

## 安装

1. 安装 openresty
1. 安装 `OPENRESTY_HOME=~/openresty ./install.sh`
1. 启动反向代理 `$OPENRESTY_HOME/bin/resty`
1. 启动目标服务 `go-rest-server -addr :8812`, `go-rest-server -addr :8813`

## 测试

直压|upstream|ngx.location.capture|resty.http|upstream(连接池1000)|upstream \+ balancer
---|---|---|---|---|---
8万|2万|1.7万|2.8万|5万|4.7万

## 参数文章

1. [10 Tips for 10x Application Performance](https://www.nginx.com/blog/10-tips-for-10x-application-performance/)
1. [HTTP Keepalive Connections and Web Performance](https://www.nginx.com/blog/http-keepalives-and-web-performance/)
1. [Developing a user-friendly OpenResty application OpenResty Con 2017 - Beijing](https://con.openresty.org/cn/2017/books/developing%20a%20friendly%20openresty%20application.pdf)
1. [巧用 Nginx 实现大规模分布式集群的高可用性](https://blog.csdn.net/russell_tao/article/details/98936540)

## 测试输出

![image](https://user-images.githubusercontent.com/1940588/98348557-def67400-2053-11eb-959e-0c40eb172c8c.png)

1. 直压:

```bash
[footstone@fs01-192-168-126-182 ~]$ gobench -u http://192.168.126.18:8812/hello -d 10s
Dispatching 100 goroutines
Waiting for results...

Total Requests:			811465 hits
Successful requests:		811465 hits
Network failed:			0 hits
Bad requests(!2xx):		0 hits
Successful requests rate:	81094 hits/sec
Read throughput:		17 MiB/sec
Write throughput:		7.4 MiB/sec
Test time:			10.006448967s
```

2. upstream

```bash
[footstone@fs01-192-168-126-182 ~]$ gobench -u http://127.0.0.1:20003 -d 10s
Dispatching 100 goroutines
Waiting for results...

Total Requests:			200208 hits
Successful requests:		200208 hits
Network failed:			0 hits
Bad requests(!2xx):		0 hits
Successful requests rate:	20008 hits/sec
Read throughput:		5.5 MiB/sec
Write throughput:		1.7 MiB/sec
Test time:			10.006127048s
```

3. ngx.location.capture

```bash
[footstone@fs01-192-168-126-182 ~]$ gobench -u http://127.0.0.1:20004 -d 10s
Dispatching 100 goroutines
Waiting for results...

Total Requests:			171983 hits
Successful requests:		171983 hits
Network failed:			0 hits
Bad requests(!2xx):		0 hits
Successful requests rate:	17184 hits/sec
Read throughput:		4.7 MiB/sec
Write throughput:		1.4 MiB/sec
Test time:			10.007750769s
```

4. resty.http

```bash
[footstone@fs01-192-168-126-182 ~]$ gobench -u http://127.0.0.1:20001 -d 10s
Dispatching 100 goroutines
Waiting for results...

Total Requests:			285712 hits
Successful requests:		285712 hits
Network failed:			0 hits
Bad requests(!2xx):		0 hits
Successful requests rate:	28551 hits/sec
Read throughput:		7.8 MiB/sec
Write throughput:		2.4 MiB/sec
Test time:			10.007055173s
```

5. upstream(连接池1000)

```bash
[footstone@fs01-192-168-126-182 ~]$ gobench -u http://127.0.0.1:20002  -d 10s
Dispatching 100 goroutines
Waiting for results...

Total Requests:			600337 hits
Successful requests:		600337 hits
Network failed:			0 hits
Bad requests(!2xx):		0 hits
Successful requests rate:	60010 hits/sec
Read throughput:		16 MiB/sec
Write throughput:		5.0 MiB/sec
Test time:			10.003810942s
```

6. upstream \+ balancer

```bash
[footstone@fs01-192-168-126-182 ~]$ gobench -u http://127.0.0.1:20005 -d 10s
Dispatching 100 goroutines
Waiting for results...

Total Requests:			471285 hits
Successful requests:		471285 hits
Network failed:			0 hits
Bad requests(!2xx):		0 hits
Successful requests rate:	47104 hits/sec
Read throughput:		12 MiB/sec
Write throughput:		3.9 MiB/sec
Test time:			10.005103665s
```

## 重点

1. [balancer.set_current_peer](https://github.com/openresty/lua-resty-core/blob/master/lib/ngx/balancer.md#set_current_peer)

balancer_by_lua阶段可以在其早期阶段（例如access_by_lua\*）中通过ngx.ctx来传值. 实践中，不能在content_by_lua中传值。



    set_current_peer
    syntax: ok, err = balancer.set_current_peer(host, port)

    context: balancer_by_lua*

    Sets the peer address (host and port) for the current backend query (which may be a retry).

    Domain names in host do not make sense. You need to use OpenResty libraries like lua-resty-dns to obtain IP address(es) from all the domain names before entering the balancer_by_lua* handler (for example, you can perform DNS lookups in an earlier phase like access_by_lua* and pass the results to the balancer_by_lua* handler via ngx.ctx.


![image](https://user-images.githubusercontent.com/1940588/98350066-c9824980-2055-11eb-9f2f-a92a0ff88a53.png)

图片来自[这里](https://wiki.shileizcc.com/confluence/pages/viewpage.action?pageId=47415936)
