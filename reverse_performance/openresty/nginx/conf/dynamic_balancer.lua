local b = require 'ngx.balancer'
-- local p = tonumber(ngx.var.arg_port or '8812')
math.randomseed (os.time())
local p = math.random (8811, 8812)
local ok, err = b.set_current_peer('192.168.126.18', p)
if not ok then
    ngx.log(ngx.ERR, 'failed to set the current peer: ', err)
    return ngx.exit(500)
end
