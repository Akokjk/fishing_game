return function(agent, blackboard)
    local rock = agent.hidingAt
    if not rock or rock.isMoving then
        agent.hideTimer = 0
        agent.isHiding  = false
        agent.hidingAt  = nil
        return "FAILURE"
    end
    rock.hidingCount = rock.hidingCount + 1
    agent.isHiding   = true
    local forceX, forceY = agent:steerToward(rock.x, rock.y)
    agent:applyForce(forceX * 0.25, forceY * 0.25)
    return "RUNNING"
end
