local conf = ngx.shared.config;

return {
	-- 白名单配置：不需要登录即可访问；除非要二次开发，否则不应更改
	whitelist = {
		"^/m1",
		"^/m2",

		"^/index$",
		"^/ask$",
		"^/share$",
		"^/category/[0-9]+$",
		"^/topics/all$",
		"^/topic/[0-9]+/view$",
		"^/topic/[0-9]+/query$",

		"^/comments/all$",

		"^/user/[0-9a-zA-Z-_]+/index$",
		"^/user/[0-9a-zA-z-_]+/topics$",
		"^/user/[0-9a-zA-z-_]+/collects$",
		"^/user/[0-9a-zA-z-_]+/comments$",
		"^/user/[0-9a-zA-z-_]+/follows$",
		"^/user/[0-9a-zA-z-_]+/fans$",
		"^/user/[0-9a-zA-z-_]+/hot_topics$",
		"^/user/[0-9a-zA-z-_]+/like_topics$",

		"^/auth/login$", -- login page
		"^/auth/sign_up$", -- sign up page
		"^/about$", -- about page
		"^/error/$" -- error page
	},

	-- 静态模板配置，保持默认不修改即可
	view_config = {
		engine = "tmpl",
		ext = "html",
		views = "./app/views"
	},


	-- 分页时每页条数配置
	page_config = {
		index_topic_page_size = 10, -- 首页每页文章数
		topic_comment_page_size = 20, -- 文章详情页每页评论数
		notification_page_size = 10, -- 通知每页个数
	},



	-- ########################## 以下配置需要使用者自定义为本地需要的配置 ########################## --

	-- 生成session的secret，请一定要修改此值为一复杂的字符串，用于加密session
	session_secret = "3584827dfed45b40328acb6242bdf13b",

	-- 用于存储密码的盐，请一定要修改此值, 一旦使用不能修改，用户也可自行实现其他密码方案
	pwd_secret = "salt_secret_for_password", 

	-- mysql配置
	mysql = {
		timeout = 5000,
		connect_config = {
		    host = conf:get("etvm_host"),
	        port = conf:get("etvm_port"),
	        database = conf:get("etvm_database"),
	        user = conf:get("etvm_user"),
	        password = conf:get("etvm_password"),
	        max_packet_size = 1024 * 1024
		},
		pool_config = {
			max_idle_timeout = 20000, -- 20s
        	pool_size = 50 -- connection pool size
		}
	},

	ejob = {
		timeout = 5000,
		connect_config = {
		    host = conf:get("ejob_host"),
		    port = conf:get("ejob_port"),
	        database = conf:get("ejob_database"),
	        user = conf:get("ejob_user"),
	        password = conf:get("ejob_password"),
	        max_packet_size = 1024 * 1024
		},
		pool_config = {
			max_idle_timeout = 20000, -- 20s
        	pool_size = 50 -- connection pool size
		}
	},

	appfuns = {
	    timeout = 5000,
		connect_config = {
		    host = conf:get("app_funs_host"),
		    port = conf:get("app_funs_port"),
	        database = conf:get("app_funs_database"),
	        user = conf:get("app_funs_user"),
	        password = conf:get("app_funs_password"),
	        max_packet_size = 1024 * 1024
		},
		pool_config = {
			max_idle_timeout = 20000, -- 20s
        	pool_size = 50 -- connection pool size
		}
	},

	-- Redis config
	redis = {
		timeout = 5000,
		read = {
		   host = conf:get("redis_host_read"),
		   port = conf:get("redis_port_read")
		},
		write = {
		   host = conf:get("redis_host_write"),
		   port = conf:get("redis_port_write")
		},
		pool_config = {
			max_idle_timeout = 10000,
			pool_size = 50
		}
	},

	-- 上传文件配置，如上传的头像、文章中的图片等
	upload_config = {
		dir = "/data/openresty-china/static", -- 文件目录，修改此值时须同时修改nginx配置文件中的$static_files_path值
	},

	base_url = conf:get("base_url"),
}
