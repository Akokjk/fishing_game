-- Slowly rotate heading toward the nearest threat (cursor or predator fish).
-- Intended for use while puffed — keeps the spiky front aimed at danger.
return function(agent, blackboard)
    agent.debugAction = "FaceClosestPredator"
    local dt = blackboard.dt or 0

    -- Cursor is preferred if within perception range; otherwise nearest in-range predator
    local r2 = (agent.perceptionRadius or 180)^2
    local threatX, threatY

    local cdx = blackboard.cursorX - agent.x
    local cdy = blackboard.cursorY - agent.y
    if cdx*cdx + cdy*cdy <= r2 then
        threatX, threatY = blackboard.cursorX, blackboard.cursorY
    elseif blackboard.predators then
        local nearestD2 = math.huge
        for _, p in ipairs(blackboard.predators) do
            local dx = p.x - agent.x
            local dy = p.y - agent.y
            local d2 = dx*dx + dy*dy
            if d2 <= r2 and d2 < nearestD2 then
                nearestD2 = d2
                threatX, threatY = p.x, p.y
            end
        end
    end

    if not threatX then return "FAILURE" end

    local dx = threatX - agent.x
    local dy = threatY - agent.y
    local d  = math.sqrt(dx*dx + dy*dy)
    if d < 1 then return "RUNNING" end

    -- Gently blend velocity direction toward the threat (slow turn)
    local spd   = math.max(8, math.sqrt(agent.vx^2 + agent.vy^2))
    local blend = 1 - math.exp(-6.0 * dt)
    agent.vx = agent.vx + (dx/d * spd - agent.vx) * blend
    agent.vy = agent.vy + (dy/d * spd - agent.vy) * blend

    return "RUNNING"
end
