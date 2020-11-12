# 网关原型

当前测试，目标服务部署容器内，gobench使用100连接并发压测

\#|gw容器内|走gw逻辑|实现方式|连接池大小|TPS|备注
---|---|:---:|---|---|---|---
1|Y|\-|无反代直压|\-|2.2万|
2|Y|\-|upstream|1000|1.7万|`keepalive 1000;`
3|N|\-|upstream|1000|2万|`keepalive 1000;`
4|Y|\-|upstream|不设|6500|
5|Y|\-|不走upstream|无|5600|`proxy_pass http://ip:port;`
6|N|\-|不走upstream|无|6452|`proxy_pass http://ip:port;`
7|Y|Y|不走upstream|无|4400|`proxy_pass http://ip:port;`
8|Y|Y|走upstream|1000|4676| `keepalive 1000;`
9|Y|Y|走upstream|不设|4637|
