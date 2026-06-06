polar = require("polar")
local hotreload = require("hotreload")


function _G.reloadGameModules()
    -- 1. Unload game modules
    package.loaded["polar"] = nil

    -- 2. Re-execute main.lua — this redefines love.draw, love.update, etc.
    local chunk, err = love.filesystem.load("main.lua")
    if chunk then
        chunk()
        love.load()  -- reinitialize state with the new love.load
    else
        print("Reload error: " .. tostring(err))
    end
end

function love.load()

  --config options
  width = 1000
  height = 1000
  boundary = 10 -- number of pixels away from edge
  love.window.setMode(width, height, {
    fullscreen = false,
    vsync = true,
    msaa = 0,
    stencil = true,
    depth = 0,
    resizable = true,
    borderless = false,
    centered = false,
    display = 1,
    minwidth = 1,
    minheight = 1
  })


  love.window.setTitle("Fishing Game on Rye")
  math.randomseed(os.time())
  width, height = love.graphics.getDimensions()


end



function love.draw()


    love.graphics.clear( 29/255, 23/255, 23/255, 1, 0, false )
    love.graphics.setColor(255,255,255)
    --love.graphics.circle("fill", 0, 0, 100); 

    love.graphics.setColor(0, 1, 1)

    --polar stuff goes here meaty man 
    polar.start(); 

    local length = width > height and height/2 or width/2 

    --bottom quad draw area angles are derived from a true isometric prospective view 
    polar.line(
      0, math.rad(0), -- Vertex 1: Bottom center corner
      length, math.rad(30),  -- Vertex 2: Far right corner (FIXED from 330)
      length, math.rad(90),  -- Vertex 3: Top center corner
      length, math.rad(150), -- Vertex 4: Far left corner (FIXED from 210)
      0, math.rad(0)  -- Close the loop back at Vertex 1
    )
    --right quad 
    polar.line(
      0, math.rad(270), -- Vertex 1: Bottom center corner
      length, math.rad(270),  -- Vertex 2: Far right corner (FIXED from 330)
      length, math.rad(330), 
      length, math.rad(30) 
    )
    --left quad
    polar.line(
      length, math.rad(150), -- Vertex 1: Bottom center corner
      length, math.rad(210),  -- Vertex 2: Far right corner (FIXED from 330)
      length, math.rad(270)
    )



    polar.stop(); 

end

function love.update(dt)
  -- Close the game immediately if Escape is pressed
    if love.keyboard.isDown("escape") then
        love.event.quit()
    end
    --this is cool beans bro i love you chat lol ai slop king 
    hotreload.check("f5") 

end


function love.quit()
  
end

