-- src/fish_types/SmallFish.lua
local FishBase = require("fish_base")
local BT = require("behavior_tree") 
local C = require("conditions") -- Load the Sensors
local A = require("actions")    -- Load the Motors

local SmallFish = setmetatable({}, {__index = FishBase})
SmallFish.__index = SmallFish

function SmallFish.new(x, y)
    local self = FishBase.new(x, y)
    setmetatable(self, SmallFish)
    
    -- AI Variables
    self.perceptionRadius = 150
    self.hunger = 100
    self.hideTimer = 0
    self.isHiding = false
    self.hidingAt = nil
    
    -- DEBUG PHYSICS: Slowed way down!
    self.maxSpeed = 1000  -- Down from 150
    self.maxForce = 1000  -- Limits how fast it can turn
        


    self.energy       = 100
    self.energyMax    = 100
    self.jumpCooldown = 0
    self.drawAlpha = 1.0
    self.scale = 0.8 + (math.random() * 0.4)
    
    -- Random pastel tinting (Subtracting between 0 and 20% from pure white)
    self.color = {
        1.0 - (math.random() * 0.5), -- Red
        1.0 - (math.random() * 0.5), -- Green
        1.0 - (math.random() * 0.5)  -- Blue
    }    
    -- THE BRAIN
    self.brain = BT.Selector:new({
        -- HOOKED: fight the line by swimming hard toward the bottom
        BT.Sequence:new({
            BT.Condition:new(C.CaughtByPlayer),
            BT.Action:new(A.FightLine)
        }),
        -- ACTIVE THREAT: flee / hide
        BT.Sequence:new({
            BT.Condition:new(C.SeesPredator),
            BT.Selector:new({
                BT.Sequence:new({ BT.Condition:new(C.RockNearby),       BT.Action:new(A.Hide) }),
                BT.Sequence:new({ BT.Condition:new(C.NearSurface),      BT.Action:new(A.Jump) }),
                BT.Sequence:new({ BT.Condition:new(C.SandCloudNearby), BT.Action:new(A.HideInCloud) }),
                BT.Sequence:new({ BT.Condition:new(C.IsCornered),       BT.Action:new(A.Thrash) }),
                BT.Sequence:new({ BT.Condition:new(C.PredatorClose), BT.Action:new(A.ZigZag) }),
                BT.Action:new(A.Flee)
            })
        }),
        -- STILL HIDING: predator gone but wait out the timer
        BT.Sequence:new({
            BT.Condition:new(C.IsHiding),
            BT.Action:new(A.CowerInHiding)
        }),
        -- DAILY LIFE
        BT.Selector:new({
            BT.Sequence:new({
                BT.Condition:new(C.IsHungry),
                BT.Condition:new(C.SeesFood),
                BT.Action:new(A.EatKrill)
            }),
            BT.Sequence:new({
                BT.Condition:new(C.OtherSmallFishNearby),
                BT.Action:new(A.School)
            }),
            BT.Action:new(A.Swim)
        })
    })
    
    return self
end

function SmallFish:update(dt, blackboard)
    self.hunger = self.hunger + (10 * dt)

    -- Energy: regenerates while swimming, drained by special actions
    self.jumpCooldown = math.max(0, self.jumpCooldown - dt)
    self.energy = math.min(self.energyMax, self.energy + 8 * dt)

    -- Count down hide timer; also bail immediately if the rock starts moving
    self.hideTimer = math.max(0, self.hideTimer - dt)
    if self.hideTimer <= 0 or (self.hidingAt and self.hidingAt.isMoving) then
        self.hidingAt = nil
        self.isHiding = false
        self.hideTimer = 0
    end

    FishBase.update(self, dt, blackboard)

    -- Fade out when inside a sand cloud, fade back in otherwise
    local inCloud = false
    for _, c in ipairs(sandClouds) do
        local dx = self.x - c.x
        local dy = self.y - c.y
        if dx*dx + dy*dy < c.radius * c.radius then
            inCloud = true
            break
        end
    end
    local target = inCloud and 0.01 or 1.0
    self.drawAlpha = self.drawAlpha + (target - self.drawAlpha) * math.min(1, dt * 5)
end


-- NEW DEBUG DRAW FUNCTION
function SmallFish:draw()
    -- 1. Draw the Perception Radius (Faint white circle)
    love.graphics.setColor(1, 1, 1, 0.4) 
    --love.graphics.circle("fill", self.x, self.y, self.perceptionRadius)
    
    -- 2. Draw the Fish
   love.graphics.setColor(self.color)
    if self.image then
        local angle = math.atan2(self.vy, self.vx)
       love.graphics.draw(self.image, self.x, self.y, angle, self.scale, self.scale, self.image:getWidth()/2, self.image:getHeight()/2)
   
    end
end

return SmallFish