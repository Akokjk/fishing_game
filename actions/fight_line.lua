return function(agent, blackboard)
    -- Steer hard toward the sand floor, fighting against being reeled to the surface
    local targetX = agent.x
    local targetY = blackboard.screenHeight - (blackboard.sandHeight or 55) - 20
    local fx, fy = agent:steerToward(targetX, targetY)
    agent:applyForce(fx * 2.5, fy * 2.5)
    return "RUNNING"
end
