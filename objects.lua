local Rock = {}
Rock.__index = Rock

function Rock.new(x, y, size)
    local self = setmetatable({}, Rock)
    self.x = x
    self.y = y
    self.vx = 0
    self.vy = 0
    self.size = size or (28 + math.random() * 36)
    self.capacity = math.max(1, math.floor(self.size / 10))
    self.isHeld = false
    self.isMoving = false
    self.hidingCount = 0
    self.hideCooldown  = 0
    self.angle         = math.random() * math.pi * 2
    self.angularVel    = 0

    -- Random jagged polygon: N points, each jittered in angle and radius
    self.vertices = {}
    local numPoints = math.random(6, 10)
    for i = 1, numPoints do
        local baseAngle = (i / numPoints) * math.pi * 2
        local angle = baseAngle + (math.random() - 0.5) * (math.pi / numPoints * 0.9)
        local r = self.size * (0.55 + math.random() * 0.75)
        table.insert(self.vertices, math.cos(angle) * r)
        table.insert(self.vertices, math.sin(angle) * r)
    end

    return self
end

function Rock:update(dt, screenWidth, screenHeight)
    local moving = self.isHeld or (math.abs(self.vy) > 8 or math.abs(self.vx) > 8)
    self.isMoving = moving

    if self.hideCooldown > 0 then
        self.hideCooldown = self.hideCooldown - dt
    end

    if self.isHeld then
        -- Spin down while held
        self.angularVel = self.angularVel * (1 - 4 * dt)
    else
        self.vy = self.vy + 600 * dt   -- gravity
        self.vx = self.vx * (1 - 4 * dt)

        self.x = self.x + self.vx * dt
        self.y = self.y + self.vy * dt

        -- Angular velocity driven by horizontal speed (tumbling)
        local targetAV = self.vx * 0.04
        self.angularVel = self.angularVel + (targetAV - self.angularVel) * math.min(1, 5 * dt)

        -- Sand floor
        local sandTop = screenHeight - (sandHeight or 55)
        local floor = sandTop - self.size * 0.4
        if self.y > floor then
            self.y = floor
            self.vy = self.vy * -0.25
            self.vx = self.vx * 0.6
            self.angularVel = self.angularVel * 0.4
            if math.abs(self.vy) < 8 then self.vy = 0 end
        end

        -- Horizontal wrap (matches fish)
        if self.x < -self.size then
            self.x = screenWidth + self.size
        elseif self.x > screenWidth + self.size then
            self.x = -self.size
        end
    end

    self.angle = self.angle + self.angularVel * dt
end

function Rock:containsPoint(px, py)
    local dx = px - self.x
    local dy = py - self.y
    return dx*dx + dy*dy < self.size * self.size
end

function Rock:draw()
    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.angle)

    -- Vertices are stored relative to origin
    if self.isHeld then
        love.graphics.setColor(0.55, 0.55, 0.6)
    else
        love.graphics.setColor(0.38, 0.38, 0.42)
    end
    love.graphics.polygon("fill", self.vertices)
    love.graphics.setColor(0.22, 0.22, 0.26)
    love.graphics.polygon("line", self.vertices)

    love.graphics.pop()
end

return Rock
