local loop_count = tonumber(arg[1])
local way = 'a' == arg[2] and 'a' or 'b'

if way == 'a' then
    print("way a")
elseif way == 'b' then
    print("way b")
end

local GW_HTTP_STATUS_ERR = 2001
local req_st = 1000
local rec_tab = {}

for i = 1, loop_count do
    for j = 1, 1000 do
        if way == 'a' then
            rec_tab = {
                flag = GW_HTTP_STATUS_ERR,
                user_time = req_st,
                user_client_ip = '-',
                user_uid = '-',
                request_size = '-',
                user_ua = '-',
                user_realip = '-',
                last_hop = '-',
                user_x_forwarded_for = '-',
                auth_is_local_ip = '-',
                auth_key_secret_check_rst = '-',
                auth_session_check_rst = '-',
                auth_sid = '-',
                auth_ucenter_platform = '-',
                auth_check_login_token_rst = '-',
                auth_cookie = '-',
                auth_invalid_msg = '-',
                api_apiid = '-',
                api_session_var_map = '-',
                resp_status = '-',
                resp_response_time = '-',
                resp_inner_response_time = '-',
                resp_inner_start_req_time = '-',
                resp_body_size = '-',
                request_id = '-',
                trace_id = '-',
                service_id = '-',
                request_body = '-',
                resp_body = '-',
                anchor_init_var = '-',
                anchor_search_api = '-',
                anchor_check_develop = '-',
                anchor_check_app = '-',
                anchor_check_session = '-',
                anchor_check_safe = '-',
                anchor_start_request = '-',
                anchor_produce_cookie = '-',
                anchor_encrypt_cookie = '-',
                anchor_produce_response = '-',
                anchor_output_log = '-'
            }
        elseif way == 'b' then
            rec_tab.flag = GW_HTTP_STATUS_ERR
            rec_tab.user_time,
                rec_tab.user_client_ip,
                rec_tab.user_uid,
                rec_tab.request_size,
                rec_tab.user_ua,
                rec_tab.user_realip,
                rec_tab.last_hop,
                rec_tab.user_x_forwarded_for = req_st, '-', '-', '-', '-', '-', '-', '-'
            rec_tab.auth_is_local_ip,
                rec_tab.auth_key_secret_check_rst,
                rec_tab.auth_session_check_rst,
                rec_tab.auth_sid,
                rec_tab.auth_ucenter_platform,
                rec_tab.auth_check_login_token_rst,
                rec_tab.auth_cookie,
                rec_tab.auth_invalid_msg = '-', '-', '-', '-', '-', '-', '-', '-'
            rec_tab.api_apiid, rec_tab.api_session_var_map = '-', '-'
            rec_tab.resp_status,
                rec_tab.resp_response_time,
                rec_tab.resp_inner_response_time,
                rec_tab.resp_inner_start_req_time,
                rec_tab.resp_body_size = '-', '-', '-', '-', '-'
            rec_tab.request_id, rec_tab.trace_id, rec_tab.service_id = '-', '-', '-'
            rec_tab.request_body = '-'
            rec_tab.resp_body = '-'
            rec_tab.anchor_init_var, rec_tab.anchor_search_api = '-', '-'
            rec_tab.anchor_check_develop, rec_tab.anchor_check_app, rec_tab.anchor_check_session = '-', '-', '-'
            rec_tab.anchor_check_safe = '-'
            rec_tab.anchor_start_request = '-'
            rec_tab.anchor_produce_cookie, rec_tab.anchor_encrypt_cookie = '-', '-'
            rec_tab.anchor_produce_response = '-'
            rec_tab.anchor_output_log = '-'
        end

        if rec_tab.is_local_ip then
            print("is_local_ip")
        end
    end
end
