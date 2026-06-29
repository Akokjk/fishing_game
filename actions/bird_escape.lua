-- Rocket upward out of the water. Once clear of the surface, resets to glide.
local ESCAPE_VY   = -480
local GLIDE_SPEED = 160

return function(agent, blackboard)
    local dt       = blackboard.dt or 0
    local waterTop = blackboard.waterTop or 0

    -- Accelerate upward
    agent.vy = math.max(agent.vy - 600 * dt, ESCAPE_VY)

    -- Restore horizontal glide speed
    local targetVx = GLIDE_SPEED * (agent.glideDir or 1)
    agent.vx = agent.vx + (targetVx - agent.vx) * 2 * dt

    -- Clear the surface
    if agent.y < waterTop - 35 then
        agent.isEscaping = false
        agent.hasFish    = false
        agent.vy         = -20
        agent.glideTimer = 3 + math.random() * 4
        return "SUCCESS"
    end

    return "RUNNING"
end
