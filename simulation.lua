local simulation = {}

simulation.create_state = function()

    local level_str = [[
m-----,------,
]     [      [
>--------D---<
]            [
/------------.
]]

  local level = {}

  for line in level_str:gmatch("([^\n]*)\n?") do
    local row = {}
    for c in line:gmatch(".") do
      local tile = {type = "empty"}

      if c == "-" then
        tile = {type = "wall", wall_type = "horizontal"}
      elseif c == "[" then
        tile = {type = "wall", wall_type = "vertical_r"}
      elseif c == "]" then
        tile = {type = "wall", wall_type = "vertical_l"}
      elseif c == "m" then
        tile = {type = "wall", wall_type = "top_left"}
      elseif c == "," then
        tile = {type = "wall", wall_type = "top_right"}
      elseif c == "." then
        tile = {type = "wall", wall_type = "bottom_right"}
      elseif c == "/" then
        tile = {type = "wall", wall_type = "bottom_left"}
      elseif c == "<" then
        tile = {type = "wall", wall_type = "t_right"}
      elseif c == ">" then
        tile = {type = "wall", wall_type = "t_left"}
      elseif c == "D" then
        tile = {type = "door"}
      end

      table.insert(row, tile)
      end
    table.insert(level, row)
  end

  return
  {
    level = level
  }
end

return simulation