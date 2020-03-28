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

render.draw_tile = function(x, y, tile_index)
  assert(render.tileset_quads[tile_index])

  love.graphics.draw(render.tileset,
                     render.tileset_quads[tile_index],
                     x * constants.render_scale,
                     y * constants.render_scale,
                     0, constants.render_scale, constants.render_scale)
end

render.draw_grid = function(x, y, tile_grid)
  for grid_y = 1,#tile_grid do
    for grid_x=1,#(tile_grid[grid_y]) do
      local index = tile_grid[grid_y][grid_x]
      if index ~= 0 then
        render.draw_tile(x + (grid_x-1) * constants.tile_size, y + (grid_y-1) * constants.tile_size, index)
      end
    end
  end

end

render.draw = function()
  --render.draw_tile(10, 10, 2)

  local level =
  {
    {1,  2,  3,  4},
    {11, 12, 0, 14},
    {11, 12, 12, 14},
    {21, 2,  2,  24},
  }

  render.draw_grid(1, 0, level)
end

return render