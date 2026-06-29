local PUFF_DURATION = 3.5

return function(agent, blackboard)
    agent.debugAction = "Puff"
    if not agent.isPuffed then
        agent.isPuffed   = true
        agent.puffTimer  = PUFF_DURATION
        -- Slow to a near-stop when puffing up
        agent.vx = agent.vx * 0.2
        agent.vy = agent.vy * 0.2
    end

    agent.puffTimer = agent.puffTimer - (blackboard.dt or 0)
    if agent.puffTimer <= 0 then
        agent.isPuffed = false
    end

    return "RUNNING"
end
