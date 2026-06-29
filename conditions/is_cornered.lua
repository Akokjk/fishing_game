return function(agent, blackboard)
    if not blackboard then return false end
    local sandTop = blackboard.screenHeight - (sandHeight or 20)
    -- Fish must be within one sand-height above the sand surface
    if agent.y < sandTop - (sandHeight or 20) then return false end
    -- A threat must also be nearby
    local threat = agent.currentThreat or blackboard.predator
    if not threat then return false end
    local dx = agent.x - threat.x
    local dy = agent.y - threat.y
    return dx*dx + dy*dy < 200*200
end
