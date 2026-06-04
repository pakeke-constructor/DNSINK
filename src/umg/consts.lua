

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


consts.DEFAULT_MENU_PATH = "src.dnsink_menu.menu"


return consts

