local ENERGY_DRAIN = 22   -- per second while thrashing

return function(agent, blackboard)
    local dt = blackboard.dt or 0

    if agent.energy < 1 then
        return "FAILURE"   -- too tired — fall through to Flee
    end

    agent.isThrashing = true
    agent.energy = math.max(0, agent.energy - ENERGY_DRAIN * dt)

    agent.thrashPuffTimer = (agent.thrashPuffTimer or 0) - dt
    if agent.thrashPuffTimer <= 0 then
        agent.thrashPuffTimer = 0.12

        local n = math.random(8, 14)
        for _ = 1, n do
            table.insert(sandParticles, {
                x      = agent.x + (math.random() - 0.5) * 40,
                y      = agent.y + (math.random() - 0.5) * 20,
                radius = 18 + math.random() * 30,
                alpha  = 0.55 + math.random() * 0.3,
                fade   = 0.18 + math.random() * 0.18,
                vx     = (math.random() - 0.5) * 80,
                vy     = -30 - math.random() * 60,
            })
        end

        table.insert(sandClouds, {
            x         = agent.x,
            y         = agent.y,
            radius    = 20,
            maxRadius = 110 + math.random() * 40,
            alpha     = 0.7,
            fade      = 0.22,
        })
    end

    return "RUNNING"
end
