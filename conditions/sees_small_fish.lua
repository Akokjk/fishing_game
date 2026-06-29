local function inSandCloud(x, y)
    for _, c in ipairs(sandClouds) do
        local dx = x - c.x
        local dy = y - c.y
        if dx*dx + dy*dy < c.radius * c.radius then return true end
    end
    return false
end

return function(agent, blackboard)
    local school = blackboard.school
    if not school then return false end
    -- Predator blinded if it is inside a cloud
    if inSandCloud(agent.x, agent.y) then return false end
    local r2 = agent.perceptionRadius^2
    for _, f in ipairs(school) do
        if not f.isHiding then
            local dx = f.x - agent.x
            local dy = f.y - agent.y
            if dx*dx + dy*dy < r2 then
                -- Fish hiding inside a cloud is invisible to this predator
                if not inSandCloud(f.x, f.y) then
                    return true
                end
            end
        end
    end
    return false
end
