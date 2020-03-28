local simulation = {}

simulation.create_state = function()

    local level_str = [[
m-----,------,
]     [      [
>--------D---<
]            [
]            [
]     h      [
]            [
]            [
]            [
/------------.
``````````````
``````````````
``````````````
``````````````
``````z```````
``````````````
``````````````
]]

  local level = {}

  for line in level_str:gmatch("([^\n]*)\n?") do
    local row = {}
    for c in line:gmatch(".") do
      local entity

      if c == "-" then
        entity = {type = "wall", wall_type = "horizontal"}
      elseif c == "[" then
        entity = {type = "wall", wall_type = "vertical_r"}
      elseif c == "]" then
        entity = {type = "wall", wall_type = "vertical_l"}
      elseif c == "m" then
        entity = {type = "wall", wall_type = "top_left"}
      elseif c == "," then
        entity = {type = "wall", wall_type = "top_right"}
      elseif c == "." then
        entity = {type = "wall", wall_type = "bottom_right"}
      elseif c == "/" then
        entity = {type = "wall", wall_type = "bottom_left"}
      elseif c == "<" then
        entity = {type = "wall", wall_type = "t_right"}
      elseif c == ">" then
        entity = {type = "wall", wall_type = "t_left"}
      elseif c == "D" then
        entity = {type = "door"}
      elseif c == "z" then
        entity = {type = "zombie"}
      elseif c == "h" then
        entity = {type = "human"}
      end

      if entity then
        entity.pos = {#row+1, #level+1}
      end

      table.insert(row, {entity = entity})
      end
    table.insert(level, row)
  end

  return
  {
    level = level,
    tick = 0,
  }
end


simulation._move_entity = function(state, entity, x, y)
  state.level[entity.pos[2]][entity.pos[1]].entity = nil

  assert(state.level[y][x].entity == nil)
  state.level[y][x].entity = entity
  entity.pos = {x, y}
end

simulation._is_passable = function(state, x, y)
  if x < 1 or x > #state.level[1] or y < 1 or y > #state.level then
    return false
  end

  return state.level[y][x].entity == nil
end

simulation._update_zombie = function(state, zombie)

  if state.tick % 60  == 0 then
    local target_pos = {zombie.pos[1], zombie.pos[2] - 1}

    if simulation._is_passable(state, target_pos[1], target_pos[2]) then
      simulation._move_entity(state, zombie, target_pos[1], target_pos[2])
    end
  end
end
simulation.update = function(state)

  for _, row in pairs(state.level) do
    for _, tile in pairs(row) do
      local entity = tile.entity

      if entity then
        if entity.type == "zombie" then simulation._update_zombie(state, entity) end
      end
    end
  end

  state.tick = state.tick + 1
end

return simulation