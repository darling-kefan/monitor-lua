local dt = require "app.libs.date"
local DB = require "app.libs.db"
local db = DB:new()
local ejob   = DB:new("ejob")
-- local http   = require "resty.http"
local cjson  = require "cjson"
local insert = table.insert
local concat = table.concat

local publish_model = {}

local function _find_pubversion(args)
    if not args then return nil, "missing args" end
    local url = "http://e.tvm.cn/api/publish?"
    if type(args) == "number" then
        url = url .. "publishid=" .. args
    else
        url = url .. "version=" .. args
    end

    local httpc = http.new()
    local res, err = httpc:request_uri(url)
    if not res or err or res.status ~= ngx.HTTP_OK then
        ngx.say(url .. " request failed. " .. err)
        return nil, url .. " request failed. " .. err
    end

    res = cjson.decode(res.body)
    if res["code"] ~= "0" or not res["msg"] then
        return nil, res["msg"]
    else
        return res["msg"], nil
    end
end

function publish_model:find_join_publish_by_pubid(pubid)
    local fields = {
        "`publishs`.`id` as `id`",
        "`publishs`.`advertiser_id` as `advertiser_id`",
        "`publishs`.`adposition_id` as `adposition_id`",
        "`publishs`.`title` as `title`",
        "`publishs`.`adplan_id` as `adplan_id`",
        "`publishs`.`stime` as `stime`",
        "`publishs`.`etime` as `etime`",
        "`publishs`.`bid` as `bid`",
        "`publishs`.`ceiling` as `ceiling`",
        "`publishs`.`allceiling` as `allceiling`",
        "`publishs`.`consumption` as `consumption`",
        "`publishs`.`status` as `status`",
        "`publishs`.`check` as `check`",
        "`publishs`.`summary` as `summary`",
        "`publishs`.`billing` as `billing`",
        "`publishs`.`mode` as `mode`",
        "`publishs`.`type` as `type`",
        "`publishs`.`card_id` as `card_id`",
        "`publishs`.`tag_id` as `tag_id`",
        "`publishs`.`again_num` as `again_num`",
        "`publishs`.`deleted_at` as `deleted_at`",
        "`publishs`.`created_at` as `created_at`",
        "`publishs`.`updated_at` as `updated_at`",
        "`cards`.`title` as `card_title`",
        "`cards`.`type` as `card_type`",
        "`cards`.`product_id` as `product_id`",
        "`cards`.`logo` as `card_logo`",
        "`cards`.`url` as `card_url`",
        "`cards`.`status` as `card_status`",
        "`cards`.`promote_type` as `promote_type`",
        "`cards`.`promote_route` as `promote_route`"
    }

    fields = concat(fields, ',')
    local sql = "SELECT " .. fields .. " FROM `publishs` LEFT JOIN `cards` " ..
                "ON `publishs`.`card_id` = `cards`.`id` WHERE" ..
                "`publishs`.`id` = " .. pubid

    local res, err = db:query(sql)
    if not res or err or type(res) ~= "table" or #res <= 0 then
        return nil, pubid .. " does not exist."
    end

    local publish = res[1]

    -- Get publish version data
    local pubversion, err = _find_pubversion(pubid)
    if not pubversion or err then
        return nil, err
    end

    publish["time"]    = pubversion["time"]
    publish["target"]  = pubversion["target"]
    publish["version"] = pubversion["version"]
    publish["keyword"] = pubversion["keyword"]
    return publish, nil
end

