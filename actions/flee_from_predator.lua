return function(agent, blackboard)
    agent.debugAction = "FleeFromPredator"
    local threat = agent.currentThreat or blackboard.predator
    if not threat then return "FAILURE" end
    local sx, sy = agent:steerToward(
        agent.x + (agent.x - threat.x),
        agent.y + (agent.y - threat.y)
    )
    agent:applyForce(sx * 2.2, sy * 2.2)
    return "RUNNING"
end
