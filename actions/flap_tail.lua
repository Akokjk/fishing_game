-- Burst away from threat with a tail-flap: quick speed boost in flee direction
return function(agent, blackboard)
    agent.debugAction = "FlapTail"
    local threat = agent.currentThreat or blackboard.predator
    if not threat then return "FAILURE" end
    local dx = agent.x - threat.x
    local dy = agent.y - threat.y
    local d  = math.sqrt(dx*dx + dy*dy)
    if d < 1 then return "FAILURE" end
    -- Impulse burst (overrides velocity directly for a snappy feel)
    agent.vx = agent.vx + (dx/d) * agent.maxSpeed * 1.2
    agent.vy = agent.vy + (dy/d) * agent.maxSpeed * 0.8
    return "SUCCESS"
end
