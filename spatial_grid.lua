local SpatialGrid = {}
SpatialGrid.__index = SpatialGrid

function SpatialGrid.new(width, height, cellSize)
    local self = setmetatable({}, SpatialGrid)
    self.cellSize = cellSize
    self.cols = math.ceil(width / cellSize)
    self.rows = math.ceil(height / cellSize)
    self.grid = {}
    return self
end

function SpatialGrid:clear()
    self.grid = {}
end

function SpatialGrid:add(entity)
    local col = math.floor(entity.x / self.cellSize) + 1
    local row = math.floor(entity.y / self.cellSize) + 1
    
    local key = col .. "," .. row
    if not self.grid[key] then self.grid[key] = {} end
    table.insert(self.grid[key], entity)
end

-- Returns fish in this cell and the 8 surrounding cells
function SpatialGrid:getNearby(x, y)
    local col = math.floor(x / self.cellSize) + 1
    local row = math.floor(y / self.cellSize) + 1
    local nearby = {}
    
    for c = col - 1, col + 1 do
        for r = row - 1, row + 1 do
            local key = c .. "," .. r
            if self.grid[key] then
                for _, entity in ipairs(self.grid[key]) do
                    table.insert(nearby, entity)
                end
            end
        end
    end
    return nearby
end

return SpatialGrid