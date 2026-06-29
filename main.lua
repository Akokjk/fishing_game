-- ============================================================
--  Globals: modules
-- ============================================================
polar       = require("polar")
hotreload   = require("hotreload")
SpatialGrid = require("spatial_grid")
SmallFish   = require("animals.small_fish")
Krill       = require("animals.krill")
PredatorFish = require("animals.predator_fish")
Shark        = require("animals.shark")
PufferFish   = require("animals.puffer_fish")
Bird         = require("animals.bird")
Rock        = require("objects")
Jellyfish   = require("animals.jellyfish")

-- ============================================================
--  Globals: ecosystem state
-- ============================================================
school          = {}
sandParticles   = {}
sandClouds      = {}
bloodClouds     = {}
sharkList       = {}
krillList       = {}
predatorList    = {}
rockList        = {}
jellyList       = {}
pufferList      = {}
blackboard      = {}
grid            = nil
fishBatch       = nil
heldRock        = nil
heldFish        = nil
heldFishByTail  = false   -- true when grabbed near the tail
debugMode          = false -- toggle with D

-- Vortices
vortexList      = {}
vortexSpawnTimer = 0
birdList        = {}

-- Ocean current
current = {
    vx         = 0,      -- actual current this frame (applied to fish)
    vy         = 0,
    targetVx   = 0,      -- what we're lerping toward
    targetVy   = 0,
    stateTimer = 0,      -- time left in current state
    isDead     = false,  -- true during calm periods
    driftX     = 0,      -- accumulated cursor drift offset (world space)
    driftY     = 0,
}
timeScale          = 1  -- slow motion for puffer debug; 1.0 = normal
predatorBiteRadius = 8  -- kill zone radius for predator fish (shared by draw + update)
lineTetherMax    = 300   -- hard cap on line length
lineTetherLength = 50   -- adjustable via scroll / up-down, range 10–lineTetherMax
lineTetherStep   = 5    -- px per scroll tick / arrow key press
fishCaught       = 0
krillSpawnTimer  = 0
krillSpawnInterval = 0.4

camera = {
    x       = 0,
    y       = 0,
    zoom    = 4,
    enabled = false,
}

-- ============================================================
--  Globals: virtual cursor
-- ============================================================
virtualCursor = {
    x = 0, y = 0,
    vx = 0, vy = 0,
    baseAccel    = 1200, baseDrag    = 4.5, baseMaxSpeed = 400,
    dashAccel    = 4000, dashMaxSpeed = 1000,
    isDashing    = false,
    baitCost     = 2.0,
    baitCooldown = 0,
    baitCooldownMax = 0.5,
    useHardwareCursor = true,
    stunTimer    = 0,
    trail        = {},
}

-- ============================================================
--  Hot-reload: unload all game modules and restart
-- ============================================================
function _G.reloadGameModules()
    local modules = {
        "polar", "hotreload", "spatial_grid",
        "animals.small_fish", "animals.krill", "animals.predator_fish",
        "animals.jellyfish", "objects", "fish_base", "behavior_tree",
        "actions", "conditions",
        "actions.flee", "actions.hide", "actions.cower_in_hiding",
        "actions.zigzag", "actions.thrash", "actions.eat_krill",
        "actions.school", "actions.swim", "actions.chase_cursor",
        "actions.chase_prey", "actions.hide_in_cloud", "actions.jump", "animals.shark",
        "actions.flap_tail", "actions.flee_from_predator", "actions.puff", "actions.face_closest_predator",
        "actions.slow_swim", "actions.fight_player", "actions.hover_swim", "actions.eat_krill_puffer",
        "conditions.is_puffed", "conditions.caught_by_player", "conditions.sees_krill", "conditions.puffer_sees_predator",
        "animals.puffer_fish",
        "conditions.sees_predator", "conditions.sees_cursor", "conditions.sand_cloud_nearby", "conditions.near_surface",
        "conditions.sees_small_fish", "conditions.rock_nearby",
        "conditions.is_hiding", "conditions.is_cornered",
        "conditions.predator_close", "conditions.is_hungry",
        "conditions.sees_food", "conditions.other_small_fish_nearby",
        "conditions.other_krill_nearby", "conditions.sees_non_krill",
        "animals.bird",
        "conditions.bird_is_underwater", "conditions.bird_is_diving", "conditions.bird_is_escaping",
        "actions.bird_glide", "actions.bird_dive", "actions.bird_swim", "actions.bird_escape",
        "load", "update", "draw",
    }
    for _, m in ipairs(modules) do package.loaded[m] = nil end

    local chunk, err = love.filesystem.load("main.lua")
    if chunk then chunk(); love.load()
    else print("Reload error: " .. tostring(err)) end
end

-- ============================================================
--  Wire up love callbacks from separate files
-- ============================================================
require("load")
require("update")
require("draw")
