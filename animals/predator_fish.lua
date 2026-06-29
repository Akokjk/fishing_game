local FishBase = require("fish_base")
local BT = require("behavior_tree")
local C = require("conditions")
local A = require("actions")

local PredatorFish = setmetatable({}, {__index = FishBase})
PredatorFish.__index = PredatorFish

function PredatorFish.new(x, y)
    local self = FishBase.new(x, y)
    setmetatable(self, PredatorFish)

    self.species          = "Predator"
    self.mouthOpen       = false
    self.mouthCloseTimer = 0
    self.trail           = {}   -- {x, y} history for trailing lines
    self.trailMaxLen     = 50   -- pixels of trail
    self.perceptionRadius = 220
    self.maxSpeed = 500
    self.maxForce = 500
    self.size = 20  -- 20% bigger than original 10

    self.color = {
        0.6 + math.random() * 0.4,
        math.random() * 0.4,
        math.random() * 0.5
    }

    self.brain = BT.Selector:new({
        BT.Sequence:new({
            BT.Condition:new(C.SeesCursor),
            BT.Action:new(A.ChaseCursor)
        }),
        BT.Sequence:new({
            BT.Condition:new(C.SeesSmallFish),
            BT.Action:new(A.ChasePrey)
        }),
        BT.Action:new(A.Swim)
    })

    return self
end

function PredatorFish:updateTrail()
    local trail = self.trail
    table.insert(trail, 1, {x = self.x, y = self.y})

    -- Trim so total arc length stays under trailMaxLen
    local totalLen = 0
    local keep = 1
    for i = 2, #trail do
        local dx = trail[i-1].x - trail[i].x
        local dy = trail[i-1].y - trail[i].y
        totalLen = totalLen + math.sqrt(dx*dx + dy*dy)
        if totalLen > self.trailMaxLen then break end
        keep = i
    end
    for i = #trail, keep + 1, -1 do
        trail[i] = nil
    end
end

function PredatorFish:fleeFromSharks(blackboard)
    if not blackboard.sharks then return end
    local fleeRadius2 = 320^2
    for _, shark in ipairs(blackboard.sharks) do
        local dx = self.x - shark.x
        local dy = self.y - shark.y
        local d2 = dx*dx + dy*dy
        if d2 < fleeRadius2 and d2 > 0 then
            local d  = math.sqrt(d2)
            local sx, sy = self:steerToward(self.x + dx/d * 200, self.y + dy/d * 200)
            self:applyForce(sx * 3.0, sy * 3.0)
        end
    end
end

function PredatorFish:update(dt, blackboard)
    if self.mouthCloseTimer > 0 then
        self.mouthCloseTimer = self.mouthCloseTimer - dt
        self.mouthOpen = false
        self:fleeFromSharks(blackboard)
        FishBase.update(self, dt, blackboard)
        self.mouthOpen = false
        self:updateTrail()
        return
    end
    self.mouthOpen = false
    self:fleeFromSharks(blackboard)
    FishBase.update(self, dt, blackboard)
    self:updateTrail()
end

-- Called by update.lua when this predator lands a bite on a small fish
function PredatorFish:bite()
    self.mouthCloseTimer = 0.3
    self.mouthOpen       = false
end


function PredatorFish:draw()
    -- Bite zone (debug only)
    if debugMode then
        local spd = math.sqrt(self.vx^2 + self.vy^2)
        if spd > 5 then
            local hx = self.vx / spd
            local hy = self.vy / spd
            local nx = self.x + hx * self.size
            local ny = self.y + hy * self.size
            love.graphics.setColor(1, 0.1, 0.1, 0.18)
            love.graphics.circle("fill", nx, ny, predatorBiteRadius)
            love.graphics.setColor(1, 0.1, 0.1, 0.55)
            love.graphics.setLineWidth(1)
            love.graphics.circle("line", nx, ny, predatorBiteRadius)
        end
    end

    -- Trailing lines: fade from opaque at head to transparent at tail
    if #self.trail >= 2 then
        for i = 1, #self.trail - 1 do
            local alpha = 1 - (i / #self.trail)
            love.graphics.setColor(1, 0.1, 0.1, alpha * 0.7)
            love.graphics.setLineWidth(1.5)
            love.graphics.line(self.trail[i].x, self.trail[i].y,
                               self.trail[i+1].x, self.trail[i+1].y)
        end
        love.graphics.setLineWidth(1)
    end

    local img = (self.mouthOpen and self.imagemouth) or self.image
    if img then
        local angle = math.atan2(self.vy, self.vx)
        local scale = (self.size * 2) / img:getWidth()
        love.graphics.setColor(self.color[1], self.color[2], self.color[3])
        love.graphics.draw(img, self.x, self.y, angle, -scale, scale,
            img:getWidth() / 2, img:getHeight() / 2)
    else
        love.graphics.setColor(1, 0, 0)
        love.graphics.circle("fill", self.x, self.y, self.size)
    end
end

return PredatorFish
