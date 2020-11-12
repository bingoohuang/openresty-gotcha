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

## JIT

LuaJIT 采用 Tracing JIT 来记录并实时编译字节码 当某个循环或者函数调用足够热时,LuaJIT 会开始记录执行的字节码,进行优化后生成 IR,然后把 IR 编译成 mcode 你可以在上面两个文档中找到对 字节码 和 IR 的一些说明 你可以在 LuaJIT 代码中添加下面一行代码,把这一过程 dump 到指定文件中

```lua
require("jit.dump").on("abimsrtx", filepath)
```

在 Nginx 的上下文中，我们可以在 nginx.conf 文件中的 http {} 配置块中添加下面这一段：

```nginx
init_by_lua_block {
    local verbose = false
    if verbose then
        require("jit.dump").on(nil, "/tmp/jit.log")
    else
        require("jit.v").on("/tmp/jit.log")
    end

    require "resty.core"
}
```
