-- hotreload.lua
local hotreload = {}
local keyWasDown = false

function hotreload.check(keyToListen)
    local targetKey = keyToListen or "r"
    local isDown = love.keyboard.isDown(targetKey)

    if keyWasDown and not isDown then
        print("--- Hot Reloading Game Code ---")

        -- Unload your game modules ONLY (never hotreload itself)
        package.loaded["polar"] = nil
        -- add more modules here as your project grows

        if _G.reloadGameModules then
            _G.reloadGameModules()
        end

        keyWasDown = isDown
        return true
    end

    keyWasDown = isDown
    return false
end

return hotreload