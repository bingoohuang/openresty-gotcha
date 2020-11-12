# lua perf

执行参数                            | 执行结果
------------------------------------|----------------------------------------------
`time lua test.lua 1000 ipairs`     | `3.17s user 0.00s system 99% cpu 3.174 total`
`time lua test.lua 1000 pairs`      | `3.44s user 0.01s system 99% cpu 3.449 total`
`time luajit test.lua 1000 ipairs`  | `0.12s user 0.00s system 94% cpu 0.133 total`
`time luajit test.lua 10000 ipairs` | `1.15s user 0.00s system 99% cpu 1.153 total`
`time luajit test.lua 1000 pairs`   | `1.51s user 0.00s system 99% cpu 1.511 total`

[出处 什么是 JIT](https://moonbingbing.gitbooks.io/openresty-best-practices/content/lua/what_jit.html)

执行参数                                | 执行结果
----------------------------------------|------------------------------------------------
`time lua  table_init.lua 10000 a`      | `13.03s user 0.01s system 99% cpu 13.056 total`
`time lua  table_init.lua 10000 b`      | `4.87s user 0.01s system 99% cpu 4.883 total`
`time luajit  table_init.lua 1000000 a` | `0.66s user 0.00s system 99% cpu 0.660 total`
`time luajit  table_init.lua 1000000 b` | `0.31s user 0.00s system 99% cpu 0.313 total`
