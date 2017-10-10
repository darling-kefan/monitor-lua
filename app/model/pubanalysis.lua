local dt = require "app.libs.date"
local DB = require "app.libs.db"
local ejob = DB:new("ejob")
local upper = string.upper

local pubanalysis_model = {}

function pubanalysis_model:find_pubs_by_args(args_date, args_status, keyword, orderProperty, orderDirection)
    local date = dt(args_date):fmt("%Y-%m-%d")

    local sql
    if args_status == 0 then
        sql = "SELECT * FROM `pubanalysis` WHERE `target_date` = '"..date.."'"
    else
        sql  = "SELECT * FROM `pubanalysis` WHERE `target_date` = '"..date.."' AND `status` = "..args_status
    end
    if #keyword > 0 then
        sql = sql.." AND (`publish_id` = "..keyword.." OR `advertiser_id` = "..keyword..")"
    end
    if #orderProperty > 0 and #orderDirection > 0 then
        if orderProperty == "pubid" then
            sql = sql.." ORDER BY `publish_id` "..upper(orderDirection)
        elseif orderProperty == "adverid" then
            sql = sql.." ORDER BY `advertiser_id` "..upper(orderDirection)
        elseif orderProperty == "ceiling" then
            sql = sql.." ORDER BY `ceiling` "..upper(orderDirection)
        elseif orderProperty == "rlconsume" then
            sql = sql.." ORDER BY `rl_consume` "..upper(orderDirection)
        elseif orderProperty == "status" then
            sql = sql.." ORDER BY `status` "..upper(orderDirection)
        elseif orderProperty == "uptime" then
            sql = sql.." ORDER BY `reached_at` "..upper(orderDirection)
        elseif orderProperty == "stshow" then
            sql = sql.." ORDER BY `st_show` "..upper(orderDirection)
        elseif orderProperty == "stconsume" then
            sql = sql.." ORDER BY `st_consume` "..upper(orderDirection)
        elseif orderProperty == "stclick" then
            sql = sql.." ORDER BY `st_click` "..upper(orderDirection)
        end
    end

    local res, err = ejob:query(sql)
    if not res or err or type(res) ~= 'table' or #res <= 0 then
        return {}
    end
    return res
end

return pubanalysis_model