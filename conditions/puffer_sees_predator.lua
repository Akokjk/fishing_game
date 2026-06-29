-- Puffer-specific predator detection: requires the threat to be inside
-- the forward view cone (CONE_COS = cos(45°)) AND within perceptionRadius.
-- The cursor counts as a predator threat.
local CONE_COS = math.cos(math.rad(45))

return function(agent, blackboard)
    local spd = math.sqrt(agent.vx^2 + agent.vy^2)
    local hx  = spd > 2 and agent.vx / spd or 1
    local hy  = spd > 2 and agent.vy / spd or 0

    local function inCone(tx, ty)
        local dx = tx - agent.x
        local dy = ty - agent.y
        local d2 = dx*dx + dy*dy
        if d2 > agent.perceptionRadius^2 then return false end
        local d = math.sqrt(d2)
        return d > 0 and (dx/d)*hx + (dy/d)*hy > CONE_COS
    end

    -- Cursor
    if inCone(blackboard.cursorX, blackboard.cursorY) then
        agent.currentThreat = { x = blackboard.cursorX, y = blackboard.cursorY }
        return true
    end

    -- Predator fish
    if blackboard.predators then
        for _, p in ipairs(blackboard.predators) do
            if inCone(p.x, p.y) then
                agent.currentThreat = p
                return true
            end
        end
    end

    -- Sharks
    if blackboard.sharks then
        for _, s in ipairs(blackboard.sharks) do
            if inCone(s.x, s.y) then
                agent.currentThreat = s
                return true
            end
        end
    end

    return false
end
