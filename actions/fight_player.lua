-- Knock the cursor back when the puffer is touched (no stun)
return function(agent, blackboard)
    agent.debugAction = "FightPlayer"
    local dx = blackboard.cursorX - agent.x
    local dy = blackboard.cursorY - agent.y
    local d  = math.sqrt(dx*dx + dy*dy)
    if d > 0 then
        virtualCursor.vx = (dx/d) * 400
        virtualCursor.vy = (dy/d) * 400
    end

    return "SUCCESS"
end
