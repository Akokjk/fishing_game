return function(agent, blackboard)
    local threat = agent.currentThreat or blackboard.predator
    if not threat then return "FAILURE" end

    local dx = agent.x - threat.x
    local dy = agent.y - threat.y
    local distance = math.sqrt(dx*dx + dy*dy)

    if distance > 0 then
        local desiredVx = (dx / distance) * agent.maxSpeed
        local desiredVy = (dy / distance) * agent.maxSpeed
        local steerX = desiredVx - agent.vx
        local steerY = desiredVy - agent.vy
        local steerMag = math.sqrt(steerX^2 + steerY^2)
        if steerMag > agent.maxForce then
            steerX = (steerX / steerMag) * agent.maxForce
            steerY = (steerY / steerMag) * agent.maxForce
        end
        agent:applyForce(steerX * 2.0, steerY * 2.0)
    end

    return "RUNNING"
end
