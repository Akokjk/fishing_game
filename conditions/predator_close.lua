return function(agent, blackboard)
    if not blackboard.predator then return false end
    local dx = agent.x - blackboard.predator.x
    local dy = agent.y - blackboard.predator.y
    return dx*dx + dy*dy < 1600  -- 40px radius
end
