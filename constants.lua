local constants = {}

constants.tile_size = 8
constants.render_scale = 8

constants.level_ascii = [[
m-----------,
]xxxxxxxxxxx[
]xxxxxdxxxxx[
]xxxxxxxxxxx[
]           [
]           [
>---  h     [
]           [
]       ----<
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

constants.screen_tiles_width = #constants.level_ascii:gmatch("([^\n]*)\n?")()

constants.screen_tiles_height = -1
local tmp = constants.level_ascii:gmatch("([^\n]*)\n?")
for _ in tmp do
  constants.screen_tiles_height = constants.screen_tiles_height + 1
end



return constants