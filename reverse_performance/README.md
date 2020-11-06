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

## 测试输出

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
