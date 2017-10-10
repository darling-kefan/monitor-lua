local DB = require "app.libs.db"
local db = DB:new()

local district_model = {}

function district_model:get_all_districts(fields)
    if type(fields) ~= 'table' then fields = {'*'} end
    local fields_string = table.concat(fields, ',')

    local sql = "select " .. fields_string .. " from `districts` order by `id` asc"
    local res, err = db:query(sql)

    if not res or err or type(res) ~= 'table' or #res <= 0 then
        return {}
    else
        return res
    end
end

return district_model
