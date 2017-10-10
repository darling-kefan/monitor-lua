local cjson = require "cjson"
local utils = require "app.libs.utils"
local date  = require "app.libs.date"
local redis = require "app.libs.redis"
local collections = require "app.libs.collections"
-- local pubservice = require "app.services.ztc.publish"
local lor = require "lor.index"
local config = require "app.config.config"
local explode = utils.explode
local insert = table.insert
local sfind = string.find
local pairs = pairs
local ztcRouter = lor:Router()

ztcRouter:get("/rlstCalc", function(req, res, next)
    local args = ngx.req.get_uri_args()
    local args_date,args_status,keyword,orderProperty,orderDirection
    local now = date()
    if args.date == nil or args.time == '' then
        args_date = ngx.localtime()
    else
        args_date = args.date
    end
    if args.status == nil or args.status == '' then
        args_status = 0
    else
        args_status = tonumber(args.status)
    end
    if args.keyword == nil then
        keyword = ''
    else
        keyword = args.keyword
    end
    if args.orderProperty == nil or args.orderProperty == '' then
        orderProperty= ''
    else
        orderProperty = args.orderProperty
    end
    if args.orderDirection == "asc" or args.orderDirection == "desc" then
        orderDirection = args.orderDirection
    else
        orderDirection= ''
    end

    local pubanalysis_model = require "app.model.pubanalysis"
    local publishs = pubanalysis_model:find_pubs_by_args(args_date, args_status, keyword, orderProperty, orderDirection)

    for k, p in pairs(publishs) do
        if p.status == 1 then publishs[k]["status_flag"] = "投放中"
        elseif p.status == 2 then publishs[k]["status_flag"] = "暂停"
        elseif p.status == 3 then publishs[k]["status_flag"] = "停止"
        elseif p.status == 4 then publishs[k]["status_flag"] = "撞线"
        end
    end

    local data = {
        now = now,
        args_date_format = date(args_date):fmt("%Y%m%d"),
        args = args,
        publishs = publishs,
        base_url = config.base_url,
    }
    res:render("ztc/rlstcalc", data)
end)

