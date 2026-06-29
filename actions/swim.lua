return function(agent, blackboard)
    if not agent.wanderAngle then
        agent.wanderAngle = math.random() * math.pi * 2
    end

    local circleDistance = 40
    local circleRadius   = 25
    local angleChange    = 0.4

    agent.wanderAngle = agent.wanderAngle + ((math.random() * 2) - 1) * angleChange

    local speed = math.sqrt(agent.vx^2 + agent.vy^2)
    local headingX, headingY
    if speed == 0 then
        headingX = math.cos(agent.wanderAngle)
        headingY = math.sin(agent.wanderAngle)
    else
        headingX = agent.vx / speed
        headingY = agent.vy / speed
    end

    local circleCenterX = agent.x + (headingX * circleDistance)
    local circleCenterY = agent.y + (headingY * circleDistance)
    local targetX = circleCenterX + (math.cos(agent.wanderAngle) * circleRadius)
    local targetY = circleCenterY + (math.sin(agent.wanderAngle) * circleRadius)

    local forceX, forceY = agent:steerToward(targetX, targetY)
    agent:applyForce(forceX * 0.7, forceY * 0.7)

    return "RUNNING"
end
