local ENERGY_COST  = 40
local COOLDOWN     = 5.0   -- seconds before fish can jump again

return function(agent, blackboard)
    if agent.energy < ENERGY_COST or agent.jumpCooldown > 0 then
        return "FAILURE"   -- exhausted or still cooling down — try next BT branch
    end

    agent.energy       = agent.energy - ENERGY_COST
    agent.jumpCooldown = COOLDOWN

    local threat  = agent.currentThreat or blackboard.predator
    local fleeVx  = 0
    if threat then
        local dx = agent.x - threat.x
        fleeVx = (dx >= 0 and 1 or -1) * agent.maxSpeed * 0.8
    end

    agent.vx = agent.vx * 0.4 + fleeVx * 0.6
    agent.vy = -agent.maxSpeed * 0.1   -- hard upward kick

    return "SUCCESS"
end
