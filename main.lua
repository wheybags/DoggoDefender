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
  if key == "space" then
    simulation.shoot(state)
  end
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
