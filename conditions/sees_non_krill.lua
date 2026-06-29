return function(agent, blackboard)
    local dangerRadius = 80
    local distToCursor = math.sqrt(
        (agent.x - blackboard.cursorX)^2 + (agent.y - blackboard.cursorY)^2
    )
    if distToCursor < dangerRadius then
        agent.currentThreat = { x = blackboard.cursorX, y = blackboard.cursorY }
        return true
    end
    for _, other in ipairs(blackboard.allFish) do
        if other.species ~= "Krill" then
            local dist = math.sqrt((agent.x - other.x)^2 + (agent.y - other.y)^2)
            if dist < dangerRadius then
                agent.currentThreat = other
                return true
            end
        end
    end
    return false
end
