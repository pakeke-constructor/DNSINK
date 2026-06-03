local settings = {}

local fullscreen = false
local language = "en"

function settings.isFullscreen()
    return fullscreen
end

function settings.setFullscreen(v)
    fullscreen = not not v
end

function settings.getLanguage()
    return language
end

function settings.setLanguage(lang)
    language = lang or "en"
end

function settings.save()
end

return settings
