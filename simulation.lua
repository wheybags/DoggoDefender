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

  local player

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
        --entity = {type = "zombie"}
      elseif c == "h" then
        entity = {type = "human"}
        player = entity
      end

      if entity then
        entity.pos = {#row+1, #level+1}
      end

      table.insert(row, {entities = {entity}})
      end
    table.insert(level, row)
  end

  if #level[#level] == 0 then
    table.remove(level, #level)
  end

  local w = #level[1]
  for _, row in pairs(level) do
    assert(#row == w)
  end

  return
  {
    level = level,
    player = player,
    tick = 0,
  }
end

simulation.shoot = function(state)
  local pos = {unpack(state.player.pos)}

  table.insert(state.level[pos[2]][pos[1]].entities, {type = "knife", pos = pos})
end

simulation._is_oob = function(state, x, y)
  return x < 1 or x > #state.level[1] or y < 1 or y > #state.level
end

simulation._remove_entity = function (state, entity)
  local old_tile = state.level[entity.pos[2]][entity.pos[1]]
  local removed = false
  for i, tile_entity in pairs(old_tile.entities) do
    if tile_entity == entity then
      table.remove(old_tile.entities, i)
      removed = true
      break
    end
  end

  assert(removed)
end

simulation._move_entity = function(state, entity, x, y)
  if simulation._is_oob(state, x, y) then
    error("oob")
  end

  simulation._remove_entity(state, entity)

  --assert(state.level[y][x].entity == nil)
  --print("AAA", x, y, #state.level[y])
  assert(state.level[y])
  assert(state.level[y][x])
  table.insert(state.level[y][x].entities, entity)
  entity.pos = {x, y}
end

simulation._is_passable = function(state, for_entity, x, y)
  if simulation._is_oob(state, x, y) then
    return false
  end

  if for_entity.type == "knife" then
    return true
  end

  for _, tile_entity in pairs(state.level[y][x].entities) do
    return false
  end

  return true
end

simulation._update_zombie = function(state, zombie)
  if state.tick % 60 == 0 then
    local target_pos = {zombie.pos[1], zombie.pos[2] - 1}

    if simulation._is_passable(state, zombie, target_pos[1], target_pos[2]) then
      simulation._move_entity(state, zombie, target_pos[1], target_pos[2])
    end
  end
end

simulation._update_knife = function(state, knife)
  if state.tick % 10 == 0 then
    local target_pos = { knife.pos[1], knife.pos[2] + 1}

    if simulation._is_oob(state, target_pos[1], target_pos[2]) then
      simulation._remove_entity(state, knife)
      return
    end

    if simulation._is_passable(state, knife, target_pos[1], target_pos[2]) then
      simulation._move_entity(state, knife, target_pos[1], target_pos[2])
    end
  end
end

simulation.update = function(state)

  local entities = {}

  for _, row in pairs(state.level) do
    for _, tile in pairs(row) do
      for _, entity in pairs(tile.entities) do
        table.insert(entities, entity)
      end
    end
  end

  for _, entity in pairs(entities) do
    if entity.type == "zombie" then simulation._update_zombie(state, entity) end
    if entity.type == "knife" then simulation._update_knife(state, entity) end
  end

  state.tick = state.tick + 1
end

return simulation