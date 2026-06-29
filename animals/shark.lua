local BT = require("behavior_tree")

local Shark = {}
Shark.__index = Shark

local CONE_HALF_ANGLE = math.rad(30)   -- ±30° forward cone for detection
local CONE_COS        = math.cos(CONE_HALF_ANGLE)
local VERT_TOLERANCE  = 80             -- px: only dip down if prey is this far below

-- ─────────────────────────────────────────────
--  HELPERS
-- ─────────────────────────────────────────────

-- Returns the shark's current facing vector (unit)
local function heading(agent)
    local spd = math.sqrt(agent.vx^2 + agent.vy^2)
    if spd > 20 then
        return agent.vx / spd, agent.vy / spd
    end
    return agent.patrolDir, 0   -- fallback to patrol direction when nearly still
end

-- Wrap-aware shortest horizontal delta
local function shortH(ax, bx, w)
    local d = bx - ax
    if d >  w * 0.5 then d = d - w end
    if d < -w * 0.5 then d = d + w end
    return d
end

-- True if (tx,ty) is inside the shark's forward detection cone
local function inCone(agent, tx, ty)
    local dx = tx - agent.x
    local dy = ty - agent.y
    local d  = math.sqrt(dx*dx + dy*dy)
    if d == 0 then return false end
    local hx, hy = heading(agent)
    return (dx/d)*hx + (dy/d)*hy > CONE_COS
end

-- ─────────────────────────────────────────────
--  INLINE CONDITIONS
-- ─────────────────────────────────────────────

local function SeesCursor(agent, blackboard)
    local p = blackboard.predator
    if not p or p.y < blackboard.waterTop then return false end
    local dx = shortH(agent.x, p.x, blackboard.screenWidth)
    local dy = p.y - agent.y
    if dx*dx + dy*dy > agent.perceptionRadius^2 then return false end
    -- Use wrap-corrected position for cone test
    return inCone(agent, agent.x + dx, agent.y + dy)
end

local function CursorInBiteRange(agent, blackboard)
    local p = blackboard.predator
    if not p then return false end
    local dx = p.x - agent.x
    local dy = p.y - agent.y
    return dx*dx + dy*dy < agent.biteRange^2
end

local function SeesPredatorFish(agent, blackboard)
    local preds = blackboard.predators
    if not preds then return false end
    local best, bestD2 = nil, agent.perceptionRadius^2
    for _, pred in ipairs(preds) do
        local dx = shortH(agent.x, pred.x, blackboard.screenWidth)
        local dy = pred.y - agent.y
        local d2 = dx*dx + dy*dy
        if d2 < bestD2 and inCone(agent, agent.x + dx, agent.y + dy) then
            bestD2 = d2
            best   = pred
        end
    end
    agent.targetPredator = best
    return best ~= nil
end

local function PredatorInAttackRange(agent, blackboard)
    local t = agent.targetPredator
    if not t then return false end
    local dx = t.x - agent.x
    local dy = t.y - agent.y
    return dx*dx + dy*dy < agent.attackRange^2
end

local function ObstacleInPath(agent, blackboard)
    local hx, hy = heading(agent)
    local coneR   = 90
    local halfCos = math.cos(math.rad(25))
    for _, f in ipairs(blackboard.school or {}) do
        local dx = f.x - agent.x
        local dy = f.y - agent.y
        local d  = math.sqrt(dx*dx + dy*dy)
        if d > 0 and d < coneR and (dx/d)*hx + (dy/d)*hy > halfCos then return true end
    end
    for _, j in ipairs(blackboard.jellyfish or {}) do
        local dx = j.x - agent.x
        local dy = j.y - agent.y
        local d  = math.sqrt(dx*dx + dy*dy)
        if d > 0 and d < coneR and (dx/d)*hx + (dy/d)*hy > halfCos then return true end
    end
    return false
end

-- ─────────────────────────────────────────────
--  INLINE ACTIONS
-- ─────────────────────────────────────────────

local function BiteCursor(agent, blackboard)
    death = true
    return "SUCCESS"
end

local function ChaseCursorAction(agent, blackboard)
    local tx, ty = blackboard.predator.x, blackboard.predator.y
    local dx = shortH(agent.x, tx, blackboard.screenWidth)
    -- Always charge horizontally at full speed
    agent.vx = agent.vx + ((dx >= 0 and 1 or -1) * agent.maxSpeedH - agent.vx) * 0.10
    -- Creep vertically toward target — slow because maxSpeedV is low
    local dy   = ty - agent.y
    local wantVy = math.max(-agent.maxSpeedV, math.min(agent.maxSpeedV, dy * 0.6))
    agent.vy = agent.vy + (wantVy - agent.vy) * 0.04
    return "RUNNING"
end

