-- Slow figure-eight hover: gentle horizontal wander + vertical sine bob
return function(agent, blackboard)
    agent.debugAction = "HoverSwim"
    local dt = blackboard.dt or 0
    agent.hoverPhase = (agent.hoverPhase or math.random() * math.pi * 2) + dt * 0.9
    local tx = agent.x + math.cos(agent.hoverPhase) * 60
    local ty = agent.hoverY or agent.y
    agent.hoverY = agent.hoverY or agent.y  -- lock baseline on first call

    local sx, sy = agent:steerToward(tx, ty + math.sin(agent.hoverPhase * 2) * 30)
    agent:applyForce(sx * 0.4, sy * 0.4)
    return "RUNNING"
end
