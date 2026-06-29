-- src/fish_types/Krill.lua
local FishBase = require("fish_base")
local BT = require("behavior_tree")
local C = require("conditions")
local A = require("actions")

local Krill = setmetatable({}, {__index = FishBase})
Krill.__index = Krill

function Krill.new(x, y)
    local self = FishBase.new(x, y)
    setmetatable(self, Krill)
    
    -- Krill are slow and weak
    self.maxSpeed = 40 
    self.maxForce = 10 
    self.color = {0, 1, 0} -- Green
    self.species = "Krill"     -- An ID tag to help other fish identify it
    
    self.currentThreat = nil   -- Used to remember what it's running from
    
    -- ==========================================
    -- THE BRAIN
    -- ==========================================
    self.brain = BT.Selector:new({
        
        -- Priority 1: Avoid EVERYTHING
        BT.Sequence:new({
            BT.Condition:new(C.SeesNonKrill),
            BT.Action:new(A.Flee)
        }),
        
        -- Priority 2: Swarm with other Krill
        BT.Sequence:new({
            BT.Condition:new(C.OtherKrillNearby),
            -- You can reuse the Small Fish 'School' action, 
            -- just make sure it looks at blackboard.krill instead of blackboard.school!
            BT.Action:new(A.School) 
        }),
        
        -- Priority 3: Drift
        BT.Action:new(A.Swim)
    })
    
    return self
end

function Krill:draw()
    -- 1. Set the color to our new green
    love.graphics.setColor(self.color)
    
    -- 2. Draw a simple filled circle at the Krill's exact X and Y
    love.graphics.circle("fill", self.x, self.y, 4)
    
    -- 3. Reset color back to white so other sprites draw normally
    love.graphics.setColor(1, 1, 1)
end

return Krill