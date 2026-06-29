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
    self.brain = nil    -- This will hold the BT nodes
    
    return self
end

-- ==========================================
-- CORE GAME LOOP FUNCTIONS
-- ==========================================

function FishBase:update(dt, blackboard)
    -- 1. Run the Brain (If it has one)
    if self.brain then
        self.brain:evaluate(self, blackboard)
    end
    
    -- 2. Apply Acceleration to Velocity (Euler Integration)
    self.vx = self.vx + (self.accX * dt)
    self.vy = self.vy + (self.accY * dt)
    
    -- 3. Clamp Velocity to Max Speed
    local currentSpeed = math.sqrt(self.vx^2 + self.vy^2)
    if currentSpeed > self.maxSpeed then
        local ratio = self.maxSpeed / currentSpeed
        self.vx = self.vx * ratio
        self.vy = self.vy * ratio
    end
    
    -- 4. Apply Velocity to Position
    self.x = self.x + (self.vx * dt)
    self.y = self.y + (self.vy * dt)
    
    -- 5. Clear Acceleration for the next frame
    self.accX = 0
    self.accY = 0
    
    -- 6. Screen Wrapping (Keep them in the tank)
    self:wrapEdges()
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

-- Keeps the fish from swimming off the screen
function FishBase:wrapEdges()
    local w, h = love.graphics.getDimensions()
    if self.x > w + 20 then self.x = -20 end
    if self.x < -20 then self.x = w + 20 end
    if self.y > h + 20 then self.y = -20 end
    if self.y < -20 then self.y = h + 20 end
end

return FishBase