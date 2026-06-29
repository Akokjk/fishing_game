return function(agent, blackboard)
    if not blackboard then return false end
    local jumpZone = 160   -- px below waterline where jumping is viable
    return agent.y < blackboard.waterTop + jumpZone
end
