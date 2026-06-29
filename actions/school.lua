return function(agent, blackboard)
    local flock = blackboard.allFish
    if agent.species == "Krill" then flock = blackboard.krill end

    local perception   = agent.perceptionRadius or 150
    local personalSpace = 30
    local alignX, alignY = 0, 0
    local cohX,   cohY   = 0, 0
    local sepX,   sepY   = 0, 0
    local totalNeighbors = 0

    for _, other in ipairs(flock) do
        if other ~= agent then
            local dx   = agent.x - other.x
            local dy   = agent.y - other.y
            local dist = math.sqrt(dx*dx + dy*dy)
            if dist > 0 and dist < perception then
                alignX = alignX + other.vx
                alignY = alignY + other.vy
                cohX   = cohX + other.x
                cohY   = cohY + other.y
                if dist < personalSpace then
                    sepX = sepX + (dx / dist) / dist
                    sepY = sepY + (dy / dist) / dist
                end
                totalNeighbors = totalNeighbors + 1
            end
        end
    end

    if totalNeighbors > 0 then
        alignX = alignX / totalNeighbors
        alignY = alignY / totalNeighbors
        cohX   = cohX   / totalNeighbors
        cohY   = cohY   / totalNeighbors

        local forceCohX, forceCohY = agent:steerToward(cohX, cohY)

        local forceAlignX, forceAlignY = 0, 0
        local alignMag = math.sqrt(alignX^2 + alignY^2)
        if alignMag > 0 then
            local desiredVx = (alignX / alignMag) * agent.maxSpeed
            local desiredVy = (alignY / alignMag) * agent.maxSpeed
            forceAlignX = desiredVx - agent.vx
            forceAlignY = desiredVy - agent.vy
            local fAMag = math.sqrt(forceAlignX^2 + forceAlignY^2)
            if fAMag > agent.maxForce then
                forceAlignX = (forceAlignX / fAMag) * agent.maxForce
                forceAlignY = (forceAlignY / fAMag) * agent.maxForce
            end
        end

        local forceSepX, forceSepY = 0, 0
        local sepMag = math.sqrt(sepX^2 + sepY^2)
        if sepMag > 0 then
            local desiredVx = (sepX / sepMag) * agent.maxSpeed
            local desiredVy = (sepY / sepMag) * agent.maxSpeed
            forceSepX = desiredVx - agent.vx
            forceSepY = desiredVy - agent.vy
            local fSMag = math.sqrt(forceSepX^2 + forceSepY^2)
            if fSMag > agent.maxForce then
                forceSepX = (forceSepX / fSMag) * agent.maxForce
                forceSepY = (forceSepY / fSMag) * agent.maxForce
            end
        end

        agent:applyForce(forceSepX   * 1.8, forceSepY   * 1.8)
        agent:applyForce(forceAlignX * 1.0, forceAlignY * 1.0)
        agent:applyForce(forceCohX   * 1.0, forceCohY   * 1.0)
    end

    return "RUNNING"
end
