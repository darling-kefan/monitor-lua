local dt = require "app.libs.date"
local DB = require "app.libs.db"
local appfuns = DB:new("appfuns")
local upper   = string.upper
local insert  = table.insert
local concat  = table.concat

local taskhongbao_model = {}

function taskhongbao_model:find_by_args(args_date, args_status, keyword, orderProperty, orderDirection, offset, limit)
   local condition = {}
   if args_date ~= nil and #args_date > 0 then
	  local date = dt(args_date):fmt("%Y-%m-%d")
	  insert(condition, "`created_at` LIKE '"..date.."%'")
   end
   if args_status ~= nil then
	  insert(condition, "`hongbao_status`="..args_status)
   end
   if keyword ~= nil and #keyword > 0 then
	  insert(condition, "(`taskid`='"..keyword.."' OR `tvmid`='"..keyword.."')")
   end

   local sql = "SELECT * FROM `taskhongbao`"
   if #condition > 0 then
	  local where = concat(condition, " AND ")
	  sql = sql.." WHERE "..where
   end

   if #orderProperty > 0 and #orderDirection > 0 then
	  if orderProperty == "tvmid" then
		 sql = sql.." ORDER BY `tvmid` "..upper(orderDirection)
	  elseif orderProperty == "taskid" then
		 sql = sql.." ORDER BY `taskid` "..upper(orderDirection)
	  elseif orderProperty == "money" then
		 sql = sql.." ORDER BY `amount` "..upper(orderDirection)
	  elseif orderProperty == "hongbao_status" then
		 sql = sql.." ORDER BY `hongbao_status` "..upper(orderDirection)
	  elseif orderProperty == "created_at" then
		 sql = sql.." ORDER BY `created_at` "..upper(orderDirection)
	  end
   end

   sql = sql.." LIMIT "..offset..","..limit

   --ngx.say(sql)
   --do return end
   
   local res, err = appfuns:query(sql)
   if not res or err or type(res) ~= 'table' or #res <= 0 then
	  return {}
   end

   return res
end

function taskhongbao_model:get_count_by_args(args_date,args_status,keyword)
   local condition = {}
   if args_date ~= nil and #args_date > 0 then
	  local date = dt(args_date):fmt("%Y-%m-%d")
	  insert(condition, "`created_at` LIKE '"..date.."%'")
   end
   if args_status ~= nil then
	  insert(condition, "`hongbao_status`="..args_status)
   end
   if keyword ~= nil and #keyword > 0 then
	  insert(condition, "(`taskid`='"..keyword.."' OR `tvmid`='"..keyword.."')")
   end

   local sql = "SELECT COUNT(*) AS `count_num` FROM `taskhongbao`"
   if #condition > 0 then
	  local where = concat(condition, " AND ")
	  sql = sql.." WHERE "..where
   end

   --ngx.say(sql)
   --do return end
   
   local res, err = appfuns:query(sql)

   --for k, v in pairs(res) do
   --    ngx.say(k, type(v))
   --    for kk, vv in pairs(v) do
   --        ngx.say(kk, vv)
   --    end
   --end
   --do return end
   
   if not res or err or type(res) ~= 'table' or #res <= 0 then
	  return 0
   end

   return res[1].count_num
end

return taskhongbao_model
