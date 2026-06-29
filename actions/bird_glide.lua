-- Glide in air with a sine bob. When the scan timer fires and a fish is spotted below,
-- commits to a dive (sets isDiving + divTargetX) and returns SUCCESS so the
-- Selector re-enters BirdIsDiving → BirdDive next frame.
local GLIDE_SPEED  = 160
local AIR_CEIL     = 10
local AIR_FLOOR_PAD = 30   -- px above waterTop to stay while gliding

return function(agent, blackboard)
    local dt       = blackboard.dt or 0
    local waterTop = blackboard.waterTop or 0

    agent.bobPhase   = (agent.bobPhase  or 0) + 2.2 * dt
    agent.glideTimer = (agent.glideTimer or 0) - dt

    -- Drive horizontal speed toward glide speed
    local targetVx = GLIDE_SPEED * (agent.glideDir or 1)
    agent.vx = agent.vx + (targetVx - agent.vx) * 8 * dt

    -- Sine vertical bob (gentle, no hard clamp — just soft bounce off limits)
    local targetVy = math.sin(agent.bobPhase) * 20
    agent.vy = agent.vy + (targetVy - agent.vy) * 6 * dt

    -- Soft air-band limits: push back without locking vy
    if agent.y > waterTop - AIR_FLOOR_PAD then
        agent.y  = waterTop - AIR_FLOOR_PAD
        if agent.vy > 0 then agent.vy = 0 end
    end
    if agent.y < AIR_CEIL then
        agent.y  = AIR_CEIL
        if agent.vy < 0 then agent.vy = 0 end
    end

    -- Scan for fish when timer fires; search entire school, pick closest below
    if agent.glideTimer <= 0 then
        local school = blackboard.school
        if school and #school > 0 then
            local best, bestDx = nil, math.huge
            for _, f in ipairs(school) do
                if not f.isAirborne and f.y > waterTop then
                    local dx = math.abs(f.x - agent.x)
                    if dx < bestDx then
                        bestDx = dx
                        best   = f
                    end
                end
            end
            if best then
                agent.isDiving   = true
                agent.divTargetX = best.x
                agent.glideDir   = best.x > agent.x and 1 or -1
                agent.vy         = 150   -- initial downward impulse into the dive
                agent.glideTimer = 2 + math.random() * 4
                return "SUCCESS"
            end
        end
        agent.glideTimer = 1 + math.random() * 2   -- retry soon if no fish found
    end

    return "RUNNING"
end
