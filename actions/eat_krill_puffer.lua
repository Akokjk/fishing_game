-- Steer toward nearest krill; eat it on contact
return function(agent, blackboard)
    agent.debugAction = "EatKrill"
    local krill = blackboard and blackboard.krill
    if not krill or not agent.targetKrill then return "FAILURE" end

    local k = agent.targetKrill
    -- Verify still alive
    local alive = false
    for _, v in ipairs(krill) do if v == k then alive = true; break end end
    if not alive then agent.targetKrill = nil; return "FAILURE" end

    local sx, sy = agent:steerToward(k.x, k.y)
    agent:applyForce(sx * 1.5, sy * 1.5)

    local dx = k.x - agent.x
    local dy = k.y - agent.y
    if dx*dx + dy*dy < (agent.size + 8)^2 then
        for i, v in ipairs(krill) do
            if v == k then table.remove(krill, i); break end
        end
        agent.targetKrill = nil
        if pop_sound then pop_sound:stop(); pop_sound:play() end
    end

    return "RUNNING"
end
