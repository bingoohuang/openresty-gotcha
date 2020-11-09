-- For simple singleshot requests, use the URI interface.
local http = require 'resty.http'
local httpc = http.new()
httpc:set_timeout(60000)

local res, err =
    httpc:request_uri(
    'http://127.0.0.1:8812/vsm/SDF_OpenDevice',
    {
        method = 'POST',
        keepalive_timeout = 60000,
        keepalive_pool = 1000
    }
)

if not res then
    ngx.say('failed to request: ', err)
    return
end

ngx.status = res.status
for k, v in pairs(res.headers) do
    ngx.header[k] = v
end
ngx.say(res.body)
