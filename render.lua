local constants = require("constants")

local render = {}

render.setup = function()
  render.tileset = love.graphics.newImage('gfx/colored_tilemap.png')
  render.tileset:setFilter("nearest")

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

render.draw_tile = function(x, y, tile_index, rotation)
  assert(render.tileset_quads[tile_index])

  if rotation == nil then rotation = 0 end

  love.graphics.draw(render.tileset,
                     render.tileset_quads[tile_index],
                     x * constants.render_scale,
                     y * constants.render_scale,
                     rotation, constants.render_scale, constants.render_scale,
                     constants.tile_size / 2, constants.tile_size / 2)
end


render._entity_to_index = function(entity)
  if entity == nil then
    return 12
  end

  if entity.type == "wall" then
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
  if entity.type == "door" then return 23 end
  if entity.type == "zombie" then return 10 end
  if entity.type == "human" then return 5 end
  if entity.type == "knife" then return 47 end
  if entity.type == "swirl" then return 10 end
  if entity.type == "tombstone" then return 79 end
end

render.draw_grid = function(x, y, state)
  local tile_grid = state.level

  for grid_y = 1,#tile_grid do
    for grid_x=1,#(tile_grid[grid_y]) do
      for _, entity in pairs(tile_grid[grid_y][grid_x].entities) do
        local index = render._entity_to_index(entity)

        local shift = 0
        if entity and entity.shift then shift = entity.shift end

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
          render.draw_tile(x + (grid_x-1) * constants.tile_size, y + (grid_y-1) * constants.tile_size + shift, index, rotation)
        end
      end
    end
  end
end


local level_to_tileset_grid = function(level)
  local grid = {}

  for y = 1,#level do
    local row = {}
    for x = 1,#(level[y]) do
      table.insert(row, render._entity_to_index(level[y][x]))
    end
    table.insert(grid, row)
  end

  return grid
end

render.draw = function(state)
  --render.draw_tile(10, 10, 2)

  --local level =
  --{
  --  {1,  2,  3,  4},
  --  {11, 12, 0, 14},
  --  {11, 12, 12, 14},
  --  {21, 2,  2,  24},
  --}



  --
  --local get = function(x, y, l)
  --  if x <= #l[1] and y <= #level and x > 0 and y > 0 then
  --    return l[y][x]
  --  end
  --
  --  return 0
  --end
  --
  --local level_walls_fixed = {table.unpack(level)}
  --
  --for y = 1,#level do
  --  for x = 1,#(level[y]) do
  --    if get(x, y, level) == 1 then
  --      if
  --    end
  --  end
  --end

  --local grid = level_to_tileset_grid(state.level)
  render.draw_grid((constants.screen_tiles_width / 2 - #state.level[1] / 2) * constants.tile_size,
                   (constants.screen_tiles_height / 2 - #state.level / 2) * constants.tile_size, state)
end

return render