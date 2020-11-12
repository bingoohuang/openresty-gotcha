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

## table.maxn

[Question](http://lua-users.org/lists/lua-l/2015-05/msg00497.html)

In Lua 5.1 table.maxn is linear, \#t is not. table.maxn only gives sequences, #t may or may not give sequences...
If table.maxn != \#t... why did table.maxn get removed again?

(At least the Lua 5.1 reference manual says table.maxn is linear...)

\#t is not linear because it's better than linear -- it's logarithmic.
Furthermore, \#t and table.maxn will always agree in the case that the
table is a sequence.

[Adam Answer](http://lua-users.org/lists/lua-l/2015-05/msg00499.html)

In practice, using maxn is almost always a mistake. It has inferior
performance (and the bigger your table is, the worse the gap gets) and
any design where you care about the difference between a sequence and
a non-sequence and you don't know in advance which you're looking at
is dubious at best. Seriously, if you're dealing in sequences, then
you ought to know you're dealing in sequences, at which point you
should be using \#t for the performance. And if you're dealing in
arbitrary tables that may or may not be a sequence, you shouldn't be
trying to treat them as sequences at all, but rather explicitly
tracking a length or something.

[Performance for table length operator](https://stackoverflow.com/questions/18200915/performance-for-table-length-operator)

The value of # for a table is not stored internally by Lua: it is computed every time it is called.

Lua uses a binary search and so the cost is logarithmic in the size of the table. [See the code](http://www.lua.org/source/5.2/ltable.c.html#luaH_getn).
In other words, the cost is essentially constant, except for huge tables.

[What is the difference between the “#” operator and string.len(s) function?](https://help.interfaceware.com/what-is-the-difference-between-the-operator-and-string-lens-function.html)

Basically, they are identical when used on Lua strings; however, the # operator will also return the length of an array as long as that array does not contain any “holes”. Similarly, while the operator can be used on arbitrary tables, the value it returns is based on numeric indices (so it may not give you the result you expect). For further discussion of this, see [Section 2.5.5 of the Lua 5.1 Reference Manual](http://www.lua.org/manual/5.1/manual.html#2.5.5).

1. The “#” operator is equivalent to string.len() when used on strings.
1. The “#” operator will also return the length of a table. Previous to Lua 5.1 you needed to use table.getn().

We recommend using the # operator instead of string.len() as it is more concise.

[online table.maxn test code](https://repl.it/join/rfpkezug-bingoohuang)

```lua
-- 各种索引都存在
local tab0 = {
	up ="Lua",
	"c",
	"c++",
	[100] = "end",
	realend = "realend",
	[-1] = "haha",
}
print("table.maxn of tab0 :", table.maxn(tab0), ", #:", #(tab0))

-- 使用默认数字索引
local tab1 = {
	"c",
	"c++",
	"php",
}
print("table.maxn of tab1 :", table.maxn(tab1), ", #:", #(tab1))

-- 负数索引
local tab2 = {
	[-1] = "c",
	[-100] = "c++",
	[-10] = "php",
}
print("table.maxn of tab2 :", table.maxn(tab2), ", #:", #(tab2))

-- 非数字索引
local tab3 = {
	first = "c",
	second = "c++",
	third = "php",
}
print("table.maxn of tab3 :", table.maxn(tab3), ", #:", #(tab3))

-- Output:
-- table.maxn of tab0 :    100 , #:    2
-- table.maxn of tab1 :    3   , #:    3
-- table.maxn of tab2 :    0   , #:    0
-- table.maxn of tab3 :    0   , #:    0
```
