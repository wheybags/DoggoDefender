local render = require("render")
local simulation = require("simulation")

local state

function love.load()
  render.setup()
  state = simulation.create_state()
end

function love.draw()
  render.draw(state)
end

function love.resize()

end

function love.keypressed(key)

end


function love.mousemoved(x,y)

end

function love.wheelmoved(x,y)

end

function love.mousepressed(x,y,button)

end

function love.quit()

end

local fixed_update = function()
  local player_vector = {0, 0}

  if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
    player_vector = {-1, 0}
  end
  if love.keyboard.isDown("right") or love.keyboard.isDown("d") then
    player_vector = {1, 0}
  end
  if love.keyboard.isDown("up") or love.keyboard.isDown("w") then
    player_vector = {0, -1}
  end
  if love.keyboard.isDown("down") or love.keyboard.isDown("s") then
    player_vector = {0, 1}
  end

  local strafing = love.keyboard.isDown("left") or love.keyboard.isDown("right") or love.keyboard.isDown("up") or love.keyboard.isDown("down")

  if player_vector[1] ~= 0 or player_vector[2] ~= 0 then
    simulation.move_player(state, player_vector, strafing)
  end

  if love.keyboard.isDown("space") then
    simulation.shoot(state)
  end

  simulation.update(state)
end


local accumulatedDeltaTime = 0
function love.update(deltaTime)
  accumulatedDeltaTime = accumulatedDeltaTime + deltaTime

  local tickTime = 1/60

  while accumulatedDeltaTime > tickTime do
    fixed_update()
    accumulatedDeltaTime = accumulatedDeltaTime - tickTime
  end

end
