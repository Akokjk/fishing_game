function love.draw()
    love.graphics.clear(29/255, 23/255, 23/255, 1, 0, false)

    -- Apply camera transform for all world-space drawing
    if camera.enabled then
        love.graphics.push()
        love.graphics.translate(width / 2, height / 2)
        love.graphics.scale(camera.zoom)
        love.graphics.translate(-camera.x, -camera.y)
    end

    -- World background (extended far beyond screen so zoom/pan never shows gaps)
    local pad    = width * 4
    local waterY = height * (1 - water_to_air_ratio)
    local sandTop = height - sandHeight

    love.graphics.setColor(0, 0, 1)
    love.graphics.rectangle("fill", -pad, -pad, width + pad * 2, waterY + pad)

    love.graphics.setColor(116/255, 204/255, 244/255)
    love.graphics.rectangle("fill", -pad, waterY, width + pad * 2, height - waterY + pad)

    -- Sand floor
    love.graphics.setColor(0.76, 0.65, 0.42)
    love.graphics.rectangle("fill", -pad, sandTop, width + pad * 2, sandHeight + pad)
    love.graphics.setColor(0.60, 0.50, 0.30, 0.6)
    love.graphics.rectangle("fill", -pad, sandTop, width + pad * 2, 6)

    -- Sun (world-space position)
    love.graphics.setColor(255/255, 129/255, 0)
    love.graphics.circle("fill", width * 0.8, height * 0.1, height * sun_radius_ratio)

    if death then
        love.graphics.setFont(debug_font)
        love.graphics.setColor(0, 0, 0)
        love.graphics.print("You died. There's no second chances here!", 10, height / 2)
    else

        -- Rocks
        for _, rock in ipairs(rockList) do rock:draw() end

        -- Sand blind clouds (large soft blobs drawn first, behind particles)
        for _, c in ipairs(sandClouds) do
            love.graphics.setColor(0.76, 0.65, 0.42, c.alpha * 0.35)
            love.graphics.circle("fill", c.x, c.y, c.radius)
            love.graphics.setColor(0.82, 0.72, 0.50, c.alpha * 0.18)
            love.graphics.circle("fill", c.x, c.y, c.radius * 1.3)
        end

        -- Sand puff particles
        for _, p in ipairs(sandParticles) do
            love.graphics.setColor(0.76, 0.65, 0.42, p.alpha)
            love.graphics.circle("fill", p.x, p.y, p.radius)
        end

        -- Krill
        for _, k in ipairs(krillList) do k:draw() end

        -- Small fish eat radius (debug)
        if debugMode then
            love.graphics.setColor(1, 0.1, 0.1, 0.7)
            love.graphics.setLineWidth(1)
            local noseOff = small_fish_img:getWidth() / 2
            for _, f in ipairs(school) do
                local spd = math.sqrt(f.vx^2 + f.vy^2)
                local hx  = spd > 2 and f.vx/spd or 1
                local hy  = spd > 2 and f.vy/spd or 0
                local nr  = noseOff * (f.scale or 1)
                love.graphics.circle("line", f.x + hx*nr, f.y + hy*nr, 5)
            end
        end

        -- Small fish (SpriteBatch — one GPU call)
        fishBatch:clear()
        local iw = small_fish_img:getWidth()  / 2
        local ih = small_fish_img:getHeight() / 2
        for _, f in ipairs(school) do
            if not f.isHiding then
                local angle = math.atan2(f.vy, f.vx)
                local a = f.drawAlpha or 1.0
                if f.stunTimer > 0 then
                    fishBatch:setColor(0.6, 0.2, 1.0, a)
                else
                    fishBatch:setColor(f.color[1], f.color[2], f.color[3], a)
                end
                fishBatch:add(f.x, f.y, angle, f.scale, f.scale, iw, ih)
            end
        end
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(fishBatch)

        -- Predators
        for _, p in ipairs(predatorList) do p:draw() end

        -- Puffer fish
        for _, pf in ipairs(pufferList) do pf:draw() end

        -- Jellyfish
        for _, jelly in ipairs(jellyList) do jelly:draw() end

        -- Sharks (drawn above jellyfish and small fish)
        for _, s in ipairs(sharkList) do s:draw() end

        -- Birds
        for _, b in ipairs(birdList) do b:draw() end

        -- Blood clouds
        for _, c in ipairs(bloodClouds) do
            love.graphics.setColor(0.72, 0.05, 0.05, c.alpha * 0.55)
            love.graphics.circle("fill", c.x, c.y, c.radius)
            love.graphics.setColor(0.85, 0.12, 0.12, c.alpha * 0.25)
            love.graphics.circle("fill", c.x, c.y, c.radius * 1.4)
        end

        -- Fishing line: white, connects cursor to fish nose or tail
        if heldFish then
            local spd = math.sqrt(heldFish.vx^2 + heldFish.vy^2)
            local hx  = spd > 5 and heldFish.vx / spd or 1
            local hy  = spd > 5 and heldFish.vy / spd or 0
            local sz  = heldFish.size or 6
            local attachX, attachY
            if heldFishByTail then
                local r = (heldFish.isPuffed and sz * 3.5 or sz)
                attachX = heldFish.x - hx * r * 0.75   -- tail is opposite to heading
                attachY = heldFish.y - hy * r * 0.75
            else
                attachX = heldFish.x + hx * sz
                attachY = heldFish.y + hy * sz
            end
            local fdx     = heldFish.x - virtualCursor.x
            local fdy     = heldFish.y - virtualCursor.y
            local tension = math.min(1, math.sqrt(fdx*fdx + fdy*fdy) / lineTetherLength)
            love.graphics.setColor(1, 1 - tension * 0.9, 1 - tension * 0.9, 0.9)
            love.graphics.setLineWidth(1.5)
            love.graphics.line(virtualCursor.x, virtualCursor.y, attachX, attachY)
            love.graphics.setLineWidth(1)
        end

        -- Ocean current arrows
        do
            local spd = math.sqrt(current.vx^2 + current.vy^2)
            if spd > 1 then
                local nx, ny  = current.vx / spd, current.vy / spd
                local alpha   = math.min(1, spd / 80) * 0.55
                local arrowL  = 12 + spd * 0.18   -- longer when stronger
                local gridX, gridY = 120, 100
                local waterY  = height * (1 - water_to_air_ratio)
                local sandTop = height - sandHeight
                love.graphics.setLineWidth(1.2)
                local cols = math.floor(width  / gridX)
                local rows = math.floor((sandTop - waterY) / gridY)
                for row = 0, rows do
                    for col = 0, cols do
                        local ax = col * gridX + gridX * 0.5
                        local ay = waterY + row * gridY + gridY * 0.5
                        local bx = ax + nx * arrowL
                        local by = ay + ny * arrowL
                        -- Arrowhead perp
                        local px, py = -ny * 4, nx * 4
                        love.graphics.setColor(1, 1, 1, alpha)
                        love.graphics.line(ax, ay, bx, by)
                        love.graphics.line(bx, by, bx - nx*5 + px, by - ny*5 + py)
                        love.graphics.line(bx, by, bx - nx*5 - px, by - ny*5 - py)
                    end
                end
                love.graphics.setLineWidth(1)
            end
        end

        -- Vortices: spiral ribbon polygons
        for _, v in ipairs(vortexList) do
            local alpha   = v.alpha * 0.7
            local r, g, b = 0.2, 0.6, 1.0

            local turns   = 2.5
            local steps   = 64
            local ribbonW = v.radius * 0.08

            -- Build outward edge, then inward edge reversed → closed ribbon polygon
            local outerPts = {}
            local innerPts = {}
            for i = 0, steps do
                local t     = i / steps
                local rad   = v.radius * t
                local angle = t * math.pi * 2 * turns + v.angle
                local cx    = v.x + math.cos(angle) * rad
                local cy    = v.y + math.sin(angle) * rad
                local innerR = math.max(0, rad - ribbonW)
                table.insert(outerPts, cx)
                table.insert(outerPts, cy)
                table.insert(innerPts, v.x + math.cos(angle) * innerR)
                table.insert(innerPts, v.y + math.sin(angle) * innerR)
            end

            -- Combine into one polygon: outer forward, inner reversed
            local poly = {}
            for i = 1, #outerPts do poly[i] = outerPts[i] end
            for i = #innerPts - 1, 1, -2 do
                table.insert(poly, innerPts[i])
                table.insert(poly, innerPts[i + 1])
            end

            love.graphics.setColor(r, g, b, alpha * 0.25)
            love.graphics.polygon("fill", poly)
            love.graphics.setColor(r, g, b, alpha * 0.8)
            love.graphics.setLineWidth(1.2)
            love.graphics.polygon("line", poly)

            -- Centre dot
            love.graphics.setColor(r, g, b, alpha)
            love.graphics.circle("fill", v.x, v.y, 4)
            love.graphics.setLineWidth(1)
        end

        -- Cursor trail (blue)
        local ct = virtualCursor.trail
        if #ct >= 2 then
            love.graphics.setLineWidth(1.5)
            for i = 1, #ct - 1 do
                local alpha = (1 - i / #ct) * 0.8
                love.graphics.setColor(0.3, 0.6, 1, alpha)
                love.graphics.line(ct[i].x, ct[i].y, ct[i+1].x, ct[i+1].y)
            end
            love.graphics.setLineWidth(1)
        end

        -- Cursor
        if virtualCursor.stunTimer > 0 then
            love.graphics.setColor(0.6, 0.2, 1.0)
        elseif virtualCursor.isDashing then
            love.graphics.setColor(1, 0.2, 0.2)
        elseif virtualCursor.y < waterY then
            love.graphics.setColor(1, 1, 0)
        else
            love.graphics.setColor(0.55, 0.20, 0.04)
        end
        love.graphics.draw(cursor, virtualCursor.x, virtualCursor.y, 0, cursorScale, cursorScale, 0, 0)
        love.graphics.setColor(1, 1, 1)
    end

    if camera.enabled then love.graphics.pop() end

    -- Sand-cloud blindness: when cursor is inside a cloud, black out the screen
    -- except for a tiny circle of vision around the cursor tip.
    local cursorInCloud = false
    for _, c in ipairs(sandClouds) do
        local dx = virtualCursor.x - c.x
        local dy = virtualCursor.y - c.y
        if dx*dx + dy*dy < c.radius * c.radius then
            cursorInCloud = true
            break
        end
    end

    if cursorInCloud then
        -- Convert cursor world position to screen space
        local sx, sy
        if camera.enabled then
            sx = width  / 2 + (virtualCursor.x - camera.x) * camera.zoom
            sy = height / 2 + (virtualCursor.y - camera.y) * camera.zoom
        else
            sx, sy = virtualCursor.x, virtualCursor.y
        end

        -- Scale the vision hole with the cursor's effective screen size
        local effectiveScale = cursorScale * (camera.enabled and camera.zoom or 1)
        local cursorPx = math.max(cursor:getWidth(), cursor:getHeight()) * effectiveScale
        local clearR  = cursorPx * 0.9    -- fully transparent inside
        local fadeR   = cursorPx * 2.5    -- fully opaque beyond

        -- Punch the clear circle into the stencil buffer
        love.graphics.stencil(function()
            love.graphics.circle("fill", sx, sy, clearR)
        end, "replace", 1)

        -- Draw full-screen black where stencil == 0 (outside the clear circle)
        love.graphics.setStencilTest("notequal", 1)
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.rectangle("fill", 0, 0, width, height)
        love.graphics.setStencilTest()

        -- Soft gradient rings from clearR to fadeR (no stencil, alpha blended)
        local steps = 24
        love.graphics.setLineWidth((fadeR - clearR) / steps * 2.2)
        for i = 1, steps do
            local t = i / steps
            love.graphics.setColor(0, 0, 0, t * t)
            love.graphics.circle("line", sx, sy, clearR + (fadeR - clearR) * t)
        end
        love.graphics.setLineWidth(1)
    end

    -- Puffer debug HUD
    if debugMode and #pufferList > 0 then
        local pf = pufferList[1]
        local C  = require("conditions")
        local x, y = 10, 60
        local lineH = 22

        -- Conditions to display: {label, result}
        local SeesPredatorCone = require("conditions.puffer_sees_predator")
        local conds = {
            { "IsPuffed",        C.IsPuffed(pf, blackboard) },
            { "SeesPredator",    SeesPredatorCone(pf, blackboard) },
            { "CaughtByPlayer",  C.CaughtByPlayer(pf, blackboard) },
            { "SeesKrill",       C.SeesKrillPuffer(pf, blackboard) },
        }

        love.graphics.setFont(debug_font)
        love.graphics.setColor(0, 0, 0, 0.55)
        love.graphics.rectangle("fill", x - 4, y - 4, 230, lineH * (#conds + 2) + 8)

        for i, c in ipairs(conds) do
            if c[2] then
                love.graphics.setColor(0.2, 1, 0.2, 1)
            else
                love.graphics.setColor(1, 0.2, 0.2, 1)
            end
            love.graphics.print((c[2] and "[T] " or "[F] ") .. c[1], x, y + (i-1)*lineH)
        end

        -- Current action
        love.graphics.setColor(1, 1, 0, 1)
        love.graphics.print("Action: " .. tostring(pf.debugAction or "?"), x, y + #conds * lineH + 4)
    end

    -- HUD (screen space — always drawn at native resolution)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(debug_font)
    -- Oxygen bar
    love.graphics.setColor(1 - (oxygen_left / oxygen_time), oxygen_left / oxygen_time, 0)
    love.graphics.rectangle("fill", 10, height - 30, oxygen_left * 10, 20)
    if not death then
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("FPS: "  .. tostring(love.timer.getFPS()), 10, 10)
        love.graphics.print("Fish: "   .. tostring(#school),    width - 120, height - 50)
        love.graphics.print("Caught: " .. tostring(fishCaught), width - 120, height - 30)
        if camera.enabled then
            love.graphics.print("CAM x" .. camera.zoom, width / 2 - 30, 10)
        end
        love.graphics.print("Line: " .. tostring(math.floor(lineTetherLength)) .. "px", 10, 30)
    end
end

function love.quit() end