ztcRouter:get("/overview", function(req, res, next)
    -- Init arguments
    local redis_instance = redis:new()
    local args = ngx.req.get_uri_args()
    local args_time, adposition_id, agent, sex, os, age, province, city, keyword, offset, limit
    local now = date()
    if args.time == nil or args.time == '' then
        args_time = ngx.localtime()
    else
        args_time = args.time
    end
    if args.adposition_id == nil or not utils.in_array(args.adposition_id, {0, 1, 2, 3}) then
        adposition_id = 0
    else
        adposition_id = args.adposition_id
    end
    if args.agent == nil or not utils.in_array(args.agent, {1, 2, 3, 6}) then
        agent = 1
    else
        agent = args.agent
    end
    if args.sex == nil or not utils.in_array(args.sex, {0, 1, 2}) then
        sex = ''
    else
        sex = args.sex
    end
    if args.os == nil or not utils.in_array(args.os, {0, 6, 7}) then
        os = ''
    else
        os = args.os
    end
    if args.age == nil or not utils.in_array(args.age, {20, 21, 22, 23, 24, 25, 26, 27}) then
        age = ''
    else
        age = args.age
    end
    if args.district1 == nil or args.district1 == '' then
        province = 0
    else
        province = tonumber(args.district1)
    end
    if args.district2 == nil or args.district2 == '' then
        city = 0
    else
        city = tonumber(args.district2)
    end
    if args.keyword == nil then
        keyword = ''
    else
        keyword = args.keyword
    end

    offset = 0
    limit = 0

    local publish_model = require "app.model.publish"
    local publishs, sql = publish_model:find_publishs_by_args(args_time, adposition_id, agent, sex, os, age, province, city, keyword, offset, limit)

    -- Get all channels own ads
    local channelPubs = publish_model:find_channel_own_ads()
    local ownAds = {}
    for _, channelPub in pairs(channelPubs) do
        insert(ownAds, channelPub.publish_id)
    end

    -- Get all districts, render the view
    local district_model = require "app.model.district"
    local districts = district_model:get_all_districts({'`id`', '`name`', '`did`', '`pid`', '`leveltype`'})
    local district_id_name = {}
    for _, v in pairs(districts) do
        district_id_name[v.id] = v.name
    end

    -- Get advertiser info
    local advers = {}
    for _, v in pairs(publishs) do
        advers[v.advertiser_id] = true
    end
    local advertiserIds = {}
    for k, _ in pairs(advers) do
        insert(advertiserIds, k)
    end
    local advertiser_model  = require "app.model.advertiser"
    local advertiser_fields = {"`id`","`name`","`shortcom`"}
    local advertisers = advertiser_model:find_advers(advertiserIds, advertiser_fields)
    local advnames = {}
    for _, adv in pairs(advertisers) do
        advnames[adv.id] = adv.shortcom
    end

    local pubs = {}
    for _, v in pairs(publishs) do
        v.card_type = ''
        if     v.adposition_id == 1 then v.card_type = '卡券'
        elseif v.adposition_id == 2 then v.card_type = '视频'
        elseif v.adposition_id == 3 then v.card_type = '开机大图'
        elseif v.adposition_id == 4 then v.card_type = 'Banner'
        end
		-- Set billing type
		if     v.billing == 1 then v.billing_name = "曝光"
		elseif v.billing == 2 then v.billing_name = "点击"
		elseif v.billing == 3 then v.billing_name = "到达"
		else             		   v.billing_name = "未知"
		end
        -- Get publish title and card info
        local pub_key  = "publishs:id:" .. v.publish_id
        local res, err = redis_instance:hgetall(pub_key)
        res = redis_instance:array_to_hash(res)
        if type(res) == 'table' and res.title then
            v.title = utils:utf8mblen(res.title) > 10 and utils:utf8sub(res.title, 1, 10)..'...' or res.title
        else
            v.title = '-'
        end
        if type(res) == 'table' and res.card then
            local card = cjson.decode(res.card)
            v.card_logo = card[1].logo
            v.card_url = card[1].url
        else
            v.card_logo = ''
            v.card_url = '#'
        end
        -- Get target data
        local target_data = {}
        if tonumber(v.t_sexes) == 1 then
		   target_data.sex = '男性'
        elseif tonumber(v.t_sexes) == 2 then
		   target_data.sex = '女性'
        end
        if tonumber(v.t_os) == 6 then
		   target_data.os = 'ios'
        elseif tonumber(v.t_os) == 7 then
		   target_data.os = 'Android'
        end
        if not sfind(v.t_ages, '0') then
            target_data.ages = {}
            local ages = explode(',', v.t_ages)
            for k, age_flag in pairs(ages) do
                if     age_flag == '1' then insert(target_data.ages, '0-18岁')
                elseif age_flag == '2' then insert(target_data.ages, '18-24岁')
                elseif age_flag == '3' then insert(target_data.ages, '25-34岁')
                elseif age_flag == '4' then insert(target_data.ages, '35-44岁')
                elseif age_flag == '5' then insert(target_data.ages, '45-54岁')
                elseif age_flag == '6' then insert(target_data.ages, '55-64岁')
                elseif age_flag == '7' then insert(target_data.ages, '65-岁')
                end
            end
        end
		if not sfind(v.t_interests, '00') then
		   target_data.interests = {}
		   local interests = explode(',', v.t_interests)
		   for _, interest_flag in pairs(interests) do
			  if     interest_flag == '01' then insert(target_data.interests, '教育')
			  elseif interest_flag == '02' then insert(target_data.interests, '旅游')
			  elseif interest_flag == '03' then insert(target_data.interests, '金融')
			  elseif interest_flag == '04' then insert(target_data.interests, '汽车')
			  elseif interest_flag == '05' then insert(target_data.interests, '房产')
			  elseif interest_flag == '06' then insert(target_data.interests, '家具')
			  elseif interest_flag == '07' then insert(target_data.interests, '服饰鞋帽箱包')
			  elseif interest_flag == '08' then insert(target_data.interests, '餐饮美食')
			  elseif interest_flag == '09' then insert(target_data.interests, '生活服务')
			  elseif interest_flag == '10' then insert(target_data.interests, '商务服务')
			  elseif interest_flag == '11' then insert(target_data.interests, '美容')
			  elseif interest_flag == '12' then insert(target_data.interests, '互联网/电子产品')
			  elseif interest_flag == '13' then insert(target_data.interests, '体育运动')
			  elseif interest_flag == '14' then insert(target_data.interests, '医疗健康')
			  elseif interest_flag == '15' then insert(target_data.interests, '孕产育儿')
			  elseif interest_flag == '16' then insert(target_data.interests, '游戏')
			  elseif interest_flag == '17' then insert(target_data.interests, '娱乐休闲')
			  end
		   end
		end
        if tonumber(v.target_type) > 1 and v.t_districts ~= '0' then
            target_data.districts = {}
            local districts = explode(',', v.t_districts)
            for _, dv in pairs(districts) do
                local da = explode('-', dv)
                insert(target_data.districts, district_id_name[tonumber(da[#da])])
            end
        end
        v.target_data = target_data
        -- Get publish budget
        local budget_key = "budget:pub:" .. v.publish_id .. ":" .. now:fmt("%Y%m%d")
        res, err = redis_instance:hgetall(budget_key)
        v.budget = {}
        if type(res) == 'table' then
            res = redis_instance:array_to_hash(res)
            v.budget.ceiling  = res.ceiling and string.format("%.2f", res.ceiling/100) or '-'
            v.budget.consume  = res.consume and string.format("%.2f", res.consume/100) or '-'
            v.budget.unfrozen = res.unfrozen and string.format("%.2f", res.unfrozen/100) or '-'
            if not res.ceiling or not res.consume then
                v.budget.lineRate = '-'
            else
                v.budget.lineRate = string.format("%.2f", (res.consume / res.ceiling) * 100)
            end
        else
            v.budget.ceiling  = '-'
            v.budget.consume  = '-'
            v.budget.unfrozen = '-'
            v.budget.lineRate = '-'
        end
        -- whether is channel own ads
        v.isChannelOwn = collections.contains_value(ownAds, v.publish_id)
        -- set advertiser's shortcom
        v.shortcom = collections.contains_key(advnames, v.advertiser_id) and advnames[v.advertiser_id] or ''

        insert(pubs, v)
    end
    publishs = pubs

	-- filter adview ads 
	if tonumber(agent) == 6 then
	   local fields = {"publish_id","third_id"}
	   local thirdpartyadvs_model = require "app.model.thirdpartyadvs"
	   local tads = thirdpartyadvs_model:effectiveAds(fields)
	   local adviewPubids = {}
	   for ＿, ad in pairs(tads) do
		  if tonumber(ad.third_id) == 6 then
			 insert(adviewPubids, tonumber(ad.publish_id))
		  end
	   end

	   local adviewAds = {}
	   for _, pub in pairs(publishs) do
		  if utils.in_array(pub.publish_id, adviewPubids) then
			 insert(adviewAds, pub)
		  end
	   end
	   publishs = adviewAds
	end

	-- get the count of advers
	local advers = {}
	for _, pub in pairs(publishs) do
	   advers[pub.advertiser_id] = true
	end
	local adversNum = 0
	for k in pairs(advers) do
	   adversNum = adversNum + 1
	end

    -- put it into the connection pool
    redis:keepalive(redis_instance)

    local data = {
        now  = now,
        args = args,
        base_url = config.base_url,
        districts = districts,
        publishs = publishs,
		adversNum = adversNum,
        sql = sql
    }
    res:render("ztc/overview", data)
end)


ztcRouter:get("/track", function(req, res, next)
    local publish_id = 22533

    local publish_model = require "app.model.publish"
    local ad_publish, err = publish_model:find_join_publish_by_pubid(publish_id)
    if err then
        ngx.say(err)
        return
    end

    pubservice = pubservice:new(ad_publish)
end)

return ztcRouter
