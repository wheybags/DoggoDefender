local simulation = {}

simulation.create_state = function()

    local level_str = [[
m-----,-----,
]     [     [
>-------D---<
]xxxxxdxxxxx[
]xxxxxxxxxxx[
]           [
]     h     [
]           [
]           [
]           [
/-----------.
`````````````
`````````````
`````````````
`````````````
`````````````
ZZZZZZZZZZZZZ
ZZZZZZZZZZZZZ
]]

  local level = {}

  local player
  local dog

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
      elseif c == "d" then
        entity = {type = "dog"}
        dog = entity
      elseif c == "x" then
        entity = {type = "dogfloor"}
      elseif c == "h" then
        entity = {type = "human", direction = {0, 1}}
        player = entity
      elseif c == "Z" then
        entity = {type = "spawner"}
      end

      if entity then
        entity.pos = {#row+1, #level+1}
        entity.creation = 0
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
    dog = dog,
    tick = 0,
    last_shot_tick = -999,
    last_move_tick = -999,
  }
end

simulation._shoot = function(state)
  if state.player == nil then return end

  if state.tick - state.last_shot_tick < 60 * 0.3 then
    return
  end

  state.last_shot_tick = state.tick

  local pos = {unpack(state.player.pos)}

  table.insert(state.level[pos[2]][pos[1]].entities, {type = "knife", pos = pos, creation = state.tick, direction = {unpack(state.player.direction)}})
end

simulation._move_player = function(state, vec, strafing)
  if state.player == nil then return end

  if not strafing then
    state.player.direction = vec
  end

  if state.tick - state.last_move_tick < 60 * 0.2 then
    return
  end

  local target_pos = {state.player.pos[1] + vec[1], state.player.pos[2] + vec[2]}

  if simulation._is_passable(state, state.player, target_pos[1], target_pos[2]) then
    simulation._move_entity(state, state.player, target_pos[1], target_pos[2])
    state.last_move_tick = state.tick
  end
end

simulation._is_oob = function(state, x, y)
  return x < 1 or x > #state.level[1] or y < 1 or y > #state.level
end

simulation._remove_entity = function (state, entity)
  entity.removed = true

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
  entity.removed = nil
end

simulation._is_passable = function(state, for_entity, x, y, blocking)
  if blocking == nil then blocking = {} end

  if simulation._is_oob(state, x, y) then
    return false
  end

  for _, tile_entity in pairs(state.level[y][x].entities) do
    local passables =
    {
      "tombstone",
      "dogfloor",
      "spawner",
    }

    local is_passable = false
    for _, passable in pairs(passables) do
      if tile_entity.type == passable then
        is_passable = true
        break
      end
    end

    if not is_passable then
      if for_entity.type == "knife" then
        if tile_entity.type == "zombie" then
          table.insert(blocking, tile_entity)
        end
        return true
      else
        table.insert(blocking, tile_entity)
        return false
      end
    end
  end

  return true
end

simulation._update_zombie = function(state, zombie)
  if (state.tick - zombie.creation) % 60 == 0 then

    local on_dogfloor = false

    local current_tile = state.level[zombie.pos[2]][zombie.pos[1]]
    for _, entity in pairs(current_tile.entities) do
      if entity.type == "dogfloor" then
        on_dogfloor = true
        break
      end
    end

    local target_pos
    if on_dogfloor and state.dog then
      if state.dog.pos[1] < zombie.pos[1] then
        target_pos =  {zombie.pos[1] - 1, zombie.pos[2]}
      elseif state.dog.pos[1] > zombie.pos[1] then
        target_pos =  {zombie.pos[1] + 1, zombie.pos[2]}
      elseif state.dog.pos[2] < zombie.pos[2] then
        target_pos =  {zombie.pos[1], zombie.pos[2] - 1}
      elseif state.dog.pos[2] > zombie.pos[2] then
        target_pos =  {zombie.pos[1], zombie.pos[2] + 1}
      end
    else
      target_pos = {zombie.pos[1], zombie.pos[2] - 1}
    end

    local blocking = {}

    if simulation._is_passable(state, zombie, target_pos[1], target_pos[2], blocking) then
      simulation._move_entity(state, zombie, target_pos[1], target_pos[2])
    end

    if blocking[1] and blocking[1].type == "wall" then
      local blocker = blocking[1]

      if zombie.blocked_by and zombie.blocked_by.blocker == blocker then
        if state.tick - zombie.blocked_by.tick > 60 * 1 then
          simulation._remove_entity(state, blocking[1])
          zombie.blocked_by = nil
        end
      else
        zombie.blocked_by = {tick = state.tick, blocker = blocker}
      end
    end

    if blocking[1] and blocking[1].type == "human" then
      simulation._remove_entity(state, blocking[1])
      state.player = nil
      table.insert(state.level[target_pos[2]][target_pos[1]].entities, {type = "swirl", orig = "human", pos = target_pos, creation = state.tick})
    end

    if blocking[1] and blocking[1].type == "dog" then
      simulation._remove_entity(state, blocking[1])
      state.dog = nil
      table.insert(state.level[target_pos[2]][target_pos[1]].entities, {type = "swirl", orig = "dog", pos = target_pos, creation = state.tick})
    end
  end
end

simulation._update_knife = function(state, knife)
  if (state.tick - knife.creation) % math.floor(60 * 0.1) == 0 then
    local target_pos = { knife.pos[1] + knife.direction[1], knife.pos[2] + knife.direction[2]}

    if simulation._is_oob(state, target_pos[1], target_pos[2]) then
      simulation._remove_entity(state, knife)
      return
    end

    local blocking = {}

    if simulation._is_passable(state, knife, target_pos[1], target_pos[2], blocking) then
      simulation._move_entity(state, knife, target_pos[1], target_pos[2])
    end

    if blocking[1] and blocking[1].type == "zombie" then
      simulation._remove_entity(state, blocking[1])
      simulation._remove_entity(state, knife)

      table.insert(state.level[target_pos[2]][target_pos[1]].entities, {type = "swirl", orig = "zombie", pos = target_pos, creation = state.tick})
      return
    end
  end
end

simulation._update_swirl = function(state, swirl)
  if state.tick - swirl.creation > 60 * 2 then
    simulation._remove_entity(state, swirl)
    table.insert(state.level[swirl.pos[2]][swirl.pos[1]].entities, {type = "tombstone", pos = swirl.pos, creation = state.tick})
  end
end

simulation._update_player = function(state)
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
    simulation._move_player(state, player_vector, strafing)
  end

  if love.keyboard.isDown("space") then
    simulation._shoot(state)
  end
end

simulation.update = function(state)
  state.tick = state.tick + 1

  if state.dog == nil then
    return
  end

  simulation._update_player(state)

  local entities = {}

  for _, row in pairs(state.level) do
    for _, tile in pairs(row) do
      for _, entity in pairs(tile.entities) do
        table.insert(entities, entity)
      end
    end
  end

  for _, entity in pairs(entities) do
    if not entity.removed then
      if entity.type == "swirl" then simulation._update_swirl(state, entity) end
      if entity.type == "zombie" then simulation._update_zombie(state, entity) end
      if entity.type == "knife" then simulation._update_knife(state, entity) end
    end
  end

  if state.tick % (60 * 10) == 0 then
    local spawners = {}
    for _, entity in pairs(entities) do
      if entity.type == "spawner" then
        table.insert(spawners, entity)
      end
    end

    local to_spawn = 10

    for _=1,to_spawn do
      local zombie = {type = "zombie", pos = {0, 0}, creation = state.tick}

      local pos
      while true do
        local index = math.floor(math.random() * (#spawners-1)) + 1
        pos = {unpack(spawners[index].pos)}

        if simulation._is_passable(state, zombie, pos[1], pos[2]) then
          break
        end
      end

      zombie.pos = pos
      table.insert(state.level[pos[2]][pos[1]].entities, zombie)
    end
  end
end

return simulation