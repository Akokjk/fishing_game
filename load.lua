function love.load()
    width  = 1920
    height = 1080
    boundary = 10
    grid = SpatialGrid.new(width, height, 100)
    love.window.setMode(width, height, {
        fullscreen = true, vsync = true, msaa = 0, stencil = true,
        depth = 0, resizable = true, borderless = false, centered = false,
        display = 1, minwidth = 1, minheight = 1,
    })

    debug_font = love.graphics.newFont("Roboto-Regular.ttf")
    love.window.setTitle("Fishing Game on Rye")
    math.randomseed(os.time())
    width, height = love.graphics.getDimensions()

    -- Assets
    cursorScale    = 2
    cursor         = love.graphics.newImage("cursor.png")
    bird_img             = love.graphics.newImage("bird.png")
    small_fish_img       = love.graphics.newImage("small_fish.png")
    pred_fish_img        = love.graphics.newImage("pred_fish.png")
    pred_fish_mouth_img  = love.graphics.newImage("pred_fish_mouth.png")
    jelly_head_img       = love.graphics.newImage("jelly_head.png")
    jell_tentacle_img    = love.graphics.newImage("jell_tenticle.png")
    bird_img:setFilter("nearest", "nearest")
    small_fish_img:setFilter("nearest", "nearest")
    pred_fish_img:setFilter("nearest", "nearest")
    pred_fish_mouth_img:setFilter("nearest", "nearest")
    jelly_head_img:setFilter("nearest", "nearest")
    jell_tentacle_img:setFilter("nearest", "nearest")
    cursor:setFilter("nearest", "nearest")
    pop_sound   = love.audio.newSource("pop.wav",   "static")
    eat_sound   = love.audio.newSource("eat.wav",   "static")
    crunch_sound = love.audio.newSource("crunch.wav", "static")

    -- Environment
    oxygen_time       = 100
    oxygen_left       = 100
    water_to_air_ratio = 0.8
    sun_radius_ratio  = 0.05
    sandHeight        = 55   -- pixels of sand at the water floor
    death             = false

    virtualCursor.x = width  / 2
    virtualCursor.y = height * (1 - water_to_air_ratio) / 2
    virtualCursor._pendingDx = 0
    virtualCursor._pendingDy = 0
    love.mouse.setRelativeMode(true)   -- lock OS cursor; use deltas only

    -- Reset ecosystem
    school        = {}
    sandParticles = {}
    sandClouds    = {}
    bloodClouds   = {}
    sharkList     = {}
    krillList    = {}
    predatorList = {}
    rockList     = {}
    jellyList    = {}
    pufferList      = {}
    vortexList      = {}
    vortexSpawnTimer = 0
    birdList        = {}
    heldRock     = nil
    heldFish     = nil
    fishCaught   = 0

    local waterTop = height * (1 - water_to_air_ratio)

    --[[ small fish, krill, predators disabled for puffer debug
   

    for i = 1, 50 do
        table.insert(krillList, Krill.new(math.random(width), math.random(waterTop, height)))
    end

   
    --]]

     for i = 1, 500 do
        local f = SmallFish.new(math.random(width), math.random(waterTop, height))
        f.image = small_fish_img
        table.insert(school, f)
    end

     for i = 1, 10 do
        local p = PredatorFish.new(math.random(width), math.random(waterTop, height))
        p.image      = pred_fish_img
        p.imagemouth = pred_fish_mouth_img
        table.insert(predatorList, p)
    end

    -- Rocks: rejection-sample so none overlap
    local attempts = 0
    while #rockList < 4 and attempts < 200 do
        attempts = attempts + 1
        local size = 14 + math.random() * 18
        local rx   = math.random(size + 10, width - size - 10)
        local ry   = height - sandHeight - size * 0.4
        local ok   = true
        for _, existing in ipairs(rockList) do
            local dx = rx - existing.x
            local dy = ry - existing.y
            if dx*dx + dy*dy < (size + existing.size + 8)^2 then
                ok = false
                break
            end
        end
        if ok then table.insert(rockList, Rock.new(rx, ry, size)) end
    end

    do
        local px = width * 0.5
        local py = waterTop + (height - waterTop) * 0.5
        table.insert(pufferList, PufferFish.new(px, py))
    end

    for i = 1, 4 do
        local bx = math.random(width)
        local by = math.random(10, math.floor(height * (1 - water_to_air_ratio) - 20))
        local b  = Bird.new(bx, by)
        b.image  = bird_img
        b.glideTimer = math.random() * 2   -- stagger so they don't all dive at once
        table.insert(birdList, b)
    end

   
    for i = 1, 1 do
        local sx = math.random(width)
        local sy = waterTop + 80 + math.random() * (height - waterTop - 200)
        table.insert(sharkList, Shark.new(sx, sy))
    end

    for i = 1, 8 do
        local jx = math.random(width)
        local jy = waterTop + 40 + math.random() * (height - waterTop - 100)
        local jelly = Jellyfish.new(jx, jy)
        jelly.headImg      = jelly_head_img
        jelly.tentacleImg  = jell_tentacle_img
        table.insert(jellyList, jelly)
    end
   

    fishBatch = love.graphics.newSpriteBatch(small_fish_img, 3000, "stream")
end
