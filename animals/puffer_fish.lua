local FishBase = require("fish_base")
local BT       = require("behavior_tree")
local C        = require("conditions")
local A        = require("actions")

local PufferFish = setmetatable({}, {__index = FishBase})
PufferFish.__index = PufferFish

local IsPuffed         = require("conditions.is_puffed")
local CaughtByPlayer   = require("conditions.caught_by_player")
local SeesKrill        = require("conditions.sees_krill")
local SeesPredatorCone = require("conditions.puffer_sees_predator")
local FlapTail       = require("actions.flap_tail")
local FleeFromPred   = require("actions.flee_from_predator")
local Puff           = require("actions.puff")
local SlowSwim       = require("actions.slow_swim")
local FightPlayer    = require("actions.fight_player")
local HoverSwim      = require("actions.hover_swim")
local EatKrillPuff          = require("actions.eat_krill_puffer")
local FaceClosestPredator   = require("actions.face_closest_predator")

function PufferFish.new(x, y)
    local self = FishBase.new(x, y)
    setmetatable(self, PufferFish)

    self.perceptionRadius = 180
    self.maxSpeed         = 200
    self.maxForce         = 180
    self.baseMaxSpeed     = 200
    
    self.size             = 8    -- small unpuffed radius
    self.isPuffed         = false
    self.puffTimer        = 0
    self.puffDuration     = 3.5   -- seconds fully puffed before deflating
    self.deflateTime      = 4.0   -- seconds to shrink back to normal size
    self.deflateTimer     = 0
    self._prevCursorDist  = nil   -- initialised on first update frame
    self.puffCooldown     = 1.5   -- grace period on spawn so it can't puff immediately
    self.puffCooldownMax  = 6.0   -- seconds before can puff again
    self.targetKrill      = nil
    self.hoverPhase       = math.random() * math.pi * 2
    self.hoverY           = y

    self.baseColor  = { 0.9, 0.75, 0.25 }   -- warm yellow-green
    self.spineColor = { 0.95, 0.55, 0.1 }

    -- Brain matches the diagram exactly:
    --   See Predator → FlapTail / FleeFromPredator
    --   Predator Close → Puff / SlowSwim
    --   Caught By Player → FightPlayer
    --   Is Puffed → SlowSwim
    --   Sees Krill → EatKrill
    --   HoverSwim (default)
    self.brain = BT.Selector:new({
        BT.Sequence:new({
            BT.Condition:new(IsPuffed),
            BT.Action:new(FaceClosestPredator),
        }),
        BT.Sequence:new({
            BT.Condition:new(SeesPredatorCone),
            BT.Selector:new({
                BT.Action:new(FlapTail),
                BT.Action:new(FleeFromPred),
            })
        }),
        BT.Sequence:new({
            BT.Condition:new(SeesPredatorCone),
            BT.Selector:new({
                BT.Action:new(Puff),
                BT.Action:new(SlowSwim),
            })
        }),
        BT.Sequence:new({
            BT.Condition:new(CaughtByPlayer),
            BT.Action:new(FightPlayer),
        }),
        BT.Sequence:new({
            BT.Condition:new(SeesKrill),
            BT.Action:new(EatKrillPuff),
        }),
        BT.Action:new(HoverSwim),
    })

    return self
end
local viewCone = 90
local CONE_COS = math.cos(math.rad(viewCone/2))

