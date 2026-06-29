-- Gentle drift in current heading, damp speed to a crawl
return function(agent, blackboard)
    agent.debugAction = "SlowSwim"
    local drag = 1 - 3 * (blackboard.dt or 0)
    agent.vx = agent.vx * drag
    agent.vy = agent.vy * drag
    -- tiny wander so they don't completely freeze
    agent.vx = agent.vx + (math.random() - 0.5) * 20
    agent.vy = agent.vy + (math.random() - 0.5) * 10
    return "RUNNING"
end
