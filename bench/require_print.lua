local _M = {}

local ngx = require('ngx')

function _M.print()
    ngx.print('ngx/print')
end

return _M