function PufferFish:update(dt, blackboard)
    if blackboard then
        local dx = blackboard.cursorX - self.x
        local dy = blackboard.cursorY - self.y
        local d2 = dx*dx + dy*dy
        local d  = math.sqrt(d2)

        -- Check if cursor is actively approaching (distance shrinking).
        -- Skip on frame 1 (no previous distance yet) to avoid false trigger at spawn.
        local prevDist      = self._prevCursorDist
        local cursorClosing = prevDist ~= nil and d < prevDist - 0.5
        self._prevCursorDist = d

        -- Check if any predator fish is in active pursuit (velocity aimed at us)
        local predatorChasing = false
        if blackboard.predators then
            for _, p in ipairs(blackboard.predators) do
                local pdx = self.x - p.x
                local pdy = self.y - p.y
                local pd  = math.sqrt(pdx*pdx + pdy*pdy)
                if pd < self.perceptionRadius and pd > 0 then
                    local pspd = math.sqrt(p.vx^2 + p.vy^2)
                    if pspd > 5 then
                        -- Dot of predator heading with direction toward puffer
                        local dot = (p.vx/pspd)*(pdx/pd) + (p.vy/pspd)*(pdy/pd)
                        if dot > 0.5 then   -- heading within ~60° toward us
                            predatorChasing = true
                            break
                        end
                    end
                end
            end
        end

        -- Puff only when threat is in the forward cone AND actively approaching
        if not self.isPuffed and self.deflateTimer <= 0 and self.puffCooldown <= 0
           and (cursorClosing or predatorChasing) then
            local spd = math.sqrt(self.vx^2 + self.vy^2)
            local hx  = spd > 5 and self.vx/spd or 1
            local hy  = spd > 5 and self.vy/spd or 0
            if d > 0 and d < self.perceptionRadius and (dx/d)*hx + (dy/d)*hy > CONE_COS then
                self.isPuffed     = true
                self.puffTimer    = self.puffDuration
                self.deflateTimer = 0
                self.vx = self.vx * 0.2
                self.vy = self.vy * 0.2
            end
        end
    end

    -- Tick puff hold timer; when it expires begin deflating
    if self.isPuffed then
        self.puffTimer = self.puffTimer - dt
        if self.puffTimer <= 0 then
            self.isPuffed     = false
            self.deflateTimer = self.deflateTime
            self.puffCooldown = self.puffCooldownMax
        end
    end

    -- Tick deflate and cooldown timers
    if self.deflateTimer > 0 then
        self.deflateTimer = math.max(0, self.deflateTimer - dt)
    end
    if self.puffCooldown > 0 then
        self.puffCooldown = math.max(0, self.puffCooldown - dt)
    end

    -- Speed: crawl while inflated or deflating, normal when fully deflated
    local inflated = self.isPuffed or self.deflateTimer > 0
    if inflated then
        self.maxSpeed = self.baseMaxSpeed * 0.15
        self.maxForce = self.baseMaxSpeed * 0.15
    else
        self.maxSpeed = self.baseMaxSpeed
        self.maxForce = self.baseMaxSpeed * 0.9
    end

    local prevVx, prevVy = self.vx, self.vy
    FishBase.update(self, dt, blackboard)

    -- -- When puffed/deflating, resist direction changes so it can't spin freely
    -- if self.isPuffed or self.deflateTimer > 0 then
    --     local blend = 1 - math.exp(-5.0 * dt)
    --     self.vx = prevVx + (self.vx - prevVx) * blend
    --     self.vy = prevVy + (self.vy - prevVy) * blend
    -- end

    -- Separate from other puffer fish
    local puffScale = (self.isPuffed or self.deflateTimer > 0) and 3.5 or 1
    local myR = self.size * puffScale
    for _, other in ipairs(pufferList) do
        if other ~= self then
            local otherScale = (other.isPuffed or other.deflateTimer > 0) and 3.5 or 1
            local dx   = self.x - other.x
            local dy   = self.y - other.y
            local d2   = dx*dx + dy*dy
            local minD = myR + other.size * otherScale + 4
            if d2 < minD*minD and d2 > 0 then
                local d    = math.sqrt(d2)
                local push = (minD - d) * 0.5
                self.x = self.x + (dx/d) * push
                self.y = self.y + (dy/d) * push
                local dot = self.vx*(dx/d) + self.vy*(dy/d)
                if dot < 0 then
                    self.vx = self.vx - dot*(dx/d)
                    self.vy = self.vy - dot*(dy/d)
                end
            end
        end
    end
end

