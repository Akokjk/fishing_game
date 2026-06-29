local FishBase = require("fish_base")
local BT       = require("behavior_tree")

local IsUnderwater = require("conditions.bird_is_underwater")
local IsDiving     = require("conditions.bird_is_diving")
local IsEscaping   = require("conditions.bird_is_escaping")

local Glide  = require("actions.bird_glide")
local Dive   = require("actions.bird_dive")
local Swim   = require("actions.bird_swim")
local Escape = require("actions.bird_escape")

local Bird = setmetatable({}, {__index = FishBase})
Bird.__index = Bird

function Bird.new(x, y)
    local self = FishBase.new(x, y)
    setmetatable(self, Bird)

    self.vx          = 160 * (math.random() < 0.5 and 1 or -1)
    self.vy          = 0
    self.maxSpeed    = 800   -- high ceiling; actions control speed directly
    self.maxForce    = 0     -- actions bypass steering forces
    self.size        = 14
    self.image       = nil   -- set externally

    -- Glide state
    self.glideDir    = self.vx > 0 and 1 or -1
    self.glideTimer  = math.random() * 6   -- stagger so birds don't all dive at once
    self.bobPhase    = math.random() * math.pi * 2

    -- Dive / underwater / escape flags
    self.isDiving    = false
    self.divTargetX  = 0
    self.subTimer    = 0
    self.isEscaping  = false
    self.hasFish     = false

    -- BT brain
    --   Priority 1: escaping water (overrides everything)
    --   Priority 2: swimming underwater (after dive)
    --   Priority 3: diving (committed plunge)
    --   Priority 4: glide (default; scans and commits to dive when ready)
    self.brain = BT.Selector:new({
        BT.Sequence:new({
            BT.Condition:new(IsEscaping),
            BT.Action:new(Escape),
        }),
        BT.Sequence:new({
            BT.Condition:new(IsUnderwater),
            BT.Action:new(Swim),
        }),
        BT.Sequence:new({
            BT.Condition:new(IsDiving),
            BT.Action:new(Dive),
        }),
        BT.Action:new(Glide),
    })

    return self
end

-- Override wrapEdges: birds live above water so skip the waterTop airborne logic.
-- Only horizontal wrap and a hard sky ceiling are needed; sand floor is a safety net.
function Bird:wrapEdges(blackboard)
    if not blackboard then return end

    -- Horizontal wrap
    if self.x < -30 then
        self.x = blackboard.screenWidth + 30
    elseif self.x > blackboard.screenWidth + 30 then
        self.x = -30
    end

    -- Hard sky ceiling
    if self.y < 5 then
        self.y  = 5
        self.vy = math.abs(self.vy)
    end

    -- Sand floor safety (bird should never reach this, but just in case)
    local sandFloor = (blackboard.screenHeight - (blackboard.sandHeight or 0)) - 10
    if self.y > sandFloor then
        self.y  = sandFloor
        self.vy = -math.abs(self.vy) * 0.5
    end
end

-- Override avoidOverlap: only separate from other birds, not from fish.
function Bird:avoidOverlap(blackboard)
    if not blackboard or not blackboard.birds then return end
    local r = self.size + 4
    for _, other in ipairs(blackboard.birds) do
        if other ~= self then
            local dx = self.x - other.x
            local dy = self.y - other.y
            local d2 = dx*dx + dy*dy
            if d2 < (r*2)^2 and d2 > 0 then
                local d = math.sqrt(d2)
                local push = (r*2 - d) * 0.3
                self.x = self.x + (dx/d) * push
                self.y = self.y + (dy/d) * push
            end
        end
    end
end

function Bird:isUnderwater(waterTop)
    return self.y >= waterTop
end

function Bird:draw()
    if not self.image then return end
    local iw    = self.image:getWidth()  / 2
    local ih    = self.image:getHeight() / 2
    local scale = (self.size * 2) / self.image:getWidth()

    local spd = math.sqrt(self.vx^2 + self.vy^2)
    -- Head is on LEFT of PNG: atan2(vy,vx) - pi rotates the left-facing sprite
    -- to align its head with the current velocity direction.
    local angle = spd > 5
        and (math.atan2(self.vy, self.vx) - math.pi)
        or  (self.glideDir >= 0 and -math.pi or 0)

    if self.stunTimer > 0 then
        love.graphics.setColor(0.6, 0.2, 1.0)
    else
        love.graphics.setColor(1, 1, 1)
    end
    love.graphics.draw(self.image, self.x, self.y, angle, scale, scale, iw, ih)
end

return Bird
