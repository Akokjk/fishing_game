return function(agent, blackboard)
    return blackboard ~= nil and agent.y >= blackboard.waterTop
end
