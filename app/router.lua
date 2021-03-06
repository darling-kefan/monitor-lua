-- 业务路由管理
local userRouter = require("app.routes.user")
local ztcRouter = require("app.routes.ztc")
local toolRouter = require("app.routes.tool")
local funsRouter = require("app.routes.funs")

return function(app)

    -- simple router: hello world!
    app:get("/hello", function(req, res, next)
        res:send("hi! welcome to lor framework.")
    end)

    -- simple router: render html, visit "/" or "/?name=foo&desc=bar
    app:get("/", function(req, res, next)
        local data = {
            name =  req.query.name or "lor",
            desc =  req.query.desc or 'a framework of lua based on OpenResty'
        }
        res:render("index", data)
    end)

    -- group router: 对以`/user`开始的请求做过滤处理
    app:use("/user", userRouter())
    app:use("/ztc", ztcRouter())
    app:use("/tool", toolRouter())
	app:use("/funs", funsRouter())
end

