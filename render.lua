local constants = require("constants")

local render = {}

render.setup = function()
  render.tileset_color = love.graphics.newImage('gfx/colored_tilemap.png')
  render.tileset_color:setFilter("nearest")
  render.tileset_mono = love.graphics.newImage('gfx/monochrome_tilemap.png')
  render.tileset_mono:setFilter("nearest")
  render.tileset_font = love.graphics.newImage('gfx/font_2.png')
  render.tileset_font:setFilter("nearest")

  render.tileset = render.tileset_color

  render.tileset_quads = {}

  local tile_pad = 1
  local tileset_dim = 9

  for y = 0,tileset_dim do
    for x = 0,tileset_dim do
      local quad = love.graphics.newQuad(x * (constants.tile_size + tile_pad), y * (constants.tile_size + tile_pad),
        constants.tile_size, constants.tile_size,
        render.tileset:getDimensions()
      )

      table.insert(render.tileset_quads, quad)
    end
  end
end

render.draw_tile = function(x, y, tile_index, rotation, tileset)
  assert(render.tileset_quads[tile_index])

  if rotation == nil then rotation = 0 end
  if tileset == nil then tileset = render.tileset end

  love.graphics.draw(tileset,
                     render.tileset_quads[tile_index],
                     (x + (constants.tile_size / 2)) * constants.render_scale,
                     (y + (constants.tile_size / 2)) * constants.render_scale,
                     rotation, constants.render_scale, constants.render_scale,
                     constants.tile_size / 2, constants.tile_size / 2)
end


render._entity_to_index = function(entity)
  local lookup

  if entity == nil then
    return 12
  end

  lookup = function(entity_type)
    if entity_type == "wall" then
      if entity.wall_type == "horizontal" then return 2 end
      if entity.wall_type == "vertical_r" then return 14 end
      if entity.wall_type == "vertical_l" then return 11 end
      if entity.wall_type == "top_right" then return 4 end
      if entity.wall_type == "top_left" then return 1 end
      if entity.wall_type == "bottom_right" then return 54 end
      if entity.wall_type == "bottom_left" then return 53 end
      if entity.wall_type == "t_right" then return 52 end
      if entity.wall_type == "t_left" then return 51 end
    end
    if entity_type == "door" then return 23 end
    if entity_type == "zombie" then return 10 end
    if entity_type == "human" then return 5 end
    if entity_type == "knife" then return 47 end
    if entity_type == "swirl" then return lookup(entity.orig) end
    if entity_type == "tombstone" then return 79 end
    if entity_type == "dog" then return 16 end
    if entity_type == "dogfloor" then return 12 end
    if entity_type == "spawner" then return 45 end
  end

  return lookup(entity.type)
end

render.draw_grid = function(x, y, state)
  local tile_grid = state.level

  for grid_y = 1,#tile_grid do
    for grid_x=1,#(tile_grid[grid_y]) do

      -- draw ground tile
      render.draw_tile((x + grid_x-1) * constants.tile_size, (y + grid_y-1) * constants.tile_size, 12, 0)


      for _, entity in pairs(tile_grid[grid_y][grid_x].entities) do
        local index = render._entity_to_index(entity)

        if index ~= 0 then
          local rotation = 0
          if entity.type == "knife" or entity.type == "swirl" then
            local rotation_lut =
            {
              0 * math.pi / 180,
              90 * math.pi / 180,
              180 * math.pi / 180,
              270 * math.pi / 180,
            }

            local rotation_index = math.floor(state.tick / 12) % 4
            rotation = rotation_lut[rotation_index + 1]
            assert(rotation)
          end

          local tileset
          if entity.type == "swirl" and entity.orig == "dog" then
            tileset = render.tileset_color
          end

          render.draw_tile((x + grid_x-1) * constants.tile_size, (y + grid_y-1) * constants.tile_size, index, rotation, tileset)

          --love.graphics.setColor(1, 0, 0)
          --love.graphics.rectangle("line",
          --  (x + grid_x-1) * constants.tile_size * constants.render_scale,
          --  (y + grid_y-1) * constants.tile_size * constants.render_scale,
          --  constants.tile_size * constants.render_scale,
          --  constants.tile_size * constants.render_scale)
          --love.graphics.setColor(1,1,1)
        end
      end
    end
  end
end

render._get_font_index = function(char)
  local char_val = string.byte(char)

  if char_val >= string.byte('a') and char_val <= string.byte('z') then
    return 1 + char_val - string.byte('a')
  end

  if char_val >= string.byte('0') and char_val <= string.byte('9') then
    return 31 + char_val - string.byte('0')
  end

  if char == "?" then return 41 end
  if char == "!" then return 42 end
  if char == " " then return 43 end

  return 41
end

render._draw_text = function(x, y, text)
  for c in text:gmatch(".") do
    local index = render._get_font_index(c)
    render.draw_tile(x * constants.tile_size, y * constants.tile_size, index, 0, render.tileset_font)

    x = x + 1
  end
end

local str_pad = function (str, pad_char, target_size)
  while string.len(str) < target_size do
    str = pad_char .. str
  end

  return str
end

render.draw = function(state)
  love.graphics.clear(34/255, 35/255, 35/255)

  render.draw_grid(0, constants.screen_offset_y, state)

  local wave_str = "wave " .. str_pad(''..state.wave_display, '0', 4)
  local wave_str_pos = math.floor(constants.screen_tiles_width / 2 - string.len(wave_str) / 2)
  render._draw_text(wave_str_pos, 0, wave_str)
end

return render