local function PursuePredatorAction(agent, blackboard)
    local t = agent.targetPredator
    if not t then return "FAILURE" end
    local dx = shortH(agent.x, t.x, blackboard.screenWidth)
    agent.vx = agent.vx + ((dx >= 0 and 1 or -1) * agent.maxSpeedH * 0.75 - agent.vx) * 0.07
    local dy     = t.y - agent.y
    local wantVy = math.max(-agent.maxSpeedV, math.min(agent.maxSpeedV, dy * 0.6))
    agent.vy = agent.vy + (wantVy - agent.vy) * 0.04
    return "RUNNING"
end

local function AttackPredatorAction(agent, blackboard)
    local t = agent.targetPredator
    if not t then return "FAILURE" end
    for i, p in ipairs(predatorList) do
        if p == t then
            table.remove(predatorList, i)
            agent.targetPredator = nil
            if eat_sound then eat_sound:stop(); eat_sound:play() end
            break
        end
    end
    return "SUCCESS"
end

local function BulldozeAction(agent, blackboard)
    local push = 900
    for _, f in ipairs(blackboard.school or {}) do
        local dx = f.x - agent.x
        local dy = f.y - agent.y
        local d  = math.sqrt(dx*dx + dy*dy)
        if d > 0 and d < agent.bulldozeRadius then
            f.vx = f.vx + (dx/d) * push
            f.vy = f.vy + (dy/d) * push * 0.5
        end
    end
    for _, j in ipairs(blackboard.jellyfish or {}) do
        local dx = j.x - agent.x
        local dy = j.y - agent.y
        local d  = math.sqrt(dx*dx + dy*dy)
        if d > 0 and d < agent.bulldozeRadius then
            j.vx = j.vx + (dx/d) * 300
        end
    end
    return "RUNNING"
end

local function PatrolAction(agent, blackboard)
    agent.patrolTimer = (agent.patrolTimer or 0) + (blackboard.dt or 0.016)
    -- Steady horizontal cruise only — no vertical movement during patrol
    local wantVx = agent.patrolDir * agent.maxSpeedH * 0.35
    agent.vx = agent.vx + (wantVx - agent.vx) * 0.025
    -- Gentle sine bob — slow enough to respect maxSpeedV cap
    local wantVy = math.sin(agent.patrolTimer * 0.25) * agent.maxSpeedV * 0.35
    agent.vy = agent.vy + (wantVy - agent.vy) * 0.02
    return "RUNNING"
end

-- ─────────────────────────────────────────────
--  CLASS
-- ─────────────────────────────────────────────

function Shark.new(x, y)
    local self = setmetatable({}, Shark)
    self.x = x;  self.y = y
    self.vx = 0; self.vy = 0

    self.species          = "Shark"
    self.size             = 50
    self.perceptionRadius = 1000
    self.biteRange        = 20
    self.attackRange      = 60
    self.bulldozeRadius   = 75
    self.maxSpeedH        = 1500
    self.maxSpeedV        = 500   -- max downward speed
    self.stunTimer        = 0
    self.patrolDir        = (math.random() > 0.5) and 1 or -1
    self.patrolTimer      = math.random() * math.pi * 2
    self.targetPredator   = nil
    self.trail            = {}
    self.trailMaxLen      = 90
    self.color = {
        0.35 + math.random() * 0.15,
        0.40 + math.random() * 0.15,
        0.50 + math.random() * 0.20,
    }

    self.brain = BT.Selector:new({
        BT.Sequence:new({
            BT.Condition:new(SeesCursor),
            BT.Selector:new({
                BT.Sequence:new({ BT.Condition:new(CursorInBiteRange),     BT.Action:new(BiteCursor) }),
                BT.Action:new(ChaseCursorAction)
            })
        }),
        BT.Sequence:new({
            BT.Condition:new(SeesPredatorFish),
            BT.Selector:new({
                BT.Sequence:new({ BT.Condition:new(PredatorInAttackRange), BT.Action:new(AttackPredatorAction) }),
                BT.Action:new(PursuePredatorAction)
            })
        }),
        BT.Action:new(PatrolAction)
    })

    return self
end

