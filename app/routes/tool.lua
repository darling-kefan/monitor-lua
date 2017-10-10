local cjson = require "cjson"
local utils = require "app.libs.utils"
local date  = require "app.libs.date"
local redis = require "app.libs.redis"
local collections = require "app.libs.collections"
local lor = require "lor.index"
local config = require "app.config.config"
local explode = utils.explode
local str_pad = utils.str_pad
local t_insert = table.insert
local s_find = string.find
local pairs = pairs
local toolRouter = lor:Router()

toolRouter:get("/tc", function(req, res, next)
    local now  = date()
    local args = ngx.req.get_uri_args()
    local redis_instance = redis:new()
    local args_time, agent, sex, os, hour, district_part, offset, limit, keys

    keys = {'tc:'}
    if args.agent == nil or not utils.in_array(args.agent, {1, 2, 3, 6, 7}) then
	    agent = '1'
	elseif tonumber(args.agent) == 7 then
	    agent = "6:c"
    else
        agent = args.agent
    end
    t_insert(keys, agent..':')

    if args.time == nil or args.time == '' then
        args_time = ngx.localtime()
    else
        args_time = args.time
    end
    hour = date(args_time):fmt("%H")
    t_insert(keys, hour)

    district_part = '0001'
    if args.district2 ~= nil and args.district2 ~= '' then
        district_part = str_pad(args.district2, 4, '0', 1)
    elseif args.district1 ~= nil and args.district1 ~= '' then
        district_part = str_pad(args.district1, 4, '0', 1)
    end
    t_insert(keys, district_part)

    if args.sex == nil or not utils.in_array(args.sex, {0, 1, 2}) then
        sex = '0'
    else
        sex = args.sex
    end
    t_insert(keys, sex)

    if args.os == nil or not utils.in_array(args.os, {0, 6, 7}) then
        os = '0'
    else
        os = args.os
    end
    t_insert(keys, os)

    local tc_key
    if args.keyword ~= nil and tonumber(args.search_type) == 2 and args.keyword ~= '' then
        tc_key = args.keyword
    else
        tc_key = table.concat(keys)
    end

    local result, err = redis_instance:zrevrange(tc_key, 0, -1)
    -- result = redis_instance:array_to_hash(result)
    local pubids = {}
    for _, v in pairs(result) do
        local va = explode('-', v)
        t_insert(pubids, va[#va])
    end

    local publish_model  = require "app.model.publish"
    local publishs = publish_model:find_by_pubids(pubids, args_time)
    
    local sortedPubs = {}
    for _, p in pairs(pubids) do
        for _, v in pairs(publishs) do
            if tonumber(p) == v.publish_id then
                t_insert(sortedPubs, v)
                break
            end
        end
    end
    publishs = sortedPubs

    -- Get all channels own ads
    local channelPubs = publish_model:find_channel_own_ads()
    local ownAds = {}
    for _, channelPub in pairs(channelPubs) do
        t_insert(ownAds, channelPub.publish_id)
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
        t_insert(advertiserIds, k)
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
		else                       v.billing_name = "未知"
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
        if not s_find(v.t_ages, '0') then
            target_data.ages = {}
            local ages = explode(',', v.t_ages)
            for k, age_flag in pairs(ages) do
                if     age_flag == '1' then t_insert(target_data.ages, '0-18岁')
                elseif age_flag == '2' then t_insert(target_data.ages, '18-24岁')
                elseif age_flag == '3' then t_insert(target_data.ages, '25-34岁')
                elseif age_flag == '4' then t_insert(target_data.ages, '35-44岁')
                elseif age_flag == '5' then t_insert(target_data.ages, '45-54岁')
                elseif age_flag == '6' then t_insert(target_data.ages, '55-64岁')
                elseif age_flag == '7' then t_insert(target_data.ages, '65-岁')
                end
            end
        end
		if not s_find(v.t_interests, '00') then
		   target_data.interests = {}
		   local interests = explode(',', v.t_interests)
		   for _, interest_flag in pairs(interests) do
			  if     interest_flag == '01' then t_insert(target_data.interests, '教育')
			  elseif interest_flag == '02' then t_insert(target_data.interests, '旅游')
			  elseif interest_flag == '03' then t_insert(target_data.interests, '金融')
			  elseif interest_flag == '04' then t_insert(target_data.interests, '汽车')
			  elseif interest_flag == '05' then t_insert(target_data.interests, '房产')
			  elseif interest_flag == '06' then t_insert(target_data.interests, '家具')
			  elseif interest_flag == '07' then t_insert(target_data.interests, '服饰鞋帽箱包')
			  elseif interest_flag == '08' then t_insert(target_data.interests, '餐饮美食')
			  elseif interest_flag == '09' then t_insert(target_data.interests, '生活服务')
			  elseif interest_flag == '10' then t_insert(target_data.interests, '商务服务')
			  elseif interest_flag == '11' then t_insert(target_data.interests, '美容')
			  elseif interest_flag == '12' then t_insert(target_data.interests, '互联网/电子产品')
			  elseif interest_flag == '13' then t_insert(target_data.interests, '体育运动')
			  elseif interest_flag == '14' then t_insert(target_data.interests, '医疗健康')
			  elseif interest_flag == '15' then t_insert(target_data.interests, '孕产育儿')
			  elseif interest_flag == '16' then t_insert(target_data.interests, '游戏')
			  elseif interest_flag == '17' then t_insert(target_data.interests, '娱乐休闲')
			  end
		   end
		end
        if tonumber(v.target_type) > 1 and v.t_districts ~= '0' then
            target_data.districts = {}
            local districts = explode(',', v.t_districts)
            for _, dv in pairs(districts) do
                local da = explode('-', dv)
                t_insert(target_data.districts, district_id_name[tonumber(da[#da])])
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

        t_insert(pubs, v)
    end
    publishs = pubs

    -- put it into the connection pool
    redis:keepalive(redis_instance)

    local data = {
        now  = now,
        args = args,
        base_url = config.base_url,
        districts = districts,
        publishs = publishs,
        tc_key = tc_key,
    }
    res:render("tool/tc", data)
end)

toolRouter:get('/rediscli', function(req, res, next)
    local now  = date()
    local args = ngx.req.get_uri_args()

    local data = {
        now  = now,
        args = args,
        base_url = config.base_url,
    }
    res:render("tool/rediscli", data)
end)


return toolRouter
