local DB = require "app.libs.db"
local db = DB:new()

local thirdpartyadvs_model = {}

function thirdpartyadvs_model:effectiveAds(fields)
   local sql = "select "..table.concat(fields, ',').." from `thirdpartyadvs` where deleted_at is null and third_publish_status<>3 and third_card_status<>3"
   local res, err = db:query(sql)
   if not res or err or type(res) ~= 'table' or #res <= 0 then
	  return {}
   end
   return res
end

return thirdpartyadvs_model
