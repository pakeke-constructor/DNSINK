

---@class g.consts
local consts = {}


consts.DEV_MODE = not not (love.filesystem.getInfo(".git", "directory") and os.getenv("DISABLE_DEV_MODE") ~= "1")
consts.TEST = not not (consts.DEV_MODE)

consts.PROFILING = false
consts.CONSOLE_LOG_LEVEL = "debug"
consts.FILE_LOG_LEVEL = "none"

consts.GAME_VERSION = 0

consts.ANALYTICS_URL = ""

consts.MAX_PLAYING_SOURCES = 30

consts.MAX_EVENT_CALLS_PER_FRAME = 30


consts.LOCALHOST_UDP_IPPORT = "localhost:57843";
-- udp-ip:port to be used for localhost server. 
-- (Hardcoded; means we don't need to do weird port-discovery stuff)


consts.DEFAULT_MENU_PATH = "src.dnsink_menu.menu"


return consts

