return function(agent, blackboard)
    agent.mouthOpen = true
    local forceX, forceY = agent:steerToward(blackboard.predator.x, blackboard.predator.y)
    agent:applyForce(forceX * 1.5, forceY * 1.5)
    return "RUNNING"
end
