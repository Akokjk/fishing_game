return function(agent, blackboard)
    local cloud = agent.nearestSandCloud
    if not cloud or cloud.alpha <= 0 then
        return "FAILURE"
    end

    -- Already inside the cloud — hold position with gentle drift
    local dx = cloud.x - agent.x
    local dy = cloud.y - agent.y
    if dx*dx + dy*dy < (cloud.radius * 0.6)^2 then
        -- Slow down to a crawl so we stay inside
        agent.vx = agent.vx * 0.85
        agent.vy = agent.vy * 0.85
        return "RUNNING"
    end

    -- Steer hard toward cloud centre
    local sx, sy = agent:steerToward(cloud.x, cloud.y)
    agent:applyForce(sx * 2.0, sy * 2.0)
    return "RUNNING"
end