function Shark:update(dt, blackboard)
    if self.stunTimer > 0 then
        self.stunTimer = self.stunTimer - dt
        self.vx = self.vx * (1 - 3 * dt)
        self.vy = self.vy * (1 - 3 * dt)
        self.x  = self.x  + self.vx * dt
        self.y  = self.y  + self.vy * dt
        self:wrapAndBound(blackboard)
        return
    end

    self.brain:evaluate(self, blackboard)

    -- Horizontal: full speed; Vertical: slow in both directions
    self.vx = math.max(-self.maxSpeedH, math.min(self.maxSpeedH, self.vx))
    self.vy = math.max(-self.maxSpeedV, math.min(self.maxSpeedV, self.vy))

    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt

    self:wrapAndBound(blackboard)

    -- Separate from other sharks
    for _, other in ipairs(sharkList) do
        if other ~= self then
            local dx  = self.x - other.x
            local dy  = self.y - other.y
            local d2  = dx*dx + dy*dy
            local minD = self.size + other.size
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

    -- Trail
    local t = self.trail
    table.insert(t, 1, {x = self.x, y = self.y})
    local total, keep = 0, 1
    for i = 2, #t do
        local dx = t[i-1].x - t[i].x
        local dy = t[i-1].y - t[i].y
        total = total + math.sqrt(dx*dx + dy*dy)
        if total > self.trailMaxLen then break end
        keep = i
    end
    for i = #t, keep + 1, -1 do t[i] = nil end
end

function Shark:wrapAndBound(blackboard)
    if not blackboard then return end
    local w = blackboard.screenWidth
    local h = blackboard.screenHeight
    -- Horizontal wrap — velocity preserved, creating the high-speed wrap-around
    if self.x < -self.size then self.x = w + self.size end
    if self.x > w + self.size then self.x = -self.size end
    -- Vertical: wrap bottom→top so the shark can descend indefinitely in loops
    local waterTop = blackboard.waterTop + self.size
    local floor    = h - (sandHeight or 55) - self.size * 0.5
    if self.y < waterTop then self.y = waterTop; self.vy =  math.abs(self.vy) * 0.3 end
    if self.y > floor    then self.y = floor;    self.vy = -math.abs(self.vy) * 0.3 end
end

function Shark:draw()
    local hx, hy = heading(self)
    local angle  = math.atan2(hy, hx)
    local s      = self.size
    local r, g, b = self.color[1], self.color[2], self.color[3]

    -- Detection cone (drawn in world space before push so it sits behind body)
    local coneLen = self.perceptionRadius
    local halfW   = coneLen * math.tan(CONE_HALF_ANGLE)
    -- Tip of cone is at the nose: self.x + hx*s, self.y + hy*s
    local nx = self.x + hx * s
    local ny = self.y + hy * s
    -- Two perpendicular axes
    local px, py = -hy, hx   -- perpendicular to heading
    love.graphics.setColor(r, g, b, 0.07)
    -- love.graphics.polygon("fill",
    --     nx,                  ny,
    --     nx + hx*coneLen + px*halfW,  ny + hy*coneLen + py*halfW,
    --     nx + hx*coneLen - px*halfW,  ny + hy*coneLen - py*halfW
    -- )
    -- Thin outline
    love.graphics.setColor(r, g, b, 0.18)
    love.graphics.setLineWidth(1)
    --love.graphics.line(nx, ny, nx + hx*coneLen + px*halfW, ny + hy*coneLen + py*halfW)
    --love.graphics.line(nx, ny, nx + hx*coneLen - px*halfW, ny + hy*coneLen - py*halfW)

    -- Trail
    if #self.trail >= 2 then
        love.graphics.setLineWidth(2)
        for i = 1, #self.trail - 1 do
            local a = (1 - i / #self.trail) * 0.55
            love.graphics.setColor(r*0.6, g*0.6, b*0.85, a)
            love.graphics.line(self.trail[i].x, self.trail[i].y,
                               self.trail[i+1].x, self.trail[i+1].y)
        end
        love.graphics.setLineWidth(1)
    end

    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(angle)

    -- Body
    love.graphics.setColor(r, g, b)
    love.graphics.polygon("fill",
         s,      0,
         s*0.3,  s*0.22,
        -s*0.6,  s*0.18,
        -s,      0,
        -s*0.6, -s*0.18,
         s*0.3, -s*0.22
    )
    -- Dorsal fin
    love.graphics.setColor(r*0.75, g*0.75, b*0.75)
    love.graphics.polygon("fill",
         s*0.15, -s*0.22,
        -s*0.1,  -s*0.55,
        -s*0.4,  -s*0.22
    )
    -- Tail fork
    love.graphics.polygon("fill", -s*0.7, 0, -s, s*0.38, -s*0.85, 0)
    love.graphics.polygon("fill", -s*0.7, 0, -s,-s*0.38, -s*0.85, 0)
    -- Eye
    love.graphics.setColor(0.05, 0.05, 0.05)
    love.graphics.circle("fill", s*0.55, -s*0.1, s*0.07)

    -- Bite zone circle at the nose tip
    love.graphics.setColor(1, 0.15, 0.15, 0.35)
    --love.graphics.circle("fill", s, 0, self.biteRange)
    love.graphics.setColor(1, 0.15, 0.15, 0.7)
    love.graphics.setLineWidth(1)
    --love.graphics.circle("line", s, 0, self.biteRange)

    love.graphics.pop()
end

return Shark
