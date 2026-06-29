return function(agent, blackboard)
    local threat = agent.currentThreat or blackboard.predator
    if not threat then return "FAILURE" end

    local dx = agent.x - threat.x
    local dy = agent.y - threat.y
    local distance = math.sqrt(dx*dx + dy*dy)

    if distance > 0 then
        local awayX = dx / distance
        local awayY = dy / distance
        local perpX = -awayY
        local perpY =  awayX
        local zigZagForce = math.sin(love.timer.getTime() * 15)
        local desiredDirX = awayX + (perpX * zigZagForce * 1.5)
        local desiredDirY = awayY + (perpY * zigZagForce * 1.5)
        local newMag = math.sqrt(desiredDirX^2 + desiredDirY^2)
        local desiredVx = (desiredDirX / newMag) * agent.maxSpeed
        local desiredVy = (desiredDirY / newMag) * agent.maxSpeed
        local steerX = desiredVx - agent.vx
        local steerY = desiredVy - agent.vy
        local steerMag = math.sqrt(steerX^2 + steerY^2)
        if steerMag > agent.maxForce then
            steerX = (steerX / steerMag) * agent.maxForce
            steerY = (steerY / steerMag) * agent.maxForce
        end
        agent:applyForce(steerX * 2.5, steerY * 2.5)
    end

    return "RUNNING"
end
