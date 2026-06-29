-- src/FishBase.lua
local FishBase = {}
FishBase.__index = FishBase

function FishBase.new(x, y)
    local self = setmetatable({}, FishBase)
    
    -- Physical Position and Vectors
    self.x = x
    self.y = y
    self.vx = 0
    self.vy = 0
    self.accX = 0
    self.accY = 0
    
    -- Default Stats (To be overwritten by specific species)
    self.maxSpeed = 100
    self.maxForce = 50  -- How fast it can turn/accelerate
    self.color = {1, 1, 1}
    
    -- AI Variables
    self.brain = nil
    self.isAirborne = false
    self.stunTimer = 0

    return self
end

-- ==========================================
-- CORE GAME LOOP FUNCTIONS
-- ==========================================

function FishBase:update(dt, blackboard)
    -- Stunned: brain suspended, fish drifts to a stop
    if self.stunTimer > 0 then
        self.stunTimer = self.stunTimer - dt
        self.vx = self.vx * (1 - 3 * dt)
        self.vy = self.vy * (1 - 3 * dt)
        self.x  = self.x  + self.vx * dt
        self.y  = self.y  + self.vy * dt
        self:wrapEdges(blackboard)
        return
    end

    if self.isAirborne then
        -- Projectile arc: gravity only, no brain or steering
        self.vy = self.vy + 700 * dt
        self.x  = self.x  + self.vx * dt
        self.y  = self.y  + self.vy * dt

        -- Horizontal wrap still applies
        if blackboard then
            if self.x < -20 then self.x = blackboard.screenWidth + 20 end
            if self.x > blackboard.screenWidth + 20 then self.x = -20 end
        end

        -- Splash back into water
        if blackboard and self.y >= blackboard.waterTop then
            self.isAirborne = false
            self.vy = self.vy * 0.4   -- dampen entry
            self.vx = self.vx * 0.8
        end
        return
    end

    -- 1. Run the Brain
    if self.brain then
        self.brain:evaluate(self, blackboard)
    end

    -- 2. Apply Acceleration to Velocity
    self.vx = self.vx + (self.accX * dt)
    self.vy = self.vy + (self.accY * dt)

    -- 3. Clamp to Max Speed
    local currentSpeed = math.sqrt(self.vx^2 + self.vy^2)
    if currentSpeed > self.maxSpeed then
        local ratio = self.maxSpeed / currentSpeed
        self.vx = self.vx * ratio
        self.vy = self.vy * ratio
    end

    -- 4. Apply Velocity to Position
    self.x = self.x + (self.vx * dt)
    self.y = self.y + (self.vy * dt)

    -- 5. Clear Acceleration
    self.accX = 0
    self.accY = 0

    self:avoidOverlap(blackboard)
    self:wrapEdges(blackboard)
end

function FishBase:draw()
    love.graphics.setColor(self.color)
    -- A simple placeholder triangle pointing in the direction of movement
    local angle = math.atan2(self.vy, self.vx)
    
    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(angle)
    love.graphics.polygon("fill", 10, 0, -10, -5, -10, 5)
    love.graphics.pop()
end

-- ==========================================
-- STEERING MATH HELPERS (Used by Actions.lua)
-- ==========================================

-- Add raw force to the fish's acceleration
function FishBase:applyForce(fx, fy)
    self.accX = self.accX + fx
    self.accY = self.accY + fy
end

-- Calculates the vector to steer TOWARD a point
function FishBase:steerToward(targetX, targetY)
    local dx = targetX - self.x
    local dy = targetY - self.y
    local distance = math.sqrt(dx^2 + dy^2)
    
    if distance > 0 then
        -- Normalize and scale to max speed
        local desiredVx = (dx / distance) * self.maxSpeed
        local desiredVy = (dy / distance) * self.maxSpeed
        
        -- Calculate the steering force (Desired - Current)
        local steerX = desiredVx - self.vx
        local steerY = desiredVy - self.vy
        
        -- Clamp to max force
        local steerMag = math.sqrt(steerX^2 + steerY^2)
        if steerMag > self.maxForce then
            steerX = (steerX / steerMag) * self.maxForce
            steerY = (steerY / steerMag) * self.maxForce
        end
        
        return steerX, steerY
    end
    
    return 0, 0
end


-- Physically pushes fish apart if their bodies overlap
function FishBase:avoidOverlap(blackboard)
    if not blackboard then return end
    
    -- Figure out who our physical neighbors are
    local neighbors = blackboard.allFish
    if self.species == "Krill" then
        neighbors = blackboard.krill
    end
    
    local physicalRadius = 12 -- The "solid" size of the fish
    
    for _, other in ipairs(neighbors) do
        -- Don't check collision against ourselves
        if other ~= self then
            local dx = self.x - other.x
            local dy = self.y - other.y
            local distance = math.sqrt(dx*dx + dy*dy)
            
            -- Fallback: If two fish spawn on the exact same pixel, give them a tiny nudge
            -- so the distance math doesn't crash trying to divide by zero!
            if distance == 0 then
                dx = math.random() - 0.5
                dy = math.random() - 0.5
                distance = math.sqrt(dx*dx + dy*dy)
            end
            
            local minDistance = physicalRadius * 2
            
            -- If the distance between them is less than their combined width...
            if distance < minDistance then
                -- Calculate exactly how many pixels they are overlapping
                local overlap = minDistance - distance
                
                -- Calculate the direction to push away
                local pushX = (dx / distance) * overlap
                local pushY = (dy / distance) * overlap
                
                -- SOFT COLLISION: We only push them 10% of the overlap distance per frame (0.1).
                -- This allows them to "squeeze" through tight crowds instead of getting wedged!
                self.x = self.x + (pushX * 0.1)
                self.y = self.y + (pushY * 0.1)
                
                -- Notice we entirely deleted the self.vx * 0.95 dampening! 
                -- Now they keep their swimming momentum while sliding around each other.
            end
        end
    end
end


-- Allows endless horizontal swimming, but traps them vertically
function FishBase:wrapEdges(blackboard)
    -- Safety check in case blackboard isn't loaded yet
    if not blackboard then return end
    
    local padding = 10 -- How close they can get to the top/bottom before bouncing
    
    -- ==========================================
    -- 1. HORIZONTAL WRAPPING (Endless Ocean)
    -- ==========================================
    -- If they swim off the far left, teleport them to the far right
    if self.x < -20 then
        self.x = blackboard.screenWidth + 20
    end
    
    -- If they swim off the far right, teleport them to the far left
    if self.x > blackboard.screenWidth + 20 then
        self.x = -20
    end
    
    -- ==========================================
    -- 2. VERTICAL WALLS (Floor and Surface)
    -- ==========================================
    -- BOTTOM FLOOR (top of sand layer)
    local sandFloor = (blackboard.screenHeight - (blackboard.sandHeight or 0)) - padding
    if self.y > sandFloor then
        self.y = sandFloor
        if self.vy > 0 then
            self.vy = self.vy * -0.5
        end
    end
    
    -- TOP SURFACE (Water Line) — fast upward fish break the surface and jump
    if self.y < blackboard.waterTop  then
        if self.vy < -10 then
            self.isAirborne = true   -- launch into the air
        else
            self.y = blackboard.waterTop 
            if self.vy < 0 then self.vy = self.vy * -0.5 end
        end
    end
end

return FishBase