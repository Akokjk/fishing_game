return function(agent, blackboard)
    if not blackboard.rocks then return false end
    local bestRock = nil
    local bestDist = math.huge
    for _, rock in ipairs(blackboard.rocks) do
        if not rock.isMoving and rock.hideCooldown <= 0 and rock.hidingCount < rock.capacity then
            local dx   = agent.x - rock.x
            local dy   = agent.y - rock.y
            local dist = math.sqrt(dx*dx + dy*dy)
            if dist < rock.size + 100 and dist < bestDist then
                bestDist = dist
                bestRock = rock
            end
        end
    end
    if bestRock then
        agent.nearestHideRock = bestRock
        return true
    end
    return false
end