function PufferFish:draw()
    local puffScale = 3.5
    local r
    if self.isPuffed then
        r = self.size * puffScale
    elseif self.deflateTimer > 0 then
        -- Lerp from full puff back to normal as deflateTimer counts down
        local t = self.deflateTimer / self.deflateTime   -- 1 = just started, 0 = done
        r = self.size * (1 + (puffScale - 1) * t)
    else
        r = self.size
    end
    local x, y = self.x, self.y

    -- View cone (debug only)
    if debugMode then
        local spd = math.sqrt(self.vx^2 + self.vy^2)
        local hx  = spd > 5 and (self.vx/spd) or 1
        local hy  = spd > 5 and (self.vy/spd) or 0
        local coneLen   = self.perceptionRadius
        local halfAngle = math.acos(CONE_COS)
        local angle1    = math.atan2(hy, hx) - halfAngle
        local angle2    = math.atan2(hy, hx) + halfAngle
        local ex1, ey1  = math.cos(angle1), math.sin(angle1)
        local ex2, ey2  = math.cos(angle2), math.sin(angle2)
        love.graphics.setColor(1, 0.85, 0.1, 0.1)
        love.graphics.polygon("fill",
            x, y,
            x + ex1 * coneLen, y + ey1 * coneLen,
            x + ex2 * coneLen, y + ey2 * coneLen
        )
        love.graphics.setColor(1, 0.85, 0.1, 0.25)
        love.graphics.setLineWidth(1)
        love.graphics.line(x, y, x + ex1 * coneLen, y + ey1 * coneLen)
        love.graphics.line(x, y, x + ex2 * coneLen, y + ey2 * coneLen)
    end

    -- Body
    local br, bg, bb = self.baseColor[1], self.baseColor[2], self.baseColor[3]
    love.graphics.setColor(br, bg, bb)
    love.graphics.circle("fill", x, y, r)

    -- Belly highlight
    love.graphics.setColor(1, 1, 0.8, 0.5)
    love.graphics.circle("fill", x, y + r * 0.15, r * 0.6)

    -- Spines visible while puffed or deflating
    if self.isPuffed or self.deflateTimer > 0 then
        love.graphics.setColor(self.spineColor)
        love.graphics.setLineWidth(1.5)
        local spineCount = 12
        for i = 0, spineCount - 1 do
            local angle = (i / spineCount) * math.pi * 2
            local sx = x + math.cos(angle) * r
            local sy = y + math.sin(angle) * r
            love.graphics.line(sx, sy, sx + math.cos(angle) * 8, sy + math.sin(angle) * 8)
        end
    end

    -- Head is in velocity direction
    local spd = math.sqrt(self.vx^2 + self.vy^2)
    local ex = spd > 5 and (self.vx / spd) or 1
    local ey = spd > 5 and (self.vy / spd) or 0
    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.circle("fill", x + ex * r * 0.55, y + ey * r * 0.2, r * 0.18)
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", x + ex * r * 0.55 + 1, y + ey * r * 0.2 - 1, r * 0.07)

    -- Tail safe zone indicator (visible while inflated or deflating); tail is behind head
    if self.isPuffed or self.deflateTimer > 0 then
        local tailX = x - ex * r * 0.75
        local tailY = y - ey * r * 0.75  -- behind = -velocity
        local tailR = r * 0.35
        love.graphics.setColor(0.4, 1, 0.4, 0.35)
        love.graphics.circle("fill", tailX, tailY, tailR)
        love.graphics.setColor(0.4, 1, 0.4, 0.7)
        love.graphics.circle("line", tailX, tailY, tailR)
    end

    -- Tail fin
    local tx = x - ex * r * 0.85
    local ty = y - ey * r * 0.85
    local perpX = -ey * r * 0.55
    local perpY =  ex * r * 0.55
    love.graphics.setColor(br, bg * 0.8, bb * 0.5, 0.85)
    love.graphics.polygon("fill",
        tx, ty,
        tx - ex * r * 0.45 + perpX, ty - ey * r * 0.45 + perpY,
        tx - ex * r * 0.45 - perpX, ty - ey * r * 0.45 - perpY
    )
end

return PufferFish
