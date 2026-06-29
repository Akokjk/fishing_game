return function(agent, blackboard)
    if not blackboard then return false end
    local dx = agent.x - blackboard.cursorX
    local dy = agent.y - blackboard.cursorY
    return dx*dx + dy*dy < (agent.size * 1.4)^2
end
