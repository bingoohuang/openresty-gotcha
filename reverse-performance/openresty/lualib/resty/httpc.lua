local _M = {}

local ngx = require 'ngx'
local http = require 'resty.http'
local ngx_req = ngx.req
local ngx_ERR = ngx.ERR
local ngx_log = ngx.log
local ngx_print = ngx.print
local ngx_req_get_headers = ngx_req.get_headers
local ngx_req_get_method = ngx_req.get_method
local ngx_req_read_body = ngx_req.read_body
local ngx_req_get_body_data = ngx_req.get_body_data
local ngx_req_get_uri_args = ngx_req.get_uri_args
local http_new = http.new

local function get_req_body()
    ngx_req_read_body()
    return ngx_req_get_body_data()
end

function _M.request(uri, options)
    local res, err =
        http_new():request_uri(
        uri,
        {
            method = ngx_req_get_method(),
            body = get_req_body(),
            query = ngx_req_get_uri_args(),
            headers = ngx_req_get_headers(),
            keepalive = true,
            keepalive_timeout = 60000,
            keepalive_pool = (options and options.keepalive_pool or 1000),
            log_reused_times = true
        }
    )
    if err then
        ngx_log(ngx_ERR, 'httpc:request_uri err : ', err)
        ngx.say('httpc:request_uri err : ', err)
        ngx.status = 500
        return err
    end

    ngx.status = res.status

    for k, v in pairs(res.headers) do
        ngx.header[k] = v
    end
    ngx.header['Content-Length'] = string.len(res.body)
    ngx_print(res.body)

    return nil
end

return _M
