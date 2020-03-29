local render = require("render")
local constants = require("constants")

local simulation = {}

simulation.create_state = function()

  local level_str = constants.level_ascii

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
        entity = {type = "human"}
        player = entity
      elseif c == "B" then
        entity = {type = "spawner", side = "bottom", direction = {0, -1}}
      elseif c == "T" then
        entity = {type = "spawner", side = "top", direction = {0, 1}}
      elseif c == "L" then
        entity = {type = "spawner", side = "left", direction = {1, -0}}
      elseif c == "R" then
        entity = {type = "spawner", side = "right", direction = {-1, 0}}
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
    wave = 1,
    wave_display = 1,
    wave_phase = 1,
    next_wave_tick = 1,
    last_shot_tick = -999,
    last_move_tick = -999,
    tileset = "color",
  }
end

simulation._shoot = function(state)
  if state.player == nil then return end

  if state.tick - state.last_shot_tick < 60 * 0.4 then
    return
  end

  state.last_shot_tick = state.tick

  for _, direction in pairs({{0,1}, {1,0}, {0,-1}, {-1,0}}) do
    local pos = {unpack(state.player.pos)}
    table.insert(state.level[pos[2]][pos[1]].entities,
      {
        type = "knife",
        pos = pos,
        creation = state.tick,
        direction = direction,
        moved = 0,
      })
  end
end

simulation._entity_die = function(state, entity)
  if entity == state.player then
    state.player = nil
  end
  if entity == state.dog then
    state.dog = nil
    state.tileset = "mono"
    stop_music()
    love.audio.play(love.audio.newSource("/sfx/Dog Death.wav", "stream"))
  end
  simulation._remove_entity(state, entity)
  table.insert(state.level[entity.pos[2]][entity.pos[1]].entities, {type = "swirl", orig = entity.type, pos = {unpack(entity.pos)}, creation = state.tick})
end

simulation._move_player = function(state, vec)
  if state.player == nil then return end

  if state.tick - state.last_move_tick < 60 * 0.15 then
    return
  end

  local target_pos = {state.player.pos[1] + vec[1], state.player.pos[2] + vec[2]}

  local blocking = {}

  if simulation._is_passable(state, state.player, target_pos[1], target_pos[2], blocking) then
    simulation._move_entity(state, state.player, target_pos[1], target_pos[2])
    state.last_move_tick = state.tick
  end

  if blocking[1] and blocking[1].type == "zombie" then
    simulation._entity_die(state, state.player)
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
        if tile_entity.type == "zombie" or tile_entity.type == "swirl" then
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

    local target_positions = {}
    if on_dogfloor and state.dog then
      if state.dog.pos[1] < zombie.pos[1] then
        table.insert(target_positions, {zombie.pos[1] - 1, zombie.pos[2]})
      end
      if state.dog.pos[1] > zombie.pos[1] then
        table.insert(target_positions, {zombie.pos[1] + 1, zombie.pos[2]})
      end
      if state.dog.pos[2] < zombie.pos[2] then
        table.insert(target_positions, {zombie.pos[1],     zombie.pos[2] - 1})
      end
      if state.dog.pos[2] > zombie.pos[2] then
        table.insert(target_positions, {zombie.pos[1],     zombie.pos[2] + 1})
      end
    else
      table.insert(target_positions, {zombie.pos[1] + zombie.direction[1], zombie.pos[2] + zombie.direction[2]})
    end

    local blocking = {}

    for _, target_pos in pairs(target_positions) do
      blocking = {}

      if simulation._is_passable(state, zombie, target_pos[1], target_pos[2], blocking) then
        simulation._move_entity(state, zombie, target_pos[1], target_pos[2])
        break
      end
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

    if blocking[1] and (blocking[1].type == "human" or blocking[1].type == "dog") then
      simulation._entity_die(state, blocking[1])
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

    if blocking[1] and blocking[1].type == "swirl" then
      simulation._remove_entity(state, knife)
      return
    end

    if blocking[1] and blocking[1].type == "zombie" then
      simulation._remove_entity(state, knife)
      simulation._entity_die(state, blocking[1])
      return
    end

    knife.moved = knife.moved + 1
    if knife.moved >= 5 then
      simulation._remove_entity(state, knife)
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

  if player_vector[1] ~= 0 or player_vector[2] ~= 0 then
    simulation._move_player(state, player_vector)
  end

  if love.keyboard.isDown("space") then
    simulation._shoot(state)
  end
end

simulation._update_spawns = function(state, entities)

  -- wait for the last phase of the wave to finish, then wait an addition few seconds between waves
  if state.wave_phase == 1 then
    for _, entity in pairs(entities) do
      if entity.type == "zombie" then
        state.next_wave_tick = state.tick + 60 * 3 -- wait between waves
        return
      end
    end
  end

  if state.tick >= state.next_wave_tick then

    local spawners_by_side = {top = {}, bottom = {}, left = {}, right = {}}
    for _, entity in pairs(entities) do
      if entity.type == "spawner" then
        table.insert(spawners_by_side[entity.side], entity)
      end
    end

    local spawn_zombies = function(spawners, to_spawn)
      for _=1,to_spawn do
        local zombie = {type = "zombie", pos = {0, 0}, creation = state.tick}

        for _=1,20 do
          local index = math.floor(math.random() * (#spawners-1)) + 1
          local try_pos = {unpack(spawners[index].pos)}

          if simulation._is_passable(state, zombie, try_pos[1], try_pos[2]) then
            zombie.pos = try_pos
            zombie.direction = {unpack(spawners[index].direction)}
            table.insert(state.level[zombie.pos[2]][zombie.pos[1]].entities, zombie)
            break
          end
        end
      end
    end

    local wave = constants.waves[state.wave]

    if wave then
      local wave_phase = wave[state.wave_phase]
      state.wave_display = state.wave

      --print("spawning wave " .. state.wave .. ", phase " .. state.wave_phase)

      local spawn_side = function(side)
        if wave_phase[side] then
          spawn_zombies(spawners_by_side[side], wave_phase[side])
        end
      end

      spawn_side("left")
      spawn_side("right")
      spawn_side("top")
      spawn_side("bottom")


      state.wave_phase = state.wave_phase + 1
      if constants.waves[state.wave][state.wave_phase] == nil then
        state.wave_phase = 1
        state.wave = state.wave + 1
      end

      state.next_wave_tick = state.tick + wave_phase.wait
    else
      -- you're winner!
    end
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

  simulation._update_spawns(state, entities)
end

return simulation