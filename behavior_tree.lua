-- src/BehaviorTree.lua
local BT = {}

-- ==========================================
-- 1. BASE NODE (The Parent Blueprint)
-- ==========================================
BT.Node = {}
BT.Node.__index = BT.Node

function BT.Node:new()
    return setmetatable({}, self)
end

function BT.Node:evaluate(agent, blackboard)
    return "FAILURE" -- Default, meant to be overridden
end

-- ==========================================
-- 2. SELECTOR (?) - The "OR" Gate
-- Tries children left-to-right. Stops if ONE succeeds.
-- ==========================================
BT.Selector = setmetatable({}, {__index = BT.Node})
BT.Selector.__index = BT.Selector

function BT.Selector:new(children)
    local self = setmetatable(BT.Node:new(), BT.Selector)
    self.children = children or {}
    return self
end

function BT.Selector:evaluate(agent, blackboard)
    for _, child in ipairs(self.children) do
        local status = child:evaluate(agent, blackboard)
        if status == "SUCCESS" or status == "RUNNING" then
            return status -- Stop immediately and pass the success up!
        end
    end
    return "FAILURE" -- Only fails if ALL children failed
end

-- ==========================================
-- 3. SEQUENCE (->) - The "AND" Gate
-- Tries children left-to-right. Stops if ONE fails.
-- ==========================================
BT.Sequence = setmetatable({}, {__index = BT.Node})
BT.Sequence.__index = BT.Sequence

function BT.Sequence:new(children)
    local self = setmetatable(BT.Node:new(), BT.Sequence)
    self.children = children or {}
    return self
end

function BT.Sequence:evaluate(agent, blackboard)
    for _, child in ipairs(self.children) do
        local status = child:evaluate(agent, blackboard)
        if status == "FAILURE" then
            return "FAILURE" -- Stop immediately! The sequence is broken.
        end
        if status == "RUNNING" then
            return "RUNNING" -- Pause here until next frame
        end
    end
    return "SUCCESS" -- Only succeeds if ALL children succeeded
end

-- ==========================================
-- 4. CONDITION (Yellow Box) - The Sensor
-- Returns SUCCESS if true, FAILURE if false.
-- ==========================================
BT.Condition = setmetatable({}, {__index = BT.Node})
BT.Condition.__index = BT.Condition

function BT.Condition:new(checkFunc)
    local self = setmetatable(BT.Node:new(), BT.Condition)
    self.checkFunc = checkFunc
    return self
end

function BT.Condition:evaluate(agent, blackboard)
    if self.checkFunc(agent, blackboard) then
        return "SUCCESS"
    else
        return "FAILURE"
    end
end

-- ==========================================
-- 5. ACTION (Green Box) - The Motor
-- Executes a function and returns its status.
-- ==========================================
BT.Action = setmetatable({}, {__index = BT.Node})
BT.Action.__index = BT.Action

function BT.Action:new(actionFunc)
    local self = setmetatable(BT.Node:new(), BT.Action)
    self.actionFunc = actionFunc
    return self
end

function BT.Action:evaluate(agent, blackboard)
    -- The action function itself must return "SUCCESS", "FAILURE", or "RUNNING"
    return self.actionFunc(agent, blackboard)
end

return BT