return function(agent, blackboard)
    local school = blackboard.school
    if not school or #school == 0 then return "FAILURE" end

    local closest      = nil
    local closestDist2 = math.huge

    for _, f in ipairs(school) do
        if not f.isHiding then
            local dx = f.x - agent.x
            local dy = f.y - agent.y
            local d2 = dx*dx + dy*dy
            if d2 < closestDist2 then
                closestDist2 = d2
                closest = f
            end
        end
    end

    if closest then
        agent.mouthOpen = true
        local forceX, forceY = agent:steerToward(closest.x, closest.y)
        agent:applyForce(forceX * 1.3, forceY * 1.3)
        return "RUNNING"
    end

    return "FAILURE"
end
