return function(agent, blackboard)
    local best, bestDist2 = nil, (300)^2   -- only care about clouds within 300px
    for _, c in ipairs(sandClouds) do
        if c.alpha > 0.1 then   -- cloud must still be substantial
            local dx = c.x - agent.x
            local dy = c.y - agent.y
            local d2 = dx*dx + dy*dy
            if d2 < bestDist2 then
                bestDist2 = d2
                best = c
            end
        end
    end
    agent.nearestSandCloud = best
    return best ~= nil
end
