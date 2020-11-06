local _M = {}

local ngx = require 'ngx'
local ngx_req = ngx.req
local ngx_req_get_method = ngx_req.get_method
local ngx_req_read_body = ngx_req.read_body
local ngx_req_get_body_data = ngx_req.get_body_data
local ngx_req_get_uri_args = ngx_req.get_uri_args
local ngx_log = ngx.log
local ngx_ERR = ngx.ERR

local ngx_location_capture = ngx.location.capture

-- from https://github.com/Kong/kong/blob/master/kong/pdk/service/request.lua
local accepted_methods = {
    ['GET'] = ngx.HTTP_GET,
    ['HEAD'] = ngx.HTTP_HEAD,
    ['PUT'] = ngx.HTTP_PUT,
    ['POST'] = ngx.HTTP_POST,
    ['DELETE'] = ngx.HTTP_DELETE,
    ['OPTIONS'] = ngx.HTTP_OPTIONS,
    ['MKCOL'] = ngx.HTTP_MKCOL,
    ['COPY'] = ngx.HTTP_COPY,
    ['MOVE'] = ngx.HTTP_MOVE,
    ['PROPFIND'] = ngx.HTTP_PROPFIND,
    ['PROPPATCH'] = ngx.HTTP_PROPPATCH,
    ['LOCK'] = ngx.HTTP_LOCK,
    ['UNLOCK'] = ngx.HTTP_UNLOCK,
    ['PATCH'] = ngx.HTTP_PATCH,
    ['TRACE'] = ngx.HTTP_TRACE
}

local function get_req_method_id()
    local method = ngx_req_get_method()
    local method_id = accepted_methods[method]
    if not method_id then
        ngx_log(ngx_ERR, 'invalid method: ', method)
        ngx.status = 500
        ngx.print('invalid method: ', method)
        return nil
    end

    return method_id
end

local function get_req_body()
    ngx_req_read_body()
    return ngx_req_get_body_data()
end

function _M.request(uri)
    local res =
        ngx_location_capture(
        uri,
        {
            method = get_req_method_id(),
            args = ngx_req_get_uri_args(),
            body = get_req_body()
        }
    )

    ngx.status = res.status
    for k, v in pairs(res.header) do
        ngx.header[k] = v
    end
    ngx.header['Content-Length'] = string.len(res.body)
    ngx.print(res.body)
end

return _M
