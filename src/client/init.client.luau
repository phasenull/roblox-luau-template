local Charm = require("@game/ReplicatedStorage/Packages/Charm")
local Loader = require("@game/ReplicatedStorage/Packages/Loader")
local input_atom = require("./Client/atoms/input.atom")
local PREFIX = "[client.luau]:"

Charm.subscribe(input_atom :: any, function(state, prev)
	print(PREFIX, `new input type: ${state.input}`)
end)
Loader.SpawnAll(Loader.LoadChildren(script.controllers), "OnStart")
Loader.SpawnAll(Loader.LoadDescendants(script.ui), "OnStart")
print(PREFIX, "Loaded controllers.")