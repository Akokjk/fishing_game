return function(agent, blackboard)
    local rock = agent.nearestHideRock
    if not rock or rock.isMoving then
        agent.nearestHideRock = nil
        return "FAILURE"
    end

    rock.hidingCount = rock.hidingCount + 1
    agent.hidingAt = rock

    local threat = agent.currentThreat or blackboard.predator
    local shelterX, shelterY
    if threat then
        local dx = rock.x - threat.x
        local dy = rock.y - threat.y
        local dist = math.sqrt(dx*dx + dy*dy)
        if dist > 0 then
            shelterX = rock.x + (dx / dist) * (rock.size + 14)
            shelterY = rock.y + (dy / dist) * (rock.size + 14)
        else
            shelterX = rock.x
            shelterY = rock.y - rock.size - 14
        end
    else
        return "FAILURE"
    end

    agent.hideTimer = 10
    agent.isHiding  = true

    local forceX, forceY = agent:steerToward(shelterX, shelterY)
    agent:applyForce(forceX * 2.0, forceY * 2.0)
    return "RUNNING"
end
