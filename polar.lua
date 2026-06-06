-- polar.lua
local polar = {}

local TARGET_SIZE = 1000
local gameCanvas = love.graphics.newCanvas(TARGET_SIZE, TARGET_SIZE)

-- Uniform 1:1 conversion
function polar.toCartesian(radius, theta)
    local x = radius * math.cos(theta)
    local y = radius * math.sin(theta)
    return x, y
end

-- New: Conversion that builds flat isometric faces natively
function polar.toIsoCartesian(radius, theta)
    local x = radius * math.cos(theta)
    -- Squish only the Y value of the calculation by 0.577
    local y = (radius * math.sin(theta)) * 0.577 
    return x, y
end

function polar.start()
    love.graphics.setCanvas(gameCanvas)
    love.graphics.clear() 

    love.graphics.push()
    love.graphics.translate(TARGET_SIZE / 2, TARGET_SIZE / 2)
    love.graphics.scale(1, -1) -- Just flip Y up, DO NOT flatten globally anymore!
end

-- Draws a line using the isometric squished perspective space
-- Perfect for the top/bottom caps of your cube
function polar.isoLine(...)
    local args = {...}
    local points = {}
    for i = 1, #args, 2 do
        local x, y = polar.toIsoCartesian(args[i], args[i+1])
        table.insert(points, x)
        table.insert(points, y)
    end
    love.graphics.line(unpack(points))
end

-- Draws a regular, un-squished polar line
-- Perfect for drawing straight vertical walls
function polar.line(...)
    local args = {...}
    local points = {}
    for i = 1, #args, 2 do
        local x, y = polar.toCartesian(args[i], args[i+1])
        table.insert(points, x)
        table.insert(points, y)
    end
    love.graphics.line(unpack(points))
end

function polar.stop()
    love.graphics.pop()
    love.graphics.setCanvas()

    local windowW = love.graphics.getWidth()
    local heightW = love.graphics.getHeight()
    local scale = math.min(windowW / TARGET_SIZE, heightW / TARGET_SIZE)
    local offsetX = (windowW - (TARGET_SIZE * scale)) / 2
    local offsetY = (heightW - (TARGET_SIZE * scale)) / 2

    love.graphics.setColor(1, 1, 1) 
    love.graphics.draw(gameCanvas, offsetX, offsetY, 0, scale, scale)
end

return polar