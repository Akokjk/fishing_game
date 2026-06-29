local function inSandCloud(x, y)
    for _, c in ipairs(sandClouds) do
        local dx = x - c.x
        local dy = y - c.y
        if dx*dx + dy*dy < c.radius * c.radius then return true end
    end
    return false
end

return function(agent, blackboard)
    if not blackboard.predator then return false end
    if blackboard.predator.y < blackboard.waterTop then return false end
    if inSandCloud(agent.x, agent.y) then return false end
    local dx = blackboard.predator.x - agent.x
    local dy = blackboard.predator.y - agent.y
    return dx*dx + dy*dy < agent.perceptionRadius^2
end
