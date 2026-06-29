return function(agent, blackboard)
    local krill = blackboard and blackboard.krill
    if not krill then return false end
    local r2 = agent.perceptionRadius^2
    for _, k in ipairs(krill) do
        local dx = k.x - agent.x
        local dy = k.y - agent.y
        if dx*dx + dy*dy < r2 then
            agent.targetKrill = k
            return true
        end
    end
    agent.targetKrill = nil
    return false
end
