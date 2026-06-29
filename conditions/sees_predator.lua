return function(agent, blackboard)
    if blackboard.predator then
        local dx = agent.x - blackboard.predator.x
        local dy = agent.y - blackboard.predator.y
        if dx*dx + dy*dy < agent.perceptionRadius^2 then
            agent.currentThreat = blackboard.predator
            return true
        end
    end
    if blackboard.predators then
        for _, p in ipairs(blackboard.predators) do
            local dx = agent.x - p.x
            local dy = agent.y - p.y
            if dx*dx + dy*dy < agent.perceptionRadius^2 then
                agent.currentThreat = p
                return true
            end
        end
    end
    if blackboard.sharks then
        local sharkR2 = (agent.perceptionRadius * 1.2)^2   -- sharks are scarier, seen from farther
        for _, shark in ipairs(blackboard.sharks) do
            local dx = agent.x - shark.x
            local dy = agent.y - shark.y
            if dx*dx + dy*dy < sharkR2 then
                agent.currentThreat = shark
                return true
            end
        end
    end
    if blackboard.jellyfish then
        local jellyR2 = (agent.perceptionRadius * 0.8)^2
        for _, jelly in ipairs(blackboard.jellyfish) do
            local dx = agent.x - jelly.x
            local dy = agent.y - jelly.y
            if dx*dx + dy*dy < jellyR2 then
                agent.currentThreat = jelly
                return true
            end
        end
    end
    if blackboard.movingRocks then
        local scatterR2 = (agent.perceptionRadius * 0.6)^2
        for _, rock in ipairs(blackboard.movingRocks) do
            local dx = agent.x - rock.x
            local dy = agent.y - rock.y
            if dx*dx + dy*dy < scatterR2 then
                agent.currentThreat = rock
                return true
            end
        end
    end
    return false
end
