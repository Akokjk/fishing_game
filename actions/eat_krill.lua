return function(agent, blackboard)
    if not blackboard.krill or #blackboard.krill == 0 then return "FAILURE" end

    local closestKrill = nil
    local closestDist  = math.huge
    local closestIndex = -1

    local spd   = math.sqrt(agent.vx^2 + agent.vy^2)
    local hx    = spd > 2 and agent.vx/spd or 1
    local hy    = spd > 2 and agent.vy/spd or 0
    local noseR = agent.size or (agent.image and agent.image:getWidth()/2 * (agent.scale or 1)) or 6
    local noseX = agent.x + hx * noseR
    local noseY = agent.y + hy * noseR

    for i, krill in ipairs(blackboard.krill) do
        local dx   = krill.x - noseX
        local dy   = krill.y - noseY
        local dist = math.sqrt(dx*dx + dy*dy)
        if dist < closestDist then
            closestDist  = dist
            closestKrill = krill
            closestIndex = i
        end
    end

    if closestKrill then
        if closestDist < 5 then
            table.remove(blackboard.krill, closestIndex)
            agent.hunger = 0
            return "SUCCESS"
        else
            local forceX, forceY = agent:steerToward(closestKrill.x, closestKrill.y)
            agent:applyForce(forceX * 1.5, forceY * 1.5)
            return "RUNNING"
        end
    end

    return "FAILURE"
end
