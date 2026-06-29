return function(agent, blackboard)
    return (agent.hideTimer or 0) > 0
        and agent.hidingAt ~= nil
        and not agent.hidingAt.isMoving
end
