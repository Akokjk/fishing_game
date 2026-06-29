local Jellyfish = {}
Jellyfish.__index = Jellyfish

function Jellyfish.new(x, y)
    local self = setmetatable({}, Jellyfish)
    self.x = x
    self.y = y
    self.radius = 18 + math.random() * 14

    -- Horizontal drift
    self.vx = (math.random() > 0.5 and 1 or -1) * (18 + math.random() * 22)
    self.vy = 0

    -- Vertical bob
    self.targetY    = y
    self.bobTimer   = math.random() * 4
    self.bobInterval = 3 + math.random() * 4

    -- Tentacles: each has an x offset, a length, a width, and a random horizontal flip
    self.tentacles = {}
    local n = 5 + math.random(4)
    for i = 1, n do
        local frac = (i - 1) / (n - 1)
        table.insert(self.tentacles, {
            ox      = (frac - 0.5) * self.radius * 1.8,
            length  = self.radius * (0.9 + math.random() * 1.4),
            width   = self.radius * (0.25 + math.random() * 0.2),
            flipped = math.random() > 0.5,
        })
    end

    -- Longest tentacle determines stun zone depth
    self.maxTentacleLen = 0
    for _, t in ipairs(self.tentacles) do
        if t.length > self.maxTentacleLen then
            self.maxTentacleLen = t.length
        end
    end

    -- Blue-purple colour with slight alpha
    local r = 0.35 + math.random() * 0.25
    local g = 0.05 + math.random() * 0.15
    local b = 0.65 + math.random() * 0.35
    self.color = { r, g, b, 0.78 }

    -- Sway animation
    self.swayTime = math.random() * math.pi * 2

    return self
end

function Jellyfish:update(dt, blackboard)
    self.swayTime = self.swayTime + dt * 1.4

    -- Hunt nearest krill within sensing range
    local krill = blackboard and blackboard.krill
    local nearestKrill, nearestDist2 = nil, (200)^2
    if krill then
        for i = #krill, 1, -1 do
            local k  = krill[i]
            local dx = k.x - self.x
            local dy = k.y - self.y
            local d2 = dx*dx + dy*dy
            if d2 < nearestDist2 then
                nearestDist2 = d2
                nearestKrill = k
                nearestKrill._idx = i
            end
            -- Eat krill caught by tentacles
            if self:stings(k.x, k.y) then
                table.remove(krill, i)
                --if pop_sound then pop_sound:stop(); pop_sound:play() end
            end
        end
    end

    -- Steer toward krill if found, otherwise random drift
    if nearestKrill then
        local dx    = nearestKrill.x - self.x
        local wantVx = math.max(-40, math.min(40, dx * 0.4))
        self.vx = self.vx + (wantVx - self.vx) * 0.06
        self.targetY = nearestKrill.y - self.radius - self.maxTentacleLen * 0.5
    else
        -- Resume idle drift speed when no target
        local idleVx = (self.vx >= 0 and 1 or -1) * (18 + math.random() * 4)
        self.vx = self.vx + (idleVx - self.vx) * 0.005
    end

    -- Horizontal movement + wrap
    self.x = self.x + self.vx * dt
    if self.x < -self.radius * 3 then
        self.x = blackboard.screenWidth + self.radius * 3
    elseif self.x > blackboard.screenWidth + self.radius * 3 then
        self.x = -self.radius * 3
    end

    -- Vertical bob: pick a new random target when not chasing krill
    if not nearestKrill then
        self.bobTimer = self.bobTimer + dt
        if self.bobTimer >= self.bobInterval then
            self.bobTimer    = 0
            self.bobInterval = 3 + math.random() * 4
            local waterTop   = blackboard.waterTop + self.radius + 10
            local waterBot   = blackboard.screenHeight - self.maxTentacleLen - 20
            if waterBot > waterTop then
                self.targetY = waterTop + math.random() * (waterBot - waterTop)
            end
        end
    end

    -- Spring toward targetY
    local dy = self.targetY - self.y
    self.vy = self.vy + dy * 1.2 * dt
    self.vy = self.vy * (1 - 4 * dt)
    self.y  = self.y + self.vy * dt

    -- Separate from other jellyfish
    for _, other in ipairs(jellyList) do
        if other ~= self then
            local dx  = self.x - other.x
            local dy2 = self.y - other.y
            local d2  = dx*dx + dy2*dy2
            local minD = self.radius + other.radius + 8
            if d2 < minD*minD and d2 > 0 then
                local d    = math.sqrt(d2)
                local push = (minD - d) * 0.5
                self.x  = self.x  + (dx/d)  * push
                self.y  = self.y  + (dy2/d) * push
                local dotX = self.vx*(dx/d)
                local dotY = self.vy*(dy2/d)
                local dot  = dotX + dotY
                if dot < 0 then
                    self.vx = self.vx - dot*(dx/d)
                    self.vy = self.vy - dot*(dy2/d)
                end
            end
        end
    end
end

-- Returns true if point (px, py) is inside the sting zone (tentacle area)
function Jellyfish:stings(px, py)
    -- Must be below the body
    local baseY = self.y + self.radius
    if py < baseY then return false end

    for _, t in ipairs(self.tentacles) do
        local sway = math.sin(self.swayTime + t.ox * 0.05) * 6
        local tx   = self.x + t.ox + sway
        local halfW = t.width / 2 + 4   -- small tolerance
        if px >= tx - halfW and px <= tx + halfW
           and py <= baseY + t.length then
            return true
        end
    end
    return false
end

function Jellyfish:draw()
    local r, g, b, a = self.color[1], self.color[2], self.color[3], self.color[4]

    -- Tentacles (drawn behind body)
    for _, t in ipairs(self.tentacles) do
        local sway = math.sin(self.swayTime + t.ox * 0.05) * 1.5
        local tx   = self.x + t.ox + sway
        local ty   = self.y + self.radius -10  -- hang from bottom of body

        if self.tentacleImg then
            local iw     = self.tentacleImg:getWidth()
            local ih     = self.tentacleImg:getHeight()
            local scaleX = (t.flipped and -1 or 1) * (t.width / iw)
            local scaleY = t.length / ih
            love.graphics.setColor(r, g, b, a * 0.85)
            -- origin at top-centre so it hangs downward from ty
            love.graphics.draw(self.tentacleImg, tx, ty, 0, scaleX, scaleY, iw / 2, 0)
        else
            love.graphics.setColor(r, g, b, a * 0.7)
            love.graphics.rectangle("fill", tx - t.width / 2, ty, t.width, t.length)
        end
    end

    -- Body dome
    if self.headImg then
        local iw    = self.headImg:getWidth()
        local ih    = self.headImg:getHeight()
        local scale = (self.radius * 2.5) / iw
        love.graphics.setColor(r, g, b, a)
        love.graphics.draw(self.headImg, self.x, self.y, 0, scale, scale, iw / 2, ih / 2)
    else
        love.graphics.setColor(r, g, b, a)
        love.graphics.circle("fill", self.x, self.y, self.radius)
        love.graphics.setColor(math.min(1, r+0.25), math.min(1, g+0.15), math.min(1, b+0.15), 0.35)
        love.graphics.circle("fill", self.x - self.radius*0.22, self.y - self.radius*0.22, self.radius*0.45)
    end
end

return Jellyfish