function publish_model:find_publishs_by_args(args_time, adposition_id, agent, sex, os, age, province, city, keyword, offset, limit)
    local date = dt(args_time):fmt("%Y-%m-%d")
    local hour = dt(args_time):fmt("%H")

    local condition = {}
    insert(condition, "`t_date` = '" .. date .. "'")
    insert(condition, "find_in_set('" .. hour .. "', `t_hours`)")
    if tonumber(agent) == 1 or tonumber(agent) == 2 or tonumber(agent) == 3 then
        insert(condition, "find_in_set('" .. agent .. "', `t_agents`)")
    end
    if tonumber(agent) == 1 then
        -- insert(condition, "`s_pcat` in (1, 3, 4, 5)")
    elseif tonumber(agent) == 2 then
        if tonumber(adposition_id) ~= 3 then
            insert(condition, "`s_pcat` in (4, 5)")
        end
    elseif tonumber(agent) == 3 then
        insert(condition, "`s_pcat` in (4, 5)")
    end
    if sex ~= '' then
        insert(condition, "find_in_set('" .. sex .. "', `t_sexes`)")
    end
    if os ~= '' then
        insert(condition, "find_in_set('" .. os .. "', `t_os`)")
    end
    if age ~= '' then
        insert(condition, "find_in_set('" .. age .. "', `t_ages`)")
    end
    if tonumber(adposition_id) ~= 0 then
        insert(condition, "`adposition_id` = " .. adposition_id)
    end
    if tonumber(city) ~= 0 then
        table.insert(condition, "find_in_set('" .. city .. "', `t_cities`)")
    elseif tonumber(province) ~= 0 then
        table.insert(condition, "find_in_set('" .. province .. "', `t_provinces`)")
    end
    if keyword ~= '' then
        insert(condition, "(`publish_id` = " .. keyword .. " or `advertiser_id` = " .. keyword .. ")")
    end
    local order_part = " order by `s_pcat` DESC,`s_bid` DESC,`s_ceiling` DESC"
    if tonumber(agent) == 6 then
        order_part = " order by `s_bid_adview` DESC,`s_ceiling` DESC"
    end
    local limit_part = ''
    if tonumber(limit) ~= 0 then
        limit_part = " limit " .. offset .. "," .. limit
    end
    local where = concat(condition, ' and ')
    local sql = "select `publish_id`, `advertiser_id`, `adposition_id`, `card_id`, `billing`, `bid`, `industry`, " ..
                "`target_type`, `t_districts`, `t_provinces`, `t_cities`, `t_sexes`, `t_os`, `t_ages`, `t_interests`, `s_pcat`, " ..
                "`s_bid`, `s_bid_adview`, `s_ceiling` from `pubcaches` where " .. where .. order_part .. limit_part

-- ngx.say(sql)
-- do return end

    local res, err = ejob:query(sql)
    if not res or err or type(res) ~= 'table' or #res <= 0 then
        return {}, sql
    else
        return res, sql
    end
end

function publish_model:find_by_pubids(pubids, args_time)
    local date = dt(args_time):fmt("%Y-%m-%d")
    local hour = dt(args_time):fmt("%H")

    local condition = {}
    insert(condition, "`t_date` = '" .. date .. "'")
    insert(condition, "find_in_set('" .. hour .. "', `t_hours`)")
    insert(condition, "`publish_id` in ("..concat(pubids, ',')..")")
    local where = concat(condition, ' and ')
    local sql = "select `publish_id`, `advertiser_id`, `adposition_id`, `card_id`, `billing`, `bid`, `industry`, " ..
                "`target_type`, `t_districts`, `t_provinces`, `t_cities`, `t_sexes`, `t_os`, `t_ages`, `t_interests`, `s_pcat`, " ..
                "`s_bid`, `s_bid_adview`, `s_ceiling` from `pubcaches` where " .. where ..
                " order by `s_pcat` DESC,`s_bid` DESC,`s_ceiling` DESC"

    local res, err = ejob:query(sql)
    if not res or err or type(res) ~= 'table' or #res <= 0 then
        return {}
    else
        return res
    end
end

function publish_model:find_channel_own_ads()
    local condition = {}
    insert(condition, "`type` = 3")
    insert(condition, "`pubtype` = 3")
    insert(condition, "`deleted_at` is null")
    local where = concat(condition, " and ")
    local sql = "select `publish_id` from `channelpub` where " .. where

    local res, err = db:query(sql)
    if not res or err or type(res) ~= 'table' or #res <= 0 then
        return {}
    else
        return res
    end
end

return publish_model
