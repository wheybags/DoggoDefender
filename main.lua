local render = require("render")
local simulation = require("simulation")


local state

local music
local music_playing = false
play_music = function()
  love.audio.play(music)
  music_playing = true
end
stop_music = function()
  love.audio.stop(music)
  music_playing = false
end


local setup = function()
  render.setup()

  music = love.audio.newSource("/sfx/2019-12-09_-_Retro_Forest_-_David_Fesliyan.mp3", "stream")
  music:setLooping(true)

  play_music()
end

function love.load()
  setup()
end

function love.draw()
  if state == nil then
    render.draw_pre_game()
  else
    render.draw(state)
  end
end

function love.resize()

end

function love.keypressed(key)
  if key == "return" and (state == nil or state.dog == nil) then
    if not music_playing then
      play_music()
    end

    state = simulation.create_state()
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
  if state == nil then
    return
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
