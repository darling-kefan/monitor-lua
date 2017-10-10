local config = require "app.config.config"
local redis = require "resty.redis"

local _M = {}

function _M.new(self, redis_type)
    local conf = (redis_type == nil or redis_type == 0) and config.redis.read or config.redis.write
    local instance = redis:new()
    instance:set_timeout(config.redis.timeout)
    local ok, err = instance:connect(conf.host, conf.port)
    if not ok then
        ngx.log(ngx.ERR, "failed to connect: " .. conf.host .. ':' .. conf.port)
        return nil
    end
    return instance
end

function _M.keepalive(self, instance)
    local ok, err = instance:set_keepalive(config.redis.pool_config.max_idle_timeout, config.redis.pool_config.pool_size)
    if not ok then
        ngx.log(ngx.ERR, "failed to set keepalive")
        return false
    end
    return true
end

return _M