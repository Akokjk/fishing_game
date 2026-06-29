function love.update(rawDt)
    if love.keyboard.isDown("escape") then love.event.quit() end
    hotreload.check("f5")

    if death then return end
    local dt = rawDt * timeScale

    -- 1. Oxygen & environment
    local isUnderwater  = virtualCursor.y >= height * (1 - water_to_air_ratio)
    local activeAccel   = virtualCursor.baseAccel
    local activeMaxSpeed = virtualCursor.baseMaxSpeed

    if isUnderwater then
        if love.mouse.isDown(2) and oxygen_left > 0 then
            virtualCursor.isDashing = true
            oxygen_left  = oxygen_left - (dt * 4)
            activeAccel  = virtualCursor.dashAccel
            activeMaxSpeed = virtualCursor.dashMaxSpeed
        else
            virtualCursor.isDashing = false
            oxygen_left = oxygen_left - dt
        end
        if oxygen_left <= 0 then
            oxygen_left = 0
            death = true
        end
    else
        virtualCursor.isDashing = false
        oxygen_left = math.min(oxygen_time, oxygen_left + dt * 3)
    end

    -- 2. Bait (spacebar)
    if virtualCursor.baitCooldown > 0 then
        virtualCursor.baitCooldown = virtualCursor.baitCooldown - dt
    end
    if love.keyboard.isDown("space") and virtualCursor.baitCooldown <= 0 and isUnderwater then
        if oxygen_left >= virtualCursor.baitCost then
            oxygen_left = oxygen_left - virtualCursor.baitCost
            virtualCursor.baitCooldown = virtualCursor.baitCooldownMax
            table.insert(krillList, Krill.new(virtualCursor.x, virtualCursor.y))
        end
    end

    -- 3. Cursor movement (relative mode: OS cursor locked, we track deltas)
    local wasStunned = virtualCursor.stunTimer > 0
    virtualCursor.stunTimer = math.max(0, virtualCursor.stunTimer - dt)

    -- Consume accumulated mouse deltas from love.mousemoved
    local mdx = virtualCursor._pendingDx or 0
    local mdy = virtualCursor._pendingDy or 0
    virtualCursor._pendingDx = 0
    virtualCursor._pendingDy = 0

    -- Accumulate current drift
    if isUnderwater then
        current.driftX = current.driftX + current.vx * dt
        current.driftY = current.driftY + current.vy * dt
    else
        current.driftX = current.driftX * (1 - 6 * dt)
        current.driftY = current.driftY * (1 - 6 * dt)
    end

    if virtualCursor.stunTimer <= 0 then
        if isUnderwater then
            virtualCursor.x = virtualCursor.x + mdx + current.vx * dt
            virtualCursor.y = virtualCursor.y + mdy + current.vy * dt
        else
            virtualCursor.x = virtualCursor.x + mdx
            virtualCursor.y = virtualCursor.y + mdy
        end
    end

    -- Horizontal wrap
    if virtualCursor.x < 0 then
        virtualCursor.x = virtualCursor.x + width
    elseif virtualCursor.x > width then
        virtualCursor.x = virtualCursor.x - width
    end
    -- Vertical clamp
    virtualCursor.y = math.max(0, math.min(height, virtualCursor.y))


    -- Cursor trail
    local ct = virtualCursor.trail
    table.insert(ct, 1, {x = virtualCursor.x, y = virtualCursor.y})
    local totalLen, keep = 0, 1
    for i = 2, #ct do
        local dx = ct[i-1].x - ct[i].x
        local dy = ct[i-1].y - ct[i].y
        totalLen = totalLen + math.sqrt(dx*dx + dy*dy)
        if totalLen > 50 then break end
        keep = i
    end
    for i = #ct, keep + 1, -1 do ct[i] = nil end

    -- Camera smooth-follow cursor
    if camera.enabled then
        local lag = 1 - math.exp(-12 * dt)  -- exponential smoothing
        camera.x = camera.x + (virtualCursor.x - camera.x) * lag
        camera.y = camera.y + (virtualCursor.y - camera.y) * lag
    end

    -- 4. Blackboard
    blackboard.cursorX    = virtualCursor.x
    blackboard.cursorY    = virtualCursor.y
    blackboard.predator   = { x = virtualCursor.x, y = virtualCursor.y }
    blackboard.krill      = krillList
    blackboard.allFish    = school
    blackboard.predators  = predatorList
    blackboard.school     = school
    blackboard.rocks      = rockList
    blackboard.jellyfish  = jellyList
    blackboard.sharks     = sharkList
    blackboard.screenWidth  = width
    blackboard.screenHeight = height
    blackboard.waterTop     = height * (1 - water_to_air_ratio)
    blackboard.sandHeight   = sandHeight
    blackboard.dt           = dt
    blackboard.current      = current

    -- Ocean current state machine
    do
        current.stateTimer = current.stateTimer - dt
        if current.stateTimer <= 0 then
            if current.isDead then
                -- Switch to a flowing period
                current.isDead     = false
                current.stateTimer = 6 + math.random() * 10   -- 6-16 s flowing
                local strength     = 150 + math.random() * 250  -- 150-400 px/s
                local dir          = math.random() < 0.5 and 1 or -1
                current.targetVx   = strength * dir
                current.targetVy   = math.max(-25, (math.random() - 0.5) * strength * 0.35)
            else
                -- Switch to a dead calm period
                current.isDead     = true
                current.stateTimer = 2 + math.random() * 4    -- 2-6 s calm
                current.targetVx   = 0
                current.targetVy   = 0
            end
        end
        -- Smooth lerp toward target
        local lerpRate = current.isDead and 1.5 or 0.4
        current.vx = current.vx + (current.targetVx - current.vx) * math.min(1, lerpRate * dt)
        current.vy = current.vy + (current.targetVy - current.vy) * math.min(1, lerpRate * dt)
    end

    -- Vortex spawn & update
    vortexSpawnTimer = vortexSpawnTimer - dt
    if vortexSpawnTimer <= 0 and #vortexList < 3 then
        vortexSpawnTimer = 8 + math.random() * 12
        local waterTop = height * (1 - water_to_air_ratio)
        local sandTop  = height - sandHeight
        local radius   = 35 + math.random() * 45   -- small: 35-80 px
        local minY     = waterTop + radius
        local maxY     = sandTop  - radius
        if maxY < minY then maxY = minY end
        table.insert(vortexList, {
            x           = math.random(math.ceil(radius), math.floor(width - radius)),
            y           = minY + math.random() * (maxY - minY),
            radius      = radius,
            pullStrength = 400 + math.random() * 600,
            spinStrength = (math.random() < 0.5 and 1 or -1) * (300 + math.random() * 400),
            angle       = math.random() * math.pi * 2,
            spinSpeed   = (math.random() < 0.5 and 1 or -1) * (0.4 + math.random() * 0.8),
            lifetime    = 8 + math.random() * 12,
            maxLifetime = 0,  -- set below
            alpha       = 0,
        })
        vortexList[#vortexList].maxLifetime = vortexList[#vortexList].lifetime
    end

    -- Helper: apply vortex force to an entity.
    -- Cancels the background current inside the vortex so it always dominates.
    local function applyVortex(ent, v, strength)
        local dx   = ent.x - v.x
        local dy   = ent.y - v.y
        local dist = math.sqrt(dx*dx + dy*dy)
        if dist < 1 or dist > v.radius then return end
        local falloff = 1 - (dist / v.radius)
        local nx, ny = dx/dist, dy/dist
        local tx, ty = -ny, nx
        -- Cancel ambient current inside the vortex (full at centre, zero at edge)
        ent.vx = ent.vx - current.vx * falloff * dt
        ent.vy = ent.vy - current.vy * falloff * dt
        -- Apply vortex pull/push and spin
        ent.vx = ent.vx - nx * v.pullStrength * falloff * strength * dt
        ent.vy = ent.vy - ny * v.pullStrength * falloff * strength * dt
        ent.vx = ent.vx + tx * v.spinStrength * falloff * strength * dt
        ent.vy = ent.vy + ty * v.spinStrength * falloff * strength * dt
    end

    for i = #vortexList, 1, -1 do
        local v = vortexList[i]
        v.lifetime = v.lifetime - dt
        v.angle    = v.angle + v.spinSpeed * dt
        v.x = v.x + current.vx * dt
        v.y = v.y + current.vy * dt
        local wTop = height * (1 - water_to_air_ratio)
        local sTop = height - sandHeight
        v.y = math.max(wTop + v.radius, math.min(sTop - v.radius, v.y))
        -- fade in first 2s, fade out last 2s
        local t    = v.lifetime / v.maxLifetime
        v.alpha    = math.min(1, math.min(t, 1 - t) * v.maxLifetime / 2)
        if v.lifetime <= 0 then
            table.remove(vortexList, i)
        else
            -- Apply to fish
            for _, f  in ipairs(school)       do applyVortex(f,  v, 1) end
            for _, pf in ipairs(pufferList)   do applyVortex(pf, v, 1) end
            for _, p  in ipairs(predatorList) do applyVortex(p,  v, 1) end
            for _, k  in ipairs(krillList)    do applyVortex(k,  v, 1) end
            for _, jl in ipairs(jellyList)    do applyVortex(jl, v, 1) end
            for _, s  in ipairs(sharkList)    do applyVortex(s,  v, 1) end
            -- Apply to rocks (positional, no velocity)
            for _, r in ipairs(rockList) do
                local dx   = r.x - v.x
                local dy   = r.y - v.y
                local dist = math.sqrt(dx*dx + dy*dy)
                if dist >= 1 and dist <= v.radius then
                    local falloff = 1 - (dist / v.radius)
                    local nx, ny = dx/dist, dy/dist
                    local tx, ty = -ny, nx
                    r.x = r.x - nx * v.pullStrength * falloff * dt * 0.3
                    r.y = r.y - ny * v.pullStrength * falloff * dt * 0.3
                    r.x = r.x + tx * v.spinStrength * falloff * dt * 0.3
                    r.y = r.y + ty * v.spinStrength * falloff * dt * 0.3
                end
            end
            -- Apply to cursor (direct position push, same math as fish)
            if isUnderwater then
                local dx   = virtualCursor.x - v.x
                local dy   = virtualCursor.y - v.y
                local dist = math.sqrt(dx*dx + dy*dy)
                if dist >= 1 and dist <= v.radius then
                    local falloff = 1 - (dist / v.radius)
                    local nx, ny  = dx/dist, dy/dist
                    local tx, ty  = -ny, nx
                    virtualCursor.x = virtualCursor.x
                        - nx * v.pullStrength * falloff * dt
                        + tx * v.spinStrength * falloff * dt
                    virtualCursor.y = virtualCursor.y
                        - ny * v.pullStrength * falloff * dt
                        + ty * v.spinStrength * falloff * dt
                end
            end
        end
    end

    -- 5. Rocks
    if heldRock then
        heldRock.x = virtualCursor.x
        heldRock.y = virtualCursor.y
    end

    -- Line-fishing: fish swims freely but is tethered to cursor.
    -- Break free if cursor yanks faster than the snap threshold,
    -- or if the fish pulls the line beyond its max length.
    local LINE_MAX      = lineTetherLength
    local PULL_STRENGTH = 420   -- force pulling fish toward cursor

    if heldFish then
        -- Distance from cursor to fish centre
        local fdx  = heldFish.x - virtualCursor.x
        local fdy  = heldFish.y - virtualCursor.y
        local dist = math.sqrt(fdx*fdx + fdy*fdy)

        do
            -- Pull force drags fish toward cursor
            if dist > 1 then
                local nx, ny = fdx / dist, fdy / dist
                heldFish.vx = heldFish.vx - nx * PULL_STRENGTH * dt
                heldFish.vy = heldFish.vy - ny * PULL_STRENGTH * dt
            end
            -- Fish pulling line out: only when near the end and swimming outward.
            -- Rate starts fast and tapers to zero as it nears lineTetherMax,
            -- simulating the fish tiring out.
            if dist > LINE_MAX * 0.85 and dist > 0 then
                local nx, ny    = fdx / dist, fdy / dist
                local outwardSpd = heldFish.vx * nx + heldFish.vy * ny  -- positive = pulling away
                if outwardSpd > 0 then
                    local fatigue = 1 - (lineTetherLength / lineTetherMax)  -- 1 fresh → 0 exhausted
                    lineTetherLength = math.min(lineTetherMax, lineTetherLength + outwardSpd * fatigue * dt)
                end
            end
            -- Hard wall: fish is always clamped to current lineTetherLength.
            -- This means reeling in (shrinking lineTetherLength) physically
            -- drags the fish closer regardless of its swim forces.
            if dist > lineTetherLength then
                local nx, ny = fdx / dist, fdy / dist
                heldFish.x = virtualCursor.x + nx * lineTetherLength
                heldFish.y = virtualCursor.y + ny * lineTetherLength
                local dot = heldFish.vx * nx + heldFish.vy * ny
                if dot > 0 then
                    heldFish.vx = heldFish.vx - dot * nx
                    heldFish.vy = heldFish.vy - dot * ny
                end
            end

            -- Caught when fish crosses above the waterline
            local waterTop = height * (1 - water_to_air_ratio)
            if heldFish.y < waterTop then
                for i = #school, 1, -1 do
                    if school[i] == heldFish then table.remove(school, i); break end
                end
                for i = #pufferList, 1, -1 do
                    if pufferList[i] == heldFish then table.remove(pufferList, i); break end
                end
                for i = #predatorList, 1, -1 do
                    if predatorList[i] == heldFish then table.remove(predatorList, i); break end
                end
                fishCaught = fishCaught + 1
                pop_sound:stop()
                pop_sound:setPitch(1.0 + (math.random() * 0.4 - 0.2))
                pop_sound:play()
                heldFish = nil
            end
        end
    end
    local movingRocks = {}
    for _, rock in ipairs(rockList) do
        rock.hidingCount = 0
        rock:update(dt, width, height)
        if not rock.isHeld then
            rock.x = rock.x + current.vx * dt
            rock.y = rock.y + current.vy * dt
            rock.angularVel = (rock.angularVel or 0) + current.vx * 0.0004
        end
        if rock.isMoving then table.insert(movingRocks, rock) end
    end
    for i = 1, #rockList do
        for j = i + 1, #rockList do
            local a, b = rockList[i], rockList[j]
            local dx    = b.x - a.x
            local dy    = b.y - a.y
            local dist2 = dx*dx + dy*dy
            local minD  = a.size + b.size + 4
            if dist2 < minD * minD and dist2 > 0 then
                local dist   = math.sqrt(dist2)
                local overlap = minD - dist
                local nx, ny = dx / dist, dy / dist
                if not a.isHeld then a.x = a.x - nx * overlap * 0.5; a.y = a.y - ny * overlap * 0.5 end
                if not b.isHeld then b.x = b.x + nx * overlap * 0.5; b.y = b.y + ny * overlap * 0.5 end
            end
        end
    end
    blackboard.movingRocks = movingRocks

    grid:clear()
    for _, f in ipairs(school) do grid:add(f) end

    -- Sand particles
    for i = #sandParticles, 1, -1 do
        local p = sandParticles[i]
        p.x     = p.x + p.vx * dt
        p.y     = p.y + p.vy * dt
        p.vy    = p.vy + 80 * dt
        p.alpha = p.alpha - p.fade * dt
        if p.alpha <= 0 then table.remove(sandParticles, i) end
    end

    -- Blood clouds
    for i = #bloodClouds, 1, -1 do
        local c = bloodClouds[i]
        if c.radius < c.maxRadius then
            c.radius = math.min(c.maxRadius, c.radius + c.maxRadius * 4 * dt)
        end
        c.alpha = c.alpha - c.fade * dt
        if c.alpha <= 0 then table.remove(bloodClouds, i) end
    end

    -- Sand clouds (blind zones for predators)
    for i = #sandClouds, 1, -1 do
        local c = sandClouds[i]
        -- Expand quickly to maxRadius, then hold while fading
        if c.radius < c.maxRadius then
            c.radius = math.min(c.maxRadius, c.radius + c.maxRadius * 3 * dt)
        end
        c.alpha = c.alpha - c.fade * dt
        if c.alpha <= 0 then table.remove(sandClouds, i) end
    end

    -- 6. Krill spawn timer
    krillSpawnTimer = krillSpawnTimer + dt
    if krillSpawnTimer >= krillSpawnInterval then
        krillSpawnTimer = 0
        local waterTop = height * (1 - water_to_air_ratio)
        table.insert(krillList, Krill.new(math.random(width), math.random(waterTop, height)))
    end

    for _, k in ipairs(krillList) do
        k:update(dt, blackboard)
        k.vx = k.vx + current.vx * dt
        k.vy = k.vy + current.vy * dt
    end

    -- 7. Jellyfish + stings
    for _, jelly in ipairs(jellyList) do
        jelly:update(dt, blackboard)
        jelly.vx = jelly.vx + current.vx * dt
        jelly.vy = jelly.vy + current.vy * dt
        for _, f in ipairs(school) do
            if not f.isHiding and not f.isAirborne and f.stunTimer <= 0 then
                if jelly:stings(f.x, f.y) then f.stunTimer = 2.5 end
            end
        end
        for _, p in ipairs(predatorList) do
            if p.stunTimer <= 0 and jelly:stings(p.x, p.y) then p.stunTimer = 2.5 end
        end
        if virtualCursor.stunTimer <= 0 and jelly:stings(virtualCursor.x, virtualCursor.y) then
            virtualCursor.stunTimer = 2.5
        end
    end

    -- 7b. Puffer fish
    blackboard.puffers = pufferList
    for _, pf in ipairs(pufferList) do
        pf:update(dt, blackboard)
        pf.vx = pf.vx + current.vx * dt
        pf.vy = pf.vy + current.vy * dt

        if pf.isPuffed or pf.deflateTimer > 0 then
            local t     = pf.isPuffed and 1 or (pf.deflateTimer / pf.deflateTime)
            local puffR = pf.size * (1 + (3.5 - 1) * t)
            local spd       = math.sqrt(pf.vx^2 + pf.vy^2)
            local hx        = spd > 5 and pf.vx/spd or 1
            local hy        = spd > 5 and pf.vy/spd or 0
            -- Tail centre = behind the fish
            local tailX     = pf.x - hx * puffR * 0.75
            local tailY     = pf.y - hy * puffR * 0.75
            local tailR     = puffR * 0.35   -- small safe zone radius

            -- Bounce small fish off the inflated body
            for _, f in ipairs(school) do
                local dx = f.x - pf.x
                local dy = f.y - pf.y
                local d2 = dx*dx + dy*dy
                if d2 < puffR * puffR and d2 > 0 then
                    local d  = math.sqrt(d2)
                    local nx, ny = dx/d, dy/d
                    f.x  = pf.x + nx * puffR
                    f.y  = pf.y + ny * puffR
                    local dot = f.vx*nx + f.vy*ny
                    if dot < 0 then
                        f.vx = f.vx - 2*dot*nx
                        f.vy = f.vy - 2*dot*ny
                    end
                end
            end

            -- Player death: inside puff radius but NOT in the tail safe zone
            if not death then
                local cx = virtualCursor.x - pf.x
                local cy = virtualCursor.y - pf.y
                if cx*cx + cy*cy < puffR * puffR then
                    local tx = virtualCursor.x - tailX
                    local ty = virtualCursor.y - tailY
                    if tx*tx + ty*ty > tailR * tailR then
                        death = true
                        crunch_sound:stop(); crunch_sound:play()
                    end
                end
            end
        end
    end

    -- 7c. Birds
    blackboard.birds = birdList
    local birdBB = {}
    for k, v in pairs(blackboard) do birdBB[k] = v end
    birdBB.allFish = birdList   -- avoidOverlap uses allFish; birds only avoid each other

    for _, b in ipairs(birdList) do
        b:update(dt, birdBB)
        -- Current only pushes birds while underwater
        if b:isUnderwater(blackboard.waterTop) then
            b.vx = b.vx + current.vx * dt
            b.vy = b.vy + current.vy * dt
        end
    end

    -- Jellyfish sting birds that are underwater
    for _, jelly in ipairs(jellyList) do
        for _, b in ipairs(birdList) do
            if b:isUnderwater(blackboard.waterTop) and b.stunTimer <= 0 then
                if jelly:stings(b.x, b.y) then
                    b.stunTimer  = 2.5
                    -- Force escape so it bobs at the surface during stun
                    b.isEscaping = false
                    b.isDiving   = false
                    b.vy         = -120
                end
            end
        end
    end

    -- 8. Predators: update, rock collision, bite cone
    local coneHalfCos = math.cos(math.rad(35))
    local coneRange   = predatorBiteRadius
    for _, p in ipairs(predatorList) do
        local predBB = {}
        for k, v in pairs(blackboard) do predBB[k] = v end
        predBB.allFish = predatorList
        p:update(dt, predBB)
        p.vx = p.vx + current.vx * dt
        p.vy = p.vy + current.vy * dt

        for _, rock in ipairs(rockList) do
            local dx    = p.x - rock.x
            local dy    = p.y - rock.y
            local dist2 = dx*dx + dy*dy
            local minD  = rock.size + p.size
            if dist2 < minD * minD and dist2 > 0 then
                local dist   = math.sqrt(dist2)
                local nx, ny = dx / dist, dy / dist
                p.x = p.x + nx * (minD - dist)
                p.y = p.y + ny * (minD - dist)
                local dot = p.vx * nx + p.vy * ny
                if dot < 0 then p.vx = p.vx - dot * nx; p.vy = p.vy - dot * ny end
            end
        end

        local spd = math.sqrt(p.vx^2 + p.vy^2)
        if spd > 10 then
            local hx = p.vx / spd
            local hy = p.vy / spd

            if not death then
                local cx    = virtualCursor.x - p.x
                local cy    = virtualCursor.y - p.y
                local cdist = math.sqrt(cx*cx + cy*cy)
                if cdist < coneRange and cdist > 0 and (cx/cdist)*hx + (cy/cdist)*hy > coneHalfCos then
                    death = true
                    crunch_sound:stop(); crunch_sound:play()
                end
            end
            for i = #school, 1, -1 do
                local f  = school[i]
                local dx = f.x - p.x
                local dy = f.y - p.y
                local dist = math.sqrt(dx*dx + dy*dy)
                if dist < coneRange and dist > 0 and not f.isHiding and not f.isAirborne then
                    if (dx/dist)*hx + (dy/dist)*hy > coneHalfCos then
                        if school[i] == heldFish then heldFish = nil end
                        table.remove(school, i)
                        p:bite()
                        eat_sound:stop()
                        eat_sound:play()
                    end
                end
            end
            -- Predator eats birds that are underwater
            for i = #birdList, 1, -1 do
                local b  = birdList[i]
                if b:isUnderwater(blackboard.waterTop) then
                    local dx = b.x - p.x
                    local dy = b.y - p.y
                    local dist = math.sqrt(dx*dx + dy*dy)
                    if dist < coneRange * 2 and dist > 0 then
                        if (dx/dist)*hx + (dy/dist)*hy > coneHalfCos then
                            table.remove(birdList, i)
                            p:bite()
                            crunch_sound:stop(); crunch_sound:play()
                        end
                    end
                end
            end
        end
    end

    -- 9. Sharks: update + bite small fish in nose zone
    for _, s in ipairs(sharkList) do
        s:update(dt, blackboard)

        -- Nose tip position (heading unit * size ahead of centre)
        local spd = math.sqrt(s.vx^2 + s.vy^2)
        local nhx = spd > 1 and s.vx/spd or s.patrolDir
        local nhy = spd > 1 and s.vy/spd or 0
        local noseX = s.x + nhx * s.size
        local noseY = s.y + nhy * s.size
        local br2   = s.biteRange^2

        for i = #school, 1, -1 do
            local f  = school[i]
            local dx = f.x - noseX
            local dy = f.y - noseY
            if dx*dx + dy*dy < br2 then
                if school[i] == heldFish then heldFish = nil end
                table.remove(school, i)
                eat_sound:stop(); eat_sound:play()
                table.insert(bloodClouds, {
                    x        = f.x,
                    y        = f.y,
                    radius   = 4,
                    maxRadius = 28 + math.random() * 14,
                    alpha    = 0.75,
                    fade     = 0.55,
                })
            end
        end
        -- Shark eats underwater birds
        for i = #birdList, 1, -1 do
            local b  = birdList[i]
            if b:isUnderwater(blackboard.waterTop) then
                local dx = b.x - noseX
                local dy = b.y - noseY
                if dx*dx + dy*dy < (s.biteRange * 1.5)^2 then
                    table.remove(birdList, i)
                    crunch_sound:stop(); crunch_sound:play()
                end
            end
        end
    end

    -- 10. Small fish (held fish still runs brain so it fights the line)
    for _, f in ipairs(school) do
        local neighbors  = grid:getNearby(f.x, f.y)
        local fishBB     = {}
        for k, v in pairs(blackboard) do fishBB[k] = v end
        fishBB.allFish   = neighbors
        f:update(dt, fishBB)
        f.vx = f.vx + current.vx * dt
        f.vy = f.vy + current.vy * dt
    end
end

function love.wheelmoved(x, y)
    lineTetherLength = math.max(10, math.min(lineTetherMax, lineTetherLength - y * lineTetherStep))
end

function love.mousemoved(x, y, dx, dy, istouch)
    virtualCursor._pendingDx = (virtualCursor._pendingDx or 0) + dx
    virtualCursor._pendingDy = (virtualCursor._pendingDy or 0) + dy
end

function love.keypressed(key)
    if key == "up" then
        lineTetherLength = math.max(10, math.min(lineTetherMax, lineTetherLength + lineTetherStep))
    elseif key == "down" then
        lineTetherLength = math.max(10, math.min(lineTetherMax, lineTetherLength - lineTetherStep))
    elseif key == "c" then
        camera.enabled = not camera.enabled
        -- Snap to cursor immediately so there's no swooping catch-up on enable
        camera.x = virtualCursor.x
        camera.y = virtualCursor.y
    elseif key == "d" then
        debugMode = not debugMode
    elseif key == "x" then
        virtualCursor.useHardwareCursor = not virtualCursor.useHardwareCursor
        if virtualCursor.useHardwareCursor then
            virtualCursor.vx = 0
            virtualCursor.vy = 0
        end
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    if button == 1 then
        -- Rocks take priority (use virtualCursor position — relative mouse mode)
        local cx, cy = virtualCursor.x, virtualCursor.y
        for i = #rockList, 1, -1 do
            if rockList[i]:containsPoint(cx, cy) then
                heldRock = rockList[i]
                heldRock.isHeld = true
                heldRock.vx = 0
                heldRock.vy = 0
                return
            end
        end

        -- Grab the nearest fish within grab radius (must not be in a sand cloud)
        local tipX, tipY = virtualCursor.x, virtualCursor.y
        local grabR2 = 20 * 20
        local best, bestDist2, bestByTail = nil, grabR2, false

        for i, f in ipairs(school) do
            local dx = f.x - tipX
            local dy = f.y - tipY
            local d2 = dx*dx + dy*dy
            if d2 < bestDist2 and not f.isAirborne then
                local inCloud = false
                for _, c in ipairs(sandClouds) do
                    local cx = f.x - c.x
                    local cy = f.y - c.y
                    if cx*cx + cy*cy < c.radius * c.radius then inCloud = true; break end
                end
                if not inCloud then
                    best, bestDist2, bestByTail = f, d2, false
                end
            end
        end

        -- Puffer fish: unpuffed = grab anywhere (nose); puffed = only the tail safe zone
        for _, pf in ipairs(pufferList) do
            local spd = math.sqrt(pf.vx^2 + pf.vy^2)
            local hx  = spd > 5 and pf.vx/spd or 1
            local hy  = spd > 5 and pf.vy/spd or 0
            if not pf.isPuffed then
                local dx = pf.x - tipX
                local dy = pf.y - tipY
                local d2 = dx*dx + dy*dy
                if d2 < bestDist2 then
                    best, bestDist2, bestByTail = pf, d2, false
                end
            else
                local puffR = pf.size * 3.5
                local tailX = pf.x - hx * puffR * 0.75
                local tailY = pf.y - hy * puffR * 0.75
                local tailR = puffR * 0.35
                local tx    = tailX - tipX
                local ty    = tailY - tipY
                local d2    = tx*tx + ty*ty
                if d2 < tailR * tailR and d2 < bestDist2 then
                    best, bestDist2, bestByTail = pf, d2, true
                end
            end
        end

        -- Predator fish: tail grab only
        for _, p in ipairs(predatorList) do
            local spd  = math.sqrt(p.vx^2 + p.vy^2)
            local hx   = spd > 5 and p.vx/spd or 1
            local hy   = spd > 5 and p.vy/spd or 0
            local tailX = p.x - hx * (p.size or 20)
            local tailY = p.y - hy * (p.size or 20)
            local tx   = tailX - tipX
            local ty   = tailY - tipY
            local d2   = tx*tx + ty*ty
            if d2 < bestDist2 then
                best, bestDist2, bestByTail = p, d2, true
            end
        end

        if best then
            heldFish       = best
            heldFishByTail = bestByTail
        end
    end
end

function love.mousereleased(x, y, button)
    if button == 1 then
        if heldRock then
            heldRock.isHeld       = false
            heldRock.vy           = 80
            heldRock.hideCooldown = 10
            heldRock = nil
        end
        if heldFish then
            heldFish.vx    = 0
            heldFish.vy    = 0
            heldFish       = nil
            heldFishByTail = false
        end
    end
end
