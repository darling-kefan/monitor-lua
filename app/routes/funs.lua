local config = require "app.config.config"
local lor = require "lor.index"
local funsRouter = lor:Router()
local utils = require "app.libs.utils"
local date  = require "app.libs.date"

funsRouter:get("/hongbao", function(req, res, next)
    local args = ngx.req.get_uri_args()
	
	local now = date()
	local args_date,args_status,keyword,pageNumber,orderProperty,orderDirection
	args_date = args.date
	if tonumber(args.status) == 0 or tonumber(args.status) == 1 then
	   args_status = tonumber(args.status)
	end
	keyword = args.keyword
	if args.pageNumber == nil or tonumber(args.pageNumber) == nil then
	   args.pageNumber = 1
	   pageNumber = 1
    else
	   pageNumber = args.pageNumber
    end
	if args.orderProperty == nil or args.orderProperty == '' then
	   orderProperty = 'created_at'
	else
	   orderProperty = args.orderProperty
	end
	if args.orderDirection == "asc" or args.orderDirection == "desc" then
	   orderDirection = args.orderDirection
	else
	   orderDirection = "desc"
	end

	local limit  = 100
	local offset = (pageNumber-1)*limit

	local taskhongbao_model = require "app.model.taskhongbao"
	local hongbaos = taskhongbao_model:find_by_args(args_date,args_status,keyword,orderProperty,orderDirection,offset,limit)

	for _, v in pairs(hongbaos) do
	   if v.hongbao_status == 1 then
		  v.hb_status = "成功"
	   else
		  v.hb_status = "失败"
	   end
	end

	local hbCount = taskhongbao_model:get_count_by_args(args_date,args_status,keyword)
	
	local data = {
	   now  = now,
	   args = args,
	   hongbaos  = hongbaos,
	   base_url  = config.base_url,
	   hongbaoCount = hbCount,
	   pageCount = math.ceil(hbCount/limit),
	}
	res:render("funs/hongbao", data)
end)

return funsRouter
