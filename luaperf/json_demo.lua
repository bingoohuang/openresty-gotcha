-- add lua_modules to package.path and package.cpath
local f = assert(io.popen('pwd', 'r'))
local pwd = assert(f:read('*a')):sub(1, -2)
f:close()

local home = os.getenv('HOME')

package.path = package.path .. ';' .. pwd .. '/luaperf/modules/?.lua'
package.cpath = package.cpath .. ';' .. home .. '/.luarocks/lib/lua/5.1/?.so'

print('package.path:', package.path)
print('package.cpath:', package.cpath)

print(require('cjson').encode({
    status = 'API-Gateway is running'
}))

local m = require('module_demo')
print(m.hello())
print(m.hello())
