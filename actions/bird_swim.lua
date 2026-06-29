-- Underwater: slow down from dive momentum, try to snatch a fish, then signal escape.
local CATCH_RADIUS = 18

return function(agent, blackboard)
    local dt = blackboard.dt or 0

    agent.isDiving = false          -- dive is over the moment we're underwater
    agent.subTimer = (agent.subTimer or 0) - dt

    -- Bleed off dive speed
    agent.vx = agent.vx * (1 - 2.5 * dt)
    agent.vy = agent.vy * (1 - 3.5 * dt)

    -- Try to snatch a fish
    if not agent.hasFish then
        local school = blackboard.school
        if school then
            for i = #school, 1, -1 do
                local f  = school[i]
                local dx = f.x - agent.x
                local dy = f.y - agent.y
                if dx*dx + dy*dy < CATCH_RADIUS * CATCH_RADIUS then
                    table.remove(school, i)
                    agent.hasFish = true
                    break
                end
            end
        end
    end

    -- Commit to escape when fish caught or time expired
    if agent.subTimer <= 0 or agent.hasFish then
        agent.isEscaping = true
        agent.vy         = -480
        return "SUCCESS"
    end

    return "RUNNING"
end
