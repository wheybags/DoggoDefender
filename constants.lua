local constants = {}

constants.tile_size = 8
constants.render_scale = 8

constants.level_ascii = [[
TTTTTTTTTTTTT
TTTTTTTTTTTTT
`````````````
`````````````
`````````````
`````````````
m-----------,
]           [
]           [
]xxxxxxxxxxx[
]xxxxxdxxxxx[
]xxxxxxxxxxx[
]     h     [
]           [
/-----------.
`````````````
`````````````
`````````````
`````````````
BBBBBBBBBBBBB
BBBBBBBBBBBBB
]]

constants.screen_tiles_width = #constants.level_ascii:gmatch("([^\n]*)\n?")()

constants.screen_tiles_height = -1
local tmp = constants.level_ascii:gmatch("([^\n]*)\n?")
for _ in tmp do
  constants.screen_tiles_height = constants.screen_tiles_height + 1
end

constants.screen_offset_y = 1


constants.waves = {}
constants.waves[1] =
{
  {
    wait = 60 * 3
  },
  {
    bottom = 3,
    wait = 60 * 10,
  }
}
constants.waves[2] =
{
  {
    bottom = 3,
    wait = 60 * 2,
  },
  {
    bottom = 3,
    wait = 60 * 2,
  },
  {
    bottom = 3,
    wait = 60 * 10,
  }
}
constants.waves[3] =
{
  {
    top = 5,
    wait = 60 * 2,
  },
  {
    bottom = 5,
    wait = 60 * 10,
  },
}



return constants