local DB = require "app.libs.db"
local db = DB:new()

local advertiser_model = {}

function advertiser_model:find_advers(advertiserIds, fields)
    local condition = {}
    table.insert(condition, "`id` in (" .. table.concat(advertiserIds, ',') .. ")")
    local where = table.concat(condition, ' and ')
    local sql = "select " .. table.concat(fields, ',') .. " from `advertisers` where " .. where

-- ngx.say(sql)
-- do return end

    local res, err = db:query(sql)
    if not res or err or type(res) ~= 'table' or #res <= 0 then
        return {}
    else
        return res
    end
end

return advertiser_model