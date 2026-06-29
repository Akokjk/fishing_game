-- Plunge downward toward divTargetX. When the bird crosses the waterline,
-- clears isDiving and sets subTimer so BirdSwim takes over next frame.
local DIVE_VY_MAX = 750
local DIVE_VX     = 160

return function(agent, blackboard)
    local dt       = blackboard.dt or 0
    local waterTop = blackboard.waterTop or 0

    -- Accelerate downward
    agent.vy = math.min(agent.vy + 1400 * dt, DIVE_VY_MAX)

    -- Steer horizontally toward target x
    local targetVx = DIVE_VX * (agent.glideDir or 1)
    agent.vx = agent.vx + (targetVx - agent.vx) * 4 * dt

    -- Hit the water
    if agent.y >= waterTop then
        agent.y        = waterTop
        agent.isDiving  = false
        agent.subTimer  = 0.6 + math.random() * 0.5
        return "SUCCESS"
    end

    return "RUNNING"
end
